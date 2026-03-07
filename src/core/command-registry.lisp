(in-package #:altera-launcher.core.command-registry)

(define-condition duplicate-command-error (error)
  ((name :initarg :name :reader duplicate-command-name))
  (:report (lambda (condition stream)
             (format stream "Command already registered: ~A"
                     (duplicate-command-name condition)))))

(defstruct command-spec
  name
  handler
  title
  description
  extension
  tags)

(defun make-command-registry ()
  (make-hash-table :test #'equal))

(defun normalize-command-name (name)
  (string-downcase (string name)))

(defun register-command (registry command)
  (let ((name (normalize-command-name (command-spec-name command))))
    (when (gethash name registry)
      (error 'duplicate-command-error :name name))
    (setf (gethash name registry) command)
    command))

(defun find-command (registry name)
  (gethash (normalize-command-name name) registry))

(defun list-commands (registry)
  (sort
   (loop for command being the hash-values of registry collect command)
   #'string<
   :key (lambda (command) (command-spec-name command))))

(defun command-metadata (command)
  (list :name (command-spec-name command)
        :title (command-spec-title command)
        :description (command-spec-description command)
        :extension (command-spec-extension command)
        :tags (copy-list (or (command-spec-tags command) '()))))
