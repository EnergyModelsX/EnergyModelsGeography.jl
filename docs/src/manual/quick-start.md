# [Quick Start](@id quick_start)

>  1. Install the most recent version of [Julia](https://julialang.org/downloads/)
>  2. Install the package [`EnergyModelsBase`](https://energymodelsx.github.io/EnergyModelsBase.jl/) and the time package [`TimeStruct`](https://sintefore.github.io/TimeStruct.jl/), by running:
>     ```
>     ] add TimeStruct
>     ] add EnergyModelsBase
>     ```
>     These packages are required as we do not only use them internally, but also for building a model.
>  3. Install the package [`EnergyModelsGeography`](https://energymodelsx.github.io/EnergyModelsGeography.jl/)
>     ```
>     ] add EnergyModelsGeography
>     ```

!!! note
    If you receive the error that `EnergyModelsGeography` is not yet registered, you have to add the package using the GitHub repository through
    ```
    ] add https://github.com/EnergyModelsX/EnergyModelsGeography.jl
    ```
    Once the package is registered, this is not required.
