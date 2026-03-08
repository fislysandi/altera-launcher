(in-package #:altera-launcher.tests.perf)

(defun env-enabled-p (name)
  "Return true when env var NAME enables perf tests."
  (let ((value (uiop:getenv name)))
    (and value
         (member (string-downcase value)
                 '("1" "true" "yes" "on")
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

(defun measure-process-ms (argv &key directory)
  "Run ARGV command in DIRECTORY and return elapsed milliseconds."
  (let ((start (now-ms)))
    (uiop:run-program argv
                      :directory directory
                      :output :string
                      :error-output :string
                      :ignore-error-status nil)
    (- (now-ms) start)))

(defun startup-command ()
  "Return SBCL command argv used for startup benchmark."
  (list "sbcl"
        "--non-interactive"
        "--load" "altera-launcher.asd"
        "--eval" "(asdf:load-system \"altera-launcher\")"
        "--quit"))

(defun bootstrap-command ()
  "Return SBCL command argv used for full bootstrap benchmark."
  (list "sbcl"
        "--non-interactive"
        "--load" "altera-launcher.asd"
        "--eval" "(asdf:load-system \"altera-launcher\")"
        "--eval" "(let ((runtime (altera-launcher:bootstrap))) (declare (ignore runtime)))"
        "--quit"))

(defun gtk-preflight-command ()
  "Return SBCL command argv used for GTK startup-path benchmark."
  (list "sbcl"
        "--non-interactive"
        "--load" "altera-launcher.asd"
        "--eval" "(asdf:load-system \"altera-launcher\")"
        "--eval" "(let* ((runtime (altera-launcher:bootstrap)) (report (altera-launcher:run-command runtime \"ui.gui.self-test\"))) (declare (ignore report)))"
        "--quit"))

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
  (let ((dir (system-source-directory :altera-launcher))
        (argv (startup-command)))
    (loop repeat count
          collect (measure-process-ms argv :directory dir))))

(defun measure-bootstrap-runs (count)
  "Measure full launcher bootstrap COUNT times and return elapsed ms list."
  (let ((dir (system-source-directory :altera-launcher))
        (argv (bootstrap-command)))
    (loop repeat count
          collect (measure-process-ms argv :directory dir))))

(defun measure-gtk-preflight-runs (count)
  "Measure GTK startup preflight path COUNT times and return elapsed ms list."
  (let ((dir (system-source-directory :altera-launcher))
        (argv (gtk-preflight-command)))
    (loop repeat count
          collect (measure-process-ms argv :directory dir))))

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
             (threshold-ms (env-ms-threshold "ALTERA_STARTUP_MAX_MS" 2000)))
        (assert-median-under-threshold runs threshold-ms "Core load-system startup"))
      (ok t "Set ALTERA_ENABLE_PERF_TESTS=1 to run startup benchmark.")))

(deftest startup-bootstrap-under-threshold
  (if (env-enabled-p "ALTERA_ENABLE_PERF_TESTS")
      (let* ((runs (measure-bootstrap-runs 3))
             (threshold-ms (env-ms-threshold "ALTERA_BOOTSTRAP_MAX_MS" 3500)))
        (assert-median-under-threshold runs threshold-ms "Full bootstrap startup"))
      (ok t "Set ALTERA_ENABLE_PERF_TESTS=1 to run bootstrap benchmark.")))

(deftest startup-gtk-path-under-threshold
  (if (env-enabled-p "ALTERA_ENABLE_GTK_PERF_TESTS")
      (let* ((runs (measure-gtk-preflight-runs 3))
             (threshold-ms (env-ms-threshold "ALTERA_GTK_STARTUP_MAX_MS" 6000)))
        (assert-median-under-threshold runs threshold-ms "GTK preflight startup path"))
      (ok t "Set ALTERA_ENABLE_GTK_PERF_TESTS=1 to run GTK startup benchmark.")))
