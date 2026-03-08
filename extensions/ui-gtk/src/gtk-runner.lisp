(defpackage #:altera-launcher.extensions.ui-gtk.runner
  (:use #:cl #:gtk #:gobject #:gdk)
  (:import-from #:altera-launcher.extensions.ui-theme
                #:active-theme-name)
  (:import-from #:altera-launcher.extensions.ui-terminal
                #:terminal-surface-state
                #:terminal-search
                #:terminal-select-next
                #:terminal-select-prev
                #:terminal-select-first
                #:terminal-select-last
                #:terminal-selected-item
                #:terminal-select-index
                #:terminal-execute-selected)
  (:import-from #:altera-launcher.extensions.keymap-engine
                #:resolve-key-action
                #:current-keymap-profile)
  (:export #:run-launcher-window))

(in-package #:altera-launcher.extensions.ui-gtk.runner)

(defparameter *control-mask-bit* (ash 1 2))
(defparameter *mod1-mask-bit* (ash 1 3))
(defparameter *super-mask-bit* (ash 1 26))

(defun event-state-has-modifier-p (state modifier-keyword mask-bit)
  (cond
    ((integerp state) (not (zerop (logand state mask-bit))))
    ((listp state) (member modifier-keyword state))
    (t nil)))

(defun event-state->modifiers (state)
  (let ((modifiers '()))
    (when (event-state-has-modifier-p state :control-mask *control-mask-bit*)
      (push "ctrl" modifiers))
    (when (event-state-has-modifier-p state :mod1-mask *mod1-mask-bit*)
      (push "alt" modifiers))
    (when (event-state-has-modifier-p state :super-mask *super-mask-bit*)
      (push "super" modifiers))
    (sort modifiers #'string<)))

(defun key-event->chord (event)
  (let* ((key-name (gdk-keyval-name (gdk-event-key-keyval event)))
         (normalized-key (and key-name (string-downcase key-name)))
         (modifiers (event-state->modifiers (gdk-event-key-state event))))
    (if (or (null normalized-key) (string= normalized-key ""))
        nil
        (if modifiers
            (format nil "~{~A~^+~}+~A" modifiers normalized-key)
            normalized-key))))

(defun apply-window-style (window)
  (setf (gtk-window-decorated window) nil)
  (setf (gtk-window-resizable window) nil)
  (setf (gtk-window-window-position window) :center))

(defun result-item-kind-label (entry)
  (let ((kind (getf entry :kind)))
    (string-capitalize (string-downcase (string kind)))))

(defun make-result-row-widget (entry)
  (let* ((row (make-instance 'gtk-list-box-row))
         (container (make-instance 'gtk-hbox :homogeneous nil :spacing 12))
         (text-column (make-instance 'gtk-vbox :homogeneous nil :spacing 2))
         (title (make-instance 'gtk-label :label (or (getf entry :title) "") :xalign 0.0))
         (subtitle (make-instance 'gtk-label :label (or (getf entry :subtitle) "") :xalign 0.0))
         (kind (make-instance 'gtk-label :label (result-item-kind-label entry) :xalign 1.0)))
    (gtk-box-pack-start text-column title :expand t :fill t :padding 0)
    (gtk-box-pack-start text-column subtitle :expand t :fill t :padding 0)
    (gtk-box-pack-start container text-column :expand t :fill t :padding 0)
    (gtk-box-pack-start container kind :expand nil :fill nil :padding 0)
    (gtk-container-add row container)
    row))

(defun clear-list-box (list-box)
  (loop for row = (gtk-list-box-get-row-at-index list-box 0)
        while row
          do (gtk-widget-destroy row)))

(defun refresh-results-listbox (state list-box)
  (clear-list-box list-box)
  (let ((results (or (getf state :results-list) '()))
        (selection-index (or (getf state :selection-index) 0)))
    (if (null results)
        (let ((placeholder-row (make-instance 'gtk-list-box-row))
              (placeholder-label (make-instance 'gtk-label :label "No matching command" :xalign 0.0)))
          (gtk-container-add placeholder-row placeholder-label)
          (gtk-list-box-insert list-box placeholder-row -1))
        (progn
          (dolist (entry results)
            (gtk-list-box-insert list-box (make-result-row-widget entry) -1))
          (let ((selected-row (gtk-list-box-get-row-at-index list-box selection-index)))
            (when selected-row
              (gtk-list-box-select-row list-box selected-row)))))))

(defun format-preview-pane (state)
  (let ((preview (getf state :preview-pane)))
    (with-output-to-string (stream)
      (format stream "Surface: ~A~%" (getf preview :surface))
      (format stream "Layout: ~A~%" (getf preview :layout))
      (format stream "Animations: ~{~A~^, ~}~%" (or (getf preview :animations) '()))
      (format stream "A11y: ~{~A~^, ~}~%" (or (getf preview :a11y) '())))))

(defun format-status-rail (state)
  (let ((rail (getf state :status-rail)))
    (format nil "Theme: ~A | Results: ~A | Selected: ~A"
            (or (getf rail :theme) (active-theme-name))
            (or (getf rail :result-count) 0)
            (or (getf rail :selection-label) "none"))))

(defun refresh-gui-state (state results-listbox preview-label status-label)
  (refresh-results-listbox state results-listbox)
  (gtk-label-set-text preview-label (format-preview-pane state))
  (gtk-label-set-text status-label (format-status-rail state)))

(defun refresh-preview-and-status (state preview-label status-label)
  (gtk-label-set-text preview-label (format-preview-pane state))
  (gtk-label-set-text status-label (format-status-rail state)))

(defun apply-key-action (action search-entry results-listbox preview-label status-label)
  (case action
    (:close-launcher
     (leave-gtk-main)
     t)
    (:move-next
     (refresh-gui-state (terminal-select-next) results-listbox preview-label status-label)
     t)
    (:move-prev
     (refresh-gui-state (terminal-select-prev) results-listbox preview-label status-label)
     t)
    (:move-top
     (refresh-gui-state (terminal-select-first) results-listbox preview-label status-label)
     t)
    (:move-bottom
     (refresh-gui-state (terminal-select-last) results-listbox preview-label status-label)
     t)
    (:focus-search
     (gtk-widget-grab-focus search-entry)
     t)
    (:execute-selected
     (let ((result (terminal-execute-selected)))
       (refresh-gui-state (terminal-surface-state) results-listbox preview-label status-label)
       (gtk-label-set-text status-label
                           (if (getf result :ok)
                               (format nil "Executed: ~A" (or (getf result :title) "item"))
                               (format nil "Execution failed: ~A" (or (getf result :error) "unknown error")))))
     t)
    (:open-command-actions
     (gtk-label-set-text status-label "Actions panel is not implemented yet.")
     t)
    (otherwise nil)))

(defun run-launcher-window ()
  (within-main-loop
    (let* ((window (make-instance 'gtk-window
                                  :type :toplevel
                                  :title "Altera Launcher - GTK"
                                  :default-width 960
                                  :default-height 520))
           (root (make-instance 'gtk-vbox :homogeneous nil :spacing 10 :border-width 14))
           (top-spacer (make-instance 'gtk-label :label ""))
           (search-row (make-instance 'gtk-hbox :homogeneous nil :spacing 12))
           (search-entry (make-instance 'gtk-entry :text ""))
           (content-row (make-instance 'gtk-hbox :homogeneous t :spacing 10))
           (results-scroller (make-instance 'gtk-scrolled-window))
           (results-listbox (make-instance 'gtk-list-box))
            (preview-label (gtk-label-new ""))
           (bottom-spacer (make-instance 'gtk-label :label ""))
           (status-label (gtk-label-new ""))
           (initial-state (terminal-surface-state)))
      (g-signal-connect window "destroy"
                        (lambda (widget)
                          (declare (ignore widget))
                          (leave-gtk-main)))

      (g-signal-connect window "key-press-event"
                        (lambda (widget event)
                          (declare (ignore widget))
                          (let* ((chord (key-event->chord event))
                                 (action (and chord (resolve-key-action chord (current-keymap-profile)))))
                            (and action
                                 (apply-key-action action search-entry results-listbox preview-label status-label)))))

      (g-signal-connect search-entry "key-press-event"
                        (lambda (widget event)
                          (declare (ignore widget))
                          (let* ((chord (key-event->chord event))
                                 (action (and chord (resolve-key-action chord (current-keymap-profile)))))
                            (and action
                                 (apply-key-action action search-entry results-listbox preview-label status-label)))))

      (g-signal-connect results-listbox "row-selected"
                        (lambda (widget row)
                          (declare (ignore widget))
                          (when row
                            (let ((index (gtk-list-box-row-get-index row)))
                              (refresh-preview-and-status (terminal-select-index index)
                                                          preview-label
                                                          status-label)))))

      (g-signal-connect results-listbox "row-activated"
                        (lambda (widget row)
                          (declare (ignore widget))
                          (when row
                            (terminal-select-index (gtk-list-box-row-get-index row)))
                          (apply-key-action :execute-selected
                                            search-entry
                                            results-listbox
                                            preview-label
                                            status-label)))

      (apply-window-style window)

      (refresh-gui-state initial-state results-listbox preview-label status-label)

      (g-signal-connect search-entry "changed"
                        (lambda (widget)
                          (declare (ignore widget))
                          (refresh-gui-state
                           (terminal-search (gtk-entry-text search-entry))
                           results-listbox
                           preview-label
                           status-label)))

      (gtk-box-pack-start root top-spacer :expand t :fill t :padding 0)
      (gtk-box-pack-start search-row search-entry :expand t :fill t :padding 120)
      (gtk-box-pack-start root search-row :expand nil :fill t :padding 0)
      (gtk-container-add results-scroller results-listbox)
      (gtk-box-pack-start content-row results-scroller :expand t :fill t :padding 0)
      (gtk-box-pack-start content-row preview-label :expand t :fill t :padding 0)
      (gtk-box-pack-start root content-row :expand t :fill t :padding 0)
      (gtk-box-pack-start root bottom-spacer :expand t :fill t :padding 0)
      (gtk-box-pack-start root status-label :expand nil :fill t :padding 0)

      (gtk-container-add window root)
      (gtk-widget-show-all window)
      (gtk-widget-grab-focus search-entry)))
  (join-gtk-main))
