(defpackage #:altera-launcher.tests.command-registry
  (:use #:cl #:rove)
  (:import-from #:altera-launcher.core.command-registry
                #:make-command-registry
                #:make-command-spec
                #:register-command
                #:find-command
                #:list-commands
                #:command-spec-name
                #:duplicate-command-error))

(defpackage #:altera-launcher.tests.extension-loader
  (:use #:cl #:rove)
  (:import-from #:altera-launcher.core.extension-loader
                #:make-extension-loader
                #:make-extension-spec
                #:register-extension
                #:find-extension
                #:list-extensions
                #:discover-extension-systems
                #:extension-spec-name
                #:duplicate-extension-error))

(defpackage #:altera-launcher.tests.dispatcher
  (:use #:cl #:rove)
  (:import-from #:altera-launcher.core.command-registry
                #:make-command-registry
                #:make-command-spec
                #:register-command)
  (:import-from #:altera-launcher.core.dispatcher
                #:dispatch-command
                #:unknown-command-error))

(defpackage #:altera-launcher.tests.query
  (:use #:cl #:rove)
  (:import-from #:altera-launcher.core.command-registry
                #:make-command-registry
                #:make-command-spec
                #:register-command)
   (:import-from #:altera-launcher.core.query
                 #:search-commands
                 #:commands-for-extension))

(defpackage #:altera-launcher.tests.options-api
  (:use #:cl #:rove)
  (:import-from #:altera-launcher.extensions.api
                #:collect-option-report))

(defpackage #:altera-launcher.tests.keymap-overrides
  (:use #:cl #:rove)
  (:import-from #:altera-launcher.core.keymap-overrides
                #:parse-override-entry
                #:normalize-override-entries))

(defpackage #:altera-launcher.tests.integration
  (:use #:cl #:rove)
  (:import-from #:altera-launcher
                #:bootstrap
                #:run-command
                #:list-available-commands
                #:list-available-extensions
                #:list-launcher-options
                #:list-extension-contract-report)
  (:import-from #:altera-launcher.core.dispatcher
                #:unknown-command-error)
  (:import-from #:altera-launcher.core.config
                #:read-launcher-config-plist)
  (:import-from #:asdf
                #:system-source-directory))

(defpackage #:altera-launcher.tests.main
  (:use #:cl)
  (:import-from #:rove
                #:run))
