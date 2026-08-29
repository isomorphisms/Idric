module Bad

import Contraction

badContraction : Integer
badContraction =
  contract
    (planeCovector 1 2)
    (threeVector 1 2 3)
