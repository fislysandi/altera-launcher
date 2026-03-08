;;;; Windows OCICL bootstrap helper for CI.

(require :asdf)

(defun required-env (name)
  (or (uiop:getenv name)
      (error "Missing required environment variable: ~A" name)))

(defun detect-ocicl-exe (home)
  (let* ((candidates
           (list
             (merge-pathnames #P".local/bin/ocicl.exe" home)
             (merge-pathnames #P"AppData/Local/ocicl/ocicl.exe" home)))
         (found (find-if #'probe-file candidates)))
    (or found
        (error "Could not locate ocicl.exe. Checked:~%  ~{~A~%  ~}" candidates))))

(defun write-path-file (path output-file)
  (with-open-file (stream output-file
                          :direction :output
                          :if-exists :supersede
                          :if-does-not-exist :create)
    (write-line (namestring path) stream)))

(defun main ()
  (let* ((repo-dir (required-env "OCICL_REPO_DIR"))
         (output-file (required-env "OCICL_EXE_PATH_FILE"))
         (repo-path (uiop:ensure-directory-pathname repo-dir)))
    (format t "Bootstrapping OCICL from ~A~%" repo-path)
    (uiop:chdir repo-path)
    (load (merge-pathnames #P"setup.lisp" repo-path))
    (let ((ocicl-exe (detect-ocicl-exe (user-homedir-pathname))))
      (write-path-file ocicl-exe output-file)
      (format t "Detected ocicl executable: ~A~%" ocicl-exe))))

(handler-case
    (progn
      (main)
      (sb-ext:exit :code 0))
  (error (condition)
    (format *error-output* "bootstrap-ocicl-windows failed: ~A~%" condition)
    (sb-ext:exit :code 1)))
