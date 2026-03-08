(in-package #:altera-launcher.extensions.ui-terminal)

(defparameter *builtin-catalog*
  '((:id "command.clipboard-history" :title "Clipboard History" :subtitle "Clipboard" :kind :command)
    (:id "command.search-files" :title "Search Files" :subtitle "Fuzzy Files" :kind :command)
    (:id "command.kill-process" :title "Kill Process" :subtitle "Process" :kind :command)
    (:id "command.search-video" :title "Search Video" :subtitle "Web" :kind :command)
    (:id "command.sync-deps" :title "Sync Dependencies" :subtitle "Extension" :kind :command)
    (:id "command.theme-presets" :title "Theme Presets" :subtitle "Customization" :kind :command)))

(defparameter *catalog* nil)

(defparameter *terminal-query* "")
(defparameter *terminal-selection-index* 0)

(defun string-prefix-p (prefix string)
  (and (<= (length prefix) (length string))
       (string= prefix string :end2 (length prefix))))

(defun desktop-field (lines prefix)
  (loop for line in lines
        when (string-prefix-p prefix line)
          return (subseq line (length prefix))))

(defun placeholder-token-p (token)
  (and (> (length token) 1)
       (char= (char token 0) #\%)))

(defun sanitize-desktop-exec (exec)
  (let ((tokens (remove-if #'placeholder-token-p (uiop:split-string exec :separator '(#\Space)))))
    (string-trim '(#\Space #\Tab)
                 (format nil "~{~A~^ ~}" tokens))))

(defun parse-desktop-entry (path)
  (let* ((lines (read-file-lines path))
         (type (desktop-field lines "Type="))
         (name (desktop-field lines "Name="))
         (exec (desktop-field lines "Exec="))
         (hidden (desktop-field lines "Hidden="))
         (no-display (desktop-field lines "NoDisplay=")))
    (when (and name
               exec
               (or (null type) (string= type "Application"))
               (not (string= hidden "true"))
               (not (string= no-display "true")))
      (list :id (format nil "app.~A" name)
            :title name
            :subtitle "Application"
            :kind :application
            :exec (sanitize-desktop-exec exec)
            :desktop-file (namestring path)))))

(defun discover-desktop-entries ()
  (let* ((user-dir (merge-pathnames ".local/share/applications/" (user-homedir-pathname)))
         (system-dir #p"/usr/share/applications/")
         (paths (append (when (probe-file user-dir)
                          (directory (merge-pathnames "*.desktop" user-dir)))
                        (when (probe-file system-dir)
                          (directory (merge-pathnames "*.desktop" system-dir))))))
    (remove nil (mapcar #'parse-desktop-entry paths))))

(defun refresh-catalog ()
  (setf *catalog* (append *builtin-catalog* (discover-desktop-entries))))

(defun ensure-catalog ()
  (unless *catalog*
    (refresh-catalog)))

(defun entry-title (entry)
  (getf entry :title))

(defun entry-subtitle (entry)
  (or (getf entry :subtitle) ""))

(defun query-match-p (candidate query)
  (let ((normalized-candidate (string-downcase candidate))
        (normalized-query (string-downcase query)))
    (or (string= normalized-query "")
        (not (null (search normalized-query normalized-candidate))))))

(defun filtered-results (query)
  (ensure-catalog)
  (loop for item in *catalog*
        for title = (entry-title item)
        for subtitle = (entry-subtitle item)
        when (or (query-match-p title query)
                 (query-match-p subtitle query))
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
                             :selection-label (or (and selected-item (entry-title selected-item)) "No result"))
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

(defun terminal-select-first ()
  (let ((animation (animated-selection *terminal-selection-index* 0)))
    (setf *terminal-selection-index* 0)
    (append (terminal-surface-state :query *terminal-query* :selection-index *terminal-selection-index*)
            (list :selection-animation animation))))

(defun terminal-select-last ()
  (let* ((results (filtered-results *terminal-query*))
         (last-index (if results (1- (length results)) 0))
         (animation (animated-selection *terminal-selection-index* last-index)))
    (setf *terminal-selection-index* last-index)
    (append (terminal-surface-state :query *terminal-query* :selection-index *terminal-selection-index*)
            (list :selection-animation animation))))

(defun terminal-selected-item ()
  (let* ((results (filtered-results *terminal-query*))
         (safe-index (bounded-index *terminal-selection-index* (length results))))
    (nth safe-index results)))

(defun terminal-select-index (index)
  (let* ((results (filtered-results *terminal-query*))
         (next-index (bounded-index index (length results)))
         (animation (animated-selection *terminal-selection-index* next-index)))
    (setf *terminal-selection-index* next-index)
    (append (terminal-surface-state :query *terminal-query* :selection-index *terminal-selection-index*)
            (list :selection-animation animation))))

(defun execute-application-entry (entry)
  (let ((exec (getf entry :exec)))
    (if (and exec (not (string= exec "")))
        (progn
          (launch-program (list "/bin/sh" "-lc" exec)
                          :output nil
                          :error-output nil
                          :wait nil)
          (list :ok t :kind :application :title (entry-title entry)))
        (list :ok nil :error "No executable command found" :title (entry-title entry)))))

(defun execute-command-entry (entry)
  (list :ok t :kind :command :title (entry-title entry) :note "Command execution hook pending"))

(defun terminal-execute-selected ()
  (let ((entry (terminal-selected-item)))
    (cond
      ((null entry) (list :ok nil :error "No selected item"))
      ((eq (getf entry :kind) :application) (execute-application-entry entry))
      (t (execute-command-entry entry)))))

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
   :tags '("ui" "terminal" "execute")))
