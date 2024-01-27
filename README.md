# EnergyModelsGeography

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://energymodelsx.github.io/EnergyModelsGeography.jl//stable)
[![In Development](https://img.shields.io/badge/docs-dev-blue.svg)](https://energymodelsx.github.io/EnergyModelsGeography.jl/dev/)

`EnergyModelsGeography` is a package to add a geographic representation to [`EnergyModelsBase`](https://github.com/EnergyModelsX/EnergyModelsBase.jl).
`EnergyModelsGeography` follows the same philosophy as `EnergyModelsBase` so that it should be easy to create new transmission options or area descriptions.

> **Note:**
>
> We migrated recently from an internal Git solution to GitHub, including the package [`EnergyModelsBase`](https://github.com/EnergyModelsX/EnergyModelsBase.jl).
> As `EnergyModelsBase` is not yet registered, it is not possible to run the tests without significant changes in the CI.\> Hence, we plan to wait with creating a release to be certain the tests are running.
> As a result, the stable docs are not yet available.
> This may impact as well some links.

## Usage

The usage of the package is based illustrated through the commented [`examples`](examples).

## Cite

If you find `EnergyModelsGeography` useful in your work, we kindly request that you cite the following publication:

```@article{boedal_2024,
  title = {Hydrogen for harvesting the potential of offshore wind: A North Sea case study},
  journal = {Applied Energy},
  volume = {357},
  pages = {122484},
  year = {2024},
  issn = {0306-2619},
  doi = {https://doi.org/10.1016/j.apenergy.2023.122484},
  url = {https://www.sciencedirect.com/science/article/pii/S0306261923018482},
  author = {Espen Flo Bødal and Sigmund Eggen Holm and Avinash Subramanian and Goran Durakovic and Dimitri Pinel and Lars Hellemo and Miguel Muñoz Ortiz and Brage Rugstad Knudsen and Julian Straus}
}
```

## Project Funding

The development of `EnergyModelsGeography` was funded by the Norwegian Research Council in the project [Clean Export](https://www.sintef.no/en/projects/2020/cleanexport/), project number [308811](https://prosjektbanken.forskningsradet.no/project/FORISS/308811)
