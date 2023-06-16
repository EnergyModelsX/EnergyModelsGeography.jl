# Quick Start

>  1. Install the most recent version of [Julia](https://julialang.org/downloads/)
>  2. Add the [CleanExport internal Julia registry](https://gitlab.sintef.no/clean_export/registrycleanexport):
>     ```
>     ] registry add git@gitlab.sintef.no:clean_export/registrycleanexport.git
>     ```
>  3. Add the [SINTEF internal Julia registry](https://gitlab.sintef.no/julia-one-sintef/onesintef):
>     ```
>     ] registry add git@gitlab.sintef.no:julia-one-sintef/onesintef.git
>     ```
>  4. Install the base package [`EnergyModelsBase.jl`](https://clean_export.pages.sintef.no/energymodelsbase.jl/) and the time package [`TimeStruct.jl`](https://gitlab.sintef.no/julia-one-sintef/timestruct.jl), and the geography package [`EnergyModelsGeography.jl`](https://clean_export.pages.sintef.no/energymodelsgeography.jl/) by running:
>     ```
>     ] add EnergyModelsBase
>     ] add EnergyModelsGeography
>     ] add TimeStruct
>     ```
>     This will fetch the packages from the CleanExport package and OneSINTEF registries.

Once the package is installed, you can start by using an existing model from `EnergyModelsBase`. The only change that is needed is to substitute the `GenAvailabilty` from `EnergyModelsBase` with `GeoAvailability`from `EnergyModelsGeography`. The `GeoAvailability` node from this local system is then connected to an `RefArea`. More areas can be created by repeating this process. `Transmission` can be added in a system with several areas. `Transmission` have one `From` `Area` one `To` `Area`. It also includes an Array of `TransmissionModes`, which describes how resources are tranported.



