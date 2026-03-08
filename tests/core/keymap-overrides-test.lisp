(in-package #:altera-launcher.tests.keymap-overrides)

(deftest parse-override-entry-matrix
  (testing "supports dotted pair entry"
    (equal (cons "ctrl+n" :move-next)
           (parse-override-entry (cons "Ctrl+N" :move-next))))
  (testing "supports two-item list with string action"
    (equal (cons "ctrl+p" :move-prev)
           (parse-override-entry (list "Ctrl+P" "move-prev"))))
  (testing "supports plist entry"
    (equal (cons "j" :move-next)
           (parse-override-entry (list :chord "J" :action :move-next))))
  (testing "returns NIL for malformed entry"
    (ok (null (parse-override-entry (list :chord "j"))))
    (ok (null (parse-override-entry 42)))))

(deftest config-overrides-filters-invalid-entries
  (equal
   (list (cons "ctrl+b" :open-command-actions)
         (cons "ctrl+n" :move-next))
   (normalize-override-entries
    (list (cons "Ctrl+B" :open-command-actions)
          (list "Ctrl+N" "move-next")
          (list :chord "broken")))))
