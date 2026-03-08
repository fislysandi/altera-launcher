(in-package #:altera-launcher.core.command-registry)

(define-condition duplicate-command-error (error)
  ((name :initarg :name :reader duplicate-command-name))
  (:documentation "Raised when a command is registered more than once by name.")
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
  "Create and return a new command registry hash table."
  (make-hash-table :test #'equal))

(defun normalize-command-name (name)
  "Normalize NAME to canonical command identifier form."
  (string-downcase (string name)))

(defun register-command (registry command)
  "Register COMMAND in REGISTRY.

Signals DUPLICATE-COMMAND-ERROR if a command with the same normalized name
already exists. Returns the registered command spec."
  (let ((name (normalize-command-name (command-spec-name command))))
    (when (gethash name registry)
      (error 'duplicate-command-error :name name))
    (setf (gethash name registry) command)
    command))

(defun find-command (registry name)
  "Find command NAME in REGISTRY and return its command spec or NIL."
  (gethash (normalize-command-name name) registry))

(defun list-commands (registry)
  "Return all command specs from REGISTRY sorted by command name."
  (sort
   (loop for command being the hash-values of registry collect command)
   #'string<
   :key (lambda (command) (command-spec-name command))))

(defun command-metadata (command)
  "Return a metadata plist for COMMAND suitable for query surfaces."
  (list :name (command-spec-name command)
        :title (command-spec-title command)
        :description (command-spec-description command)
        :extension (command-spec-extension command)
        :tags (copy-list (or (command-spec-tags command) '()))))
