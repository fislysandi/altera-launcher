(defpackage #:altera-launcher.extensions.ocicl-manager
  (:use #:cl #:altera-launcher.extensions.api)
  (:import-from #:uiop
                #:run-program
                #:getcwd)
  (:export #:ocicl-sync
           #:ocicl-install
           #:ocicl-extension-list
           #:read-extensions-manifest
           #:manifest-extension-names
           #:manifest-ocicl-projects
           #:install-from-manifest))
