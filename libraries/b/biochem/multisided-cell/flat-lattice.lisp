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


(in-package #I@FILE) 

(include @LIBRARY/biochem/dimensionalization :use)
(include @LIBRARY/biochem/multisided-cell :expose)

(check-assumption-exists :biochem-dimensionalization)

(defcon flat-lattice () 
  (&optional (ID := *name*) 
             &property
             (cells := (make-hash-table :test 'equalp))
             (appositions := (make-hash-table :test 'equalp))))
 
(defield flat-lattice.define-apposition 
  (cell-1 cell-1-memb cell-2 cell-2-memb
          &optional
          (size (quantity 1 
                          (location-class-dimension membrane)))
          (ic-size (quantity 1 (location-class-dimension compartment))))
  "Input: is the cells and membranes to be apposed, given as numbers."
  (let* ((m1    (.cell cell-1).membranes.,cell-1-memb)
         (m2    (.cell cell-2).membranes.,cell-2-memb))
    (appose-cell object cell-1 m1 cell-2 m2 size ic-size)))

(defield flat-lattice.define-appositions (apposition-definitions)
  (loop for apposition-definition in apposition-definitions
        do (.apply :define-apposition apposition-definition)))

(defield flat-lattice.define-cells (cell-areas side-lengths) 
  (loop for i from 1 to (length cell-areas)
        for carea = (nth (+ i -1) cell-areas)
        for slength = (nth (+ i -1) side-lengths)
        do (create-cell object                         
                        carea
                        slength i)))

(defield flat-lattice.cell (&rest name)
  (gethash name .cells))

(defield flat-lattice.apposition (cellnum1 cellnum2)
  .appositions.,(list cellnum1 cellnum2))

(defield flat-lattice.do-cells (fn)
  (loop for cell being the hash-values of .cells
        collect (funcall fn cell)))

(defield flat-lattice.do-appositions (fn)
  (loop for app being the hash-values of .appositions
        collect (funcall fn app)))

;;;
;;; HELPER FUNCTIONS:
;;;
(defun appose-cell (lattice cell1num membrane-1 cell2num membrane-2 side-length ic-size)
  "Creates a membrane apposition, named according to which 2 cells are being apposed"
  (let ((ma (_appose-single-cell lattice cell1num membrane-1 cell2num membrane-2)))
    (_appose-single-cell lattice cell2num membrane-2 cell1num membrane-1)
    (with-fields ma
      {.size.value := side-length}
      {membrane-1.size.value := side-length}
      {membrane-1.inverse.size.value := side-length}
      {membrane-2.size.value := side-length}
      {membrane-2.inverse.size.value := side-length}
      {.ic.size.value := ic-size})
    ma))

(defun _appose-single-cell (lattice cell1num membrane-1 cell2num membrane-2)  
  {lattice.(apposition cell1num cell2num) :#
           {lattice.appositions.,(list cell1num
                                       cell2num) := 
                                [membrane-apposition membrane-1 membrane-2]}})

    
(defun create-cell (lattice carea length-list n)
  (loop with cell = (make-cell lattice carea n)
        with last-membrane =  (length length-list)
        for i from 1 to last-membrane
        do cell.(add-membrane i length-list.[i.1-])
        ;; make the membrane interfaces
        finally (loop for i from 1 to last-membrane
                      for adj-membrane  = (if i.(= 1) last-membrane i.1-)
                      do cell.(define-membrane-interface adj-membrane i))
                      finally (return cell)))

(defun make-cell (lattice ar num) 
  (let ((cell   {lattice.(cell num) :#
                         {(gethash (list num) lattice.cells) := [multisided-cell]}}))
    {cell.inner.size.value := ar  }
    {cell.size.value := ar}
     
    cell))








