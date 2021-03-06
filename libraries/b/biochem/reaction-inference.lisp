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


;;; File: reaction-inference.lisp
;;; Description:  when included, this rule infers which species and reactions
;;;               are implied by an initial set of species and reactions.

;;; $Id: reaction-inference.lisp,v 1.10 2008/09/06 00:23:08 amallavarapu Exp $

(in-package #I@FILE)

(include @>/biochem :use)

(defprop reaction.substitution-table
    (:= (make-hash-table)
      :documentation "A hashtable mapping higher-level objects (e.g., species-types) to species"))



(defcon reaction-type-requirement-location ()
  (requirement location))

 
(defrule empty-reaction-type-requirement-satisfied
  (:and (?rt-req [reaction-type-requirement 
                  ?rxn-type :lhs nil nil nil])
        (?loc [location])
        (:test (subtypep   (class-of ?loc)  ; the reaction can occur in ?rxn-loc
                           ?rxn-type.location-class)))
  =>
  [reaction ?rxn-type ?loc])

(defrule reaction-type-requirement-satisfied
   (:and (?species   [species ?species-type ?species-loc])    ; and the species in question exists in the right location,        
    [has-sublocation ?rxn-loc ?localization ?species-loc] ; given relationship between a location and sublocation
    (?rt-req    [reaction-type-requirement               
                 ?rxn-type :lhs                     
                 ?species-type ?localization ?stoich])
    (:test (subtypep   (class-of ?rxn-loc)                      ; the reaction can occur in ?rxn-loc
                       ?rxn-type.location-class)))
  =>  ;; one of the reaction-type requirements has been satisfied
  (with-b-error-context ("While creating ~S.(in ~S)" ?rxn-type ?rxn-loc)
    ;; record that ?species satisfies the localization requirement ?loc-req
    {?rxn-type.(lhs-species ?rxn-loc ?rt-req) := ?species}
    (when ?rxn-type.(satisfied-at ?rxn-loc)
      (infer-reaction ?rxn-type ?rxn-loc))))

(defun infer-reaction (rtype loc)
  "creates a reaction and adds substitions to the substition table"
  (let* ((r      [reaction rtype loc])
         (table  (|REACTION.SUBSTITUTION-TABLE| r))
         (rtr-species  rtype.reactants.[loc])) ;  a list of conses like (reaction-type-requirement . species)
    (dolist (s rtr-species)
      (let* ((rtr       (car s))
             (species   (cdr s))
             (stype     rtr.species-type)
             (subloc    rtr.sublocation)
             (specifier (if subloc {stype @ subloc} stype)))
      (setf (gethash specifier table) species))
    r)))


;;;; THIS CODE GENERATES RULES DYNAMICALLY - an alternative approach that is
;;;; conceptually quite nice: reaction-types are convereted into littleb/lisa 
;;;; pattern-matching rules.  The problem is it's horribly slow.

;;;; (defrule reaction-inference-generator
;;;;   (?rtype reaction-type)
;;;;   =>
;;;;   (multiple-value-bind (patterns substitution-list)
;;;;       (generate-reaction-inference-rule ?rtype '?loc)
;;;;     (add-rule patterns
;;;;               `(infer-reaction ,?rtype ?loc ,substitution-list)
;;;;               (intern (format nil "~A" ?rtype)))))

;;;; (defun infer-reaction (rtype loc substs)
;;;;   "creates a reaction and adds substitions to the substition table"
;;;;   (let* ((r [reaction rtype loc])
;;;;          (table (|REACTION.SUBSTITUTION-TABLE| r)))
;;;;     (dolist (s substs)
;;;;       (setf (gethash (car s) table) (cdr s)))
;;;;     r))

;;;; (defun generate-reaction-inference-rule (rtype mainlocvar)
;;;;   "Returns a pattern suitable for defrule, and a form which computes the list of substitutions (of entities to species"
;;;;   (let ((location-patterns `((nil ,mainlocvar (,mainlocvar [,(class-name rtype.location-class)]))))
;;;;         (subloc-counter    0))
;;;;     (flet ((get-location-var (subloc)
;;;;              (let ((existing (assoc subloc location-patterns)))
;;;;                (if existing (second existing)
;;;;                  (let* ((sublocvar (intern (format nil "?SUBLOC~A" (incf subloc-counter)))))
;;;;                    (push `(,subloc ,sublocvar [has-sublocation ,mainlocvar ,subloc ,sublocvar])
;;;;                          location-patterns)
;;;;                    sublocvar)))))   
;;;;       
;;;;       (loop for req in rtype.lhs-requirements
;;;;             for i = 1 then (1+ i)
;;;;             for species-var = (intern (format nil "?SPECIES~A" i))
;;;;             for stype = req.species-type
;;;;             for location-var = (get-location-var req.sublocation)
;;;;             collect `(,species-var [species ,stype ,location-var]) into species-patterns
;;;;             collect `(cons ,req.(localization t) ,species-var) into substitutions
;;;;             finally (return 
;;;;                      (values (list* :and
;;;;                                     (nconc (nreverse (mapcar #'third location-patterns))
;;;;                                            species-patterns))
;;;;                              
;;;;                              `(list ,@substitutions)))))))
;;;;             
;;;;         
