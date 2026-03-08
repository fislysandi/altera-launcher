(defpackage #:altera-launcher.extensions.ui-gtk.runner
  (:use #:cl #:gtk #:gobject #:gdk)
  (:import-from #:altera-launcher
                #:list-launcher-options
                #:run-command)
  (:import-from #:altera-launcher.extensions.ui-theme
                #:active-theme-name
                #:active-theme-tokens)
  (:import-from #:altera-launcher.extensions.keymap-engine
                #:resolve-key-action
                #:current-keymap-profile)
  (:export #:run-launcher-window))

(in-package #:altera-launcher.extensions.ui-gtk.runner)

(defparameter *control-mask-bit* (ash 1 2)
  "Bit mask used to detect Ctrl modifier in GTK key event state.")
(defparameter *mod1-mask-bit* (ash 1 3)
  "Bit mask used to detect Alt modifier in GTK key event state.")
(defparameter *super-mask-bit* (ash 1 26)
  "Bit mask used to detect Super modifier in GTK key event state.")

(defun nested-plist-get (plist key)
  "Return value for KEY from PLIST."
  (getf plist key))

(defun theme-color (tokens color-key fallback)
  "Return theme color COLOR-KEY from TOKENS palette or FALLBACK."
  (or (getf (nested-plist-get tokens :palette) color-key)
      fallback))

(defun key-hints-text ()
  "Return footer key hint text for current keymap profile."
  (if (string= (current-keymap-profile) "emacs")
      "Ctrl+n/p move  Enter launch  Ctrl+b actions  Ctrl+g close"
      "j/k move  Enter launch  Ctrl+b actions  Esc close"))

(defun build-theme-css ()
  "Build GTK CSS string from active theme tokens."
  (let* ((tokens (active-theme-tokens))
         (bg (theme-color tokens :background "#1f252b"))
         (fg (theme-color tokens :foreground "#f0f4f7"))
         (primary (theme-color tokens :primary "#5db2a4"))
         (accent (theme-color tokens :accent "#f08a4b")))
    (format nil
            "window { background-color: ~A; color: ~A; }~%
             entry { border-radius: 12px; padding: 12px 14px; background-color: rgba(0,0,0,0.15); color: ~A; border: 1px solid rgba(255,255,255,0.12); }~%
             list { background-color: rgba(0,0,0,0.08); border-radius: 12px; }~%
             list row { padding: 10px 12px; border-radius: 8px; }~%
             list row:selected { background-color: rgba(255,255,255,0.1); border-left: 3px solid ~A; }~%
             label { color: ~A; }~%"
            bg fg fg primary primary)))

(defun write-theme-css-temp-file (css)
  "Write CSS to a temporary file and return pathname."
  (let* ((base (uiop:ensure-directory-pathname
                (merge-pathnames "altera-css/" (uiop:temporary-directory))))
         (path (merge-pathnames "theme.css" base)))
    (uiop:ensure-all-directories-exist (list base))
    (with-open-file (stream path :direction :output :if-exists :supersede :if-does-not-exist :create)
      (write-string css stream))
    path))

(defun apply-theme-css-provider ()
  "Load generated theme CSS and apply it to the default GTK screen."
  (let* ((provider (gtk-css-provider-new))
         (css (build-theme-css))
         (css-path (write-theme-css-temp-file css))
         (screen (gdk-screen-get-default)))
    (gtk-css-provider-load-from-path provider (namestring css-path))
    (when screen
      (gtk-style-context-add-provider-for-screen
       screen
       provider
       +gtk-style-provider-priority-application+))))

(defun apply-window-style (window)
  "Apply baseline Altera window style to WINDOW."
  (setf (gtk-window-decorated window) nil)
  (setf (gtk-window-resizable window) nil)
  (setf (gtk-window-window-position window) :center))

(defun event-state-has-modifier-p (state modifier-keyword mask-bit)
  "Return true when STATE indicates MODIFIER-KEYWORD via MASK-BIT."
  (cond
    ((integerp state) (not (zerop (logand state mask-bit))))
    ((listp state) (member modifier-keyword state))
    (t nil)))

(defun event-state->modifiers (state)
  "Convert GTK key event STATE into sorted modifier name list."
  (let ((modifiers '()))
    (when (event-state-has-modifier-p state :control-mask *control-mask-bit*)
      (push "ctrl" modifiers))
    (when (event-state-has-modifier-p state :mod1-mask *mod1-mask-bit*)
      (push "alt" modifiers))
    (when (event-state-has-modifier-p state :super-mask *super-mask-bit*)
      (push "super" modifiers))
    (sort modifiers #'string<)))

(defun key-event->chord (event)
  "Convert GTK key EVENT to normalized chord string like ctrl+b."
  (let* ((key-name (gdk-keyval-name (gdk-event-key-keyval event)))
         (normalized-key (and key-name (string-downcase key-name)))
         (modifiers (event-state->modifiers (gdk-event-key-state event))))
    (if (or (null normalized-key) (string= normalized-key ""))
        nil
        (if modifiers
            (format nil "~{~A~^+~}+~A" modifiers normalized-key)
            normalized-key))))

(defun bounded-index (index length)
  "Clamp INDEX to valid bounds for sequence of LENGTH."
  (cond
    ((<= length 0) 0)
    ((< index 0) 0)
    ((>= index length) (1- length))
    (t index)))

(defun result-item-kind-label (entry)
  "Return display label for ENTRY kind field."
  (string-capitalize (string-downcase (string (or (getf entry :kind) :command)))))

(defun default-icon-name-for-kind (kind)
  "Return fallback icon name for option KIND."
  (if (eq kind :application)
      "application-x-executable"
      "system-run"))

(defun resolve-icon-widget (entry)
  "Create GTK image widget for ENTRY icon metadata with fallback behavior."
  (let* ((kind (or (getf entry :kind) :command))
         (icon (getf entry :icon))
         (icon-path (and (stringp icon)
                         (ignore-errors (probe-file icon))))
         (image (cond
                  (icon-path
                   (gtk-image-new-from-file (namestring icon-path)))
                  ((and (stringp icon) (not (string= icon "")))
                   (gtk-image-new-from-icon-name icon :dialog))
                  (t
                   (gtk-image-new-from-icon-name (default-icon-name-for-kind kind) :dialog)))))
    (setf (gtk-image-pixel-size image) 22)
    image))

(defun make-result-row-widget (entry)
  "Build GTK list row widget for launcher option ENTRY."
  (let* ((row (make-instance 'gtk-list-box-row))
          (container (make-instance 'gtk-hbox :homogeneous nil :spacing 12))
         (icon (resolve-icon-widget entry))
         (text-column (make-instance 'gtk-vbox :homogeneous nil :spacing 2))
         (title (make-instance 'gtk-label :label (or (getf entry :title) "") :xalign 0.0))
         (subtitle (make-instance 'gtk-label :label (or (getf entry :subtitle) "") :xalign 0.0))
         (kind (make-instance 'gtk-label :label (result-item-kind-label entry) :xalign 1.0)))
    (gtk-box-pack-start container icon :expand nil :fill nil :padding 0)
    (gtk-box-pack-start text-column title :expand t :fill t :padding 0)
    (gtk-box-pack-start text-column subtitle :expand t :fill t :padding 0)
    (gtk-box-pack-start container text-column :expand t :fill t :padding 0)
    (gtk-box-pack-start container kind :expand nil :fill nil :padding 0)
    (gtk-container-add row container)
    row))

(defun clear-list-box (list-box)
  "Destroy all rows currently present in LIST-BOX."
  (loop for row = (gtk-list-box-get-row-at-index list-box 0)
        while row
          do (gtk-widget-destroy row)))

(defun refresh-results-listbox (options selection-index list-box)
  "Render OPTIONS into LIST-BOX and select row at SELECTION-INDEX."
  (clear-list-box list-box)
  (if (null options)
      (let ((placeholder-row (make-instance 'gtk-list-box-row))
            (placeholder-label (make-instance 'gtk-label :label "No matching option" :xalign 0.0)))
        (gtk-container-add placeholder-row placeholder-label)
        (gtk-list-box-insert list-box placeholder-row -1))
      (progn
        (dolist (entry options)
          (gtk-list-box-insert list-box (make-result-row-widget entry) -1))
        (let ((row (gtk-list-box-get-row-at-index list-box selection-index)))
          (when row
            (gtk-list-box-select-row list-box row)))))
  (gtk-widget-show-all list-box))

(defun selected-option (options selection-index)
  "Return selected option from OPTIONS using bounded SELECTION-INDEX."
  (nth (bounded-index selection-index (length options)) options))

(defun format-preview-pane (option query selection-index)
  "Format preview pane text for OPTION, QUERY, and SELECTION-INDEX."
  (with-output-to-string (stream)
    (format stream "Title: ~A~%" (or (getf option :title) "No selection"))
    (format stream "Kind: ~A~%" (or (getf option :kind) :none))
    (format stream "Source: ~A~%" (or (getf option :source) "n/a"))
    (format stream "Query: ~A~%" query)
    (format stream "Selection Index: ~A~%" selection-index)
    (format stream "Command: ~A~%" (or (getf option :command) "n/a"))))

(defun format-status-rail (options selection-index)
  "Format status rail text from OPTIONS and SELECTION-INDEX."
  (let ((option (selected-option options selection-index)))
    (format nil "Theme: ~A | Results: ~A | Selected: ~A"
            (active-theme-name)
            (length options)
            (or (getf option :title) "none"))))

(defun fetch-options (runtime query)
  "Fetch launcher option items for RUNTIME filtered by QUERY."
  (list-launcher-options runtime :query query :limit 250))

(defun execute-selected-option (runtime options selection-index)
  "Execute selected option command and return status plist."
  (let ((option (selected-option options selection-index)))
    (if (and option (getf option :command))
        (handler-case
            (progn
              (apply #'run-command runtime (getf option :command) (or (getf option :args) '()))
              (list :ok t :title (getf option :title)))
          (error (condition)
            (list :ok nil :error (princ-to-string condition) :title (getf option :title))))
        (list :ok nil :error "Selected option has no command"))))

(defun make-launcher-widgets ()
  "Create and return launcher GTK widgets as a plist."
  (list :window (make-instance 'gtk-window :type :toplevel :title "Altera Launcher - GTK" :default-width 960 :default-height 520)
        :root (make-instance 'gtk-vbox :homogeneous nil :spacing 10 :border-width 14)
        :top-spacer (make-instance 'gtk-label :label "")
        :search-row (make-instance 'gtk-hbox :homogeneous nil :spacing 12)
        :search-entry (make-instance 'gtk-entry :text "")
        :content-row (make-instance 'gtk-hbox :homogeneous t :spacing 10)
        :results-scroller (make-instance 'gtk-scrolled-window)
        :results-listbox (make-instance 'gtk-list-box)
        :preview-label (gtk-label-new "")
        :bottom-spacer (make-instance 'gtk-label :label "")
        :status-label (gtk-label-new "")
        :footer-label (gtk-label-new "")))

(defun make-launcher-state (runtime)
  "Create and return mutable launcher state plist for RUNTIME."
  (list :query ""
        :options (fetch-options runtime "")
        :selection-index 0))

(defun refresh-launcher-view (state widgets)
  "Refresh launcher list, preview, and status widgets from STATE."
  (let* ((options (getf state :options))
         (selection-index (bounded-index (getf state :selection-index) (length options)))
         (query (getf state :query))
         (results-listbox (getf widgets :results-listbox))
         (preview-label (getf widgets :preview-label))
         (status-label (getf widgets :status-label)))
    (setf (getf state :selection-index) selection-index)
    (refresh-results-listbox options selection-index results-listbox)
    (gtk-label-set-text preview-label
                        (format-preview-pane (selected-option options selection-index)
                                             query
                                             selection-index))
    (gtk-label-set-text status-label (format-status-rail options selection-index))))

(defun refresh-from-query (state widgets runtime next-query)
  "Refresh launcher STATE and WIDGETS after NEXT-QUERY update."
  (setf (getf state :query) next-query
        (getf state :options) (fetch-options runtime next-query)
        (getf state :selection-index) 0)
  (refresh-launcher-view state widgets))

(defun move-selection (state widgets delta)
  "Move launcher selection in STATE by DELTA and refresh WIDGETS."
  (let* ((options (getf state :options))
         (results-listbox (getf widgets :results-listbox))
         (next-index (bounded-index (+ (getf state :selection-index) delta)
                                    (length options))))
    (setf (getf state :selection-index) next-index)
    (let ((row (gtk-list-box-get-row-at-index results-listbox next-index)))
      (when row
        (gtk-list-box-select-row results-listbox row)))
    (refresh-launcher-view state widgets)))

(defun apply-key-action (state widgets runtime action)
  "Apply key ACTION to launcher STATE, update WIDGETS, and return handled flag."
  (let ((search-entry (getf widgets :search-entry))
        (status-label (getf widgets :status-label)))
    (case action
      (:close-launcher (leave-gtk-main) t)
      (:move-next (move-selection state widgets 1) t)
      (:move-prev (move-selection state widgets -1) t)
      (:move-top
       (setf (getf state :selection-index) 0)
       (refresh-launcher-view state widgets)
       t)
      (:move-bottom
       (setf (getf state :selection-index)
             (if (getf state :options) (1- (length (getf state :options))) 0))
       (refresh-launcher-view state widgets)
       t)
      (:focus-search (gtk-widget-grab-focus search-entry) t)
      (:execute-selected
       (let* ((options (getf state :options))
              (selection-index (getf state :selection-index))
              (selected (selected-option options selection-index))
              (result (execute-selected-option runtime options selection-index)))
         (gtk-label-set-text status-label
                             (if (getf result :ok)
                                 (format nil "Executed: ~A" (or (getf result :title) "item"))
                                 (format nil "Execution failed: ~A" (or (getf result :error) "unknown"))))
         (when (and (getf result :ok)
                    (eq (getf selected :kind) :application))
           (leave-gtk-main)))
       t)
      (:open-command-actions
       (gtk-label-set-text status-label "Actions panel is not implemented yet.")
       t)
      (otherwise nil))))

(defun connect-launcher-signals (state widgets runtime)
  "Connect GTK signal handlers for launcher STATE, WIDGETS, and RUNTIME."
  (let ((window (getf widgets :window))
        (search-entry (getf widgets :search-entry))
        (results-listbox (getf widgets :results-listbox))
        (preview-label (getf widgets :preview-label))
        (status-label (getf widgets :status-label)))
    (flet ((handle-key-event (event)
             (let* ((chord (key-event->chord event))
                    (action (and chord (resolve-key-action chord (current-keymap-profile)))))
               (and action (apply-key-action state widgets runtime action)))))
      (g-signal-connect window "destroy"
                        (lambda (widget)
                          (declare (ignore widget))
                          (leave-gtk-main)))

      (g-signal-connect window "key-press-event"
                        (lambda (widget event)
                          (declare (ignore widget))
                          (handle-key-event event)))

      (g-signal-connect search-entry "key-press-event"
                        (lambda (widget event)
                          (declare (ignore widget))
                          (handle-key-event event)))

      (g-signal-connect search-entry "changed"
                        (lambda (widget)
                          (declare (ignore widget))
                          (refresh-from-query state widgets runtime (gtk-entry-text search-entry))))

      (g-signal-connect results-listbox "row-selected"
                        (lambda (widget row)
                          (declare (ignore widget))
                          (when row
                            (setf (getf state :selection-index) (gtk-list-box-row-get-index row))
                            (gtk-label-set-text preview-label
                                                (format-preview-pane (selected-option (getf state :options)
                                                                                      (getf state :selection-index))
                                                                     (getf state :query)
                                                                     (getf state :selection-index)))
                            (gtk-label-set-text status-label
                                                (format-status-rail (getf state :options)
                                                                    (getf state :selection-index))))))

      (g-signal-connect results-listbox "row-activated"
                        (lambda (widget row)
                          (declare (ignore widget))
                          (when row
                            (setf (getf state :selection-index) (gtk-list-box-row-get-index row)))
                          (apply-key-action state widgets runtime :execute-selected))))))

(defun build-launcher-layout (widgets)
  "Build and show launcher widget layout from WIDGETS."
  (let ((window (getf widgets :window))
        (root (getf widgets :root))
        (top-spacer (getf widgets :top-spacer))
        (search-row (getf widgets :search-row))
        (search-entry (getf widgets :search-entry))
        (content-row (getf widgets :content-row))
        (results-scroller (getf widgets :results-scroller))
        (results-listbox (getf widgets :results-listbox))
        (preview-label (getf widgets :preview-label))
        (bottom-spacer (getf widgets :bottom-spacer))
        (status-label (getf widgets :status-label))
        (footer-label (getf widgets :footer-label)))
    (gtk-box-pack-start root top-spacer :expand t :fill t :padding 0)
    (gtk-box-pack-start search-row search-entry :expand t :fill t :padding 120)
    (gtk-box-pack-start root search-row :expand nil :fill t :padding 0)
    (gtk-container-add results-scroller results-listbox)
    (gtk-box-pack-start content-row results-scroller :expand t :fill t :padding 0)
    (gtk-box-pack-start content-row preview-label :expand t :fill t :padding 0)
    (gtk-box-pack-start root content-row :expand t :fill t :padding 0)
    (gtk-box-pack-start root bottom-spacer :expand t :fill t :padding 0)
    (gtk-box-pack-start root status-label :expand nil :fill t :padding 0)
    (gtk-box-pack-start root footer-label :expand nil :fill t :padding 0)
    (gtk-container-add window root)
    (gtk-widget-show-all window)
    (gtk-widget-grab-focus search-entry)))

(defun run-launcher-window (runtime)
  "Run interactive GTK launcher window loop using RUNTIME option/command APIs."
  (within-main-loop
    (let* ((widgets (make-launcher-widgets))
           (state (make-launcher-state runtime))
           (window (getf widgets :window))
           (footer-label (getf widgets :footer-label)))
      (connect-launcher-signals state widgets runtime)
      (apply-window-style window)
      (apply-theme-css-provider)
      (gtk-label-set-text footer-label (key-hints-text))
      (refresh-launcher-view state widgets)
      (build-launcher-layout widgets)))
  (join-gtk-main))

(setf (fdefinition 'altera-launcher.extensions.ui-gtk::run-launcher-window-dispatch)
      #'run-launcher-window)
