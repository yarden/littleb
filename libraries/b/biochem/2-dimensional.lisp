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

(in-package #I@FILE)

(include (@</dimensionalization/2d ; first load the dimensionalization
          @>/biochem)           ; now load the biochem package
         :expose)

(include-documentation :description "Including this file causes the biochem system to expect quantities of a flat \"2 dimensional ~
                                     world\".  For example, compartment sizes are areas, membrane sizes are distances, ~
                                     and moles are used to represent amounts of species.")

