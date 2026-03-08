(defpackage #:altera-launcher.extensions.app-scanner
  (:use #:cl #:altera-launcher.extensions.api)
  (:import-from #:altera-launcher.core.desktop-apps
                #:discover-desktop-apps
                #:launch-desktop-app-entry)
  (:export #:refresh-app-index
           #:list-apps
           #:launch-app-by-id))
