(in-package #:altera-launcher)

(defun default-config-root ()
  "Return the default user configuration root pathname."
  (merge-pathnames ".config/altera-launcher/" (user-homedir-pathname)))

(defun default-extensions-directory (config-root)
  "Return the default extension directory under CONFIG-ROOT."
  (merge-pathnames "extensions/" config-root))

(defun default-config-file (config-root)
  "Return the default config file pathname under CONFIG-ROOT."
  (merge-pathnames "config.lisp" config-root))

(defun default-extension-pattern (config-root)
  "Return the default glob pattern used to discover extension ASDF files."
  (namestring (merge-pathnames "*/*.asd" (default-extensions-directory config-root))))

(defun ensure-default-config-layout (config-root)
  "Create default config directories and config file when missing.

The generated config includes extension path patterns and baseline runtime options."
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
                 :keymap-profile "vim"
                 :keymap-overrides ()
                 :theme-preset "atelier-light"
                 :notes "Default Altera Launcher config.")
               :stream stream
               :pretty t)))))

(defun read-config-plist (config-file)
  "Read CONFIG-FILE as a Lisp plist and return it.

Returns an empty list when the file contains no readable form."
  (with-open-file (stream config-file :direction :input)
    (read stream nil '())))

(defun resolve-extension-paths (config-root)
  "Resolve extension discovery patterns from user config at CONFIG-ROOT."
  (let* ((config-file (default-config-file config-root))
         (config (read-config-plist config-file)))
    (or (getf config :extension-paths)
        (list (default-extension-pattern config-root)))))

(defun register-extension-system-definition (extension-entry)
  "Register one extension ASDF system definition from EXTENSION-ENTRY."
  (asdf:load-asd (getf extension-entry :asd-file)))

(defun load-extension-system (loader registry option-sources extension-entry)
  "Load one extension system with active extension bootstrap context bindings."
  (let ((altera-launcher.extensions.api:*active-loader* loader)
        (altera-launcher.extensions.api:*active-registry* registry)
        (altera-launcher.extensions.api:*active-option-sources* option-sources))
    (let ((system-name (getf extension-entry :system-name)))
      (let ((system (asdf:find-system system-name nil)))
        (unless (and system (asdf:component-loaded-p system))
          (asdf:load-system system-name))))))

(defun bootstrap (&key extension-paths (config-root (default-config-root)))
  "Create and initialize a launcher runtime.

When EXTENSION-PATHS is not provided, bootstrap loads patterns from
the user config under CONFIG-ROOT and creates default config layout when needed.
Returns a plist containing runtime registries and loader state."
  (let ((registry (make-command-registry))
        (loader (make-extension-loader))
        (option-sources (make-hash-table :test #'equal))
        (paths (or extension-paths
                   (progn
                     (ensure-default-config-layout config-root)
                     (resolve-extension-paths config-root)))))
    (let ((entries (discover-extension-systems paths)))
      (dolist (entry entries)
        (register-extension-system-definition entry))
      (dolist (entry entries)
      (load-extension-system loader registry option-sources entry))
      )
    (list :registry registry
          :loader loader
          :option-sources option-sources)))

(defun run-command (runtime command-name &rest args)
  "Run COMMAND-NAME in RUNTIME with ARGS and return command result."
  (apply #'dispatch-command (getf runtime :registry) command-name args))

(defun list-available-commands (runtime &optional (query ""))
  "Return command metadata visible in RUNTIME, filtered by QUERY."
  (search-commands (getf runtime :registry) query))

(defun list-available-extensions (runtime)
  "Return loaded extension metadata for RUNTIME."
  (mapcar
   (lambda (extension)
     (list :name (altera-launcher.core.extension-loader:extension-spec-name extension)
           :version (altera-launcher.core.extension-loader:extension-spec-version extension)
           :description (altera-launcher.core.extension-loader:extension-spec-description extension)))
   (list-extensions (getf runtime :loader))))

(defun list-launcher-options (runtime &key (query "") source-id limit context)
  "Return normalized launcher option items for RUNTIME.

QUERY filters items by title/subtitle, SOURCE-ID scopes to one options source,
LIMIT bounds the result size, and CONTEXT is forwarded to providers."
  (collect-option-items (getf runtime :option-sources)
                        :query query
                        :source-id source-id
                        :limit limit
                        :context context))
