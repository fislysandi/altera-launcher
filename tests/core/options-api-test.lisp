(in-package #:altera-launcher.tests.options-api)

(deftest collect-option-report-surfaces-provider-errors
  (let ((sources (make-hash-table :test #'equal)))
    (setf (gethash "ok.source" sources)
          (list :id "ok.source"
                :extension "ok-extension"
                :provider (lambda (query &optional context)
                            (declare (ignore query context))
                            (list (list :id "ok.item"
                                        :title "Working Item"
                                        :kind :command
                                        :command "ok.run")))))
    (setf (gethash "bad.source" sources)
          (list :id "bad.source"
                :extension "bad-extension"
                :provider (lambda (query &optional context)
                            (declare (ignore query context))
                            (error "provider exploded"))))
    (let ((report (collect-option-report sources :query "")))
      (testing "successful provider items remain available"
        (ok (= 1 (length (getf report :items)))))
      (testing "provider error metadata is returned"
        (ok (= 1 (length (getf report :errors))))
        (ok (string= "bad.source"
                     (getf (first (getf report :errors)) :source)))))))
