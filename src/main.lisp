(in-package #:altera-launcher)

(defvar *active-runtime* nil
  "Dynamically bound runtime during command dispatch.")

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

(defun append-startup-phase (profile phase elapsed-ms &key details)
  "Append startup PHASE timing to PROFILE and return updated profile."
  (append profile
          (list (append (list :phase phase
                              :ms elapsed-ms)
                        details))))

(defun require-active-runtime ()
  "Return active runtime bound for command dispatch or signal an error."
  (or *active-runtime*
      (error "No active runtime is bound for this command invocation.")))

(defun default-config-root ()
  "Return the default user configuration root pathname."
  (altera-launcher.core.config:launcher-config-root))

(defun default-extensions-directory (config-root)
  "Return the default extension directory under CONFIG-ROOT."
  (merge-pathnames "extensions/" config-root))

(defun default-config-file (config-root)
  "Return the default config file pathname under CONFIG-ROOT."
  (altera-launcher.core.config:launcher-config-file :config-root config-root))

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
                 :enabled-extensions ()
                 :disabled-extensions ()
                 :extensions-auto-reload nil
                 :keymap-profile "vim"
                 :keymap-overrides ()
                 :theme-preset "atelier-light"
                 :notes "Default Altera Launcher config.")
                :stream stream
                :pretty t)))))

(defun read-config-plist (config-file)
  "Read CONFIG-FILE as a Lisp plist and return it.

Returns an empty list when the file contains no readable form."
  (altera-launcher.core.config:read-launcher-config-plist config-file))

(defun resolve-extension-paths (config-root)
  "Resolve extension discovery patterns from user config at CONFIG-ROOT."
  (let* ((config-file (default-config-file config-root))
         (config (read-config-plist config-file)))
    (or (getf config :extension-paths)
        (list (default-extension-pattern config-root)))))

(defun normalize-extension-id (name)
  "Normalize extension NAME to lowercase id string."
  (string-downcase (string name)))

(defun normalized-extension-list (value)
  "Return normalized extension id list from config VALUE."
  (remove-duplicates
   (loop for item in (or value '())
         when (or (stringp item) (symbolp item))
           collect (normalize-extension-id item))
   :test #'string=))

(defun resolve-extension-filters (config-root)
  "Return enabled/disabled extension filters from config at CONFIG-ROOT."
  (let* ((config-file (default-config-file config-root))
         (config (read-config-plist config-file)))
    (list :enabled (normalized-extension-list (getf config :enabled-extensions))
          :disabled (normalized-extension-list (getf config :disabled-extensions)))))

(defun extensions-auto-reload-enabled-p (config-root)
  "Return true when extension auto reload is enabled in config at CONFIG-ROOT."
  (let* ((config-file (default-config-file config-root))
         (config (read-config-plist config-file)))
    (not (null (getf config :extensions-auto-reload)))))

(defun extension-entry-enabled-p (entry filters)
  "Return true when extension ENTRY passes ENABLED/DISABLED FILTERS."
  (let* ((name (normalize-extension-id (getf entry :system-name)))
         (enabled (getf filters :enabled))
         (disabled (getf filters :disabled))
         (in-enabled (or (null enabled)
                         (member name enabled :test #'string=)))
         (in-disabled (member name disabled :test #'string=)))
    (and in-enabled (not in-disabled))))

(defun filter-extension-entries (entries filters)
  "Return ENTRIES filtered by extension FILTERS."
  (remove-if-not (lambda (entry)
                   (extension-entry-enabled-p entry filters))
                 entries))

(defun update-extension-config-lists (config-root extension-name mode)
  "Update extension enable/disable lists in config and return updated config.

MODE must be :ENABLE or :DISABLE."
  (let* ((config-file (default-config-file config-root))
         (config (read-config-plist config-file))
         (extension-id (normalize-extension-id extension-name))
         (enabled (normalized-extension-list (getf config :enabled-extensions)))
         (disabled (normalized-extension-list (getf config :disabled-extensions))))
    (ecase mode
      (:enable
       (setf enabled (adjoin extension-id enabled :test #'string=)
             disabled (remove extension-id disabled :test #'string=)))
      (:disable
       (setf disabled (adjoin extension-id disabled :test #'string=)
             enabled (remove extension-id enabled :test #'string=))))
    (setf (getf config :enabled-extensions) enabled
          (getf config :disabled-extensions) disabled)
    (altera-launcher.core.config:write-launcher-config-plist config config-file)))

(defun runtime-state-from-extensions (entries config-root &key force-reload)
  "Return fresh runtime state loaded from extension ENTRIES at CONFIG-ROOT."
  (let ((registry (make-command-registry))
        (loader (make-extension-loader))
        (option-sources (make-hash-table :test #'equal))
        (profile '()))
    (multiple-value-bind (_ elapsed-ms)
        (measure-ms (lambda ()
                      (dolist (entry entries)
                        (register-extension-system-definition entry))))
      (declare (ignore _))
      (setf profile (append-startup-phase profile
                                          :register-extension-system-definitions
                                          elapsed-ms
                                          :details (list :count (length entries)))))
    (multiple-value-bind (_ elapsed-ms)
        (measure-ms (lambda ()
                      (dolist (entry entries)
                        (load-extension-system loader
                                               registry
                                               option-sources
                                               entry
                                               :force-reload force-reload))))
      (declare (ignore _))
      (setf profile (append-startup-phase profile
                                          :load-extension-systems
                                          elapsed-ms
                                          :details (list :count (length entries)))))
    (multiple-value-bind (_ elapsed-ms)
        (measure-ms (lambda ()
                      (register-runtime-diagnostics-commands loader registry option-sources config-root)))
      (declare (ignore _))
      (setf profile (append-startup-phase profile
                                          :register-runtime-diagnostics-commands
                                          elapsed-ms)))
    (list :registry registry
          :loader loader
          :option-sources option-sources
          :startup-profile profile
          :pending-extension-entries '())))

(defun runtime-state-lazy-from-extensions (entries config-root)
  "Return fresh runtime state with extension ENTRIES deferred for lazy loading."
  (let ((registry (make-command-registry))
        (loader (make-extension-loader))
        (option-sources (make-hash-table :test #'equal))
        (profile '()))
    (multiple-value-bind (_ elapsed-ms)
        (measure-ms (lambda ()
                      (dolist (entry entries)
                        (register-extension-system-definition entry))))
      (declare (ignore _))
      (setf profile (append-startup-phase profile
                                          :register-extension-system-definitions
                                          elapsed-ms
                                          :details (list :count (length entries)))))
    (multiple-value-bind (_ elapsed-ms)
        (measure-ms (lambda ()
                      (register-runtime-diagnostics-commands loader registry option-sources config-root)))
      (declare (ignore _))
      (setf profile (append-startup-phase profile
                                          :register-runtime-diagnostics-commands
                                          elapsed-ms)))
    (list :registry registry
          :loader loader
          :option-sources option-sources
          :startup-profile profile
          :pending-extension-entries entries)))

(defun rebuild-runtime-state (runtime &key force-reload)
  "Rebuild RUNTIME state by reloading configured extension entries.

When FORCE-RELOAD is true, extension systems are loaded with ASDF force mode."
  (let* ((config-root (or (getf runtime :config-root) (default-config-root)))
         (paths (or (getf runtime :extension-paths)
                    (resolve-extension-paths config-root)))
         (explicit-paths (getf runtime :extension-paths-explicit))
         (filters (and (not explicit-paths)
                       (resolve-extension-filters config-root)))
         (entries (if filters
                      (filter-extension-entries (discover-extension-systems paths) filters)
                      (discover-extension-systems paths)))
         (fresh (runtime-state-from-extensions entries config-root
                                               :force-reload force-reload)))
    (setf (getf runtime :registry) (getf fresh :registry)
          (getf runtime :loader) (getf fresh :loader)
          (getf runtime :option-sources) (getf fresh :option-sources)
          (getf runtime :pending-extension-entries) (getf fresh :pending-extension-entries))))

(defun load-pending-extensions (runtime)
  "Load pending extension entries for RUNTIME and clear pending state."
  (let ((pending (copy-list (getf runtime :pending-extension-entries))))
    (when pending
      (multiple-value-bind (_ elapsed-ms)
          (measure-ms (lambda ()
                        (dolist (entry pending)
                          (load-extension-system (getf runtime :loader)
                                                 (getf runtime :registry)
                                                 (getf runtime :option-sources)
                                                 entry))))
        (declare (ignore _))
        (setf (getf runtime :startup-profile)
              (append-startup-phase (or (getf runtime :startup-profile) '())
                                    :lazy-load-pending-extensions
                                    elapsed-ms
                                    :details (list :count (length pending)))))
      (setf (getf runtime :pending-extension-entries) '()))
    runtime))

(defun maybe-auto-reload-runtime (runtime)
  "Reload runtime extension state when auto reload is enabled in config."
  (when (getf runtime :extensions-auto-reload)
    (handler-case
        (rebuild-runtime-state runtime :force-reload t)
      (error () runtime)))
  runtime)

(defun reload-runtime-on-demand (&optional extension-name)
  "Reload active runtime extension state and return status plist.

When EXTENSION-NAME is provided, it is included in status metadata.
The reload first attempts force mode and falls back to soft mode."
  (let ((runtime (require-active-runtime)))
    (handler-case
        (progn
          (rebuild-runtime-state runtime :force-reload t)
          (list :ok t
                :mode :forced
                :extension (and extension-name (normalize-extension-id extension-name))))
      (error (condition)
        (rebuild-runtime-state runtime)
        (list :ok t
              :mode :soft
              :extension (and extension-name (normalize-extension-id extension-name))
              :warning (princ-to-string condition))))))

(defmacro with-runtime-state ((runtime) &body body)
  "Evaluate BODY after applying optional runtime auto-reload for RUNTIME."
  `(progn
     (maybe-auto-reload-runtime ,runtime)
     ,@body))

(defun register-extension-system-definition (extension-entry)
  "Register one extension ASDF system definition from EXTENSION-ENTRY."
  (asdf:load-asd (getf extension-entry :asd-file)))

(defun load-extension-system (loader registry option-sources extension-entry &key force-reload)
  "Load one extension system with active extension bootstrap context bindings."
  (let ((altera-launcher.extensions.api:*active-loader* loader)
        (altera-launcher.extensions.api:*active-registry* registry)
        (altera-launcher.extensions.api:*active-option-sources* option-sources))
    (let ((system-name (getf extension-entry :system-name)))
      (if force-reload
          (asdf:load-system system-name :force t)
          (let ((system (asdf:find-system system-name nil)))
            (unless (and system
                         (asdf:component-loaded-p system))
              (asdf:load-system system-name)))))))

(defun extension-metadata-warnings (loader)
  "Return extension metadata warning entries for LOADER."
  (loop for extension in (list-extensions loader)
        append (remove nil
                       (list (unless (altera-launcher.core.extension-loader:extension-spec-version extension)
                               (list :type :missing-extension-version
                                     :extension (altera-launcher.core.extension-loader:extension-spec-name extension)))
                             (unless (altera-launcher.core.extension-loader:extension-spec-description extension)
                               (list :type :missing-extension-description
                                     :extension (altera-launcher.core.extension-loader:extension-spec-name extension)))
                             (unless (altera-launcher.core.extension-loader:extension-spec-author extension)
                               (list :type :missing-extension-author
                                     :extension (altera-launcher.core.extension-loader:extension-spec-name extension)))
                             (unless (altera-launcher.core.extension-loader:extension-spec-homepage extension)
                               (list :type :missing-extension-homepage
                                     :extension (altera-launcher.core.extension-loader:extension-spec-name extension)))))))

(defun command-metadata-warnings (registry)
  "Return command metadata warning entries for REGISTRY."
  (loop for command in (altera-launcher.core.command-registry:list-commands registry)
        append (remove nil
                       (list (unless (altera-launcher.core.command-registry:command-spec-title command)
                               (list :type :missing-command-title
                                     :command (altera-launcher.core.command-registry:command-spec-name command)
                                     :extension (altera-launcher.core.command-registry:command-spec-extension command)))
                             (unless (altera-launcher.core.command-registry:command-spec-description command)
                               (list :type :missing-command-description
                                     :command (altera-launcher.core.command-registry:command-spec-name command)
                                     :extension (altera-launcher.core.command-registry:command-spec-extension command)))))))

(defun options-source-metadata-warnings (option-sources)
  "Return option source metadata warning entries for OPTION-SOURCES."
  (loop for source being the hash-values of option-sources
        append (remove nil
                       (list (unless (getf source :title)
                               (list :type :missing-source-title
                                     :source (getf source :id)
                                     :extension (getf source :extension)))
                             (unless (getf source :description)
                               (list :type :missing-source-description
                                     :source (getf source :id)
                                     :extension (getf source :extension)))))))

(defun extension-contract-report (loader registry option-sources &key (query ""))
  "Return extension contract health report for active runtime registries."
  (let* ((options-report (collect-option-report option-sources :query query))
         (provider-errors (getf options-report :errors))
         (warnings (append (extension-metadata-warnings loader)
                           (command-metadata-warnings registry)
                           (options-source-metadata-warnings option-sources))))
    (list :ok (and (null provider-errors) (null warnings))
          :extensions-count (length (list-extensions loader))
          :commands-count (length (altera-launcher.core.command-registry:list-commands registry))
          :option-sources-count (hash-table-count option-sources)
          :provider-errors provider-errors
          :warnings warnings)))

(defun extension-command-count (registry extension-name)
  "Return number of commands in REGISTRY owned by EXTENSION-NAME."
  (count extension-name
         (altera-launcher.core.command-registry:list-commands registry)
         :test #'string=
         :key #'altera-launcher.core.command-registry:command-spec-extension))

(defun extension-option-source-count (option-sources extension-name)
  "Return number of option sources in OPTION-SOURCES owned by EXTENSION-NAME."
  (loop for source being the hash-values of option-sources
        count (string= extension-name (getf source :extension))))

(defun extension-health-status (error-count warning-count)
  "Return health status keyword from ERROR-COUNT and WARNING-COUNT."
  (cond
    ((plusp error-count) :error)
    ((plusp warning-count) :warning)
    (t :healthy)))

(defun extension-index-report (loader registry option-sources &key (query ""))
  "Return extension index entries with contract health status.

Each entry includes extension metadata, command/source counts, warning/error
counts, and an overall :STATUS keyword."
  (let* ((contract (extension-contract-report loader registry option-sources :query query))
         (warnings (getf contract :warnings))
         (provider-errors (getf contract :provider-errors)))
    (loop for extension in (list-extensions loader)
          for extension-name = (altera-launcher.core.extension-loader:extension-spec-name extension)
          for extension-warnings = (remove-if-not
                                    (lambda (entry)
                                      (string= extension-name (getf entry :extension)))
                                    warnings)
          for extension-errors = (remove-if-not
                                  (lambda (entry)
                                    (string= extension-name (getf entry :extension)))
                                  provider-errors)
          collect (list :name extension-name
                        :version (altera-launcher.core.extension-loader:extension-spec-version extension)
                        :description (altera-launcher.core.extension-loader:extension-spec-description extension)
                        :command-count (extension-command-count registry extension-name)
                        :option-source-count (extension-option-source-count option-sources extension-name)
                        :warning-count (length extension-warnings)
                        :error-count (length extension-errors)
                        :status (extension-health-status (length extension-errors)
                                                         (length extension-warnings))))))

(defun register-runtime-diagnostics-commands (loader registry option-sources config-root)
  "Register runtime diagnostics commands after extension load.

These commands validate extension contracts and provider health at runtime."
  (altera-launcher.core.command-registry:register-command
   registry
   (altera-launcher.core.command-registry:make-command-spec
    :name "extensions.contract.validate"
    :handler (lambda (&optional (query "") &rest args)
               (declare (ignore args))
               (extension-contract-report loader registry option-sources :query query))
    :title "Validate Extension Contracts"
    :description "Returns extension, command, and option-source contract health report."
    :extension "altera-core"
    :tags '("extensions" "diagnostics" "contracts")))
  (altera-launcher.core.command-registry:register-command
   registry
   (altera-launcher.core.command-registry:make-command-spec
    :name "extensions.index"
    :handler (lambda (&optional (query "") &rest args)
               (declare (ignore args))
               (extension-index-report loader registry option-sources :query query))
    :title "Index Extensions"
    :description "Lists loaded extensions with command/source counts and health status."
    :extension "altera-core"
    :tags '("extensions" "diagnostics" "index")))
  (altera-launcher.core.command-registry:register-command
   registry
   (altera-launcher.core.command-registry:make-command-spec
    :name "extensions.enable"
    :handler (lambda (extension-name &rest args)
               (declare (ignore args))
               (update-extension-config-lists config-root extension-name :enable)
               (list :ok t
                     :extension (normalize-extension-id extension-name)
                     :mode :enable
                     :requires-restart t))
    :title "Enable Extension"
    :description "Enables an extension in user config for next launcher start."
    :extension "altera-core"
    :tags '("extensions" "config")))
  (altera-launcher.core.command-registry:register-command
   registry
   (altera-launcher.core.command-registry:make-command-spec
    :name "extensions.disable"
    :handler (lambda (extension-name &rest args)
               (declare (ignore args))
               (update-extension-config-lists config-root extension-name :disable)
               (list :ok t
                     :extension (normalize-extension-id extension-name)
                     :mode :disable
                     :requires-restart t))
    :title "Disable Extension"
    :description "Disables an extension in user config for next launcher start."
    :extension "altera-core"
    :tags '("extensions" "config")))
  (altera-launcher.core.command-registry:register-command
   registry
   (altera-launcher.core.command-registry:make-command-spec
    :name "extensions.reload"
    :handler (lambda (&optional extension-name &rest args)
               (declare (ignore args))
               (reload-runtime-on-demand extension-name))
    :title "Reload Extensions"
     :description "Reloads extension runtime state on demand."
     :extension "altera-core"
     :tags '("extensions" "diagnostics" "reload")))
  (altera-launcher.core.command-registry:register-command
   registry
   (altera-launcher.core.command-registry:make-command-spec
    :name "startup.profile"
    :handler (lambda (&rest args)
               (declare (ignore args))
               (or (getf (require-active-runtime) :startup-profile)
                   '()))
    :title "Startup Profile"
    :description "Returns startup timing profile phases for the active runtime."
    :extension "altera-core"
    :tags '("diagnostics" "startup" "performance"))))

(defun bootstrap (&key extension-paths (config-root (default-config-root)) (lazy-load-extensions t))
  "Create and initialize a launcher runtime.

When EXTENSION-PATHS is not provided, bootstrap loads patterns from
the user config under CONFIG-ROOT and creates default config layout when needed.
Returns a plist containing runtime registries and loader state."
  (let ((profile '())
        (paths nil))
    (if extension-paths
        (setf paths extension-paths)
        (progn
          (multiple-value-bind (_ elapsed-ms)
              (measure-ms (lambda () (ensure-default-config-layout config-root)))
            (declare (ignore _))
            (setf profile (append-startup-phase profile :ensure-default-config-layout elapsed-ms)))
          (multiple-value-bind (resolved elapsed-ms)
              (measure-ms (lambda () (resolve-extension-paths config-root)))
            (setf paths resolved)
            (setf profile (append-startup-phase profile :resolve-extension-paths elapsed-ms)))))
    (let* ((filters (and (null extension-paths)
                         (multiple-value-bind (resolved elapsed-ms)
                             (measure-ms (lambda () (resolve-extension-filters config-root)))
                           (setf profile (append-startup-phase profile :resolve-extension-filters elapsed-ms))
                           resolved)))
           (discovered (multiple-value-bind (items elapsed-ms)
                           (measure-ms (lambda () (discover-extension-systems paths)))
                         (setf profile (append-startup-phase profile
                                                             :discover-extension-systems
                                                             elapsed-ms
                                                             :details (list :count (length items))))
                         items))
           (entries (if filters
                        (multiple-value-bind (filtered elapsed-ms)
                            (measure-ms (lambda () (filter-extension-entries discovered filters)))
                          (setf profile (append-startup-phase profile
                                                              :filter-extension-entries
                                                              elapsed-ms
                                                              :details (list :count (length filtered))))
                          filtered)
                        discovered))
           (state (if lazy-load-extensions
                      (runtime-state-lazy-from-extensions entries config-root)
                      (runtime-state-from-extensions entries config-root))))
      (setf profile (append profile (or (getf state :startup-profile) '())))
      (append (list :startup-profile profile
                    :config-root config-root
                    :extension-paths paths
                    :extension-paths-explicit (not (null extension-paths))
                    :lazy-load-extensions lazy-load-extensions
                    :extensions-auto-reload (extensions-auto-reload-enabled-p config-root))
              state))))

(defun run-command (runtime command-name &rest args)
  "Run COMMAND-NAME in RUNTIME with ARGS and return command result."
  (with-runtime-state (runtime)
    (let ((*active-runtime* runtime))
      (handler-case
          (apply #'dispatch-command (getf runtime :registry) command-name args)
        (altera-launcher.core.dispatcher:unknown-command-error (condition)
          (if (getf runtime :pending-extension-entries)
              (progn
                (load-pending-extensions runtime)
                (apply #'dispatch-command (getf runtime :registry) command-name args))
              (error condition)))))))

(defun list-available-commands (runtime &optional (query ""))
  "Return command metadata visible in RUNTIME, filtered by QUERY."
  (with-runtime-state (runtime)
    (search-commands (getf runtime :registry) query)))

(defun list-available-extensions (runtime)
  "Return loaded extension metadata for RUNTIME."
  (with-runtime-state (runtime)
    (mapcar
     (lambda (extension)
       (list :name (altera-launcher.core.extension-loader:extension-spec-name extension)
             :version (altera-launcher.core.extension-loader:extension-spec-version extension)
             :description (altera-launcher.core.extension-loader:extension-spec-description extension)
             :author (altera-launcher.core.extension-loader:extension-spec-author extension)
             :homepage (altera-launcher.core.extension-loader:extension-spec-homepage extension)))
     (list-extensions (getf runtime :loader)))))

(defun list-launcher-options (runtime &key (query "") source-id limit context)
  "Return normalized launcher option items for RUNTIME.

QUERY filters items by title/subtitle, SOURCE-ID scopes to one options source,
LIMIT bounds the result size, and CONTEXT is forwarded to providers."
  (with-runtime-state (runtime)
    (collect-option-items (getf runtime :option-sources)
                          :query query
                          :source-id source-id
                          :limit limit
                          :context context)))

(defun list-launcher-option-report (runtime &key (query "") source-id limit context)
  "Return launcher options and provider diagnostics for RUNTIME.

The result is a plist with :ITEMS and :ERRORS."
  (with-runtime-state (runtime)
    (collect-option-report (getf runtime :option-sources)
                           :query query
                           :source-id source-id
                           :limit limit
                           :context context)))

(defun list-extension-contract-report (runtime &key (query ""))
  "Return extension contract health report for RUNTIME."
  (with-runtime-state (runtime)
    (extension-contract-report (getf runtime :loader)
                               (getf runtime :registry)
                               (getf runtime :option-sources)
                               :query query)))

(defun list-startup-profile (runtime)
  "Return startup timing profile entries for RUNTIME."
  (with-runtime-state (runtime)
    (copy-list (or (getf runtime :startup-profile) '()))))
