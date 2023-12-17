# LDS Inferences

This is an **IN PROGRESS** implementation of the K nearest neighbors Space-Time Simulator (KSTS) method described in

> Amonkar, Y., Farnham, D. J., & Lall, U. (2022). A k-nearest neighbor space-time simulator with applications to large-scale wind and solar power modeling. Patterns, 3(3), 100454. https://doi.org/10.1016/j.patter.2022.100454

This repository is developed by [James Doss-Gollin](https://github.com/jdossgollin/) (design and implementation) and [Sophia Prieto](https://github.com/sophiaprieto) (some implementation and testing).
Thanks to [Yash Amonkar](https://github.com/yashamonkar) for sharing the R codes used in the original paper.

**THIS CODEBASE IS NOT BEING ACTIVELY DEVELOPED AND IS NOT READY FOR "OFF THE SHELF" USE.**
That being said, we achieved **significant** speedups (not to mention greatly increased user-friendliness) relative to the original R codes.
We think further improvements and features would be fairly straightforward to implement.
If you are interested in using this method, please reach out and we would be happy to collaborate with you to finish this package.

## Notation

[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)

We generally follow the notation of Amonkar et al, though with some modifications which we think improve clarity.

* scalar constants are given capital letters: `N = 10`, `M = 3`, etc
* indices are lowercase: `[f(n) for n in 1:N]`
* single-letter matrices (that follow the notation of Amonkar et al) are given uppercase bold letters: `𝐗 = [1 2; 3 4]`, etc (type `\bfX` + `Tab`)
* everything else follows the Blue code style recommendations (click on the badge above). Generally this means striving towards self-documenting variable names

We envision the package being used as follows: 

1. create a `WindSolarData` object
2. call `fit` on that object

## Ongoing

1. Figure out how to add more lags
2. Add day of year screen on input data to restrict the window
