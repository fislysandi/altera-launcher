(in-package #:altera-launcher.core.extension-loader)

(define-condition duplicate-extension-error (error)
  ((name :initarg :name :reader duplicate-extension-name))
  (:documentation "Raised when an extension is registered more than once by name.")
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
  "Normalize NAME to canonical extension identifier form."
  (string-downcase (string name)))

(defun asd-file->system-name (asd-file)
  "Derive ASDF system name from ASD-FILE pathname."
  (pathname-name asd-file))

(defun discover-extension-systems (path-patterns)
  "Discover extension system entries from PATH-PATTERNS.

Each entry is a plist containing :ASD-FILE and :SYSTEM-NAME."
  (sort
   (loop for pattern in path-patterns
         append
         (loop for asd-file in (directory pattern)
               collect (list :asd-file (namestring asd-file)
                             :system-name (asd-file->system-name asd-file))))
   #'string<
   :key (lambda (entry) (getf entry :system-name))))

(defun register-extension (loader extension)
  "Register EXTENSION in LOADER and return it.

Signals DUPLICATE-EXTENSION-ERROR for duplicate normalized names."
  (let* ((extensions (extension-loader-extensions loader))
         (name (normalize-extension-name (extension-spec-name extension))))
    (when (gethash name extensions)
      (error 'duplicate-extension-error :name name))
    (setf (gethash name extensions) extension)
    extension))

(defun find-extension (loader name)
  "Find extension NAME in LOADER and return extension spec or NIL."
  (gethash (normalize-extension-name name)
           (extension-loader-extensions loader)))

(defun list-extensions (loader)
  "Return all registered extensions sorted by extension name."
  (sort
   (loop for extension being the hash-values of (extension-loader-extensions loader)
         collect extension)
   #'string<
   :key (lambda (extension) (extension-spec-name extension))))
