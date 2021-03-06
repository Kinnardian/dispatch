;;; web.arc: a web toolkit

;; Paths
; (defpath /hello (req)  (prs "hello" req!ip "you are visiting" req!path))
;   -> normal, literal path, 'defop-like
;
; (defpath /user/: (req usr)  (prs "hello" usr))
;   -> matches "/user/pal", "/user/john" but NOT "/user/pal/stuff"
;
; (defpath /user/:/file/* (req usr file)  (prs usr "requesting" file))
;   -> matches "/user/pal/file/http.arc", "/user/pal/file/web/beta/wf.arc"
;
; 'register-complexpath / 'find-complexpath not to be used directly:
; they are called by 'register-path / 'findpath when needed

(= litpaths* (table)  complexpaths* ())

(def register-path (str f)
  (if (some [in _ #\: #\*] str)
    (register-complexpath str f)
    (= litpaths*.str f)))

(def register-complexpath (str f)
  (let pstruct (list (tokens str #\/) f)
    (aif (assoc str complexpaths*)
      (= it.1 pstruct)  ; already exists, replace
      (push (list str pstruct) complexpaths*))))

(def findpath (path)  ; actually "find the handler function for this path"
  (aif litpaths*.path
    it
    (find-complexpath (tokens path #\/))))

(def find-complexpath (ptoks (o cands complexpaths*))
  (whenlet (str (toks f)) (car cands)
    (aif (complexpath-match ptoks toks)
      (list f rev.it)
      (find-complexpath ptoks (cdr cands)))))

(def complexpath-match (pc cc (o acc))  ; return the list of bindings if matched
  (if (and no.pc no.cc)
    acc
    (when (car cc)
      (case cc.0.0  ; first char
        #\: (complexpath-match (cdr pc) (cdr cc) (cons (car pc) acc))
        #\* (cons (string:intersperse #\/ pc) acc)
            (when (is cc.0 (car pc))  ; literal token
              (complexpath-match (cdr pc) (cdr cc) acc))))))

(mac defpath-raw (path vars . body)
  `(register-path ,(string path) (fn ,vars ,@body)))

(mac defpath (path vars . body)
  `(defpath-raw ,path ,vars
     (resphead)
     ,@body))


;; Bring a taste of state to HTTP
; stealed from {srv|app}.arc but made simpler/saner:
; can't see, for instance, why /x and /r should be on different paths.
; and also, no twenty ...form ('arform 'tarform and 'onclick etc.)
; You're of course free to define 'onclick and co., if you need them:
; but we advice you to think twice about it: this stuff is good, but its
; scope is or at least should be limited.  Javascript exists, and
; client caching is cool.  It's 2k9 now, not 1999.  Be a man and code an
; Arc to JS compiler (have a look at scheme2js).  The Arc challenge
; is a joke.


(= ops*    (table)  ; todo: expires after some sensible time val (6 hours?)
   opurl*  "/x/")

(register-path (string opurl* ":")
  (fn (req id)  (aif ops*.id (it req) (resp-err))))

(def new-opid ((o leng 12))
  (check (rand-string leng) ~ops* (new-opid leng)))

(def newop (f)
  (atlet id (new-opid)
    (= ops*.id f)
    id))

(def opurl (id)  (string opurl* id))

(mac fnform (f . body)
  `(let id (newop ,f)
     (tag (form method 'post action (opurl id))
       ,@body)))


;; Misc utils

(def resp-err ((o msg "404 - Not found") (o sta http-notfound+))
  (resphead sta (copy httpd-headers* "Content-Type" "text/plain"))
  (prn msg))

(defs arg  (req argname)   (alref req!args argname)
      hd   (req hdname)    (alref req!headers hdname)
      cook (req cookname)  (alref req!cooks cookname))


(def dispatch (req)
  (iflet handler (findpath req!path)
    (if (alist handler)  ; true if complex path
      (apply handler.0 (cons req handler.1))
      (handler req))
    (resp-err)))

; (= httpd-handler dispatch)  ; the right choice for 95% of cases, but
; for instance you might want to use a unique session cookie for each
; visitor, in this case, do some "Cookie" header parsing before to dispatch.
