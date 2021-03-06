;;; -*- Mode: LISP; Syntax: Common-lisp; Base: 10; Package: (artificial-flavors :nicknames (af) :use cl) -*-
;;; A  straightforward partial implementation of Symbolics New Flavors in PCL.
;;; Michael Travers 8 Dec 88
;;; updated for "5/22/89 Victoria PCL", 13 September 89
;;; CLOS version 24 Aug 90

(in-package :af)

(defmacro defflavor (name ivs components &rest options)
  (let ((reader-slots nil)
        (writer-slots nil)
        (init-slots nil)
        (bare-ivs nil)
        (keyword-package (find-package 'keyword)))
    (dolist (option options)
      (let ((option-name (if (listp option) (car option) option))
            (option-value (if (listp option) (cdr option) nil)))
        (flet ((spec-or-all-ivs (spec)
                 (or spec
                     (mapcar #'(lambda (iv) (if (listp iv) (car iv) iv)) ivs))))
          (case option-name
            (:writable-instance-variables
              (setq writer-slots (spec-or-all-ivs option-value))
              (setq reader-slots (nunion reader-slots (spec-or-all-ivs option-value))))
            (:readable-instance-variables
              (setq reader-slots (nunion reader-slots (spec-or-all-ivs option-value))))
            (:initable-instance-variables
             (setq init-slots (spec-or-all-ivs option-value)))
            (t (error "Can't handle defflavor option ~A" option-name))))))
    (setq reader-slots (set-difference reader-slots writer-slots))
    (flet ((process-iv (iv-form)
             (let ((iv (if (listp iv-form) (car iv-form) iv-form)))
               (push iv bare-ivs)
               `(,iv
                 ,@(if (and (listp iv-form) (cdr iv-form))
                     `(:initform ,(cadr iv-form)))
                 ,@(if (member iv init-slots)
                     `(:initarg ,(intern (symbol-name iv) keyword-package)))
                 ,@(if (member iv reader-slots)
                     `(:reader ,(implode name "-" iv)))
                 ,@(if (member iv writer-slots)
                     `(:accessor ,(implode name "-" iv)))))))
      `(eval-when (:compile-toplevel :load-toplevel :execute)           ;We have to compile class to expand methods
         (defclass ,name ,components ,(mapcar #'process-iv ivs))))))

(defun implode (&rest components)
  (intern (apply #'concatenate 'string (mapcar #'string components))))

(defmacro defmethod ((function class &optional type) arglist &body body)
  (if (eq function 'make-instance)
      (setq function 'initialize-instance))
  (multiple-value-bind (decls body)
      (split-off-declarations body)
    `(cl:defmethod ,function ,@(if type (list type)) ((self ,class) ,@arglist)
       ,@decls
       ;; Like with-slots, but avoids an extra binding (and compiler warnings)
       (cl:symbol-macrolet ,(mapcar #'(lambda (s) `(,s (slot-value self ',s)))
                                 (slots-for-class class))
         ,@body))))

#-scl
(defun slots-for-class (class-name)
  (let ((class (find-class class-name)))
    (mapcar #'(lambda (sd)
                (c2mop:slot-definition-name sd))
            (c2mop:class-slots class))))

#+scl
(defun slots-for-class (class-name)
  (let ((class (find-class class-name)))
    (mapcar #'(lambda (sd)
                (clos:slot-definition-name sd))
            (clos:class-slots class))))

(defun split-off-declarations (body)
  (do ((rest body (cdr rest))
       (declarations nil))
      ((null rest)
       (values declarations nil))
    (if (or (stringp (car rest))
            (and (listp (car rest))
                 (eq 'declare (car (car rest)))))
        (push (car rest) declarations)
        (return-from split-off-declarations
          (values (nreverse declarations) rest)))))

(defun make-instance (class &rest init-plist)
  (apply #'cl:make-instance class init-plist))

(defmacro symbol-value-in-instance (instance symbol)
  `(slot-value ,instance ,symbol))

;; (defsetf symbol-value-in-instance pcl::set-slot-value)

(defmacro boundp-in-instance (instance symbol)
  `(slot-boundp ,instance ,symbol))

(defmacro compile-flavor-methods (&rest ignore)
  #+:mcl (declare (ignore ignore)))

(#-:mcl provide #+:mcl ccl:provide 'artificial-flavors)
(push :artificial-flavors *features*)
