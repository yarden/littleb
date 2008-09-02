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

;;; File: 
;;; Description:  

;;; $Id: unit-systems.lisp,v 1.2 2008/09/02 14:58:10 amallavarapu Exp $
;;;

(in-package #I@FILE)

(include @LIBRARY/math :use)

;; unit systems
(define systeme-internationale [unit-system])

(define si-units systeme-internationale)

(define b-units [unit-system])

(define imperial-units [unit-system])
