(in-package #:altera-launcher.extensions.ui-theme)

(define-theme "graphite-dark"
  :palette (:background "#1f252b" :foreground "#f0f4f7" :primary "#5db2a4" :accent "#f08a4b")
  :typography (:ui "Outfit" :display "Space Grotesk" :mono "IBM Plex Mono" :scale (:sm 0.875 :md 1.0 :lg 1.2 :xl 1.6))
  :spacing (:base 4 :scale (:1 4 :2 8 :3 12 :4 16 :6 24 :8 32 :12 48))
  :motion (:duration-fast 80 :duration-medium 150 :duration-slow 260 :curve "cubic-bezier(0.16,1,0.3,1)"))
