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
  (let* ((default-output (merge-pathnames ".tmp/perf/altera-startup.core"
                                          (repository-root)))
         (from-env (uiop:getenv "ALTERA_STARTUP_CORE_OUTPUT")))
    (if (and from-env (> (length from-env) 0))
        (pathname from-env)
        default-output)))

(defun ensure-output-directory (pathname)
  (uiop:ensure-all-directories-exist
   (list (make-pathname :name nil :type nil :defaults pathname))))

(defun main ()
  (asdf:load-asd (namestring (asd-pathname)))
  (asdf:load-system :altera-launcher)
  (let ((output (output-pathname)))
    (ensure-output-directory output)
    (format t "[perf] writing startup core: ~A~%" (namestring output))
    (sb-ext:save-lisp-and-die (namestring output)
                              :executable nil
                              :compression nil)))

(main)
