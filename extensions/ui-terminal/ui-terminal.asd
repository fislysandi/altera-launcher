(asdf:defsystem "ui-terminal"
  :description "Terminal launcher surface consuming ui-theme and ui-renderer contracts"
  :author "altera-launcher contributors"
  :license "MIT"
  :version "0.1.0"
  :depends-on ("altera-launcher" "ui-theme" "ui-renderer")
  :serial t
  :components ((:file "src/packages")
               (:file "src/terminal")))
