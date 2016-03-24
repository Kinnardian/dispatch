; Epigraphy — arc-language HTML Templating Engine
; we use HTML5.  that means, less cruft (things like closing </html> or
; type="text/javascript" not mandatory, so skipped to save bandwidth)
; but don't worry old browsers will still be able to handle it (IE6 does!)

(def prdoctype ((o dt "html"))  (pr "<!doctype " dt ">"))

 (mac htmlpage (headers . body)
   `(do (prdoctype)
        (start-tag 'html)
        (tag head
             (gentag meta http-equiv "content-type"
                    content "text/html; charset=utf-8")
             ; better to specify encoding here, in the html: avoid
             ; problems if the user locally saves and consults the page
             ,@headers)
        (flushout)
        (start-tag 'body)
        ,@body))

(defs js   (url) (tag (script src url))
      ijs  (str) (tag script (disp str))  ; inline code
      css  (url) (gentag link href url rel "stylesheet")
      icss (str) (tag style (disp str)))

(def lblinp (label name (o typ "text") (o val) (o sz 12))
  (tag (label for name) (pr label))
  (gentag input type typ  id name  name name  value val  size sz))

(def render (view (o parameters))(

  (prn "I was asked to render this view: " view)
)
)

(render "CartoonWorld")