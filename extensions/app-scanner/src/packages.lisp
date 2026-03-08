(defpackage #:altera-launcher.extensions.app-scanner
  (:use #:cl #:altera-launcher.extensions.api)
  (:import-from #:uiop
                #:read-file-lines
                #:launch-program)
  (:export #:refresh-app-index
           #:list-apps
           #:launch-app-by-id))
