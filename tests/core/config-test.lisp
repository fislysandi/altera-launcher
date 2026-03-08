(in-package #:altera-launcher.tests.config)

(defun manifest-like-shaped-p (value)
  (and (listp value)
       (evenp (length value))
       (or (null (getf value :extensions))
           (listp (getf value :extensions)))))

(deftest read-launcher-config-plist-returns-empty-on-invalid-input
  (let* ((base (uiop:ensure-directory-pathname
                (merge-pathnames "altera-config-read-test/" (uiop:temporary-directory))))
         (config-file (merge-pathnames "config.lisp" base)))
    (unwind-protect
         (progn
           (uiop:ensure-all-directories-exist (list base))
           (with-open-file (stream config-file
                                   :direction :output
                                   :if-exists :supersede
                                   :if-does-not-exist :create)
             (write-string "(:theme \"dracula\" :extensions" stream))
           (ok (equal '() (read-launcher-config-plist config-file)))
           (with-open-file (stream config-file
                                   :direction :output
                                   :if-exists :supersede
                                   :if-does-not-exist :create)
             (write '(1 2 3) :stream stream :pretty t))
           (ok (equal '() (read-launcher-config-plist config-file))))
      (ignore-errors (uiop:delete-directory-tree base :validate t)))))

(deftest read-safe-form-from-file-returns-default-on-invalid-input
  (let* ((base (uiop:ensure-directory-pathname
                (merge-pathnames "altera-safe-read-test/" (uiop:temporary-directory))))
         (manifest-file (merge-pathnames "extensions-manifest.lisp" base)))
    (unwind-protect
         (progn
           (uiop:ensure-all-directories-exist (list base))
           (with-open-file (stream manifest-file
                                   :direction :output
                                   :if-exists :supersede
                                   :if-does-not-exist :create)
             (write-string "(:extensions ((:name \"ui-theme\")" stream))
           (ok (equal '()
                      (read-safe-form-from-file manifest-file #'manifest-like-shaped-p :default '())))
           (with-open-file (stream manifest-file
                                   :direction :output
                                   :if-exists :supersede
                                   :if-does-not-exist :create)
             (write '(:extensions ((:name "ui-theme" :ocicl-projects ("ui-theme"))))
                    :stream stream
                    :pretty t))
           (ok (equal '(:extensions ((:name "ui-theme" :ocicl-projects ("ui-theme"))))
                      (read-safe-form-from-file manifest-file
                                               #'manifest-like-shaped-p
                                               :default '()))))
      (ignore-errors (uiop:delete-directory-tree base :validate t)))))
