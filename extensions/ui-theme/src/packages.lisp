(defpackage #:altera-launcher.extensions.ui-theme
  (:use #:cl #:altera-launcher.extensions.api)
  (:import-from #:altera-launcher.core.config
                #:launcher-config-root
                #:read-launcher-config-plist)
  (:export #:available-theme-presets
           #:active-theme-name
           #:set-active-theme
           #:active-theme-tokens))
