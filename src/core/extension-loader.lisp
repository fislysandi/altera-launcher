(in-package #:altera-launcher.core.extension-loader)

(define-condition duplicate-extension-error (error)
  ((name :initarg :name :reader duplicate-extension-name))
  (:report (lambda (condition stream)
             (format stream "Extension already registered: ~A"
                     (duplicate-extension-name condition)))))

(defstruct extension-spec
  name
  version
  description)

(defstruct (extension-loader
            (:constructor make-extension-loader ()))
  (extensions (make-hash-table :test #'equal)))

(defun normalize-extension-name (name)
  (string-downcase (string name)))

(defun asd-file->system-name (asd-file)
  (pathname-name asd-file))

(defun discover-extension-systems (path-patterns)
  (sort
   (loop for pattern in path-patterns
         append
         (loop for asd-file in (directory pattern)
               collect (list :asd-file (namestring asd-file)
                             :system-name (asd-file->system-name asd-file))))
   #'string<
   :key (lambda (entry) (getf entry :system-name))))

(defun register-extension (loader extension)
  (let* ((extensions (extension-loader-extensions loader))
         (name (normalize-extension-name (extension-spec-name extension))))
    (when (gethash name extensions)
      (error 'duplicate-extension-error :name name))
    (setf (gethash name extensions) extension)
    extension))

(defun find-extension (loader name)
  (gethash (normalize-extension-name name)
           (extension-loader-extensions loader)))

(defun list-extensions (loader)
  (sort
   (loop for extension being the hash-values of (extension-loader-extensions loader)
         collect extension)
   #'string<
   :key (lambda (extension) (extension-spec-name extension))))
