(in-package #:altera-launcher.core.keymap-overrides)

(defun normalize-chord (chord)
  "Normalize CHORD to lowercase trimmed string form."
  (string-downcase (string-trim '(#\Space #\Tab) (string chord))))

(defun normalize-action (action)
  "Normalize ACTION to a keyword action symbol or NIL."
  (cond
    ((keywordp action) action)
    ((symbolp action) (intern (string-upcase (symbol-name action)) :keyword))
    ((stringp action) (intern (string-upcase action) :keyword))
    (t nil)))

(defun parse-override-entry (entry)
  "Parse one keymap override ENTRY and return (chord . action) or NIL."
  (cond
    ((and (consp entry)
          (stringp (car entry))
          (or (keywordp (cdr entry))
              (stringp (cdr entry))
              (symbolp (cdr entry))))
     (cons (normalize-chord (car entry)) (normalize-action (cdr entry))))
    ((and (listp entry)
          (= (length entry) 2)
          (stringp (first entry)))
     (cons (normalize-chord (first entry)) (normalize-action (second entry))))
    ((and (listp entry)
          (getf entry :chord)
          (getf entry :action))
     (cons (normalize-chord (getf entry :chord))
           (normalize-action (getf entry :action))))
    (t nil)))

(defun normalize-override-entries (entries)
  "Return normalized keymap override entries from ENTRIES.

Malformed entries are ignored."
  (remove nil (mapcar #'parse-override-entry entries)))
