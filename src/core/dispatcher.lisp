(in-package #:altera-launcher.core.dispatcher)

(define-condition unknown-command-error (error)
  ((name :initarg :name :reader unknown-command-name))
  (:documentation "Raised when dispatch is requested for an unknown command name.")
  (:report (lambda (condition stream)
             (format stream "Unknown command: ~A"
                     (unknown-command-name condition)))))

(defun dispatch-command (registry command-name &rest args)
  "Dispatch COMMAND-NAME through REGISTRY with ARGS and return command result.

Signals UNKNOWN-COMMAND-ERROR if the command is not registered."
  (let ((command (find-command registry command-name)))
    (unless command
      (error 'unknown-command-error :name command-name))
    (apply (command-spec-handler command) args)))
