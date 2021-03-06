;;;; This file is part of little b.

;;;; The MIT License

;;;; Copyright (c) 2003-2008 Aneil Mallavarapu

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


;;; $Id: std-rate-functions.lisp,v 1.9 2008/09/06 00:23:08 amallavarapu Exp $

(in-package #I@FILE)

(include-declaration :use-packages mallavar-utility
                  :expose-symbols (mass-action custom-rate mass-action-constant-dimension))

(include (@>/math 
          @>/biochem 
          @>/util
          @>/biochem/ode
          @>/biochem/dimensionalization) :use)

(define-custom-rate mass-action (constant) 
    (:rate-dimension rate-dimension
     :entities entities
     :stoichiometries stoichiometries
     :dimensions dimensions)
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
    
    (store-parameter :mass-action constant)

    {:mass-action * mass-action-term}))

(define-custom-rate custom-rate (expr &rest constants) ()
  "USAGE: X.(set-rate-function 'custom-rate {mathematical-expression} :const1-name const1 :const2-name const2) where X is an object which supports has a SET-RATE-FUNCTION field"
  ;; stuff the constants in the dictionary
  (do () ((null constants))
    (let ((key (pop constants))
          (val (pop constants)))
      (store-parameter key val)))
  expr)

(define-custom-rate hill (species &key (kd 1) (hill 1)) ()
  ;; NEED TO WRITE DIMENSION CHECKING CODE
  (store-parameter :kd kd)
  (store-parameter :hill hill)
  {species ^ :hill / {species ^ :hill + :kd ^ :hill}})
  


