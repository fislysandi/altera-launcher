(in-package #:altera-launcher.extensions.api)

(define-condition extension-context-error (error)
  ((message :initarg :message :reader extension-context-error-message))
  (:documentation "Raised when extension registration runs without bootstrap bindings.")
  (:report (lambda (condition stream)
             (format stream "~A" (extension-context-error-message condition)))))

(defvar *active-loader* nil)
(defvar *active-registry* nil)
(defvar *active-option-sources* nil)
(defvar *active-extension* nil)

(defun ensure-bootstrap-context ()
  "Ensure active extension bootstrap dynamic bindings are present.

Signals EXTENSION-CONTEXT-ERROR when called outside extension load context."
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
  "Normalize NAME to canonical lowercase identifier string."
  (string-downcase (string name)))

(defun register-extension-definition (name &key version description author homepage)
  "Register extension metadata for NAME in the active loader context."
  (ensure-bootstrap-context)
  (register-extension
   *active-loader*
   (make-extension-spec :name (normalize-id name)
                        :version version
                        :description description
                        :author author
                        :homepage homepage)))

(defun define-command (name handler &key title description tags)
  "Register a command in the active registry under the active extension context."
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
  "Register PROVIDER as an options source under ID.

Provider receives QUERY and optional CONTEXT, and should return one item plist
or a list of item plists."
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
  "Define and register an options source provider in extension context.

BODY should return one option plist or a list of option plists."
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
  "Return true when ITEM title or subtitle matches QUERY."
  (let* ((needle (string-downcase (or query "")))
         (title (string-downcase (or (getf item :title) "")))
         (subtitle (string-downcase (or (getf item :subtitle) ""))))
    (or (string= needle "")
        (not (null (search needle title)))
        (not (null (search needle subtitle))))))

(defun normalize-option-item (source item)
  "Normalize ITEM emitted by SOURCE to launcher option contract shape."
  (let* ((raw-id (or (getf item :id) (getf source :id)))
         (normalized-id (normalize-id raw-id)))
    (list :id normalized-id
        :title (or (getf item :title) "")
        :subtitle (or (getf item :subtitle) "")
        :kind (or (getf item :kind) :command)
        :icon (getf item :icon)
        :command (getf item :command)
        :args (or (getf item :args) '())
        :source (getf source :id)
        :extension (getf source :extension))))

(defun option-item-valid-p (item)
  "Return true when ITEM satisfies minimum launcher option validity rules."
  (let ((kind (getf item :kind)))
    (and (getf item :id)
         (stringp (getf item :title))
         (or (eq kind :application)
             (and (eq kind :command)
                  (or (null (getf item :command))
                      (stringp (getf item :command))))))))

(defun provider-option-items (source query context)
  "Collect, normalize, and filter option items from one SOURCE provider."
  (let* ((provider (getf source :provider))
         (result (funcall provider query context))
         (items (if (and (listp result) (or (null result) (listp (first result))))
                    result
                    (list result))))
    (loop for item in items
          for normalized = (normalize-option-item source item)
          when (and (option-item-valid-p normalized)
                    (option-match-p normalized query))
            collect normalized)))

(defun provider-option-report (source query context)
  "Return provider result items and optional error metadata for SOURCE."
  (handler-case
      (values (provider-option-items source query context) nil)
    (error (condition)
      (values '()
              (list :source (getf source :id)
                    :extension (getf source :extension)
                    :error (princ-to-string condition))))))

(defun dedupe-option-items (items)
  "Remove duplicate option items from ITEMS by normalized :ID."
  (let ((seen (make-hash-table :test #'equal)))
    (loop for item in items
          for id = (getf item :id)
          unless (gethash id seen)
            do (setf (gethash id seen) t)
               and collect item)))

(defun sort-option-items (items)
  "Sort ITEMS by case-insensitive title, then by id for stable ordering."
  (sort items
        (lambda (a b)
          (let ((title-a (string-downcase (getf a :title)))
                (title-b (string-downcase (getf b :title))))
            (or (string< title-a title-b)
                (and (string= title-a title-b)
                     (string< (getf a :id) (getf b :id))))))))

(defun collect-option-items (option-sources &key (query "") source-id limit context)
  "Return normalized launcher options from OPTION-SOURCES.

Aggregates provider results, applies validation/filtering, deduplicates by id,
sorts output for stable UI consumption, and optionally applies LIMIT."
  (let* ((report (collect-option-report option-sources
                                        :query query
                                        :source-id source-id
                                        :limit limit
                                        :context context))
         (stable-items (getf report :items)))
    stable-items))

(defun collect-option-report (option-sources &key (query "") source-id limit context)
  "Return launcher options and provider diagnostics from OPTION-SOURCES.

The returned plist has keys :ITEMS and :ERRORS."
  (let ((normalized-source-id (and source-id (normalize-id source-id)))
        (collected '())
        (errors '()))
    (maphash
     (lambda (_ source)
       (declare (ignore _))
       (when (or (null normalized-source-id)
                 (string= normalized-source-id (getf source :id)))
         (multiple-value-bind (items item-error)
             (provider-option-report source query context)
           (setf collected (nconc collected items))
           (when item-error
             (push item-error errors)))))
     option-sources)
    (let ((stable-items (sort-option-items (dedupe-option-items collected))))
      (list :items (if limit
                       (subseq stable-items 0 (min limit (length stable-items)))
                       stable-items)
            :errors (nreverse errors)))))

(defmacro define-extension ((name &key (version "0.1.0") description author homepage) &body body)
  "Register extension metadata and evaluate BODY in active extension scope."
  `(progn
     (register-extension-definition ,name
                                    :version ,version
                                    :description ,description
                                    :author ,author
                                    :homepage ,homepage)
     (let ((*active-extension* (normalize-id ,name)))
        ,@body)))
