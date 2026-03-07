(in-package #:altera-launcher.extensions.template)

(defun template-health-check ()
  "template-extension-ready")

(define-extension ("template"
                   :version "0.1.0"
                   :description "Example starter extension for altera-launcher")
  (define-command
   "template.health"
   (lambda (&rest args)
     (declare (ignore args))
     (template-health-check))
   :title "Template Health"
   :description "Smoke command proving the extension is wired correctly."
   :tags '("template" "example")))
