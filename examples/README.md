# Running the examples

You have to add the package `EnergyModelsGeography` to your current project in order to run the examples.
It is not necessary to add the other used packages, as each example instantiates its own environment.
How to add packages is explained in the *[Quick start](https://energymodelsx.github.io/EnergyModelsGeography.jl/stable/manual/quick-start/)* of the documentation.

You can run the following code from the Julia REPL:

```julia
# Import EnergyModelsGeography
using EnergyModelsGeography

# Get the path of the examples directory
exdir = joinpath(pkgdir(EnergyModelsGeography), "examples")

# Include the code into the Julia REPL to run the network example
include(joinpath(exdir, "network.jl"))

# Include the code into the Julia REPL to run the investment example
include(joinpath(exdir, "investments.jl"))
```
