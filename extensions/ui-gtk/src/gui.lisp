(in-package #:altera-launcher.extensions.ui-gtk)

(define-condition gtk-runtime-missing-error (error)
  ((message :initarg :message :reader gtk-runtime-missing-message))
  (:documentation "Raised when GTK runtime requirements are unavailable.")
  (:report (lambda (condition stream)
             (format stream "~A" (gtk-runtime-missing-message condition)))))

(defvar *gtk-runtime-ready-p* nil
  "Non-NIL when GTK runtime dependencies are loaded in this process.")

(defvar *gtk-runner-loaded-p* nil
  "Non-NIL when GTK runner implementation has been loaded in this process.")

(defun display-available-p ()
  "Return non-NIL when DISPLAY or WAYLAND display environment is available."
  (or (uiop:getenv "DISPLAY")
      (uiop:getenv "WAYLAND_DISPLAY")))

(defun project-root ()
  "Return root directory pathname for altera-launcher system source."
  (asdf:system-source-directory :altera-launcher))

(defun now-ms ()
  "Return current runtime clock value in milliseconds."
  (* 1000.0
     (/ (get-internal-real-time)
        internal-time-units-per-second)))

(defun measure-ms (thunk)
  "Execute THUNK and return two values: result and elapsed milliseconds."
  (let ((start (now-ms)))
    (values (funcall thunk)
            (- (now-ms) start))))

(defun append-phase (profile phase elapsed-ms &key details)
  "Append timing PHASE with ELAPSED-MS and optional DETAILS to PROFILE."
  (append profile
          (list (append (list :phase phase
                              :ms elapsed-ms)
                        details))))

(defun ensure-ocicl-source-registry ()
  "Ensure OCICL vendored source tree is registered for ASDF lookup."
  (let ((ocicl-root (merge-pathnames "ocicl/" (project-root))))
    (when (probe-file ocicl-root)
      (asdf:initialize-source-registry
       `(:source-registry
         (:tree ,(namestring ocicl-root))
         :inherit-configuration)))))

(defun ensure-gtk-runtime ()
  "Load GTK runtime dependencies and validate GTK package availability."
  (unless *gtk-runtime-ready-p*
    (ensure-ocicl-source-registry)
    (handler-case
        (asdf:load-system "cl-cffi-gtk")
      (error (condition)
        (error 'gtk-runtime-missing-error
               :message (format nil
                                "GTK runtime load failed (~A). Run: OCICL_LOCAL_ONLY=1 ocicl install cl-cffi-gtk"
                                condition))))
    (unless (find-package "GTK")
      (error 'gtk-runtime-missing-error
             :message "GTK package not available after load-system cl-cffi-gtk."))
    (setf *gtk-runtime-ready-p* t))
  t)

(defun ensure-gtk-runner-loaded ()
  "Load GTK runner implementation file containing run-launcher-window."
  (unless *gtk-runner-loaded-p*
    (let ((runner-file (merge-pathnames "src/gtk-runner.lisp"
                                         (asdf:system-source-directory :ui-gtk))))
      (load runner-file)
      (setf *gtk-runner-loaded-p* t)))
  t)

(defun run-launcher-window-dispatch (runtime)
  "Dispatch launcher window run call to GTK runner implementation."
  (declare (ignore runtime))
  (error 'gtk-runtime-missing-error
         :message "GTK runner implementation is not loaded."))

(defun gui-preflight-report ()
  "Return diagnostic plist for GTK runtime, display, and runner availability."
  (let ((profile '()))
    (handler-case
        (progn
          (multiple-value-bind (_ elapsed-ms)
              (measure-ms (lambda () (ensure-gtk-runtime)))
            (declare (ignore _))
            (setf profile (append-phase profile :ensure-gtk-runtime elapsed-ms)))
          (multiple-value-bind (_ elapsed-ms)
              (measure-ms (lambda () (ensure-gtk-runner-loaded)))
            (declare (ignore _))
            (setf profile (append-phase profile :ensure-gtk-runner-loaded elapsed-ms)))
          (multiple-value-bind (symbol-present elapsed-ms)
              (measure-ms (lambda () (fboundp 'run-launcher-window-dispatch)))
            (setf profile (append-phase profile :resolve-runner-symbol elapsed-ms))
            (let ((display-available (not (null (display-available-p)))))
              (setf profile (append-phase profile :display-availability-check 0.0))
              (list :ok t
                    :gtk-package-present (not (null (find-package "GTK")))
                    :display-available display-available
                    :runner-symbol-present symbol-present
                    :profile profile))))
      (error (condition)
        (list :ok nil
              :error (princ-to-string condition)
              :display-available (not (null (display-available-p)))
              :profile profile)))))

(defun gui-window-spec ()
  "Return GUI window behavior contract advertised by GTK extension."
  (list :decorated nil
        :window-position :center
        :close-on-escape t
        :search-box-position :middle
        :default-keymap-profile "vim"
        :available-keymap-profiles '("vim" "emacs")
        :keymap-customizable t
        :theme-css-bridge t
        :footer-key-hints t))

(defun resolve-runtime (&optional runtime)
  "Return provided RUNTIME or bootstrap a fresh launcher runtime."
  (or runtime
      (bootstrap)))

(defun launch-gui (&optional runtime)
  "Launch GTK window using optional RUNTIME and return runner result."
  (ensure-gtk-runtime)
  (ensure-gtk-runner-loaded)
  (run-launcher-window-dispatch (resolve-runtime runtime)))

(define-extension ("ui-gtk"
                   :version "0.1.0"
                   :description "GTK GUI launcher using theme and renderer contracts")
  (define-command
   "ui.gui.self-test"
   (lambda (&rest args)
     (declare (ignore args))
     (gui-preflight-report))
   :title "GUI Self Test"
   :description "Validates GTK runtime, runner wiring, and display availability."
   :tags '("ui" "gtk" "gui" "test"))

  (define-command
   "ui.gui.window-spec"
   (lambda (&rest args)
     (declare (ignore args))
     (gui-window-spec))
   :title "GUI Window Spec"
   :description "Reports window behavior contract for GUI tests."
   :tags '("ui" "gtk" "gui" "test"))

  (define-command
   "ui.gui.launch"
   (lambda (&optional runtime &rest args)
     (declare (ignore args))
     (launch-gui runtime)
     :ok)
   :title "Launch GTK GUI"
   :description "Opens the Altera GTK launcher window with search, results, and preview."
   :tags '("ui" "gtk" "gui")))
