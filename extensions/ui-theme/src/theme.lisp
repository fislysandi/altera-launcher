(in-package #:altera-launcher.extensions.ui-theme)

(defparameter *theme-presets* (make-hash-table :test #'equal)
  "Registry mapping normalized theme names to theme token entries.")
(defparameter *themes-loaded-p* nil
  "Non-NIL when bundled theme files have been loaded into registry.")

(defparameter *active-theme* "atelier-light"
  "Active theme preset name used by UI extensions.")

(defun normalize-theme-name (theme-name)
  "Normalize THEME-NAME to canonical lowercase string form."
  (string-downcase (string theme-name)))

(defun register-theme-preset (theme-name tokens)
  "Register THEME-NAME with token plist TOKENS in theme preset registry."
  (setf (gethash (normalize-theme-name theme-name) *theme-presets*)
        (cons (normalize-theme-name theme-name) tokens)))

(defmacro define-theme (theme-name &rest token-plist)
  "Define one theme preset THEME-NAME with TOKEN-PLIST token sections."
  `(register-theme-preset ,theme-name ',token-plist))

(defun themes-root-directory ()
  "Return root directory containing bundled theme definition files."
  (merge-pathnames "themes/" (asdf:system-source-directory :ui-theme)))

(defun user-themes-root-directory ()
  "Return root directory containing user theme definition files."
  (merge-pathnames "themes/" (launcher-config-root)))

(defun discover-theme-files-in-directory (root-directory)
  "Return sorted theme definition file namestrings in ROOT-DIRECTORY."
  (if (probe-file root-directory)
      (sort (mapcar #'namestring
                    (directory (merge-pathnames "*/*.lisp" root-directory)))
            #'string<)
      '()))

(defun discover-theme-files ()
  "Return sorted list of user and bundled theme definition files.

User theme files are loaded first and can override bundled themes by name."
  (append (discover-theme-files-in-directory (user-themes-root-directory))
          (discover-theme-files-in-directory (themes-root-directory))))

(defun load-theme-files ()
  "Reload all bundled theme files and repopulate preset registry."
  (clrhash *theme-presets*)
  (dolist (file (discover-theme-files))
    (load file))
  (setf *themes-loaded-p* t))

(defun ensure-themes-loaded ()
  "Ensure theme presets are loaded before access."
  (unless *themes-loaded-p*
    (load-theme-files)))

(defun read-launcher-config ()
  "Read launcher config plist for theme extension, or empty plist if missing."
  (read-launcher-config-plist))

(defun apply-theme-from-config ()
  "Apply configured theme preset from user config when available."
  (ensure-themes-loaded)
  (let* ((config (read-launcher-config))
         (preset (or (getf config :theme-preset)
                     (getf config :theme)
                     *active-theme*)))
    (when (find-theme preset)
      (setf *active-theme* preset))))

(defun available-theme-presets ()
  "Return sorted list of available theme preset names."
  (ensure-themes-loaded)
  (sort (loop for key being the hash-keys of *theme-presets* collect key)
        #'string<))

(defun find-theme (theme-name)
  "Return registered theme entry for THEME-NAME or NIL."
  (ensure-themes-loaded)
  (gethash (normalize-theme-name theme-name) *theme-presets*))

(defun active-theme-name ()
  "Return active theme preset name."
  *active-theme*)

(defun set-active-theme (theme-name)
  "Set active theme to THEME-NAME when present in preset registry."
  (if (find-theme theme-name)
      (setf *active-theme* (normalize-theme-name theme-name))
      (error "Unknown theme preset: ~A" theme-name)))

(defun active-theme-tokens ()
  "Return token plist for active theme preset."
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
