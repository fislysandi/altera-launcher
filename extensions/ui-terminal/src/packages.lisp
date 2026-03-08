(defpackage #:altera-launcher.extensions.ui-terminal
  (:use #:cl #:altera-launcher.extensions.api)
  (:import-from #:uiop
                #:read-file-lines
                #:launch-program)
  (:import-from #:altera-launcher.extensions.ui-theme
                #:active-theme-name
                #:active-theme-tokens)
  (:import-from #:altera-launcher.extensions.ui-renderer
                #:render-preview-model)
  (:export #:terminal-surface-state
           #:terminal-search
           #:terminal-select-next
           #:terminal-select-prev
           #:terminal-select-first
           #:terminal-select-last
           #:terminal-selected-item
           #:terminal-select-index
           #:terminal-execute-selected))
