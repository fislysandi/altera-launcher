(in-package #:altera-launcher.extensions.app-scanner)

(defparameter *app-index* nil
  "Cached list of parsed desktop application entries.")

(defun string-prefix-p (prefix string)
  "Return true when STRING starts with PREFIX."
  (and (<= (length prefix) (length string))
       (string= prefix string :end2 (length prefix))))

(defun desktop-field (lines prefix)
  "Return value for first desktop file field in LINES matching PREFIX=."
  (loop for line in lines
        when (string-prefix-p prefix line)
          return (subseq line (length prefix))))

(defun placeholder-token-p (token)
  "Return true when TOKEN is a desktop Exec placeholder like %U or %f."
  (and (> (length token) 1)
       (char= (char token 0) #\%)))

(defun sanitize-desktop-exec (exec)
  "Strip placeholder tokens from desktop Exec command string EXEC."
  (let ((tokens (remove-if #'placeholder-token-p (uiop:split-string exec :separator '(#\Space)))))
    (string-trim '(#\Space #\Tab)
                 (format nil "~{~A~^ ~}" tokens))))

(defun normalize-app-id (desktop-file name)
  "Return stable launcher id for DESKTOP-FILE and fallback NAME."
  (let ((slug (string-downcase (or (pathname-name desktop-file) name "unknown"))))
    (format nil "app.~A" slug)))

(defun parse-desktop-entry (path)
  "Parse one .desktop file PATH into a launcher application plist or NIL."
  (let* ((lines (read-file-lines path))
         (type (desktop-field lines "Type="))
         (name (desktop-field lines "Name="))
         (icon (desktop-field lines "Icon="))
         (exec (desktop-field lines "Exec="))
         (hidden (desktop-field lines "Hidden="))
         (no-display (desktop-field lines "NoDisplay=")))
    (when (and name
               exec
               (or (null type) (string= type "Application"))
               (not (string= hidden "true"))
               (not (string= no-display "true")))
      (list :id (normalize-app-id path name)
            :title name
            :subtitle "Application"
            :kind :application
            :icon icon
            :exec (sanitize-desktop-exec exec)
            :desktop-file (namestring path)))))

(defun desktop-entry-paths ()
  "Return candidate .desktop file pathnames from user and system directories."
  (let ((user-dir (merge-pathnames ".local/share/applications/" (user-homedir-pathname)))
        (system-dir #p"/usr/share/applications/"))
    (append (when (probe-file user-dir)
              (directory (merge-pathnames "*.desktop" user-dir)))
            (when (probe-file system-dir)
              (directory (merge-pathnames "*.desktop" system-dir))))))

(defun dedupe-apps-by-id (apps)
  "Remove duplicate application entries from APPS by :ID."
  (let ((seen (make-hash-table :test #'equal)))
    (loop for app in apps
          for id = (getf app :id)
          unless (gethash id seen)
            do (setf (gethash id seen) t)
               and collect app)))

(defun dedupe-apps-by-title (apps)
  "Remove duplicate application entries from APPS by case-insensitive title."
  (let ((seen (make-hash-table :test #'equal)))
    (loop for app in apps
          for title = (string-downcase (or (getf app :title) ""))
          unless (gethash title seen)
            do (setf (gethash title seen) t)
               and collect app)))

(defun sort-apps (apps)
  "Return APPS sorted by case-insensitive title."
  (sort apps #'string< :key (lambda (app) (string-downcase (getf app :title)))))

(defun refresh-app-index ()
  "Rebuild cached desktop application index and return sorted result."
  (setf *app-index*
        (sort-apps
         (dedupe-apps-by-title
          (dedupe-apps-by-id
           (remove nil (mapcar #'parse-desktop-entry (desktop-entry-paths))))))))

(defun ensure-app-index ()
  "Ensure application index exists for subsequent lookup operations."
  (unless *app-index*
    (refresh-app-index)))

(defun list-apps (&optional (query ""))
  "Return indexed applications matching case-insensitive title QUERY."
  (ensure-app-index)
  (let ((needle (string-downcase query)))
    (loop for app in *app-index*
          for title = (string-downcase (getf app :title))
          when (or (string= needle "")
                   (search needle title))
            collect app)))

(defun find-app-by-id (app-id)
  "Find one indexed application by APP-ID or return NIL."
  (ensure-app-index)
  (find app-id *app-index* :key (lambda (app) (getf app :id)) :test #'string=))

(defun launch-app-by-id (app-id)
  "Launch indexed application APP-ID and return status plist."
  (let ((app (find-app-by-id app-id)))
    (if app
        (let ((exec (getf app :exec)))
          (if (and exec (not (string= exec "")))
              (progn
                (launch-program (list "/bin/sh" "-lc" exec)
                                :output nil
                                :error-output nil
                                :wait nil)
                (list :ok t :id app-id :title (getf app :title)))
              (list :ok nil :id app-id :error "No executable command")))
        (list :ok nil :id app-id :error "Unknown app id"))))

(define-extension ("app-scanner"
                   :version "0.1.0"
                   :description "Scans installed desktop applications and exposes launcher options")
  (define-command
   "apps.scan.refresh"
   (lambda (&rest args)
     (declare (ignore args))
     (refresh-app-index)
     (length *app-index*))
   :title "Refresh App Index"
   :description "Scans .desktop entries and refreshes installed app index."
   :tags '("apps" "scan"))

  (define-command
   "apps.scan.list"
   (lambda (&optional (query "") &rest args)
     (declare (ignore args))
     (list-apps query))
   :title "List Installed Apps"
   :description "Lists scanned desktop applications."
   :tags '("apps" "scan"))

  (define-command
   "apps.scan.launch"
   (lambda (app-id &rest args)
     (declare (ignore args))
     (launch-app-by-id app-id))
   :title "Launch App By Id"
   :description "Launches scanned app by launcher option id."
   :tags '("apps" "launch"))

  (define-options-source "apps.scanner.options" (query)
    (loop for app in (list-apps query)
          collect (list :id (getf app :id)
                        :title (getf app :title)
                        :subtitle "Application"
                        :kind :application
                        :icon (getf app :icon)
                        :command "apps.scan.launch"
                        :args (list (getf app :id))))))
