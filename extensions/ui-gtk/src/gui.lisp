(in-package #:altera-launcher.extensions.ui-gtk)

(define-condition gtk-runtime-missing-error (error)
  ((message :initarg :message :reader gtk-runtime-missing-message))
  (:report (lambda (condition stream)
             (format stream "~A" (gtk-runtime-missing-message condition)))))

(defun display-available-p ()
  (or (uiop:getenv "DISPLAY")
      (uiop:getenv "WAYLAND_DISPLAY")))

(defun project-root ()
  (asdf:system-source-directory :altera-launcher))

(defun ensure-ocicl-source-registry ()
  (let ((ocicl-root (merge-pathnames "ocicl/" (project-root))))
    (when (probe-file ocicl-root)
      (asdf:initialize-source-registry
       `(:source-registry
         (:tree ,(namestring ocicl-root))
         :inherit-configuration)))))

(defun ensure-gtk-runtime ()
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
           :message "GTK package not available after load-system cl-cffi-gtk.")))

(defun ensure-gtk-runner-loaded ()
  (let ((runner-file (merge-pathnames "src/gtk-runner.lisp"
                                      (asdf:system-source-directory :ui-gtk))))
    (load runner-file)))

(defun gui-preflight-report ()
  (handler-case
      (progn
        (ensure-gtk-runtime)
        (ensure-gtk-runner-loaded)
        (list :ok t
              :gtk-package-present (not (null (find-package "GTK")))
              :display-available (not (null (display-available-p)))
              :runner-symbol-present
              (not (null (find-symbol "RUN-LAUNCHER-WINDOW"
                                      "ALTERA-LAUNCHER.EXTENSIONS.UI-GTK.RUNNER")))))
    (error (condition)
      (list :ok nil
            :error (princ-to-string condition)
            :display-available (not (null (display-available-p)))))))

(defun gui-window-spec ()
  (list :decorated nil
        :window-position :center
        :close-on-escape t
        :search-box-position :middle
        :default-keymap-profile "vim"
        :available-keymap-profiles '("vim" "emacs")
        :keymap-customizable t
        :theme-css-bridge t
        :footer-key-hints t))

(defun launch-gui (&optional runtime)
  (ensure-gtk-runtime)
  (ensure-gtk-runner-loaded)
  (unless runtime
    (error "UI GTK launch requires runtime argument for unified options pipeline."))
  (funcall (symbol-function
            (find-symbol "RUN-LAUNCHER-WINDOW" "ALTERA-LAUNCHER.EXTENSIONS.UI-GTK.RUNNER"))
           runtime))

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
