(in-package #:altera-launcher.extensions.ui-terminal)

(defparameter *builtin-catalog*
  '((:id "command.clipboard-history" :title "Clipboard History" :subtitle "Clipboard" :kind :command)
    (:id "command.search-files" :title "Search Files" :subtitle "Fuzzy Files" :kind :command)
    (:id "command.kill-process" :title "Kill Process" :subtitle "Process" :kind :command)
    (:id "command.search-video" :title "Search Video" :subtitle "Web" :kind :command)
    (:id "command.sync-deps" :title "Sync Dependencies" :subtitle "Extension" :kind :command)
    (:id "command.theme-presets" :title "Theme Presets" :subtitle "Customization" :kind :command))
  "Built-in non-application terminal launcher entries.")

(defparameter *catalog* nil
  "Cached terminal catalog containing built-ins and discovered apps.")

(defparameter *terminal-query* ""
  "Current query string for terminal launcher state.")
(defparameter *terminal-selection-index* 0
  "Current selected row index for terminal launcher state.")

(defun refresh-catalog ()
  "Refresh terminal catalog by combining builtins and discovered applications."
  (setf *catalog* (append *builtin-catalog* (discover-desktop-apps))))

(defun ensure-catalog ()
  "Ensure terminal catalog is populated before querying or selection."
  (unless *catalog*
    (refresh-catalog)))

(defun entry-title (entry)
  "Return title string for catalog ENTRY."
  (getf entry :title))

(defun entry-subtitle (entry)
  "Return subtitle string for catalog ENTRY, defaulting to empty string."
  (or (getf entry :subtitle) ""))

(defun find-entry-by-id (entry-id)
  "Find catalog entry by ENTRY-ID or return NIL."
  (ensure-catalog)
  (find entry-id *catalog* :key (lambda (entry) (getf entry :id)) :test #'string=))

(defun query-match-p (candidate query)
  "Return true when CANDIDATE matches QUERY using case-insensitive substring."
  (let ((normalized-candidate (string-downcase candidate))
        (normalized-query (string-downcase query)))
    (or (string= normalized-query "")
        (not (null (search normalized-query normalized-candidate))))))

(defun filtered-results (query)
  "Return deduplicated catalog results that match QUERY."
  (ensure-catalog)
  (let ((seen (make-hash-table :test #'equal)))
    (loop for item in *catalog*
          for title = (entry-title item)
          for subtitle = (entry-subtitle item)
          for kind = (or (getf item :kind) :unknown)
          for key = (format nil "~A::~A" kind (string-downcase (or title "")))
          when (and (or (query-match-p title query)
                        (query-match-p subtitle query))
                    (not (gethash key seen)))
            do (setf (gethash key seen) t)
            and collect item)))

(defun bounded-index (index length)
  "Clamp INDEX to valid bounds for sequence of LENGTH."
  (cond
    ((<= length 0) 0)
    ((< index 0) 0)
    ((>= index length) (1- length))
    (t index)))

(defun animated-selection (from-index to-index)
  "Return animation metadata for selection transition FROM-INDEX to TO-INDEX."
  (list :from from-index
        :to to-index
        :frames (list :focus-ring-expand :selection-glide :focus-ring-settle)
        :duration-ms 140
        :curve "cubic-bezier(0.22,1,0.36,1)"))

(defun terminal-surface-state (&key (query *terminal-query*) (selection-index *terminal-selection-index*))
  "Return terminal surface model for QUERY and SELECTION-INDEX."
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
                             :selection-label (or (and selected-item (entry-title selected-item)) "No result"))
          :style (active-theme-tokens))))

(defun terminal-search (query)
  "Set terminal QUERY and reset selection to first result, returning new state."
  (setf *terminal-query* query
        *terminal-selection-index* 0)
  (terminal-surface-state :query *terminal-query* :selection-index *terminal-selection-index*))

(defun terminal-select-next ()
  "Move terminal selection to next result and return updated animated state."
  (let* ((results (filtered-results *terminal-query*))
         (next-index (bounded-index (1+ *terminal-selection-index*) (length results)))
         (animation (animated-selection *terminal-selection-index* next-index)))
    (setf *terminal-selection-index* next-index)
    (append (terminal-surface-state :query *terminal-query* :selection-index *terminal-selection-index*)
            (list :selection-animation animation))))

(defun terminal-select-prev ()
  "Move terminal selection to previous result and return updated animated state."
  (let* ((results (filtered-results *terminal-query*))
         (next-index (bounded-index (1- *terminal-selection-index*) (length results)))
         (animation (animated-selection *terminal-selection-index* next-index)))
    (setf *terminal-selection-index* next-index)
    (append (terminal-surface-state :query *terminal-query* :selection-index *terminal-selection-index*)
            (list :selection-animation animation))))

(defun terminal-select-first ()
  "Move terminal selection to first result and return updated animated state."
  (let ((animation (animated-selection *terminal-selection-index* 0)))
    (setf *terminal-selection-index* 0)
    (append (terminal-surface-state :query *terminal-query* :selection-index *terminal-selection-index*)
            (list :selection-animation animation))))

(defun terminal-select-last ()
  "Move terminal selection to last result and return updated animated state."
  (let* ((results (filtered-results *terminal-query*))
         (last-index (if results (1- (length results)) 0))
         (animation (animated-selection *terminal-selection-index* last-index)))
    (setf *terminal-selection-index* last-index)
    (append (terminal-surface-state :query *terminal-query* :selection-index *terminal-selection-index*)
            (list :selection-animation animation))))

(defun terminal-selected-item ()
  "Return currently selected terminal result item or NIL."
  (let* ((results (filtered-results *terminal-query*))
         (safe-index (bounded-index *terminal-selection-index* (length results))))
    (nth safe-index results)))

(defun terminal-select-index (index)
  "Set terminal selection to INDEX (bounded) and return updated animated state."
  (let* ((results (filtered-results *terminal-query*))
         (next-index (bounded-index index (length results)))
         (animation (animated-selection *terminal-selection-index* next-index)))
    (setf *terminal-selection-index* next-index)
    (append (terminal-surface-state :query *terminal-query* :selection-index *terminal-selection-index*)
            (list :selection-animation animation))))

(defun execute-application-entry (entry)
  "Launch application ENTRY and return execution status plist."
  (launch-desktop-app-entry entry))

(defun execute-command-entry (entry)
  "Return placeholder execution status for non-application command ENTRY."
  (list :ok t :kind :command :title (entry-title entry) :note "Command execution hook pending"))

(defun terminal-execute-selected ()
  "Execute currently selected terminal item and return status plist."
  (let ((entry (terminal-selected-item)))
    (cond
      ((null entry) (list :ok nil :error "No selected item"))
      ((eq (getf entry :kind) :application) (execute-application-entry entry))
      (t (execute-command-entry entry)))))

(defun terminal-execute-entry-id (entry-id)
  "Execute terminal catalog entry by ENTRY-ID and return status plist."
  (let ((entry (find-entry-by-id entry-id)))
    (if entry
        (if (eq (getf entry :kind) :application)
            (execute-application-entry entry)
            (execute-command-entry entry))
        (list :ok nil :error (format nil "Unknown entry id: ~A" entry-id)))))

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
   :tags '("ui" "terminal" "selection" "animation"))

  (define-command
   "ui.terminal.select.first"
   (lambda (&rest args)
     (declare (ignore args))
     (terminal-select-first))
   :title "Terminal Select First"
   :description "Moves selection to first result."
   :tags '("ui" "terminal" "selection" "animation"))

  (define-command
   "ui.terminal.select.last"
   (lambda (&rest args)
     (declare (ignore args))
     (terminal-select-last))
   :title "Terminal Select Last"
   :description "Moves selection to last result."
   :tags '("ui" "terminal" "selection" "animation"))

  (define-command
   "ui.terminal.selected"
   (lambda (&rest args)
     (declare (ignore args))
     (terminal-selected-item))
   :title "Terminal Selected Item"
   :description "Returns currently selected terminal result item."
   :tags '("ui" "terminal" "selection"))

  (define-command
   "ui.terminal.select.index"
   (lambda (index &rest args)
     (declare (ignore args))
     (terminal-select-index index))
   :title "Terminal Select Index"
   :description "Sets selection index to specific result row."
   :tags '("ui" "terminal" "selection"))

  (define-command
   "ui.terminal.execute-selected"
   (lambda (&rest args)
     (declare (ignore args))
     (terminal-execute-selected))
   :title "Terminal Execute Selected"
   :description "Executes selected item (launches app entries immediately)."
   :tags '("ui" "terminal" "execute"))

  (define-command
   "ui.terminal.execute.entry"
   (lambda (entry-id &rest args)
     (declare (ignore args))
     (terminal-execute-entry-id entry-id))
   :title "Terminal Execute Entry"
   :description "Executes terminal catalog entry by id."
   :tags '("ui" "terminal" "execute"))

  (define-options-source "ui.terminal.options" (query)
    (loop for entry in (filtered-results query)
          when (not (eq (getf entry :kind) :application))
          collect (list :id (getf entry :id)
                        :title (getf entry :title)
                        :subtitle (getf entry :subtitle)
                        :kind (getf entry :kind)
                        :command "ui.terminal.execute.entry"
                        :args (list (getf entry :id))))))
