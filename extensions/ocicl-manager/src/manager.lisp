(in-package #:altera-launcher.extensions.ocicl-manager)

(defun string-lines (string)
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
  (run-program (append '("env" "OCICL_LOCAL_ONLY=1" "ocicl") args)
               :output '(:string :stripped t)
               :error-output '(:string :stripped t)
               :ignore-error-status nil))

(defun ocicl-sync ()
  (ocicl-run "install"))

(defun ocicl-install (project-name)
  (ocicl-run "install" project-name))

(defun ocicl-extension-list ()
  (let* ((csv-path (merge-pathnames "ocicl.csv" (getcwd)))
         (exists (probe-file csv-path)))
    (if exists
        (loop for line in (string-lines (uiop:read-file-string csv-path))
              for columns = (csv-line->columns line)
              unless (or (string= line "")
                         (string= (first columns) "project"))
                 collect (first columns))
        '())))

(defun read-extensions-manifest (&optional (manifest-path "extensions/extensions-manifest.lisp"))
  (with-open-file (stream manifest-path :direction :input)
    (read stream nil '())))

(defun manifest-extension-entries (manifest)
  (or (getf manifest :extensions) '()))

(defun manifest-extension-names (manifest)
  (mapcar (lambda (entry) (getf entry :name))
          (manifest-extension-entries manifest)))

(defun manifest-ocicl-projects (manifest)
  (remove-duplicates
   (loop for entry in (manifest-extension-entries manifest)
         append (or (getf entry :ocicl-projects) '()))
   :test #'string=))

(defun install-from-manifest (&optional (manifest-path "extensions/extensions-manifest.lisp") dry-run)
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
   :tags '("extensions" "ocicl" "manifest" "deps")))
