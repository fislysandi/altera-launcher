(asdf:defsystem "ui-renderer"
  :description "Launcher surface contract and layout hooks for altera-launcher"
  :author "altera-launcher contributors"
  :license "GPL-3.0-or-later"
  :version "0.1.0"
  :depends-on ("altera-launcher")
  :serial t
  :components ((:file "src/packages")
               (:file "src/renderer")))
