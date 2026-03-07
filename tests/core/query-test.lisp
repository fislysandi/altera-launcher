(in-package #:altera-launcher.tests.query)

(deftest search-commands-matches-name-and-description
  (let ((registry (make-command-registry)))
    (register-command
     registry
     (make-command-spec :name "hello"
                        :handler (lambda () "ok")
                        :title "Hello"
                        :description "Greets user"
                        :extension "reference"))
    (register-command
     registry
     (make-command-spec :name "sum"
                        :handler (lambda (&rest args) (reduce #'+ args :initial-value 0))
                        :title "Sum"
                        :description "Adds numbers"
                        :extension "reference"))
    (equal 1 (length (search-commands registry "greet")))
    (equal 1 (length (search-commands registry "sum")))))

(deftest commands-for-extension-filters-correctly
  (let ((registry (make-command-registry)))
    (register-command registry (make-command-spec :name "a" :handler (lambda () :a) :extension "ref"))
    (register-command registry (make-command-spec :name "b" :handler (lambda () :b) :extension "other"))
    (equal 1 (length (commands-for-extension registry "ref")))))
