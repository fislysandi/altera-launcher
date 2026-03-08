(:version "1"
 :extensions
 ((:name "ocicl-manager"
   :system "ocicl-manager"
   :asd "extensions/ocicl-manager/ocicl-manager.asd"
   :ocicl-projects ("rove"))
  (:name "ui-theme"
   :system "ui-theme"
   :asd "extensions/ui-theme/ui-theme.asd"
   :ocicl-projects ())
  (:name "ui-renderer"
   :system "ui-renderer"
   :asd "extensions/ui-renderer/ui-renderer.asd"
   :ocicl-projects ())
  (:name "ui-terminal"
   :system "ui-terminal"
   :asd "extensions/ui-terminal/ui-terminal.asd"
   :ocicl-projects ())
  (:name "app-scanner"
   :system "app-scanner"
   :asd "extensions/app-scanner/app-scanner.asd"
   :ocicl-projects ())
  (:name "keymap-engine"
   :system "keymap-engine"
   :asd "extensions/keymap-engine/keymap-engine.asd"
   :ocicl-projects ())
  (:name "ui-gtk"
   :system "ui-gtk"
   :asd "extensions/ui-gtk/ui-gtk.asd"
   :ocicl-projects ("cl-cffi-gtk" "cl-cffi-graphene")))
 :notes "Extension project manifest for one-command setup.")
