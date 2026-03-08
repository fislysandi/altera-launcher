(defpackage #:altera-launcher.extensions.keymap-engine
  (:use #:cl #:altera-launcher.extensions.api)
  (:import-from #:altera-launcher.core.keymap-overrides
                #:normalize-chord
                #:normalize-action
                #:parse-override-entry
                #:normalize-override-entries)
  (:import-from #:altera-launcher.core.config
                #:read-launcher-config-plist)
  (:export #:resolve-key-action
           #:current-keymap-profile
           #:set-keymap-profile
           #:list-key-bindings
           #:reload-keymap-config))
