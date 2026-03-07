(in-package #:altera-launcher.extensions.api)

(define-condition extension-context-error (error)
  ((message :initarg :message :reader extension-context-error-message))
  (:report (lambda (condition stream)
             (format stream "~A" (extension-context-error-message condition)))))

(defvar *active-loader* nil)
(defvar *active-registry* nil)
(defvar *active-extension* nil)

(defun ensure-bootstrap-context ()
  (unless *active-loader*
    (error 'extension-context-error
           :message "No active extension loader is bound."))
  (unless *active-registry*
    (error 'extension-context-error
           :message "No active command registry is bound.")))

(defun register-extension-definition (name &key version description)
  (ensure-bootstrap-context)
  (register-extension
   *active-loader*
   (make-extension-spec :name (string-downcase (string name))
                        :version version
                        :description description)))

(defun define-command (name handler &key title description tags)
  (ensure-bootstrap-context)
  (register-command
   *active-registry*
   (make-command-spec :name (string-downcase (string name))
                      :handler handler
                      :title title
                      :description description
                      :extension *active-extension*
                      :tags tags)))

(defmacro define-extension ((name &key (version "0.1.0") description) &body body)
  `(progn
     (register-extension-definition ,name
                                    :version ,version
                                    :description ,description)
     (let ((*active-extension* (string-downcase (string ,name))))
       ,@body)))
