;;; -*- mode: common-lisp;   common-lisp-style: modern;    coding: utf-8; -*-
;;;;
;;;; This interface is adapted from Gabor Mellis' Latent-Semantic-Indexing
;;;; project and all credit is entirely due to him, any blame to me...
;;;;
;;;; A `mapper' is a function that takes a function as its first
;;;; argument and applies it in some way to the elements of its
;;;; remaining arguments. These arguments are what the mapper is said
;;;; to `map from' or simply `map'. A mapper that only takes an
;;;; function argument is called a `lister'. The parameters the
;;;; function is called with is what the mapper is said to `map to'.

(in-package :templeton)
(in-suite test)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; General mappers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun null-mapper (&rest args)
  (declare (ignore args)))

(defun compose-mappers (&rest mappers)
  "Return a mapper that maps from the same set as the first of MAPPERS
maps from and maps to what the last of MAPPERS maps to, composing them
in a chain. If MAPPERS is NIL #'FUNCALL, the identity mapper, is
returned."
  (flet ((compose2 (mapper1 mapper2)
           (lambda (fn &rest args)
             (apply mapper1 (lambda (&rest args)
                              (apply mapper2 fn args))
                    args))))
    (cond ((endp mappers) #'funcall)
          ((endp (rest mappers)) (first mappers))
          (t (compose2 (first mappers)
                       (apply #'compose-mappers (rest mappers)))))))

(defun concatente-mappers (&rest mappers)
  "Return a mapper that is the concatention of MAPPERS."
  (lambda (function &rest args)
    (dolist (mapper mappers)
      (apply mapper function args))))

(defun curry-mapper (mapper &rest curried-args)
  "What makes a mapper is that the first is a function that is somehow
applied to arguments. Currying a mapper leaves the function parameter
alone and curries the rest of the parameters."
  (lambda (function &rest args)
    (apply mapper function (append curried-args args))))

(defun make-mapper (&rest sequences)
  "Return a mapper that maps from SEQUENCES to elements of SEQUENCES."
  (lambda (function)
    (apply #'map nil function sequences)))


(defun encode-mapper (mapper encoder &key allocate-new-index-p)
  "Translate MAPPER by encoding its sole argument with ENCODER."
  (compose-mappers mapper
   (lambda (fn x)
     (let ((index (->index encoder x :allocate-new-index-p allocate-new-index-p)))
       (when index (funcall fn index))))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; specialied mappers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(defgeneric map-lines (function object)
  (:method (function (stream stream))
    (loop for line = (read-line stream nil nil)
          while line
          do (funcall function line)))
  (:method (function (pathname pathname))
    (with-open-file (stream pathname)
      (map-lines stream function)))
  (:method (function (string string))
    (with-input-from-string (stream string)
      (map-lines stream function))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; test
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(def test  test-compose-mappers.0 ()
  (funcall (make-mapper '(0 1 2 3 4 5)) #'print)
  (funcall (compose-mappers (make-mapper '(0 1 2 3 4 5))) #'print)
  (funcall (compose-mappers (make-mapper '(0 1 2 3 4 5)) #'funcall) #'print))
