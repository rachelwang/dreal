(set-logic QF_NRA)

(declare-fun skoS () Real)
(declare-fun skoC () Real)
(declare-fun skoCB () Real)
(declare-fun skoSB () Real)
(declare-fun skoX () Real)
(assert (and (<= (+ (/ 760000. 7383.) (* skoC (/ (- 3400.) 7383.))) skoS) (and (= (* skoSB skoSB) (+ 1. (* skoCB (* skoCB (- 1.))))) (and (= (* skoS skoS) (+ 1. (* skoC (* skoC (- 1.))))) (and (<= skoX (/ 1. 10000000.)) (<= 0. skoX))))))
(set-info :status unsat)
(check-sat)