; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.

;; Command is installed in "File->Generate style sheet for hmi..."
;;
;; A checkbox provides the option of using the layernames for the
;; filenames. 
;;
;; When saving to GIF files, the GIMP's default values are used to
;; convert to INDEXED mode (255 color palette, no dithering).
;; Note: this is done on a layer-by-layer basis, so more colors may result
;; than if the entire image were converted to INDEXED before saving.

;Batch all the layers
(define (get-all-layers image)
  (let* (
    (all-layers (gimp-image-get-layers image))
    (i (car all-layers))
    (bottom-to-top ())
    )
    (set! all-layers (cadr all-layers))
    (while (> i 0)
      (set! bottom-to-top (append bottom-to-top (cons (aref all-layers (- i 1)) '())))
      (set! i (- i 1))
    )
    bottom-to-top
  )
)
  
;Only batch visible layers
(define (get-visible-layers image)
  (let* (
    (all-layers (gimp-image-get-layers image))
    (i (car all-layers))
    (viewable '())
    )
    (set! all-layers (cadr all-layers))
    (while (> i 0)
      (set! i (- i 1))
      (if (= (car (gimp-drawable-get-visible (vector-ref all-layers i))) TRUE)
        (set! viewable (cons (vector-ref all-layers i) viewable))
      )
    )
    viewable
  )
)

;Save the layer as an image
(define (save-layer orig-image layer name)
  (let* (
    (image 0)
    (buffer "")
    )
    (set! buffer (car (gimp-edit-named-copy layer "temp-copy")))
    (set! image (car (gimp-edit-named-paste-as-new buffer)))
    (when (and (not (= (car (gimp-image-base-type image)) INDEXED))
               (string-ci=? (car (last (strbreakup name "."))) "gif"))
      (gimp-image-convert-indexed image
                                  NO-DITHER
                                  MAKE-PALETTE
                                  255
                                  FALSE
                                  FALSE
                                  "")
    )
    (gimp-file-save RUN-NONINTERACTIVE image (car (gimp-image-get-active-layer image)) name name)
    (gimp-buffer-delete buffer)
    (gimp-image-delete image)
  )
)

(define (sg-generate-style-sheet orig-image drawable
                                    rename-layers
                                    select-visible-layers
                                    target-directory)
  (let* (
    (layers nil)
    (fullname "")
    (basename "")
    (layername "")
    (template "frame_~~~~.png")  
    (format "")
    (layerpos 1)
    (framenum "")
    (settings "")
    (extension "png")
    (orig-selection 0)
    )
    (gimp-image-undo-disable orig-image)
    (set! orig-selection (car (gimp-selection-save orig-image)))
    (gimp-selection-none orig-image)

    (when (= rename-layers TRUE)
      (set! format (strbreakup template "~"))
      (if (> (length format) 1)
        (begin
          (set! basename (car format))
          (set! format (cdr format))
          (set! format (cons "" (butlast format)))
          (set! format (string-append "0" (unbreakupstr format "0")))
          )
        (begin
          (set! basename (car (strbreakup template ".")))
          (set! format "0000")
          )
        )
    )
    (if (= select-visible-layers TRUE)
      (set! layers (get-visible-layers orig-image))
      (set! layers (get-all-layers orig-image))
    )
    (while (pair? layers)
      (if (= rename-layers TRUE)
        (begin ;Create the name with the frame number 
          (set! framenum (number->string layerpos))
          (set! framenum (string-append
                (substring format 0 (- (string-length format)
                                       (string-length framenum))) framenum))
          (set! fullname (string-append basename framenum))
        )
        (begin ;Create the name with the layer name
          (set! fullname (car (gimp-drawable-get-name (car layers))))
        )
      )
      (set! fullname (string-append target-directory "/" fullname)) ;Add the path
      (set! fullname (string-append fullname "." extension)) ;Add the extension
      (save-layer orig-image (car layers) fullname) ;Save the layer as an image
      (set! layers (cdr layers)) ;Next layer
      (set! layerpos (+ layerpos 1)) ;Increment the frame number
    )
    (gimp-selection-load orig-selection)
    (gimp-image-remove-channel orig-image orig-selection)
    (gimp-image-undo-enable orig-image)
  )
)


(script-fu-register "sg-generate-style-sheet"
 "Generate style sheet for hmi..."
 "Save each layer and coordinates to files."
 "Philippe COLLIOT"
 "Philippe COLLIOT"
 "05/04/2014"
 "*"
 SF-IMAGE    "Image"    0
 SF-DRAWABLE "Drawable" 0
 SF-TOGGLE "Rename layers (ex: 'frame__0001')" FALSE
 SF-TOGGLE "Save only visible layers"    TRUE
 SF-DIRNAME "Target directory" "$HOME"
)

(script-fu-menu-register "sg-generate-style-sheet"
                         "<Image>/File/")
