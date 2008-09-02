;;;; This file is part of little b.

;;;; Copyright (c) 2005-8 Aneil Mallavarapu

;;;; Little b is free software: you can redistribute it and/or modify
;;;; it under the terms of the GNU General Public License as published by
;;;; the Free Software Foundation, either version 3 of the License, or
;;;; (at your option) any later version.

;;;; Little b is distributed in the hope that it will be useful,
;;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;;; GNU General Public License for more details.

;;;; You should have received a copy of the GNU General Public License
;;;; along with little b.  If not, see <http://www.gnu.org/licenses/>.

;;; File: field-functions
;;; Description: implements functions and methods as fields

;;; $Id: field-function.lisp,v 1.2 2008/09/02 14:58:10 amallavarapu Exp $
;;; $Name:  $
(in-package b)

(eval-when (:compile-toplevel :load-toplevel :execute)

#+Lispworks
(setf lispworks:*handle-warn-on-redefinition* nil)

#+Lispworks 
(define-field-form-parser defun)
#+Lispworks
(define-field-form-parser defmethod)

;; DEF-FLD-FUN - macro
(defmacro def-fld-fun (name (&rest args) &body body)
  "Where args is an ordinary lambda list with at least 1 argument, which 
represents the object on which the call is made."
  (error "USE OF (DEFUN fld-form ...) IS NOT PERMITTED.  USE DEFMETHOD INSTEAD.")
  `(eval-when (:compile-toplevel :load-toplevel :Execute)
     (portable:dspec (cl:defun ,(fld-form-to-symbol name))
       (define-field-function cl:defun ,name nil ,args ,body))))

(defun fld-form-fn-name-to-symbol (fem)
  (cond
   ((fld-form-setf-name-p fem)
    (sym '|(SETF | (fld-form-to-symbol (second fem)) '|)|))
   ((math-setf-form-p fem)
    (fld-form-fn-name-to-symbol `(setf ,(math-setf-form-place fem))))
   (t    (fld-form-to-symbol fem))))

(defmacro def-fld-method (name &body body)
;   (let* ((offset     (position-if #'listp body))
;          (qualifiers (subseq body 0 offset))
;          (args       (nth offset body))
;          (body       (subseq body  (+ 1 offset))))
  (destructure-method-body (quals args declares code) body
    `(eval-when (:compile-toplevel :load-toplevel :Execute)
       (portable:dspec (defmethod ,(fld-form-fn-name-to-symbol name))
         (define-field-function cl:defmethod ,name ,quals ,args ,declares ,code)))))

(defun count-declares (lst)
  (flet ((declare-form-p (o)
           (and (consp o)
                (eq (first o) 'declare))))
    (if lst (position-if-not #'declare-form-p lst))))

;(defconstant *function-lambda-list-keywords* '(&key &optional &allow-other-keys &body &rest &aux))

(defun lambda-list-keyword-p (o)
  (member o lambda-list-keywords))

(deftype lambda-list-keyword ()
  `(satisfies lambda-list-keyword-p))

(defun ?field-p (o) (eq o :?field))

(defun parse-field-function-name (name qualifiers args)
  (cond
   ((fld-form-setf-name-p name)
    (let ((value (first args)))
      (b-assert (not (char= (char (symbol-name value) 0) #\&)) ()
          "Invalid SETF argument list ~S" args)
      (values (second name) 
              (first args)                           
              nil
              `(,value object ,@(rest args)))))
   
   ((math-setf-form-p name)     
    (values (math-setf-form-place name)
            (math-setf-form-value name)
            nil
            `(,(math-setf-form-value name)
              object ,@args)))
   (t       
    (values name
            nil
            (find :matchable qualifiers)
            `(object ,@args)))))

(defmacro define-field-function (defform name qualifiers args doc/decl body)
  (labels ((declare-ignorable (a)
             (typecase a
               (cons                 `(declare (ignorable ,(first a))))
               (lambda-list-keyword  nil)
               (symbol               `(declare (ignorable ,a)))))
           (declare-ignorables ()
             (remove-if #'null (mapcar #'declare-ignorable args))))  
    (let+ (((fe setf-value matchable o-args)
                          (parse-field-function-name name qualifiers args))
           (fn-symbol     (fld-form-fn-name-to-symbol name))
           (obj           (fld-form-object fe))
           (fld           (fld-form-field fe))
           (code-start    (if (and (stringp (first body))
                                   (> (length body) 1))
                              (1+ (count-declares (rest body)))
                            (count-declares body)))
           (qualifiers    (remove :matchable qualifiers))
           (doc/decl      (append doc/decl
                                  (declare-ignorables)
                                  (if (?field-p fld) '((declare (special ?field))))))
           (code-body     (subseq body code-start))
           (cclass        (global-value obj))
           (accessor-name (field-accessor-fn-name obj fld))
           (reader        (unless setf-value `',accessor-name))
           (writer        (if setf-value `#'(setf ,accessor-name))))
      (assert (global-const-fld-form-p fe) ()
        "Expecting a global constant field expression, but received ~A" (print-b-expr fe))
      `(portable:dspec (,defform ,fn-symbol)
         (,defform ,(if setf-value `(setf ,accessor-name) accessor-name)
                   ,@qualifiers ,o-args
                   ,@doc/decl
                   (with-fields object
                     ,@code-body))
         (cclass-add-function ,cclass ',fld ,reader ,writer ',args nil ,matchable)
         ',fn-symbol))))

;;;; (defmacro define-field-function (defform name qualifiers args body)
;;;;   (labels ((declare-ignorable (a)
;;;;              (typecase a
;;;;                (cons                 `(declare (ignorable ,(first a))))
;;;;                (lambda-list-keyword  nil)
;;;;                (symbol               `(declare (ignorable ,a)))))
;;;;            (declare-ignorables ()
;;;;              (remove-if #'null (mapcar #'declare-ignorable args))))  
;;;;     (let* ((setf?         (fld-form-setf-name-p name))
;;;;            (fe            (if setf? (second name) name))
;;;;            (fn-symbol     (fld-form-fn-name-to-symbol name))
;;;;            (obj           (fld-form-object fe))
;;;;            (fld           (fld-form-field fe))
;;;;            (o-args        (if setf? (cons 'value `(object ,@args))
;;;;                             `(object ,@args)))
;;;;            (code-start    (if (and (stringp (first body))
;;;;                                    (> (length body) 1))
;;;;                               (1+ (count-declares (rest body)))
;;;;                             (count-declares body)))
;;;;            (matchable     (if (and (not setf?) (find :matchable qualifiers)) t))
;;;;            (qualifiers    (remove :matchable qualifiers))
;;;;            (doc/decl      (append (subseq body 0 code-start)
;;;;                                   (declare-ignorables)))
;;;;            (code-body     (subseq body code-start))
;;;;            (code-body     (if setf? (append code-body (list 'value)) code-body))
;;;;            (declarations  (if (?field-p fld) '((declare (special ?field)))))
;;;;            (cclass        (global-value obj))
;;;;            (accessor-name (field-accessor-fn-name obj fld))
;;;;            (reader        (unless setf? `',accessor-name))
;;;;            (writer        (if setf? `#'(setf ,accessor-name))))
;;;;       (assert (global-const-fld-form-p fe) ()
;;;;         "Expecting a global constant field expression, but received ~A" (print-b-expr fe))
;;;;       `(portable:dspec (,defform ,fn-symbol)
;;;;          (,defform ,(if setf? `(setf ,accessor-name) accessor-name)
;;;;                    ,@qualifiers ,o-args
;;;;                    ,@declarations
;;;;                    (with-fields object
;;;;                      ,@code-body))
;;;;          (cclass-add-function ,cclass ',fld ,reader ,writer ',args nil ,matchable)
;;;;          ',fn-symbol))))
;;;; 
)
