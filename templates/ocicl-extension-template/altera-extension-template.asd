(asdf:defsystem "altera-extension-template"
  :description "Starter template for building altera-launcher extensions"
  :author "template author"
  :license "GPL-3.0-or-later"
  :version "0.1.0"
  :depends-on ("altera-launcher")
  :serial t
  :components ((:file "src/packages")
               (:file "src/extension")))
