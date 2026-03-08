(in-package #:altera-launcher.extensions.ui-theme)

(define-theme "neo-brass"
  :palette (:background "#fff6db" :foreground "#18120d" :primary "#e15c2c" :accent "#6a57d2")
  :typography (:ui "DM Sans" :display "Oxanium" :mono "Space Mono" :scale (:sm 0.9 :md 1.0 :lg 1.3 :xl 1.8))
  :spacing (:base 4 :scale (:1 4 :2 8 :3 12 :4 16 :6 24 :8 32 :12 48))
  :motion (:duration-fast 70 :duration-medium 140 :duration-slow 220 :curve "cubic-bezier(0.2,0.8,0.2,1)"))
