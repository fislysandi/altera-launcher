(in-package #:altera-launcher.extensions.ui-theme)

(define-theme "dracula"
  :palette (:background "#282a36" :foreground "#f8f8f2" :primary "#bd93f9" :accent "#ff79c6")
  :typography (:ui "JetBrains Mono" :display "Space Grotesk" :mono "JetBrains Mono" :scale (:sm 0.9 :md 1.0 :lg 1.2 :xl 1.6))
  :spacing (:base 4 :scale (:1 4 :2 8 :3 12 :4 16 :6 24 :8 32 :12 48))
  :motion (:duration-fast 80 :duration-medium 150 :duration-slow 240 :curve "cubic-bezier(0.2,0.8,0.2,1)"))
