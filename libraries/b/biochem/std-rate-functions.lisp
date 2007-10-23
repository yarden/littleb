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

;;; File: std-rate-functions
;;; Description:


;;; $Id: std-rate-functions.lisp,v 1.2 2007/10/23 17:25:55 amallavarapu Exp $

(in-package #I@FILE)

(include-declaration :use-packages mallavar-utility
                  :expose-symbols (mass-action custom-rate mass-action-constant-dimension))

(include (@>/math 
          @>/biochem 
          @>/util
          @>/biochem/ode
          @>/biochem/dimensionalization) :use)

;;;

  
(define-custom-rate mass-action (constant) 
    (rate-dimension
     dictionary
     entities
     stoichiometries
     dimensions)
  (let ((mass-action-term 1) ;; initialize the mass-action term and 
        (constant-dimension rate-dimension)) ;; expected dimension of the constant

    ;; calculate the mass-action term and the constant's expected dimension
    (loop for stoich in stoichiometries
          for entity in entities
          for dimension in dimensions
          do (setf mass-action-term {mass-action-term * entity ^ stoich}
                   constant-dimension {constant-dimension / dimension ^ stoich}))

    ;; check the constant's dimension
    (unless (eq (dimension-of constant) constant-dimension)
      (cond

       ;; if it's a number, we'll warn & fix it automatically:
       ((numberp constant) 
        (setf constant {constant * constant-dimension.unit})
        (b-warn "Numeric constant give for ~S.mass-action. Using dimensional constant: ~S."
                dictionary constant))

       ;; incorrect units provided: throw an error 
       (t (b-error "Invalid units used for ~S.mass-action.  Expecting ~S."
                   dictionary constant-dimension.unit))))
    
    (setf constant {dictionary.mass-action :#= (ensure-reference-var constant)})

    {constant * mass-action-term}))

(define-custom-rate custom-rate (expr &rest constants)
    (rate-dimension dictionary entities stoichiometries dimensions)
  "USAGE: X.(set-rate-function 'custom-rate {mathematical-expression} :const1-name const1 :const2-name const2) where X is an object which supports has a SET-RATE-FUNCTION field"
  (declare (ignorable stoichiometries entities dimensions rate-dimension))
  ;; stuff the constants in the dictionary
  (do () ((null constants))
    (let ((key (pop constants))
          (val (pop constants)))
    {dictionary.,key 
                :#=
                (ensure-reference-var val)}))
  expr.(map-substitution (lambda (o) 
                           (or dictionary.(_try-key o) o))))

(defun hill-function (stoichiometries entities dimensions rate-dimension dictionary 
                                      species &key (kd 1) (hill 1))
  ;; NEED TO WRITE DIMENSION CHECKING CODE
  (setf dictionary.kd (ensure-reference-var kd)
        dictionary.hill (ensure-reference-var hill))
  {species ^ :hill / {species ^ :hill + :kd ^ :hill}})
  


;;;; (defun std-rate-var-substitution-fn (rxn)
;;;;   "Given a reaction object, returns a function which returns the appropriate
;;;; substitution of a reaction-type, location-requirement, keyword or"
;;;;   (flet ((subst-obj (o)
;;;;            (funcall (std-rate-var-substitution-fn rxn) o)))
;;;;     (lambda (o)
;;;;       (typecase o 
;;;;         (species-type        (cdr (assoc o rxn.reactants 
;;;;                                          :key ?.species-type)).conc)
;;;;         (localization        (cdr (assoc o rxn.reactants :key ?.location-requirement.lo)).conc)
;;;;         (function             (funcall o rxn))
;;;;         (t                    o)))))

;;;; (defun custom-rate-var-substitution-fn (rxn)
;;;;   (let ((std-fn (std-rate-var-substitution-fn rxn)))
;;;;     (lambda (o)
;;;;       (funcall std-fn 
;;;;                (if (keywordp o) rxn.type.k.,o o)))))
;;;; (define-generic custom-rate (rtype args)
;;;;   (:method ((rtype reaction-type) &optional args)
;;;;    (destructuring-bind (math-expr &rest consts) args
;;;;      {rtype.rate-fn := (calculate-custom-rate-function math-expr)}
;;;;      (map-plist (lambda (const-name val)
;;;;                   {rtype.k.,const-name :#= (ensure-reference-var val)})
;;;;                 consts))))

;;;; (defun calculate-custom-rate-function (math-expr)
;;;;   (lambda (rxn) 
;;;;     (lambda () 
;;;;       (handler-case math-expr.(map (custom-rate-var-substitution-fn rxn))
;;;;         (dimension-combination-error (dim-err)
;;;;                                      (setf (b-error-cause dim-err)
;;;;                                            (format nil "Computing custom rate of ~S."
;;;;                                                    rxn))
;;;;                                      (error dim-err))))))
;;;; ;;;;  
;;;; ;;;;     


;;;; (defun has-let-method-p (e)
;;;;   (or (polynomial-p e)
;;;;       (rational-polynomial-p e)))

;;;; (defun custom-rate (exp)
;;;;   "Given an expression-concept EXP, returns a function which takes R, a reaction, as an argument, and returns EXP-SUB, an expression where the reaction-terms have been substituted for the concentrations of the reactions described by those reaction terms.  E.g., (custom-rate {RTK.part.i.(at :inner-surface) * Rate-X}) will return (LAMBDA (R)...), which when applied to a specific reaction will substitute the concentration of the species RTK  which has PART.I in the inner surface into this expression."
;;;;   (cond
;;;;    ((has-let-method-p exp)
;;;;     (lambda (rxn)
;;;;       (flet ((create-let-binding (type-species) ; creates a binary list 
;;;;                (list (first type-species) 
;;;;                      (second type-species).amount)))
;;;;         exp.(let (mapcan #'create-let-binding
;;;;                           (append rxn.lhs rxn.rhs))))))
;;;;    (t exp)))



;;;; (defun replace-species-type-with-conc (rxn)
;;;;   (lambda (rtype)
;;;;     (find rtype rxn

;;;; (defun exponentiate-var-to-num (a1 a2)
;;;;   (cond ((and (numberp a1) (var-p a2)) {a2 ^ a1})
;;;;         ((and (numberp a2) (var-p a1)) {a1 ^ a2})
;;;;         (t (error "Expecting VARIABLE * NUMBER, but received ~S * ~S" a1 a2))))

;;;; (defun mass-action-rate-calculator (rxn)
;;;;   (let ((rtype rxn.type))
;;;;     {rtype.k.mass-action 
;;;;      * rtype.lhs.(map (replace-species-type-with-conc-fn rxn) '+ '* '* 'exponentiate-var-to-num)}))

;;;; (defun mass-action-term-dimension (rtype-lhs &optional rtype-loc-class)
;;;;   (values
;;;;    (reduce (lambda (term1 term2) 
;;;;              (let* ((var    (car term2))
;;;;                     (st-lc  (cond
;;;;                              ((location-requirement-p var) var.type.location-class)
;;;;                              (t                            
;;;;                               (unless (or (null rtype-loc-class)
;;;;                                           (eql rtype-loc-class var.location-class))
;;;;                                 (error "Invalid location ~S" var.location-class))
;;;;                               (setf rtype-loc-class var.location-class))))
;;;;                     (stoich (cdr term2)))
;;;;                {term1 * *molecular-amount-dimension* / (location-class-dimension st-lc) ^ stoich}))
;;;;            (list* nil rtype-lhs.map-terms))
;;;;    rtype-loc-class))

;;;; (defun mass-action-constant-dimension (rtype-lhs &optional rtype-loc-class)
;;;;   (let+ (((matd rtype-loc-class) (mass-action-term-dimension rtype-lhs rtype-loc-class)))         
;;;;     {*molecular-amount-dimension* 
;;;;      / *time-dimension* 
;;;;      / (location-class-dimension rtype-loc-class) 
;;;;      / matd}))

