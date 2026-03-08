(in-package #:altera-launcher.core.desktop-apps)

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

(defun unsafe-shell-character-p (character)
  "Return true when CHARACTER is a shell metacharacter.

The launcher rejects desktop entries containing these characters to avoid
shell-like command expansion behavior."
  (find character "|&;<>()`$\\\"" :test #'char=))

(defun safe-exec-token-p (token)
  "Return true when TOKEN is safe for argv-based execution."
  (and (stringp token)
       (> (length token) 0)
       (notany #'unsafe-shell-character-p token)))

(defun desktop-exec->argv (exec)
  "Convert desktop Exec string EXEC to safe argv list or NIL."
  (let* ((tokens (split-string exec :separator '(#\Space #\Tab)))
         (clean (remove-if (lambda (token)
                             (or (string= token "")
                                 (placeholder-token-p token)))
                           tokens)))
    (when (and clean (every #'safe-exec-token-p clean))
      clean)))

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
         (exec-argv (and exec (desktop-exec->argv exec)))
         (hidden (desktop-field lines "Hidden="))
         (no-display (desktop-field lines "NoDisplay=")))
    (when (and name
               exec-argv
               (or (null type) (string= type "Application"))
               (not (string= hidden "true"))
               (not (string= no-display "true")))
      (list :id (normalize-app-id path name)
            :title name
            :subtitle "Application"
            :kind :application
            :icon icon
            :exec-argv exec-argv
            :desktop-file (namestring path)))))

(defun desktop-entry-paths ()
  "Return candidate .desktop file pathnames from user and system directories."
  (let ((user-dir (merge-pathnames ".local/share/applications/" (user-homedir-pathname)))
        (system-dir #p"/usr/share/applications/"))
    (append (when (probe-file user-dir)
              (directory (merge-pathnames "*.desktop" user-dir)))
            (when (probe-file system-dir)
              (directory (merge-pathnames "*.desktop" system-dir))))))

(defun discover-desktop-apps ()
  "Discover and parse desktop application entries from user and system paths."
  (remove nil (mapcar #'parse-desktop-entry (desktop-entry-paths))))

(defun launch-desktop-app-entry (entry)
  "Launch desktop application ENTRY and return a status plist."
  (let ((exec-argv (getf entry :exec-argv)))
    (if (and exec-argv (consp exec-argv))
        (progn
          (launch-program exec-argv :output nil :error-output nil :wait nil)
          (list :ok t
                :id (getf entry :id)
                :title (getf entry :title)
                :kind :application))
        (list :ok nil
              :id (getf entry :id)
              :title (getf entry :title)
              :error "No safe executable command"))))
