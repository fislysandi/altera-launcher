(in-package #:altera-launcher.core.config)

(defun launcher-config-root ()
  "Return default user configuration root pathname for launcher config."
  (merge-pathnames ".config/altera-launcher/" (user-homedir-pathname)))

(defun launcher-config-file (&key (config-root (launcher-config-root)))
  "Return launcher config file pathname under CONFIG-ROOT."
  (merge-pathnames "config.lisp" config-root))

(defun read-launcher-config-plist (&optional (config-file (launcher-config-file)))
  "Read launcher config CONFIG-FILE as a plist, or return empty plist.

Read evaluation is disabled and non-plist forms are ignored."
  (flet ((plist-shaped-p (value)
           (and (listp value) (evenp (length value)))))
    (if (probe-file config-file)
        (with-open-file (stream config-file :direction :input)
          (let ((*read-eval* nil)
                (form (read stream nil '())))
            (if (plist-shaped-p form)
                form
                '())))
        '())))

(defun write-launcher-config-plist (config &optional (config-file (launcher-config-file)))
  "Write launcher CONFIG plist to CONFIG-FILE and return it."
  (with-open-file (stream config-file
                          :direction :output
                          :if-exists :supersede
                          :if-does-not-exist :create)
    (write config :stream stream :pretty t))
  config)
