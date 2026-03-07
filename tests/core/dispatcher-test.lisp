(in-package #:altera-launcher.tests.dispatcher)

(deftest dispatches-registered-command
  (let ((registry (make-command-registry)))
    (register-command
     registry
     (make-command-spec :name "sum"
                        :handler (lambda (&rest args)
                                   (reduce #'+ args :initial-value 0))
                        :extension "reference"))
    (equal 6 (dispatch-command registry "sum" 1 2 3))))

(deftest unknown-command-signals-error
  (let ((registry (make-command-registry)))
    (ok (signals (dispatch-command registry "missing") 'unknown-command-error))))
