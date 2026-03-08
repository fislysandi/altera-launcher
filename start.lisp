(require :asdf)

(defparameter *altera-runtime* nil)

(defun env-true-p (name)
  (let ((value (uiop:getenv name)))
    (and value (string= value "1"))))

(defun display-available-p ()
  (or (uiop:getenv "DISPLAY")
      (uiop:getenv "WAYLAND_DISPLAY")))

(defun sync-dependencies ()
  (uiop:run-program '("env" "OCICL_LOCAL_ONLY=1" "ocicl" "install")
                    :output *standard-output*
                    :error-output *error-output*
                    :ignore-error-status nil))

(let* ((root (or *load-truename* *default-pathname-defaults*))
       (asd-path (merge-pathnames "altera-launcher.asd" root)))
  (asdf:load-asd asd-path)
  (asdf:load-system :altera-launcher)
  (sync-dependencies)
  (let* ((bootstrap-fn (symbol-function (find-symbol "BOOTSTRAP" "ALTERA-LAUNCHER")))
         (list-extensions-fn (symbol-function (find-symbol "LIST-AVAILABLE-EXTENSIONS" "ALTERA-LAUNCHER")))
         (run-command-fn (symbol-function (find-symbol "RUN-COMMAND" "ALTERA-LAUNCHER"))))
    (setf *altera-runtime* (funcall bootstrap-fn))
    (format t "[altera] runtime bootstrapped~%")
    (format t "[altera] extensions loaded: ~A~%"
            (mapcar (lambda (entry) (getf entry :name))
                    (funcall list-extensions-fn *altera-runtime*)))
    (let ((preflight (funcall run-command-fn *altera-runtime* "ui.gui.self-test")))
      (format t "[altera] gui preflight: ~A~%" preflight)
      (cond
        ((not (getf preflight :ok))
         (format t "[altera] GUI self-test failed. Fix the reported error before launch.~%"))
        ((env-true-p "ALTERA_NO_GUI")
         (format t "[altera] ALTERA_NO_GUI=1 set, skipping GUI launch.~%"))
        ((not (display-available-p))
         (format t "[altera] no GUI display found (DISPLAY/WAYLAND_DISPLAY missing).~%"))
        (t
         (format t "[altera] launching GTK GUI...~%")
         (handler-case
             (funcall run-command-fn *altera-runtime* "ui.gui.launch" *altera-runtime*)
           (error (condition)
             (format t "[altera] failed to launch GUI: ~A~%" condition)))))))
  (values))
