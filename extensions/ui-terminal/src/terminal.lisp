(in-package #:altera-launcher.extensions.ui-terminal)

(defparameter *catalog*
  '("Open Browser" "Search Files" "Run Shell Snippet" "Switch Workspace" "Paste Clipboard Item"
    "Open Settings" "Open Notes" "Install Extension" "Sync Dependencies" "Theme Presets"))

(defparameter *terminal-query* "")
(defparameter *terminal-selection-index* 0)

(defun query-match-p (candidate query)
  (let ((normalized-candidate (string-downcase candidate))
        (normalized-query (string-downcase query)))
    (or (string= normalized-query "")
        (not (null (search normalized-query normalized-candidate))))))

(defun filtered-results (query)
  (loop for item in *catalog*
        when (query-match-p item query)
          collect item))

(defun bounded-index (index length)
  (cond
    ((<= length 0) 0)
    ((< index 0) 0)
    ((>= index length) (1- length))
    (t index)))

(defun animated-selection (from-index to-index)
  (list :from from-index
        :to to-index
        :frames (list :focus-ring-expand :selection-glide :focus-ring-settle)
        :duration-ms 140
        :curve "cubic-bezier(0.22,1,0.36,1)"))

(defun terminal-surface-state (&key (query *terminal-query*) (selection-index *terminal-selection-index*))
  (let* ((results (filtered-results query))
         (safe-index (bounded-index selection-index (length results)))
         (selected-item (nth safe-index results)))
    (list :query query
          :selection-index safe-index
          :results-list results
          :search-box (list :placeholder "Type a command or extension action..." :value query)
          :preview-pane (render-preview-model query safe-index)
          :status-rail (list :result-count (length results)
                             :theme (active-theme-name)
                             :selection-label (or selected-item "No result"))
          :style (active-theme-tokens))))

(defun terminal-search (query)
  (setf *terminal-query* query
        *terminal-selection-index* 0)
  (terminal-surface-state :query *terminal-query* :selection-index *terminal-selection-index*))

(defun terminal-select-next ()
  (let* ((results (filtered-results *terminal-query*))
         (next-index (bounded-index (1+ *terminal-selection-index*) (length results)))
         (animation (animated-selection *terminal-selection-index* next-index)))
    (setf *terminal-selection-index* next-index)
    (append (terminal-surface-state :query *terminal-query* :selection-index *terminal-selection-index*)
            (list :selection-animation animation))))

(defun terminal-select-prev ()
  (let* ((results (filtered-results *terminal-query*))
         (next-index (bounded-index (1- *terminal-selection-index*) (length results)))
         (animation (animated-selection *terminal-selection-index* next-index)))
    (setf *terminal-selection-index* next-index)
    (append (terminal-surface-state :query *terminal-query* :selection-index *terminal-selection-index*)
            (list :selection-animation animation))))

(define-extension ("ui-terminal"
                   :version "0.1.0"
                   :description "Terminal UI surface using ui-theme and ui-renderer contracts")
  (define-command
   "ui.terminal.state"
   (lambda (&optional (query *terminal-query*) (selection-index *terminal-selection-index*) &rest args)
     (declare (ignore args))
     (terminal-surface-state :query query :selection-index selection-index))
   :title "Terminal Surface State"
   :description "Returns search box, results list, preview pane, and status model."
   :tags '("ui" "terminal" "renderer"))

  (define-command
   "ui.terminal.search"
   (lambda (&optional (query "") &rest args)
     (declare (ignore args))
     (terminal-search query))
   :title "Terminal Search"
   :description "Updates terminal query and returns refreshed surface state."
   :tags '("ui" "terminal" "search"))

  (define-command
   "ui.terminal.select.next"
   (lambda (&rest args)
     (declare (ignore args))
     (terminal-select-next))
   :title "Terminal Select Next"
   :description "Moves selection down and returns animated transition state."
   :tags '("ui" "terminal" "selection" "animation"))

  (define-command
   "ui.terminal.select.prev"
   (lambda (&rest args)
     (declare (ignore args))
     (terminal-select-prev))
   :title "Terminal Select Previous"
   :description "Moves selection up and returns animated transition state."
   :tags '("ui" "terminal" "selection" "animation")))
