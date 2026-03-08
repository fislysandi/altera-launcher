(in-package #:altera-launcher.extensions.ui-theme)

(defparameter *theme-presets*
  '(("atelier-light"
     :palette (:background "#f4f0e6" :foreground "#1f1a16" :primary "#ca5b2a" :accent "#2f8f7f")
     :typography (:ui "Space Grotesk" :display "Oxanium" :mono "JetBrains Mono" :scale (:sm 0.875 :md 1.0 :lg 1.25 :xl 1.75))
     :spacing (:base 4 :scale (:1 4 :2 8 :3 12 :4 16 :6 24 :8 32 :12 48))
     :motion (:duration-fast 90 :duration-medium 160 :duration-slow 280 :curve "cubic-bezier(0.22,1,0.36,1)"))
    ("graphite-dark"
     :palette (:background "#1f252b" :foreground "#f0f4f7" :primary "#5db2a4" :accent "#f08a4b")
     :typography (:ui "Outfit" :display "Space Grotesk" :mono "IBM Plex Mono" :scale (:sm 0.875 :md 1.0 :lg 1.2 :xl 1.6))
     :spacing (:base 4 :scale (:1 4 :2 8 :3 12 :4 16 :6 24 :8 32 :12 48))
     :motion (:duration-fast 80 :duration-medium 150 :duration-slow 260 :curve "cubic-bezier(0.16,1,0.3,1)"))
    ("neo-brass"
     :palette (:background "#fff6db" :foreground "#18120d" :primary "#e15c2c" :accent "#6a57d2")
     :typography (:ui "DM Sans" :display "Oxanium" :mono "Space Mono" :scale (:sm 0.9 :md 1.0 :lg 1.3 :xl 1.8))
     :spacing (:base 4 :scale (:1 4 :2 8 :3 12 :4 16 :6 24 :8 32 :12 48))
     :motion (:duration-fast 70 :duration-medium 140 :duration-slow 220 :curve "cubic-bezier(0.2,0.8,0.2,1)"))))

(defparameter *active-theme* "atelier-light")

(defun launcher-config-file ()
  (merge-pathnames ".config/altera-launcher/config.lisp" (user-homedir-pathname)))

(defun read-launcher-config ()
  (let ((path (launcher-config-file)))
    (if (probe-file path)
        (with-open-file (stream path :direction :input)
          (read stream nil '()))
        '())))

(defun apply-theme-from-config ()
  (let* ((config (read-launcher-config))
         (preset (or (getf config :theme-preset)
                     (getf config :theme)
                     *active-theme*)))
    (when (find-theme preset)
      (setf *active-theme* preset))))

(defun available-theme-presets ()
  (mapcar #'first *theme-presets*))

(defun find-theme (theme-name)
  (find theme-name *theme-presets* :key #'first :test #'string=))

(defun active-theme-name ()
  *active-theme*)

(defun set-active-theme (theme-name)
  (if (find-theme theme-name)
      (setf *active-theme* theme-name)
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
