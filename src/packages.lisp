(defpackage #:altera-launcher.core.command-registry
  (:use #:cl)
  (:export #:duplicate-command-error
           #:command-spec
           #:make-command-spec
           #:command-spec-name
           #:command-spec-handler
           #:command-spec-title
           #:command-spec-description
           #:command-spec-extension
           #:command-spec-tags
           #:make-command-registry
           #:register-command
           #:find-command
           #:list-commands
           #:command-metadata))

(defpackage #:altera-launcher.core.extension-loader
  (:use #:cl)
  (:export #:duplicate-extension-error
            #:extension-spec
            #:make-extension-spec
             #:extension-spec-name
            #:extension-spec-version
             #:extension-spec-description
             #:extension-spec-author
             #:extension-spec-homepage
             #:make-extension-loader
             #:discover-extension-systems
             #:register-extension
            #:find-extension
            #:list-extensions))

(defpackage #:altera-launcher.core.dispatcher
  (:use #:cl)
  (:import-from #:altera-launcher.core.command-registry
                #:find-command
                #:command-spec-handler)
  (:export #:unknown-command-error
           #:dispatch-command))

(defpackage #:altera-launcher.core.query
  (:use #:cl)
  (:import-from #:altera-launcher.core.command-registry
                #:list-commands
                #:command-metadata)
  (:export #:search-commands
           #:commands-for-extension))

(defpackage #:altera-launcher.core.config
  (:use #:cl)
  (:export #:launcher-config-root
           #:launcher-config-file
           #:read-launcher-config-plist
           #:write-launcher-config-plist))

(defpackage #:altera-launcher.core.keymap-overrides
  (:use #:cl)
  (:export #:normalize-chord
           #:normalize-action
           #:parse-override-entry
           #:normalize-override-entries))

(defpackage #:altera-launcher.core.desktop-apps
  (:use #:cl)
  (:import-from #:uiop
                #:read-file-lines
                #:launch-program
                #:split-string)
  (:export #:discover-desktop-apps
           #:launch-desktop-app-entry))

(defpackage #:altera-launcher.extensions.api
  (:use #:cl)
  (:import-from #:altera-launcher.core.command-registry
                #:make-command-spec
                #:register-command)
  (:import-from #:altera-launcher.core.extension-loader
                #:make-extension-spec
                #:register-extension)
  (:export #:*active-loader*
           #:*active-registry*
           #:*active-option-sources*
           #:define-extension
           #:define-command
           #:define-options-source
           #:collect-option-items
           #:collect-option-report))

(defpackage #:altera-launcher
  (:use #:cl)
  (:import-from #:altera-launcher.core.command-registry
                #:make-command-registry)
  (:import-from #:altera-launcher.core.extension-loader
                #:make-extension-loader
                #:discover-extension-systems
                #:list-extensions)
  (:import-from #:altera-launcher.core.dispatcher
                #:dispatch-command)
  (:import-from #:altera-launcher.core.query
                #:search-commands)
  (:import-from #:altera-launcher.extensions.api
                #:*active-loader*
                #:*active-registry*
                #:*active-option-sources*
                #:collect-option-items
                #:collect-option-report)
  (:export #:bootstrap
            #:run-command
            #:list-available-commands
            #:list-available-extensions
            #:list-launcher-options
            #:list-launcher-option-report
            #:list-extension-contract-report))
