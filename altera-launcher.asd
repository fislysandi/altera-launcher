(asdf:defsystem "altera-launcher"
  :description "Minimal, extension-first launcher core written in Common Lisp"
  :author "altera-launcher contributors"
  :license "GPL-3.0-or-later"
  :version "0.1.0"
  :serial t
  :depends-on ("uiop")
  :components ((:file "src/packages")
               (:file "src/core/command-registry")
               (:file "src/core/extension-loader")
               (:file "src/core/dispatcher")
               (:file "src/core/query")
               (:file "src/core/config")
               (:file "src/core/keymap-overrides")
               (:file "src/core/desktop-apps")
               (:file "src/extensions/api")
               (:file "src/main")))

(asdf:defsystem "altera-launcher/tests"
  :description "Test system for altera-launcher"
  :depends-on ("altera-launcher" "rove")
  :serial t
  :components ((:file "tests/packages")
               (:file "tests/core/command-registry-test")
               (:file "tests/core/extension-loader-test")
               (:file "tests/core/dispatcher-test")
               (:file "tests/core/query-test")
               (:file "tests/core/options-api-test")
               (:file "tests/core/keymap-overrides-test")
               (:file "tests/integration/extension-loading-test")
               (:file "tests/main"))
  :perform (asdf:test-op (op component)
             (declare (ignore op component))
             (funcall (intern "RUN-ALL-TESTS" "ALTERA-LAUNCHER.TESTS.MAIN"))))
