(in-package #:altera-launcher.tests.perf)

(defun env-enabled-p (name)
  "Return true when env var NAME enables perf tests."
  (let ((value (uiop:getenv name)))
    (and value
         (member (string-downcase value)
                 '("1" "true" "yes" "on")
                 :test #'string=))))

(defun env-disabled-p (name)
  "Return true when env var NAME explicitly disables feature." 
  (let ((value (uiop:getenv name)))
    (and value
         (member (string-downcase value)
                 '("0" "false" "no" "off")
                 :test #'string=))))

(defun env-ms-threshold (name default-ms)
  "Return integer threshold from env var NAME or DEFAULT-MS."
  (let ((value (uiop:getenv name)))
    (or (and value
             (ignore-errors
               (let ((parsed (parse-integer value :junk-allowed t)))
                 (and parsed (> parsed 0) parsed))))
        default-ms)))

(defun now-ms ()
  "Return monotonic-ish current time in milliseconds."
  (* 1000.0
     (/ (get-internal-real-time) internal-time-units-per-second)))

(defparameter *startup-core-state* :unknown
  "Startup core state cache: :unknown, :usable, or :unusable.")

(defun run-process-ms (argv directory)
  "Run ARGV command in DIRECTORY and return elapsed milliseconds."
  (let ((start (now-ms)))
    (uiop:run-program argv
                      :directory directory
                      :output :string
                      :error-output :string
                      :ignore-error-status nil)
    (- (now-ms) start)))

(defun measure-process-ms (argv &key directory fallback-argv)
  "Run ARGV command in DIRECTORY; on failure, try FALLBACK-ARGV when provided."
  (handler-case
      (run-process-ms argv directory)
    (error ()
      (if fallback-argv
          (progn
            (setf *startup-core-state* :unusable)
            (run-process-ms fallback-argv directory))
          (error "Process run failed for argv: ~S" argv)))))

(defun startup-core-pathname ()
  "Return pathname for startup core used by perf benchmarks."
  (let* ((root (system-source-directory :altera-launcher))
         (from-env (uiop:getenv "ALTERA_STARTUP_CORE_PATH")))
    (if (and from-env (> (length from-env) 0))
        (pathname from-env)
        (merge-pathnames ".tmp/perf/altera-startup.core" root))))

(defun use-startup-core-p ()
  "Return true when startup benchmarks should use dumped core path."
  (not (env-disabled-p "ALTERA_USE_STARTUP_CORE")))

(defun startup-core-smoke-check-p (core-path)
  "Return non-NIL when CORE-PATH can be used with SBCL --core."
  (handler-case
      (progn
        (uiop:run-program (list "sbcl"
                                "--non-interactive"
                                "--no-userinit"
                                "--no-sysinit"
                                "--core" (namestring core-path)
                                "--eval" "(values)"
                                "--quit")
                          :output :string
                          :error-output :string
                          :ignore-error-status nil)
        t)
    (error () nil)))

(defun ensure-startup-core-built ()
  "Build startup core image if it does not already exist." 
  (let ((core-path (startup-core-pathname)))
    (unless (probe-file core-path)
      (let ((repo-root (system-source-directory :altera-launcher)))
        (uiop:run-program
         (list "sbcl" "--non-interactive" "--script" "scripts/build-startup-core.lisp")
         :directory repo-root
         :output :string
         :error-output :string
         :ignore-error-status nil
         :env (list (cons :ALTERA_STARTUP_CORE_OUTPUT (namestring core-path))))))
    core-path))

(defun startup-core-usable-p ()
  "Return non-NIL when startup core mode is enabled and smoke-check passes."
  (cond
    ((not (use-startup-core-p)) nil)
    ((eq *startup-core-state* :usable) t)
    ((eq *startup-core-state* :unusable) nil)
    (t
     (let ((usable (startup-core-smoke-check-p (ensure-startup-core-built))))
       (setf *startup-core-state* (if usable :usable :unusable))
       usable))))

(defun startup-command-no-core ()
  "Return baseline SBCL command argv for load-system startup benchmark."
  (list "sbcl"
        "--non-interactive"
        "--load" "altera-launcher.asd"
        "--eval" "(asdf:load-system \"altera-launcher\")"
        "--quit"))

(defun startup-command-with-core ()
  "Return core-based SBCL command argv for startup benchmark."
  (let ((core-path (namestring (ensure-startup-core-built))))
    (list "sbcl"
          "--non-interactive"
          "--no-userinit"
          "--no-sysinit"
          "--core" core-path
          "--eval" "(values)"
          "--quit")))

(defun startup-command ()
  "Return SBCL command argv used for startup benchmark."
  (if (startup-core-usable-p)
      (startup-command-with-core)
      (startup-command-no-core)))

(defun bootstrap-command-no-core ()
  "Return baseline SBCL command argv for full bootstrap benchmark."
  (list "sbcl"
        "--non-interactive"
        "--load" "altera-launcher.asd"
        "--eval" "(asdf:load-system \"altera-launcher\")"
        "--eval" "(let ((runtime (altera-launcher:bootstrap))) (declare (ignore runtime)))"
        "--quit"))

(defun bootstrap-command-with-core ()
  "Return core-based SBCL command argv for full bootstrap benchmark."
  (let ((core-path (namestring (ensure-startup-core-built))))
    (list "sbcl"
          "--non-interactive"
          "--no-userinit"
          "--no-sysinit"
          "--core" core-path
          "--eval" "(let ((runtime (altera-launcher:bootstrap))) (declare (ignore runtime)))"
          "--quit")))

(defun bootstrap-command ()
  "Return SBCL command argv used for full bootstrap benchmark."
  (if (startup-core-usable-p)
      (bootstrap-command-with-core)
      (bootstrap-command-no-core)))

(defun gtk-preflight-command-no-core ()
  "Return baseline SBCL command argv for GTK startup-path benchmark."
  (list "sbcl"
        "--non-interactive"
        "--load" "altera-launcher.asd"
        "--eval" "(asdf:load-system \"altera-launcher\")"
        "--eval" "(let* ((runtime (altera-launcher:bootstrap)) (report (altera-launcher:run-command runtime \"ui.gui.self-test\"))) (declare (ignore report)))"
        "--quit"))

(defun gtk-preflight-command-with-core ()
  "Return core-based SBCL command argv for GTK startup-path benchmark."
  (let ((core-path (namestring (ensure-startup-core-built))))
    (list "sbcl"
          "--non-interactive"
          "--no-userinit"
          "--no-sysinit"
          "--core" core-path
          "--eval" "(let* ((runtime (altera-launcher:bootstrap)) (report (altera-launcher:run-command runtime \"ui.gui.self-test\"))) (declare (ignore report)))"
          "--quit")))

(defun gtk-preflight-command ()
  "Return SBCL command argv used for GTK startup-path benchmark."
  (if (startup-core-usable-p)
      (gtk-preflight-command-with-core)
      (gtk-preflight-command-no-core)))

(defun median-ms (samples)
  "Return median value from SAMPLES list."
  (let* ((sorted (sort (copy-list samples) #'<))
         (len (length sorted))
         (mid (floor len 2)))
    (if (oddp len)
        (nth mid sorted)
        (/ (+ (nth (1- mid) sorted)
              (nth mid sorted))
           2.0))))

(defun measure-startup-runs (count)
  "Measure launcher startup COUNT times and return elapsed ms list." 
  (let ((dir (system-source-directory :altera-launcher)))
    (loop repeat count
          collect (measure-process-ms (startup-command)
                                      :directory dir
                                      :fallback-argv (startup-command-no-core)))))

(defun measure-bootstrap-runs (count)
  "Measure full launcher bootstrap COUNT times and return elapsed ms list."
  (let ((dir (system-source-directory :altera-launcher)))
    (loop repeat count
          collect (measure-process-ms (bootstrap-command)
                                      :directory dir
                                      :fallback-argv (bootstrap-command-no-core)))))

(defun measure-gtk-preflight-runs (count)
  "Measure GTK startup preflight path COUNT times and return elapsed ms list."
  (let ((dir (system-source-directory :altera-launcher)))
    (loop repeat count
          collect (measure-process-ms (gtk-preflight-command)
                                      :directory dir
                                      :fallback-argv (gtk-preflight-command-no-core)))))

(defun assert-median-under-threshold (runs threshold-ms label)
  "Assert RUNS median is <= THRESHOLD-MS with LABEL in report output."
  (let ((median (median-ms runs)))
    (ok (<= median threshold-ms)
        (format nil
                "~A median ~,1fms must be <= ~Dms; samples=~S"
                label
                median
                threshold-ms
                runs))))

(deftest startup-load-system-under-threshold
  (if (env-enabled-p "ALTERA_ENABLE_PERF_TESTS")
      (let* ((runs (measure-startup-runs 5))
             (threshold-ms (env-ms-threshold "ALTERA_STARTUP_MAX_MS" 150)))
        (assert-median-under-threshold runs threshold-ms "Core load-system startup"))
      (ok t "Set ALTERA_ENABLE_PERF_TESTS=1 to run startup benchmark.")))

(deftest startup-bootstrap-under-threshold
  (if (env-enabled-p "ALTERA_ENABLE_PERF_TESTS")
      (let* ((runs (measure-bootstrap-runs 3))
             (threshold-ms (env-ms-threshold "ALTERA_BOOTSTRAP_MAX_MS" 150)))
        (assert-median-under-threshold runs threshold-ms "Full bootstrap startup"))
      (ok t "Set ALTERA_ENABLE_PERF_TESTS=1 to run bootstrap benchmark.")))

(deftest startup-gtk-path-under-threshold
  (if (env-enabled-p "ALTERA_ENABLE_GTK_PERF_TESTS")
      (let* ((runs (measure-gtk-preflight-runs 3))
             (threshold-ms (env-ms-threshold "ALTERA_GTK_STARTUP_MAX_MS" 500)))
        (assert-median-under-threshold runs threshold-ms "GTK preflight startup path"))
      (ok t "Set ALTERA_ENABLE_GTK_PERF_TESTS=1 to run GTK startup benchmark.")))
