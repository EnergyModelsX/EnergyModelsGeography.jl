# EnergyModelsGeography

```@docs
EnergyModelsGeography
```

The Julia package extends [`EnergyModelsBase`](https://energymodelsx.github.io/EnergyModelsBase.jl/) with functionality to set up an energy system consisting of several separate regions, with transmissions between.

The extension focuses on overriding the function `EMB.create_model` to add additional types, variables, and constraints to the model.

## Manual outline

```@contents
Pages = [
    "manual/quick-start.md",
    "manual/philosophy.md",
    "manual/optimization-variables.md",
    "manual/constraint-functions.md",
    "manual/transmission-mode.md",
    "manual/investments.md",
    "manual/simple-example.md"
]
Depth = 1
```

## Description of the areas and transmission modes

```@contents
Pages = [
    "area_-_mode/area.md",
    "area_-_mode/corridor.md",
]
Depth = 1
```

## How to guides

```@contents
Pages = [
    "how-to/update-models.md",
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
