(defpackage #:altera-launcher.extensions.ui-terminal
  (:use #:cl #:altera-launcher.extensions.api)
  (:import-from #:altera-launcher.extensions.ui-theme
                #:active-theme-name
                #:active-theme-tokens)
  (:import-from #:altera-launcher.extensions.ui-renderer
                #:render-preview-model)
  (:export #:terminal-surface-state
           #:terminal-search
           #:terminal-select-next
           #:terminal-select-prev))
