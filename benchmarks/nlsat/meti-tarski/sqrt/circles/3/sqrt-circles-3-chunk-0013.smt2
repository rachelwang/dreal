(set-logic QF_NRA)

(declare-fun skoA () Real)
(declare-fun skoD () Real)
(declare-fun skoY () Real)
(declare-fun skoX () Real)
(assert (and (not (<= (* skoY (+ (+ (* skoA (- 1.)) (* skoD (- 1.))) (* skoY (/ 1. 2.)))) (+ (+ (+ (/ (- 1.) 2.) (* skoA (+ 1. (* skoA (/ (- 1.) 2.))))) (* skoD (+ (+ 1. (* skoA (- 1.))) (* skoD (/ (- 1.) 2.))))) (* skoX (* skoX (/ (- 1.) 2.)))))) (and (<= (* skoY (+ (* skoA (- 2.)) skoY)) (* skoX (* skoX (- 1.)))) (and (<= 0. skoD) (<= 0. skoA)))))
(set-info :status sat)
(check-sat)