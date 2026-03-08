(in-package #:altera-launcher.extensions.ocicl-manager)

(defun string-lines (string)
  "Split STRING into a list of lines without trailing newline characters."
  (let ((lines '())
        (start 0))
    (loop for end = (position #\Newline string :start start)
          do (if end
                 (progn
                   (push (subseq string start end) lines)
                   (setf start (1+ end)))
                 (progn
                   (when (< start (length string))
                     (push (subseq string start) lines))
                   (return (nreverse lines)))))))

(defun csv-line->columns (line)
  "Split one CSV LINE by commas and return column list.

This parser is intentionally minimal and does not handle quoted commas."
  (let ((columns '())
        (start 0))
    (loop for comma = (position #\, line :start start)
          do (if comma
                 (progn
                   (push (subseq line start comma) columns)
                   (setf start (1+ comma)))
                 (progn
                   (push (subseq line start) columns)
                   (return (nreverse columns)))))))

(defun ocicl-run (&rest args)
  "Run OCICL with ARGS in local-only mode and return run-program result."
  (run-program (append '("env" "OCICL_LOCAL_ONLY=1" "ocicl") args)
               :output '(:string :stripped t)
               :error-output '(:string :stripped t)
               :ignore-error-status nil))

(defun ocicl-sync ()
  "Run OCICL install to sync workspace dependencies."
  (ocicl-run "install"))

(defun ocicl-install (project-name)
  "Install one OCICL PROJECT-NAME dependency."
  (ocicl-run "install" project-name))

(defun ocicl-extension-list ()
  "Return installed OCICL project names from workspace ocicl.csv."
  (let* ((csv-path (merge-pathnames "ocicl.csv" (getcwd)))
         (exists (probe-file csv-path)))
    (if exists
        (loop for line in (string-lines (uiop:read-file-string csv-path))
              for columns = (csv-line->columns line)
              unless (or (string= line "")
                         (string= (first columns) "project"))
                 collect (first columns))
        '())))

(defun manifest-shaped-p (value)
  "Return true when VALUE is a valid extensions manifest plist shape."
  (and (listp value)
       (evenp (length value))
       (or (null (getf value :extensions))
           (listp (getf value :extensions)))))

(define-safe-reader read-extensions-manifest (manifest-path "extensions/extensions-manifest.lisp")
  :default '()
  :validator #'manifest-shaped-p
  :doc "Read and return extension manifest plist from MANIFEST-PATH.

Malformed, unreadable, or invalid manifest files return an empty plist.")

(defun manifest-extension-entries (manifest)
  "Return extension entry list from MANIFEST plist."
  (or (getf manifest :extensions) '()))

(defun manifest-extension-names (manifest)
  "Return extension names declared in MANIFEST."
  (mapcar (lambda (entry) (getf entry :name))
          (manifest-extension-entries manifest)))

(defun manifest-ocicl-projects (manifest)
  "Return unique OCICL project names required by MANIFEST extensions."
  (remove-duplicates
   (loop for entry in (manifest-extension-entries manifest)
         append (or (getf entry :ocicl-projects) '()))
   :test #'string=))

(defun install-from-manifest (&optional (manifest-path "extensions/extensions-manifest.lisp") dry-run)
  "Install manifest-declared OCICL projects, or return dry-run summary.

When DRY-RUN is true, no installation commands are executed."
  (let* ((manifest (read-extensions-manifest manifest-path))
         (projects (manifest-ocicl-projects manifest)))
    (if dry-run
        (list :manifest manifest-path
              :projects projects
              :extensions (manifest-extension-names manifest)
              :dry-run t)
        (progn
          (dolist (project projects)
            (ocicl-install project))
          (ocicl-sync)
          (list :manifest manifest-path
                :installed-projects projects
                :extensions (manifest-extension-names manifest)
                :dry-run nil)))))

(define-extension ("ocicl-manager"
                   :version "0.1.0"
                   :description "Manage extensions and dependencies with OCICL")
  (define-command
   "extensions.sync"
   (lambda (&rest args)
     (declare (ignore args))
     (ocicl-sync)
     "Dependencies synchronized with OCICL_LOCAL_ONLY=1")
   :title "Sync Dependencies"
   :description "Runs OCICL dependency sync for the launcher workspace."
   :tags '("extensions" "ocicl" "deps"))

  (define-command
   "extensions.install"
   (lambda (project-name &rest args)
     (declare (ignore args))
     (ocicl-install project-name)
     (format nil "Installed dependency project: ~A" project-name))
   :title "Install Dependency Project"
   :description "Installs an OCICL project by name."
   :tags '("extensions" "ocicl" "deps"))

  (define-command
   "extensions.list"
   (lambda (&rest args)
     (declare (ignore args))
     (ocicl-extension-list))
   :title "List Installed Dependency Projects"
   :description "Lists project names from local ocicl.csv."
   :tags '("extensions" "ocicl" "deps"))

  (define-command
   "extensions.manifest.list"
   (lambda (&optional manifest-path &rest args)
     (declare (ignore args))
     (let ((manifest (read-extensions-manifest (or manifest-path "extensions/extensions-manifest.lisp"))))
       (manifest-extension-names manifest)))
   :title "List Extensions from Manifest"
   :description "Reads extension names from the extension manifest file."
   :tags '("extensions" "ocicl" "manifest"))

  (define-command
   "extensions.manifest.install"
   (lambda (&optional manifest-path dry-run &rest args)
     (declare (ignore args))
     (install-from-manifest (or manifest-path "extensions/extensions-manifest.lisp") dry-run))
   :title "Install Manifest Dependencies"
   :description "Installs all OCICL projects declared in extension manifest."
   :tags '("extensions" "ocicl" "manifest" "deps"))

  (define-options-source "ocicl.manager.options" (query)
    (let* ((needle (string-downcase (or query "")))
           (core-options
             (list (list :id "ocicl.sync"
                         :title "Sync Dependencies"
                         :subtitle "OCICL"
                         :kind :command
                         :command "extensions.sync")
                   (list :id "ocicl.manifest.install"
                         :title "Install Manifest Dependencies"
                         :subtitle "OCICL"
                         :kind :command
                         :command "extensions.manifest.install"
                         :args (list "extensions/extensions-manifest.lisp" nil))))
           (project-options
             (loop for project in (ocicl-extension-list)
                   when (or (string= needle "")
                            (search needle (string-downcase project)))
                     collect (list :id (format nil "ocicl.install.~A" project)
                                   :title (format nil "Install ~A" project)
                                   :subtitle "OCICL Project"
                                   :kind :command
                                   :command "extensions.install"
                                   :args (list project)))))
      (append core-options project-options))))
