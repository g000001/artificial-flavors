#+:Genera
(eval-when (load compile)
  (unless (member :clos *features*)
    (error "Sorry, CLOS is required.  Look for the PCL version in the attic.")))

;;; We DON'T package-use CLOS, because we define our own version of defmethod, etc.
;;; instead we refer to CLOS symbols eith explicit pkg names.

(defpackage :artificial-flavors
  (:nicknames "AF")
  (:use :cl)
  (:shadow :defmethod :make-instance)
  (:export :defflavor :defmethod :make-instance :symbol-value-in-instance :boundp-in-instance
           :compile-flavor-methods :self))

#+:MCL
(defpackage clos
  (:use CCL CL)
  (:export defclass defmethod with-slots initialize-instance find-class make-instance slot-value slot-boundp))


