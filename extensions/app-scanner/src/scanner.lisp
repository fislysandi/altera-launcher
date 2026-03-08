(in-package #:altera-launcher.extensions.app-scanner)

(defparameter *app-index* nil
  "Cached list of parsed desktop application entries.")

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
           (discover-desktop-apps))))))

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
        (launch-desktop-app-entry app)
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
