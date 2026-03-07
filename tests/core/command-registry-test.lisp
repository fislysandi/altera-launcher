(in-package #:altera-launcher.tests.command-registry)

(deftest register-and-find-command
  (let ((registry (make-command-registry)))
    (register-command
     registry
     (make-command-spec :name "hello"
                        :handler (lambda (&rest args)
                                   (declare (ignore args))
                                   :ok)
                        :extension "reference"))
    (ok (find-command registry "hello"))))

(deftest duplicate-command-registration-signals-error
  (let ((registry (make-command-registry)))
    (register-command
     registry
     (make-command-spec :name "hello"
                        :handler (lambda (&rest args)
                                   (declare (ignore args))
                                   :ok)
                        :extension "reference"))
    (ok (signals
         (register-command
          registry
          (make-command-spec :name "hello"
                             :handler (lambda () :duplicate)
                             :extension "reference"))
         'duplicate-command-error))))

(deftest list-commands-is-sorted
  (let ((registry (make-command-registry)))
    (register-command registry (make-command-spec :name "zeta" :handler (lambda () :z)))
    (register-command registry (make-command-spec :name "alpha" :handler (lambda () :a)))
    (equal '("alpha" "zeta")
           (mapcar #'command-spec-name (list-commands registry)))))
