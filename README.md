# LDS Inferences

## Citation

> TODO: cite Yash's paper

## Installation

In Julia, open up the `Pkg` manager by typing `]`

Then type `activate .`

## Usage

The first step is to create a `WindSolarData` object.

The second step is to call `fit` on that object.

## A word on notation

[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)

We generally follow the notation of Amonkar et al, though with some modifications which we think improve clarity.

* scalar constants are given capital letters: `N = 10`, `M = 3`, etc
* indices are lowercase: `[f(n) for n in 1:N]`
* single-letter matrices (that follow the notation of Amonkar et al) are given uppercase bold letters: `𝐗 = [1 2; 3 4]`, etc (type `\bfX` + `Tab`)
* everything else follows the Blue code style recommendations (click on the badge above). Generally this means striving towards self-documenting variable names

## TODO

1. Figure out how to add more lags
2. Add day of year screen on input data to restrict the window
