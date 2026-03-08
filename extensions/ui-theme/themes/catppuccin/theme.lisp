(in-package #:altera-launcher.extensions.ui-theme)

(define-theme "catppuccin"
  :palette (:background "#1e1e2e" :foreground "#cdd6f4" :primary "#89b4fa" :accent "#f5c2e7")
  :typography (:ui "Inter" :display "Space Grotesk" :mono "JetBrains Mono" :scale (:sm 0.9 :md 1.0 :lg 1.2 :xl 1.6))
  :spacing (:base 4 :scale (:1 4 :2 8 :3 12 :4 16 :6 24 :8 32 :12 48))
  :motion (:duration-fast 80 :duration-medium 150 :duration-slow 240 :curve "cubic-bezier(0.2,0.8,0.2,1)"))
