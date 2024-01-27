# Running the examples

You have to add the package `EnergyModelsGeography` to your current project in order to run the example.
It is not necessary to add the other used packages, as the example is instantiating itself.
How to add packages is explained in the *[Quick start](https://energymodelsx.github.io/EnergyModelsGeography.jl/stable/manual/quick-start/)* of the documentation

You can run from the Julia REPL the following code:

```julia
# Starts the Julia REPL
julia> using EnergyModelsGeography
# Get the path of the examples directory
julia> exdir = joinpath(pkgdir(EnergyModelsGeography), "examples")
# Include the code into the Julia REPL to run the examples
julia> include(joinpath(exdir, "network.jl"))
```

> **Note**
>
> The example is not running yet, as the instantiation would require that the package [`EnergyModelsBase`](https://github.com/EnergyModelsX/EnergyModelsBase.jl) is registered.
> It is however possible to run the code directly from a local project in which the packages `TimeStruct`, `EnergyModelsBase`, `EnergyModelsGeography`, `JuMP`, and `HiGHS` are loaded.
> In this case, you have to comment lines 2-7 out:
> ```julia
> # Activate the test-environment, where HiGHS is added as dependency.
> Pkg.activate(joinpath(@__DIR__, "../test"))
> # Install the dependencies.
> Pkg.instantiate()
> # Add the package EnergyModelsGeography to the environment.
> Pkg.develop(path=joinpath(@__DIR__, ".."))
> ```
