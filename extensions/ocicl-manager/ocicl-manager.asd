(asdf:defsystem "ocicl-manager"
  :description "OCICL-powered extension manager for altera-launcher"
  :author "altera-launcher contributors"
  :license "MIT"
  :version "0.1.0"
  :depends-on ("altera-launcher" "uiop")
  :serial t
  :components ((:file "src/packages")
               (:file "src/manager")))
