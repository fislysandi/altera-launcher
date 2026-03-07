(defpackage #:altera-launcher.extensions.ui-gtk.runner
  (:use #:cl #:gtk #:gobject #:gdk)
  (:import-from #:altera-launcher.extensions.ui-theme
                #:active-theme-name)
  (:import-from #:altera-launcher.extensions.ui-terminal
                #:terminal-surface-state
                #:terminal-search
                #:terminal-select-next
                #:terminal-select-prev)
  (:export #:run-launcher-window))

(in-package #:altera-launcher.extensions.ui-gtk.runner)

(defparameter *escape-keyval* (gdk-keyval-from-name "Escape"))

(defun escape-key-event-p (event)
  (= (gdk-event-key-keyval event) *escape-keyval*))

(defun apply-window-style (window)
  (setf (gtk-window-decorated window) nil)
  (setf (gtk-window-resizable window) nil)
  (setf (gtk-window-window-position window) :center))

(defun format-results-list (state)
  (let ((results (or (getf state :results-list) '()))
        (selection (or (getf state :selection-index) 0)))
    (if (null results)
        "No matching command"
        (with-output-to-string (stream)
          (loop for item in results
                for idx from 0
                do (format stream "~A ~A~%"
                           (if (= idx selection) ">" " ")
                           item))))))

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

(defun refresh-gui-state (state results-label preview-label status-label)
  (gtk-label-set-text results-label (format-results-list state))
  (gtk-label-set-text preview-label (format-preview-pane state))
  (gtk-label-set-text status-label (format-status-rail state)))

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
           (results-label (gtk-label-new ""))
           (preview-label (gtk-label-new ""))
           (bottom-spacer (make-instance 'gtk-label :label ""))
           (controls (make-instance 'gtk-hbox :homogeneous nil :spacing 8))
           (prev-button (gtk-button-new-with-label "Prev"))
           (next-button (gtk-button-new-with-label "Next"))
           (close-button (gtk-button-new-with-label "Close"))
           (status-label (gtk-label-new ""))
           (initial-state (terminal-surface-state)))
      (g-signal-connect window "destroy"
                        (lambda (widget)
                          (declare (ignore widget))
                          (leave-gtk-main)))

      (g-signal-connect window "key-press-event"
                        (lambda (widget event)
                          (declare (ignore widget))
                          (if (escape-key-event-p event)
                              (progn
                                (leave-gtk-main)
                                t)
                              nil)))

      (g-signal-connect search-entry "key-press-event"
                        (lambda (widget event)
                          (declare (ignore widget))
                          (if (escape-key-event-p event)
                              (progn
                                (leave-gtk-main)
                                t)
                              nil)))

      (apply-window-style window)

      (refresh-gui-state initial-state results-label preview-label status-label)

      (g-signal-connect search-entry "changed"
                        (lambda (widget)
                          (declare (ignore widget))
                          (refresh-gui-state
                           (terminal-search (gtk-entry-text search-entry))
                           results-label
                           preview-label
                           status-label)))

      (g-signal-connect next-button "clicked"
                        (lambda (widget)
                          (declare (ignore widget))
                          (refresh-gui-state
                           (terminal-select-next)
                           results-label
                           preview-label
                           status-label)))

      (g-signal-connect prev-button "clicked"
                        (lambda (widget)
                          (declare (ignore widget))
                          (refresh-gui-state
                           (terminal-select-prev)
                           results-label
                           preview-label
                           status-label)))

      (g-signal-connect close-button "clicked"
                        (lambda (widget)
                          (declare (ignore widget))
                          (gtk-widget-destroy window)))

      (gtk-box-pack-start root top-spacer :expand t :fill t :padding 0)
      (gtk-box-pack-start search-row search-entry :expand t :fill t :padding 120)
      (gtk-box-pack-start root search-row :expand nil :fill t :padding 0)
      (gtk-box-pack-start content-row results-label :expand t :fill t :padding 0)
      (gtk-box-pack-start content-row preview-label :expand t :fill t :padding 0)
      (gtk-box-pack-start root content-row :expand t :fill t :padding 0)
      (gtk-box-pack-start root bottom-spacer :expand t :fill t :padding 0)

      (gtk-box-pack-start controls prev-button :expand nil :fill nil :padding 0)
      (gtk-box-pack-start controls next-button :expand nil :fill nil :padding 0)
      (gtk-box-pack-start controls close-button :expand nil :fill nil :padding 0)
      (gtk-box-pack-start root controls :expand nil :fill nil :padding 0)
      (gtk-box-pack-start root status-label :expand nil :fill t :padding 0)

      (gtk-container-add window root)
      (gtk-widget-show-all window)
      (gtk-widget-grab-focus search-entry)))
  (join-gtk-main))
