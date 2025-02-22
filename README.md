# EnergyModelsGeography

[![DOI](https://joss.theoj.org/papers/10.21105/joss.06619/status.svg)](https://doi.org/10.21105/joss.06619)
[![Build Status](https://github.com/EnergyModelsX/EnergyModelsGeography.jl/workflows/CI/badge.svg)](https://github.com/EnergyModelsX/EnergyModelsGeography.jl/actions?query=workflow%3ACI)
[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://energymodelsx.github.io/EnergyModelsGeography.jl//stable)
[![In Development](https://img.shields.io/badge/docs-dev-blue.svg)](https://energymodelsx.github.io/EnergyModelsGeography.jl/dev/)

`EnergyModelsGeography` is a package to add a geographic representation to [`EnergyModelsBase`](https://github.com/EnergyModelsX/EnergyModelsBase.jl).
`EnergyModelsGeography` follows the same philosophy as `EnergyModelsBase` so that it should be easy to create new transmission options or area descriptions.

## Usage

The usage of the package is best illustrated through the commented [`examples`](examples).
The current example shows how to add geographical information to an energy system model built using `EnergyModelsBase`.
It is extending the [network](https://github.com/EnergyModelsX/EnergyModelsBase.jl/blob/main/examples/network.jl) example of `EnergyModelsBase` to 7 areas.

## Cite

If you find `EnergyModelsGeography` useful in your work, we kindly request that you cite the following [publication](https://doi.org/10.21105/joss.06619):

```bibtex
@article{hellemo2024energymodelsx,
  title = {EnergyModelsX: Flexible Energy Systems Modelling with Multiple Dispatch},
  author = {Hellemo, Lars and B{\o}dal, Espen Flo and Holm, Sigmund Eggen and Pinel, Dimitri and Straus, Julian},
  journal = {Journal of Open Source Software},
  volume = {9},
  number = {97},
  pages = {6619},
  year = {2024},
  doi = {10.21105/joss.06619},
  url = {https://doi.org/10.21105/joss.06619},
}
```

For earlier work, see our [paper in Applied Energy](https://www.sciencedirect.com/science/article/pii/S0306261923018482):

```bibtex
@article{boedal_2024,
  title = {Hydrogen for harvesting the potential of offshore wind: A {N}orth {S}ea case study},
  journal = {Applied Energy},
  volume = {357},
  pages = {122484},
  year = {2024},
  issn = {0306-2619},
  doi = {10.1016/j.apenergy.2023.122484},
  url = {https://www.sciencedirect.com/science/article/pii/S0306261923018482},
  author = {Espen Flo B{\o}dal and Sigmund Eggen Holm and Avinash Subramanian and Goran Durakovic and Dimitri Pinel and Lars Hellemo and Miguel Mu{\~n}oz Ortiz and Brage Rugstad Knudsen and Julian Straus}
}
```

## Project Funding

The development of `EnergyModelsGeography` was funded by the Norwegian Research Council in the project [Clean Export](https://www.sintef.no/en/projects/2020/cleanexport/), project number [308811](https://prosjektbanken.forskningsradet.no/project/FORISS/308811)
