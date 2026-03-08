;;;; Windows OCICL bootstrap helper for CI.

(require :asdf)

(defun required-env (name)
  (or (uiop:getenv name)
      (error "Missing required environment variable: ~A" name)))

(defun main ()
  (let* ((repo-dir (required-env "OCICL_REPO_DIR"))
         (repo-path (uiop:ensure-directory-pathname repo-dir)))
    (format t "Bootstrapping OCICL from ~A~%" repo-path)
    (uiop:chdir repo-path)
    (load (merge-pathnames #P"setup.lisp" repo-path))
    (format t "OCICL bootstrap completed.~%")))

(handler-case
    (progn
      (main)
      (sb-ext:exit :code 0))
  (error (condition)
    (format *error-output* "bootstrap-ocicl-windows failed: ~A~%" condition)
    (sb-ext:exit :code 1)))
