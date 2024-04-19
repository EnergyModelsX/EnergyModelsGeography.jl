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
    "manual/simple-example.md"
]
```

## How to guides

```@contents
Pages = [
    "how-to/contribute.md",
]
```

## Library outline

```@contents
Pages = [
    "library/public.md",
    "library/internals/reference.md",
    ]
```
