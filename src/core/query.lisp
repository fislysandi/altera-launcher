(in-package #:altera-launcher.core.query)

(defun query-match-p (text query)
  (let ((haystack (string-downcase (or text "")))
        (needle (string-downcase (or query ""))))
    (or (string= needle "")
        (not (null (search needle haystack))))))

(defun search-commands (registry query)
  (loop for command in (list-commands registry)
        for metadata = (command-metadata command)
        when (or (query-match-p (getf metadata :name) query)
                 (query-match-p (getf metadata :title) query)
                 (query-match-p (getf metadata :description) query))
          collect metadata))

(defun commands-for-extension (registry extension-name)
  (let ((normalized-extension (string-downcase (string extension-name))))
    (loop for command in (list-commands registry)
          for metadata = (command-metadata command)
          when (string= normalized-extension
                        (string-downcase (or (getf metadata :extension) "")))
            collect metadata)))
