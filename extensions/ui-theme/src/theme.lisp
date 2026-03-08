(in-package #:altera-launcher.extensions.ui-theme)

(defparameter *theme-presets* (make-hash-table :test #'equal))
(defparameter *themes-loaded-p* nil)

(defparameter *active-theme* "atelier-light")

(defun normalize-theme-name (theme-name)
  (string-downcase (string theme-name)))

(defun register-theme-preset (theme-name tokens)
  (setf (gethash (normalize-theme-name theme-name) *theme-presets*)
        (cons (normalize-theme-name theme-name) tokens)))

(defmacro define-theme (theme-name &rest token-plist)
  `(register-theme-preset ,theme-name ',token-plist))

(defun themes-root-directory ()
  (merge-pathnames "themes/" (asdf:system-source-directory :ui-theme)))

(defun discover-theme-files ()
  (sort (mapcar #'namestring (directory (merge-pathnames "*/*.lisp" (themes-root-directory))))
        #'string<))

(defun load-theme-files ()
  (clrhash *theme-presets*)
  (dolist (file (discover-theme-files))
    (load file))
  (setf *themes-loaded-p* t))

(defun ensure-themes-loaded ()
  (unless *themes-loaded-p*
    (load-theme-files)))

(defun launcher-config-file ()
  (merge-pathnames ".config/altera-launcher/config.lisp" (user-homedir-pathname)))

(defun read-launcher-config ()
  (let ((path (launcher-config-file)))
    (if (probe-file path)
        (with-open-file (stream path :direction :input)
          (read stream nil '()))
        '())))

(defun apply-theme-from-config ()
  (ensure-themes-loaded)
  (let* ((config (read-launcher-config))
         (preset (or (getf config :theme-preset)
                     (getf config :theme)
                     *active-theme*)))
    (when (find-theme preset)
      (setf *active-theme* preset))))

(defun available-theme-presets ()
  (ensure-themes-loaded)
  (sort (loop for key being the hash-keys of *theme-presets* collect key)
        #'string<))

(defun find-theme (theme-name)
  (ensure-themes-loaded)
  (gethash (normalize-theme-name theme-name) *theme-presets*))

(defun active-theme-name ()
  *active-theme*)

(defun set-active-theme (theme-name)
  (if (find-theme theme-name)
      (setf *active-theme* (normalize-theme-name theme-name))
      (error "Unknown theme preset: ~A" theme-name)))

(defun active-theme-tokens ()
  (rest (or (find-theme *active-theme*)
            (error "Active theme preset is invalid: ~A" *active-theme*))))

(define-extension ("ui-theme"
                   :version "0.1.0"
                   :description "Theme tokens, typography, spacing, and motion settings")
  (apply-theme-from-config)

  (define-command
   "ui.theme.presets"
   (lambda (&rest args)
     (declare (ignore args))
     (available-theme-presets))
   :title "List Theme Presets"
   :description "Lists available visual theme presets."
   :tags '("ui" "theme" "customization"))

  (define-command
   "ui.theme.current"
   (lambda (&rest args)
     (declare (ignore args))
     (active-theme-name))
   :title "Current Theme"
   :description "Returns the active theme preset name."
   :tags '("ui" "theme" "customization"))

  (define-command
   "ui.theme.set"
   (lambda (theme-name &rest args)
     (declare (ignore args))
     (set-active-theme theme-name))
   :title "Set Theme"
   :description "Sets the active theme preset."
   :tags '("ui" "theme" "customization"))

  (define-command
   "ui.theme.tokens"
   (lambda (&rest args)
     (declare (ignore args))
     (active-theme-tokens))
   :title "Theme Tokens"
   :description "Returns full token map for the active theme."
   :tags '("ui" "theme" "customization")))
