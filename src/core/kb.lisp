;;;; This file is part of little b.

;;;; The MIT License

;;;; Copyright (c) 2007 Aneil Mallavarapu

;;;; Permission is hereby granted, free of charge, to any person obtaining a copy
;;;; of this software and associated documentation files (the "Software"), to deal
;;;; in the Software without restriction, including without limitation the rights
;;;; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;;;; copies of the Software, and to permit persons to whom the Software is
;;;; furnished to do so, subject to the following conditions:

;;;; The above copyright notice and this permission notice shall be included in
;;;; all copies or substantial portions of the Software.

;;;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;;;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;;;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;;;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;;;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;;;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
;;;; THE SOFTWARE.

;;; File: kb
;;; Description: Mostly internal functions for dealing with the knowledge base

;;; $Id: kb.lisp,v 1.4 2007/12/12 15:06:07 amallavarapu Exp $
;;; $Name:  $

(in-package b)

(eval-when (:compile-toplevel :load-toplevel :execute)

(defun kb-find-object (hashkey)
  (gethash hashkey +OBJECTS+))

(defun kb-add-object (hashkey object)
  (let ((class (class-of object)))
    (cond
     ((kb-class-matchable-p class)        
      (assert (not (kb-find-object hashkey)) ()
        "BUG: Attempt to add duplicate object ~S" object)    
      (push (cons :add object) *kb-command-queue*)) ; either add the object now
     (t (push (cons :trace-new object) *kb-command-queue*)
        (push object (kb-class-unmatched-instances class))
        )) ; or save this instance for later
    (setf (gethash hashkey +objects+) object
          (kb-object-hashkey object) hashkey)
    object))

(Defun kb-unwind-object (hashkey object)
  (remhash hashkey +objects+)
  (setf *kb-command-queue* (delete object *kb-command-queue* :key #'cdr)))

(defun kb-request-run ()
  (unless *kb-command-queue*
    (push (cons :request-run nil) *kb-command-queue*)))

(defun kb-register-matchable-class (class)
  (unless (kb-class-matchable-p class)
    (mapc #'kb-register-matchable-class (portable:class-direct-subclasses class))
    (push (cons :add-class class) *kb-command-queue*)
    (setf (slot-value class 'matchable-p) t)))

(defun kb-update-object (object)
  (when (kb-class-matchable-p (class-of object))
    (push (cons :update object) *kb-command-queue*)
    (add-object-trace :update object))
  object)

(defun kb-run ()
  (let ((transaction ()))
    (loop while *kb-command-queue*
          do (setf transaction (nreverse *kb-command-queue*)
                   *kb-command-queue* nil)
          when transaction
          sum (loop for cmd = (pop transaction)
                    do (kb-do-command cmd)
                    sum (lisa:run)
                    while transaction))))

(defun kb-do-command (cmd)
  (let ((action (car cmd))
        (object (cdr cmd)))
    (ecase action
      (:update      (lisa:mark-instance-as-changed object))
      (:add         (kb-do-add-command object))
      (:add-class   (kb-add-unmatched-instances object))
      (:trace-new   (kb-do-trace-object-command object))
      (:request-run ()))))

(defun kb-do-add-command (object)
  (lisa:assert-instance object)
  (add-object-trace :new object)
  object)


(defun kb-do-trace-object-command (object)
  (add-object-trace :new object)
  object)

(defun kb-add-unmatched-instances (class)
  (loop for object = (pop (kb-class-unmatched-instances class))
        while object
        do (lisa:assert-instance object)))

;;;; (defun add-object-undo-info (fact)
;;;;   (add-undo (lambda () (kb-retract (lisa::find-instance-of-fact fact)))))

;;; CCLASS-CREATE-FROM-HASHKEY - added to support reify-concept
(defun cclass-create-from-hashkey (hashkey)
  (let ((cclass   (first hashkey))
        (id-vals  (rest hashkey)))
    (cclass-create-instance
     cclass
     (loop for id-fld in (cclass-id-field-order cclass)
           for val    in id-vals
           nconc (list id-fld val)))))

(defun kb-reset ()
  (maphash (lambda (k v)
             (declare (ignorable k))
             (when (conceptp v)
               (setf (kb-object-hashkey v) nil)))
           +OBJECTS+)
  (clrhash +OBJECTS+)
  (setf *kb-command-queue* nil)
  (lisa:clear)
  (lisa:reset)
  t)

(defun kb-retract (o)
  (let* ((hashkey (concept-hashkey o)))
    (cond ((gethash hashkey +OBJECTS+)  
           (setf (gethash hashkey +OBJECTS+) nil)
           (lisa:retract-instance o)
           (add-object-trace :delete o)
           t)
          (t nil))))

                
(defun kb-finalize-property (prop)
  (let ((*relevance* t))
    (setf (fld (property-object prop) (pclass-field-symbol (class-of prop)))
          (property-value prop))))

)



