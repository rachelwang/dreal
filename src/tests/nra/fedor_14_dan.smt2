(set-logic QF_NRA)
(declare-fun x0 () Real)
(declare-fun y0 () Real)
(declare-fun x1 () Real)
(declare-fun y1 () Real)
(declare-fun x2 () Real)
(declare-fun y2 () Real)
(declare-fun x3 () Real)
(declare-fun y3 () Real)
(assert (<= x0 7.5))
(assert (<= y0 7.5))
(assert (<= x1 7.5))
(assert (<= y1 7.5))
(assert (<= x2 7.5))
(assert (<= y2 7.5))
(assert (<= x3 7.5))
(assert (<= y3 7.5))

(assert (<= 2.5 x0))
(assert (<= 2.5 y0))
(assert (<= 2.5 x1))
(assert (<= 2.5 y1))
(assert (<= 2.5 x2))
(assert (<= 2.5 y2))
(assert (<= 2.5 x3))
(assert (<= 2.5 y3))

(assert (and
(or (<= 5.0 (- x0 x1)) (<= 5.0 (- x1 x0)) (<= 5.0 (- y0 y1)) (<= 5.0 (- y1 y0)))
(or (<= 5.0 (- x0 x2)) (<= 5.0 (- x2 x0)) (<= 5.0 (- y0 y2)) (<= 5.0 (- y2 y0)))
(or (<= 5.0 (- x0 x3)) (<= 5.0 (- x3 x0)) (<= 5.0 (- y0 y3)) (<= 5.0 (- y3 y0)))
(or (<= 5.0 (- x1 x2)) (<= 5.0 (- x2 x1)) (<= 5.0 (- y1 y2)) (<= 5.0 (- y2 y1)))
(or (<= 5.0 (- x1 x3)) (<= 5.0 (- x3 x1)) (<= 5.0 (- y1 y3)) (<= 5.0 (- y3 y1)))
(or (<= 5.0 (- x2 x3)) (<= 5.0 (- x3 x2)) (<= 5.0 (- y2 y3)) (<= 5.0 (- y3 y2)))
))
(check-sat)
(exit)
