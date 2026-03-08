(asdf:defsystem "ui-gtk"
  :description "GTK GUI launcher surface for altera-launcher"
  :author "altera-launcher contributors"
  :license "GPL-3.0-or-later"
  :version "0.1.0"
  :depends-on ("altera-launcher" "ui-theme" "ui-renderer" "ui-terminal" "keymap-engine" "uiop")
  :serial t
  :components ((:file "src/packages")
               (:file "src/gui")))
