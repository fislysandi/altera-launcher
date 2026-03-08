(asdf:defsystem "app-scanner"
  :description "Installed application scanner extension for Altera launcher"
  :author "altera-launcher contributors"
  :license "GPL-3.0-or-later"
  :version "0.1.0"
  :depends-on ("altera-launcher" "uiop")
  :serial t
  :components ((:file "src/packages")
               (:file "src/scanner")))
