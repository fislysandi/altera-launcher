(in-package #:altera-launcher.extensions.keymap-engine)

(defparameter *active-profile* nil
  "In-memory active keymap profile for current launcher session.")

(defparameter *profile-bindings*
  '(("vim" . (("j" . :move-next)
               ("k" . :move-prev)
               ("down" . :move-next)
               ("up" . :move-prev)
               ("home" . :move-top)
               ("end" . :move-bottom)
               ("return" . :execute-selected)
               ("escape" . :close-launcher)
               ("slash" . :focus-search)
               ("ctrl+b" . :open-command-actions)))
    ("emacs" . (("ctrl+n" . :move-next)
                 ("ctrl+p" . :move-prev)
                 ("down" . :move-next)
                 ("up" . :move-prev)
                 ("ctrl+a" . :move-top)
                 ("ctrl+e" . :move-bottom)
                 ("return" . :execute-selected)
                 ("ctrl+g" . :close-launcher)
                 ("ctrl+s" . :focus-search)
                 ("ctrl+b" . :open-command-actions)))))
  "Built-in key binding sets by profile name.")

(defun default-config-file ()
  "Return default launcher config pathname used by keymap engine."
  (merge-pathnames ".config/altera-launcher/config.lisp" (user-homedir-pathname)))

(defun read-launcher-config ()
  "Read launcher config plist, or return empty plist when missing."
  (let ((config-file (default-config-file)))
    (if (probe-file config-file)
        (with-open-file (stream config-file :direction :input)
          (read stream nil '()))
        '())))

(defun normalize-chord (chord)
  "Normalize CHORD to lowercase trimmed string form."
  (string-downcase (string-trim '(#\Space #\Tab) (string chord))))

(defun normalize-action (action)
  "Normalize ACTION to a keyword action symbol or NIL."
  (cond
    ((keywordp action) action)
    ((symbolp action) (intern (string-upcase (symbol-name action)) :keyword))
    ((stringp action) (intern (string-upcase action) :keyword))
    (t nil)))

(defun parse-override-entry (entry)
  "Parse one keymap override ENTRY and return (chord . action) or NIL."
  (cond
    ((and (consp entry)
          (stringp (car entry))
          (or (keywordp (cdr entry))
              (stringp (cdr entry))
              (symbolp (cdr entry))))
     (cons (normalize-chord (car entry)) (normalize-action (cdr entry))))
    ((and (listp entry)
          (= (length entry) 2)
          (stringp (first entry)))
     (cons (normalize-chord (first entry)) (normalize-action (second entry))))
    ((and (listp entry)
          (getf entry :chord)
          (getf entry :action))
     (cons (normalize-chord (getf entry :chord))
           (normalize-action (getf entry :action))))
    (t nil)))

(defun config-overrides (config)
  "Return normalized keymap override bindings from CONFIG."
  (let ((overrides (or (getf config :keymap-overrides) '())))
    (remove nil (mapcar #'parse-override-entry overrides))))

(defun configured-profile (config)
  "Return configured profile name from CONFIG, defaulting to \"vim\"."
  (let ((profile (string-downcase (or (getf config :keymap-profile) "vim"))))
    (if (assoc profile *profile-bindings* :test #'string=)
        profile
        "vim")))

(defun current-keymap-profile ()
  "Return active keymap profile, loading from config on first access."
  (or *active-profile*
      (setf *active-profile* (configured-profile (read-launcher-config)))))

(defun set-keymap-profile (profile-name)
  "Set active keymap profile to PROFILE-NAME for the current session."
  (let ((normalized (string-downcase (string profile-name))))
    (unless (assoc normalized *profile-bindings* :test #'string=)
      (error "Unknown keymap profile: ~A" profile-name))
    (setf *active-profile* normalized)))

(defun base-bindings-for-profile (profile)
  "Return base key bindings for PROFILE as a fresh alist copy."
  (copy-list (cdr (assoc profile *profile-bindings* :test #'string=))))

(defun merge-bindings (base overrides)
  "Merge OVERRIDES into BASE bindings, replacing existing chord mappings."
  (reduce (lambda (bindings override)
            (let* ((chord (car override))
                   (action (cdr override))
                   (existing (assoc chord bindings :test #'string=)))
              (if existing
                  (progn
                    (setf (cdr existing) action)
                    bindings)
                  (acons chord action bindings))))
          overrides
          :initial-value (copy-list base)))

(defun list-key-bindings (&optional (profile (current-keymap-profile)))
  "Return effective sorted key bindings for PROFILE plus config overrides."
  (let* ((config (read-launcher-config))
         (selected-profile (or profile (configured-profile config)))
         (base (base-bindings-for-profile selected-profile))
         (merged (merge-bindings base (config-overrides config))))
    (sort merged #'string< :key #'car)))

(defun resolve-key-action (chord &optional (profile (current-keymap-profile)))
  "Resolve CHORD in PROFILE to a launcher action keyword or NIL."
  (cdr (assoc (normalize-chord chord)
              (list-key-bindings profile)
              :test #'string=)))

(defun reload-keymap-config ()
  "Reload active keymap profile from launcher config and return profile name."
  (setf *active-profile* (configured-profile (read-launcher-config))))

(define-extension ("keymap-engine"
                   :version "0.1.0"
                   :description "Configurable keyboard mapping profiles for launcher UIs")
  (define-command
   "keymap.profile.current"
   (lambda (&rest args)
     (declare (ignore args))
     (current-keymap-profile))
   :title "Current Keymap Profile"
   :description "Returns active keymap profile name."
   :tags '("keymap" "config"))

  (define-command
   "keymap.profile.set"
   (lambda (profile-name &rest args)
     (declare (ignore args))
     (set-keymap-profile profile-name))
   :title "Set Keymap Profile"
   :description "Sets active keymap profile for this launcher session."
   :tags '("keymap" "config"))

  (define-command
   "keymap.bindings.list"
   (lambda (&optional profile-name &rest args)
     (declare (ignore args))
     (list-key-bindings (or profile-name (current-keymap-profile))))
   :title "List Key Bindings"
   :description "Lists effective key bindings for active profile and config overrides."
   :tags '("keymap" "config"))

  (define-command
   "keymap.bindings.resolve"
   (lambda (chord &optional profile-name &rest args)
     (declare (ignore args))
     (resolve-key-action chord (or profile-name (current-keymap-profile))))
   :title "Resolve Key Action"
   :description "Resolves a key chord like 'ctrl+b' into a launcher action keyword."
   :tags '("keymap" "engine"))

  (define-command
   "keymap.config.reload"
   (lambda (&rest args)
     (declare (ignore args))
     (reload-keymap-config))
   :title "Reload Keymap Config"
   :description "Reloads keymap profile from user config file."
   :tags '("keymap" "config")))
