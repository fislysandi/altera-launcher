(in-package #:altera-launcher.tests.integration)

(deftest bootstrap-loads-extension-projects
  (let* ((root (system-source-directory :altera-launcher))
         (pattern (namestring (merge-pathnames "extensions/*/*.asd" root)))
         (runtime (bootstrap :extension-paths (list pattern))))
    (ok (listp (run-command runtime "extensions.list")))
    (ok (member "atelier-light" (run-command runtime "ui.theme.presets") :test #'string=))
    (ok (member "dracula" (run-command runtime "ui.theme.presets") :test #'string=))
    (ok (member "catppuccin" (run-command runtime "ui.theme.presets") :test #'string=))
    (equal "graphite-dark" (run-command runtime "ui.theme.set" "graphite-dark"))
    (ok (listp (run-command runtime "ui.renderer.contract")))
    (equal "spotlight" (run-command runtime "ui.renderer.layout.set" "spotlight"))
    (ok (listp (run-command runtime "ui.renderer.preview" "open" 1)))
    (ok (listp (getf (run-command runtime "ui.terminal.state") :results-list)))
    (ok (listp (getf (run-command runtime "ui.terminal.search" "open") :results-list)))
    (ok (listp (getf (run-command runtime "ui.terminal.select.next") :selection-animation)))
    (ok (listp (run-command runtime "apps.scan.list")))
    (let ((app-options (list-launcher-options runtime :source-id "apps.scanner.options" :limit 5)))
      (ok (listp app-options)))
    (equal "vim" (run-command runtime "keymap.profile.current"))
    (equal :open-command-actions (run-command runtime "keymap.bindings.resolve" "ctrl+b"))
    (equal :move-next (run-command runtime "keymap.bindings.resolve" "j"))
    (equal "emacs" (run-command runtime "keymap.profile.set" "emacs"))
     (equal :move-next (run-command runtime "keymap.bindings.resolve" "ctrl+n"))
     (let ((contract-report (run-command runtime "extensions.contract.validate")))
       (ok (listp contract-report))
       (ok (integerp (getf contract-report :extensions-count)))
       (ok (integerp (getf contract-report :commands-count)))
       (ok (integerp (getf contract-report :option-sources-count)))
       (ok (listp (getf contract-report :provider-errors)))
       (ok (listp (getf contract-report :warnings))))
     (let ((contract-report (list-extension-contract-report runtime)))
       (ok (listp contract-report))
       (ok (eq (getf contract-report :ok)
               (null (append (getf contract-report :provider-errors)
                             (getf contract-report :warnings))))))
     (let ((options (list-launcher-options runtime :query "sync")))
       (ok (plusp (length options)))
       (ok (some (lambda (item)
                  (string= (getf item :source) "ocicl.manager.options"))
                options)))
    (let* ((all-ocicl-options
             (list-launcher-options runtime :query "" :source-id "ocicl.manager.options" :limit 20))
           (ids (mapcar (lambda (item) (getf item :id)) all-ocicl-options)))
      (equal (length ids)
             (length (remove-duplicates ids :test #'string=))))
    (let ((gui-self-test (run-command runtime "ui.gui.self-test")))
      (equal t (getf gui-self-test :ok))
      (equal t (getf gui-self-test :runner-symbol-present)))
    (let ((window-spec (run-command runtime "ui.gui.window-spec")))
      (equal nil (getf window-spec :decorated))
      (equal :center (getf window-spec :window-position))
      (equal t (getf window-spec :close-on-escape))
      (equal :middle (getf window-spec :search-box-position))
      (equal "vim" (getf window-spec :default-keymap-profile))
      (equal t (getf window-spec :keymap-customizable))
      (equal t (getf window-spec :theme-css-bridge))
      (equal t (getf window-spec :footer-key-hints)))
    (let ((manifest-install (run-command runtime "extensions.manifest.install"
                                         "extensions/extensions-manifest.lisp"
                                         t)))
      (equal t (getf manifest-install :dry-run))
      (ok (member "ui-theme" (getf manifest-install :extensions) :test #'string=)))
    (ok (>= (length (list-available-commands runtime "ui.gui")) 1))
    (equal 7 (length (list-available-extensions runtime)))))

(deftest bootstrap-creates-default-user-config-layout
  (let* ((base (uiop:ensure-directory-pathname
                (merge-pathnames "altera-config-test/" (uiop:temporary-directory))))
         (runtime (bootstrap :config-root base))
         (config-file (merge-pathnames "config.lisp" base))
         (extensions-dir (merge-pathnames "extensions/" base)))
    (unwind-protect
         (progn
           (ok (probe-file config-file))
            (ok (probe-file extensions-dir))
            (equal 0 (length (list-available-extensions runtime))))
      (ignore-errors (uiop:delete-directory-tree base :validate t)))))

(deftest bootstrap-respects-enabled-disabled-extension-config
  (let* ((base (uiop:ensure-directory-pathname
                (merge-pathnames "altera-config-filter-test/" (uiop:temporary-directory))))
         (root (system-source-directory :altera-launcher))
         (pattern (namestring (merge-pathnames "extensions/*/*.asd" root)))
         (config-file (merge-pathnames "config.lisp" base)))
    (unwind-protect
         (progn
           (uiop:ensure-all-directories-exist (list (merge-pathnames "extensions/" base)))
           (with-open-file (stream config-file
                                   :direction :output
                                   :if-exists :supersede
                                   :if-does-not-exist :create)
             (write `(:version "1"
                      :extension-paths (,pattern)
                      :enabled-extensions ()
                      :disabled-extensions ("ui-theme")
                      :extensions-auto-reload t)
                    :stream stream
                    :pretty t))
           (let ((runtime (bootstrap :config-root base)))
             (equal t (getf runtime :extensions-auto-reload))
             (ok (signals (run-command runtime "ui.theme.presets") 'unknown-command-error))
             (ok (listp (run-command runtime "extensions.index")))
             (ok (getf (run-command runtime "extensions.enable" "ui-theme") :ok))
             (ok (member "ui-theme"
                         (getf (read-launcher-config-plist config-file) :enabled-extensions)
                         :test #'string=))
             (ok (getf (run-command runtime "extensions.disable" "ui-renderer") :ok))
             (ok (member "ui-renderer"
                         (getf (read-launcher-config-plist config-file) :disabled-extensions)
                         :test #'string=))))
      (ignore-errors (uiop:delete-directory-tree base :validate t)))))

(deftest extensions-reload-applies-config-when-auto-reload-off
  (let* ((base (uiop:ensure-directory-pathname
                (merge-pathnames "altera-config-reload-test/" (uiop:temporary-directory))))
         (root (system-source-directory :altera-launcher))
         (pattern (namestring (merge-pathnames "extensions/*/*.asd" root)))
         (config-file (merge-pathnames "config.lisp" base)))
    (unwind-protect
         (progn
           (uiop:ensure-all-directories-exist (list (merge-pathnames "extensions/" base)))
           (with-open-file (stream config-file
                                   :direction :output
                                   :if-exists :supersede
                                   :if-does-not-exist :create)
             (write `(:version "1"
                      :extension-paths (,pattern)
                      :enabled-extensions ()
                      :disabled-extensions ("ui-theme")
                      :extensions-auto-reload nil)
                    :stream stream
                    :pretty t))
            (let ((runtime (bootstrap :config-root base)))
              (ok (null (getf runtime :extensions-auto-reload)))
              (ok (signals (run-command runtime "ui.theme.presets") 'unknown-command-error))
              (ok (getf (run-command runtime "extensions.enable" "ui-theme") :ok))
              (ok (signals (run-command runtime "ui.theme.presets") 'unknown-command-error))
              (let ((reload (run-command runtime "extensions.reload" "ui-theme")))
                (ok (getf reload :ok))
                (ok (member (getf reload :mode) '(:forced :soft)))
                (if (eq (getf reload :mode) :forced)
                    (ok (listp (run-command runtime "ui.theme.presets")))
                    (ok (signals (run-command runtime "ui.theme.presets")
                                 'unknown-command-error))))))
       (ignore-errors (uiop:delete-directory-tree base :validate t)))))
