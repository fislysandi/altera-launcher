(in-package #:altera-launcher.core.query)

(defun query-match-p (text query)
  "Return true when TEXT matches QUERY using case-insensitive substring search."
  (let ((haystack (string-downcase (or text "")))
        (needle (string-downcase (or query ""))))
    (or (string= needle "")
        (not (null (search needle haystack))))))

(defun search-commands (registry query)
  "Return command metadata from REGISTRY matching QUERY.

Matching checks command name, title, and description fields."
  (loop for command in (list-commands registry)
        for metadata = (command-metadata command)
        when (or (query-match-p (getf metadata :name) query)
                 (query-match-p (getf metadata :title) query)
                 (query-match-p (getf metadata :description) query))
          collect metadata))

(defun commands-for-extension (registry extension-name)
  "Return command metadata from REGISTRY owned by EXTENSION-NAME."
  (let ((normalized-extension (string-downcase (string extension-name))))
    (loop for command in (list-commands registry)
          for metadata = (command-metadata command)
          when (string= normalized-extension
                        (string-downcase (or (getf metadata :extension) "")))
            collect metadata)))
