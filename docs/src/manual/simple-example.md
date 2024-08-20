# [Examples](@id man-exampl)

For the content of the example, see the *[examples](https://github.com/EnergyModelsX/EnergyModelsGeography.jl/tree/main/examples)* directory in the project repository.

## The package is installed with `] add`

From the Julia REPL, run

```julia
# Starts the Julia REPL
julia> using EnergyModelsGeography
# Get the path of the examples directory
julia> exdir = joinpath(pkgdir(EnergyModelsGeography), "examples")
# Include the code into the Julia REPL to run the examples
julia> include(joinpath(exdir, "network.jl"))
```

## The code was downloaded with `git clone`

The examples can be run from the terminal with

```shell script
~/../energymodelsgeography.jl/examples $ julia network.jl
```
