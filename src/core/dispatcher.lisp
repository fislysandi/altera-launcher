(in-package #:altera-launcher.core.dispatcher)

(define-condition unknown-command-error (error)
  ((name :initarg :name :reader unknown-command-name))
  (:report (lambda (condition stream)
             (format stream "Unknown command: ~A"
                     (unknown-command-name condition)))))

(defun dispatch-command (registry command-name &rest args)
  (let ((command (find-command registry command-name)))
    (unless command
      (error 'unknown-command-error :name command-name))
    (apply (command-spec-handler command) args)))
