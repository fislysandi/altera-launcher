(in-package #:altera-launcher.tests.extension-loader)

(deftest register-and-find-extension
  (let ((loader (make-extension-loader)))
    (register-extension
     loader
     (make-extension-spec :name "reference" :version "0.1.0" :description "ref"))
    (ok (find-extension loader "reference"))))

(deftest duplicate-extension-registration-signals-error
  (let ((loader (make-extension-loader)))
    (register-extension
     loader
     (make-extension-spec :name "reference" :version "0.1.0" :description "ref"))
    (ok (signals
         (register-extension
          loader
          (make-extension-spec :name "reference" :version "0.1.1" :description "dup"))
         'duplicate-extension-error))))

(deftest discover-extension-systems-sorts-results
  (let* ((base (uiop:ensure-directory-pathname
                (merge-pathnames "altera-loader-test/" (uiop:temporary-directory))))
         (file-a (merge-pathnames "zeta-extension.asd" base))
         (file-b (merge-pathnames "alpha-extension.asd" base)))
    (uiop:ensure-all-directories-exist (list base))
    (with-open-file (stream file-a :direction :output :if-exists :supersede :if-does-not-exist :create)
      (write-line "; stub" stream))
    (with-open-file (stream file-b :direction :output :if-exists :supersede :if-does-not-exist :create)
      (write-line "; stub" stream))
    (unwind-protect
         (equal '("alpha-extension" "zeta-extension")
                (mapcar (lambda (entry) (getf entry :system-name))
                        (discover-extension-systems (list (namestring (merge-pathnames "*.asd" base))))))
      (ignore-errors (delete-file file-a))
      (ignore-errors (delete-file file-b))
      (ignore-errors (uiop:delete-directory-tree base :validate t)))))

(deftest list-extensions-is-sorted
  (let ((loader (make-extension-loader)))
    (register-extension loader (make-extension-spec :name "zeta" :version "0.1.0" :description "z"))
    (register-extension loader (make-extension-spec :name "alpha" :version "0.1.0" :description "a"))
    (equal '("alpha" "zeta")
           (mapcar #'extension-spec-name (list-extensions loader)))))
