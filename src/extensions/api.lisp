(in-package #:altera-launcher.extensions.api)

(define-condition extension-context-error (error)
  ((message :initarg :message :reader extension-context-error-message))
  (:report (lambda (condition stream)
             (format stream "~A" (extension-context-error-message condition)))))

(defvar *active-loader* nil)
(defvar *active-registry* nil)
(defvar *active-option-sources* nil)
(defvar *active-extension* nil)

(defun ensure-bootstrap-context ()
  (unless *active-loader*
    (error 'extension-context-error
           :message "No active extension loader is bound."))
  (unless *active-registry*
    (error 'extension-context-error
           :message "No active command registry is bound."))
  (unless *active-option-sources*
    (error 'extension-context-error
           :message "No active option source registry is bound.")))

(defun normalize-id (name)
  (string-downcase (string name)))

(defun register-extension-definition (name &key version description)
  (ensure-bootstrap-context)
  (register-extension
   *active-loader*
   (make-extension-spec :name (normalize-id name)
                        :version version
                        :description description)))

(defun define-command (name handler &key title description tags)
  (ensure-bootstrap-context)
  (register-command
   *active-registry*
   (make-command-spec :name (normalize-id name)
                      :handler handler
                      :title title
                      :description description
                      :extension *active-extension*
                      :tags tags)))

(defun register-options-source (id provider &key title description tags)
  (ensure-bootstrap-context)
  (let ((normalized-id (normalize-id id)))
    (setf (gethash normalized-id *active-option-sources*)
          (list :id normalized-id
                :title title
                :description description
                :tags tags
                :extension *active-extension*
                :provider provider))))

(defmacro define-options-source (id (query-var &optional context-var) &body body)
  (if context-var
      `(register-options-source
        ,id
        (lambda (,query-var &optional ,context-var)
          (declare (ignorable ,query-var ,context-var))
          ,@body))
      `(register-options-source
        ,id
        (lambda (,query-var &optional context)
          (declare (ignorable ,query-var context))
          ,@body))))

(defun option-match-p (item query)
  (let* ((needle (string-downcase (or query "")))
         (title (string-downcase (or (getf item :title) "")))
         (subtitle (string-downcase (or (getf item :subtitle) ""))))
    (or (string= needle "")
        (not (null (search needle title)))
        (not (null (search needle subtitle))))))

(defun normalize-option-item (source item)
  (list :id (or (getf item :id) (getf source :id))
        :title (or (getf item :title) "")
        :subtitle (or (getf item :subtitle) "")
        :kind (or (getf item :kind) :command)
        :command (getf item :command)
        :args (or (getf item :args) '())
        :source (getf source :id)
        :extension (getf source :extension)))

(defun collect-option-items (option-sources &key (query "") source-id limit)
  (let* ((normalized-source-id (and source-id (normalize-id source-id)))
         (collected
           (loop for source being the hash-values of option-sources
                 when (or (null normalized-source-id)
                          (string= normalized-source-id (getf source :id)))
                   append
                   (let ((provider (getf source :provider)))
                     (handler-case
                         (loop for item in (funcall provider query nil)
                               for normalized = (normalize-option-item source item)
                               when (option-match-p normalized query)
                                 collect normalized)
                       (error () '()))))))
    (if limit
        (subseq collected 0 (min limit (length collected)))
        collected)))

(defmacro define-extension ((name &key (version "0.1.0") description) &body body)
  `(progn
     (register-extension-definition ,name
                                    :version ,version
                                    :description ,description)
     (let ((*active-extension* (normalize-id ,name)))
       ,@body)))
