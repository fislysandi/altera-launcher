(require :asdf)

(defun parent-directory (pathname)
  (let ((directory (pathname-directory pathname)))
    (make-pathname :directory (butlast directory)
                   :name nil
                   :type nil
                   :defaults pathname)))

(defun repository-root ()
  (parent-directory *load-truename*))

(defun asd-pathname ()
  (merge-pathnames "altera-launcher.asd" (repository-root)))

(defun output-pathname ()
  (let* ((platform (software-type))
         (arch (machine-type))
         (suffix (if (search "Windows" platform :test #'char-equal) ".exe" ""))
         (default-output (merge-pathnames (format nil "dist/altera-launcher-~A-~A~A"
                                                  (string-downcase platform)
                                                  (string-downcase arch)
                                                  suffix)
                                         (repository-root)))
         (from-env (uiop:getenv "ALTERA_BUILD_OUTPUT")))
    (if (and from-env (> (length from-env) 0))
        (pathname from-env)
        default-output)))

(defun ensure-output-directory (pathname)
  (uiop:ensure-all-directories-exist (list (make-pathname :name nil :type nil :defaults pathname))))

(defun main ()
  (asdf:load-asd (namestring (asd-pathname)))
  (asdf:load-system :altera-launcher)
  (let ((output (output-pathname)))
    (ensure-output-directory output)
    (format t "[build] writing executable: ~A~%" (namestring output))
    (sb-ext:save-lisp-and-die (namestring output)
                              :toplevel (lambda ()
                                          (let* ((bootstrap (symbol-function (find-symbol "BOOTSTRAP" "ALTERA-LAUNCHER")))
                                                 (run-command (symbol-function (find-symbol "RUN-COMMAND" "ALTERA-LAUNCHER")))
                                                 (list-commands (symbol-function (find-symbol "LIST-AVAILABLE-COMMANDS" "ALTERA-LAUNCHER")))
                                                 (runtime (funcall bootstrap)))
                                            (handler-case
                                                (funcall run-command runtime "ui.gui.launch")
                                              (error (condition)
                                                (format t "[build] ui.gui.launch failed: ~A~%" condition)
                                                (format t "[build] commands: ~D~%"
                                                        (length (funcall list-commands runtime "")))))))
                              :executable t
                              :compression t)))

(main)
