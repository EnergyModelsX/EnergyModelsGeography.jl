# EnergyModelsGeography

```@docs
EnergyModelsGeography
```

The Julia package extends [`EnergyModelsBase`](https://energymodelsx.github.io/EnergyModelsBase.jl/) with functionality to set up an energy system consisting of several separate regions, with transmission between them.

The extension introduces the new elements `Area` and `Transmission` and adds methods to the functions of `EnergyModelsBase` to include their variables and constraints in the model.

## Manual outline

```@contents
Pages = [
    "manual/quick-start.md",
    "manual/philosophy.md",
    "manual/optimization-variables.md",
    "manual/constraint-functions.md",
    "manual/investments.md",
    "manual/simple-example.md"
]
Depth = 1
```

## Description of the areas and transmission modes

```@contents
Pages = [
    "area_mode/area.md",
    "area_mode/corridor.md",
    "area_mode/mode.md",
]
Depth = 1
```

## How-to guides

```@contents
Pages = [
    "how-to/update-models.md",
    "how-to/extend-resource-functionality.md",
    "how-to/contribute.md",
]
Depth = 1
```

## Library outline

### Public library

```@contents
Pages = [
    "library/public/area.md",
    "library/public/transmission.md",
    "library/public/mode.md",
    "library/public/emi_extension.md",
    "library/public/case_element.md",
    ]
Depth = 1
```

### Internal library

```@contents
Pages = [
    "library/internals/functions.md",
    "library/internals/methods_EMB.md",
    "library/internals/methods_EMIExt.md",
    ]
Depth = 1
```
