(in-package #:altera-launcher.extensions.ui-theme)

(define-theme "atelier-light"
  :palette (:background "#f4f0e6" :foreground "#1f1a16" :primary "#ca5b2a" :accent "#2f8f7f")
  :typography (:ui "Space Grotesk" :display "Oxanium" :mono "JetBrains Mono" :scale (:sm 0.875 :md 1.0 :lg 1.25 :xl 1.75))
  :spacing (:base 4 :scale (:1 4 :2 8 :3 12 :4 16 :6 24 :8 32 :12 48))
  :motion (:duration-fast 90 :duration-medium 160 :duration-slow 280 :curve "cubic-bezier(0.22,1,0.36,1)"))
