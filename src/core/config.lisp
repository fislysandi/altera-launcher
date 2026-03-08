(in-package #:altera-launcher.core.config)

(defun launcher-config-root ()
  "Return default user configuration root pathname for launcher config."
  (merge-pathnames ".config/altera-launcher/" (user-homedir-pathname)))

(defun launcher-config-file (&key (config-root (launcher-config-root)))
  "Return launcher config file pathname under CONFIG-ROOT."
  (merge-pathnames "config.lisp" config-root))

(defun plist-shaped-p (value)
  "Return true when VALUE is a plist-shaped list."
  (and (listp value)
       (evenp (length value))))

(defun read-safe-form-from-file (file-path validator &key (default '()))
  "Read one form from FILE-PATH using VALIDATOR and return DEFAULT on failure."
  (if (probe-file file-path)
      (handler-case
          (with-open-file (stream file-path :direction :input)
            (let ((*read-eval* nil)
                  (form (read stream nil default)))
              (if (funcall validator form)
                  form
                  default)))
        (error () default))
      default))

(defmacro define-safe-reader (name (path-var default-path) &key default validator doc)
  "Define NAME reader that returns DEFAULT on malformed or unreadable files."
  `(defun ,name (&optional (,path-var ,default-path))
     ,doc
     (read-safe-form-from-file ,path-var ,validator :default ,default)))

(define-safe-reader read-launcher-config-plist (config-file (launcher-config-file))
  :default '()
  :validator #'plist-shaped-p
  :doc "Read launcher config CONFIG-FILE as a plist, or return empty plist.

Read evaluation is disabled and malformed/non-plist forms are ignored.")

(defun write-launcher-config-plist (config &optional (config-file (launcher-config-file)))
  "Write launcher CONFIG plist to CONFIG-FILE and return it."
  (with-open-file (stream config-file
                          :direction :output
                          :if-exists :supersede
                          :if-does-not-exist :create)
    (write config :stream stream :pretty t))
  config)
