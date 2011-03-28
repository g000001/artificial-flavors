;;;; artificial-flavors.asd

(asdf:defsystem #:artificial-flavors
  :serial t
  :depends-on (:closer-mop)
  :components ((:file "package")
               (:file "artificial-flavors")))

