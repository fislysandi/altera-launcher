(in-package #:altera-launcher.extensions.ui-renderer)

(defparameter *renderer-layout-hooks*
  '(("compact" :list-width-ratio 0.62 :preview-visible t :status-rail "minimal")
    ("balanced" :list-width-ratio 0.55 :preview-visible t :status-rail "full")
    ("spotlight" :list-width-ratio 0.75 :preview-visible nil :status-rail "minimal"))
  "Named layout hook presets exposed by renderer extension.")

(defparameter *active-layout-hook* "balanced"
  "Currently selected renderer layout hook name.")

(defun renderer-contract ()
  "Return toolkit-agnostic renderer surface and behavior contract plist."
  '(:surface (:input :results-list :preview-panel :status-rail)
    :style-hooks (:palette :typography :spacing :motion)
    :layout-hooks (:list-width-ratio :preview-visible :status-rail)
    :behavior-hooks (:staggered-results :selection-animation :empty-state)
    :responsiveness (:mobile-single-column t :desktop-split-layout t)))

(defun list-layout-hooks ()
  "Return available renderer layout hook names."
  (mapcar #'first *renderer-layout-hooks*))

(defun find-layout-hook (name)
  "Find layout hook by NAME and return full hook plist entry or NIL."
  (find name *renderer-layout-hooks* :key #'first :test #'string=))

(defun select-layout-hook (name)
  "Set active layout hook to NAME and return selected hook name."
  (if (find-layout-hook name)
      (setf *active-layout-hook* name)
      (error "Unknown layout hook: ~A" name)))

(defun render-preview-model (query selected-index)
  "Build preview model for QUERY and SELECTED-INDEX using active layout."
  (list :surface "launcher-v1"
        :query query
        :selection selected-index
        :layout *active-layout-hook*
        :layout-options (rest (find-layout-hook *active-layout-hook*))
        :animations '(:page-load-fade :staggered-results :selection-slide)
        :a11y '(:high-contrast-focus-ring :reduced-motion-compatible)))

(define-extension ("ui-renderer"
                   :version "0.1.0"
                   :description "Customizable launcher rendering contract and layout hooks")
  (define-command
   "ui.renderer.contract"
   (lambda (&rest args)
     (declare (ignore args))
     (renderer-contract))
   :title "Renderer Contract"
   :description "Returns renderer surface contract for extension implementors."
   :tags '("ui" "renderer" "contract"))

  (define-command
   "ui.renderer.layouts"
   (lambda (&rest args)
     (declare (ignore args))
     (list-layout-hooks))
   :title "List Layout Hooks"
   :description "Lists available renderer layout hooks."
   :tags '("ui" "renderer" "layout"))

  (define-command
   "ui.renderer.layout.set"
   (lambda (layout-name &rest args)
     (declare (ignore args))
     (select-layout-hook layout-name))
   :title "Set Layout Hook"
   :description "Sets active renderer layout hook."
   :tags '("ui" "renderer" "layout" "customization"))

  (define-command
   "ui.renderer.preview"
   (lambda (&optional (query "") (selected-index 0) &rest args)
     (declare (ignore args))
     (render-preview-model query selected-index))
   :title "Renderer Preview Model"
   :description "Returns preview model for rendering the launcher shell."
   :tags '("ui" "renderer" "preview")))
