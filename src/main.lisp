(in-package #:altera-launcher)

(defun default-config-root ()
  (merge-pathnames ".config/altera-launcher/" (user-homedir-pathname)))

(defun default-extensions-directory (config-root)
  (merge-pathnames "extensions/" config-root))

(defun default-config-file (config-root)
  (merge-pathnames "config.lisp" config-root))

(defun default-extension-pattern (config-root)
  (namestring (merge-pathnames "*/*.asd" (default-extensions-directory config-root))))

(defun ensure-default-config-layout (config-root)
  (let ((extensions-dir (default-extensions-directory config-root))
        (config-file (default-config-file config-root)))
    (uiop:ensure-all-directories-exist (list extensions-dir))
    (unless (probe-file config-file)
      (with-open-file (stream config-file
                              :direction :output
                              :if-exists :error
                              :if-does-not-exist :create)
        (write `(:version "1"
                 :extension-paths (,(default-extension-pattern config-root))
                 :notes "Default Altera Launcher config.")
               :stream stream
               :pretty t)))))

(defun read-config-plist (config-file)
  (with-open-file (stream config-file :direction :input)
    (read stream nil '())))

(defun resolve-extension-paths (config-root)
  (let* ((config-file (default-config-file config-root))
         (config (read-config-plist config-file)))
    (or (getf config :extension-paths)
        (list (default-extension-pattern config-root)))))

(defun register-extension-system-definition (extension-entry)
  (asdf:load-asd (getf extension-entry :asd-file)))

(defun load-extension-system (loader registry extension-entry)
  (let ((altera-launcher.extensions.api:*active-loader* loader)
        (altera-launcher.extensions.api:*active-registry* registry))
    (let ((system-name (getf extension-entry :system-name)))
      (let ((system (asdf:find-system system-name nil)))
        (unless (and system (asdf:component-loaded-p system))
          (asdf:load-system system-name))))))

(defun bootstrap (&key extension-paths (config-root (default-config-root)))
  (let ((registry (make-command-registry))
        (loader (make-extension-loader))
        (paths (or extension-paths
                   (progn
                     (ensure-default-config-layout config-root)
                     (resolve-extension-paths config-root)))))
    (let ((entries (discover-extension-systems paths)))
      (dolist (entry entries)
        (register-extension-system-definition entry))
      (dolist (entry entries)
      (load-extension-system loader registry entry))
      )
    (list :registry registry
          :loader loader)))

(defun run-command (runtime command-name &rest args)
  (apply #'dispatch-command (getf runtime :registry) command-name args))

(defun list-available-commands (runtime &optional (query ""))
  (search-commands (getf runtime :registry) query))

(defun list-available-extensions (runtime)
  (mapcar
   (lambda (extension)
     (list :name (altera-launcher.core.extension-loader:extension-spec-name extension)
           :version (altera-launcher.core.extension-loader:extension-spec-version extension)
           :description (altera-launcher.core.extension-loader:extension-spec-description extension)))
   (list-extensions (getf runtime :loader))))
