# Release notes

## Unversioned

* Included a new method for identifying nodes within an area using breadth-first search.
  This method allows for an arbitrary connection of links between a node and the availability node.
* Minor typo updates in the documentation.

## Version 0.10.1 (2024-10-16)

### Minor updates

* Reworked the tests and included the tests for investments.
* Included an option to deactive the checks entirely with printing a warning, similarly to `EnergyModelsBase`.
* Adjusted to [`EnergyModelsBase` v0.8.1](https://github.com/EnergyModelsX/EnergyModelsBase.jl/releases/tag/v0.8.1) and [`EnergyModelsInvestments` v0.8.0](https://github.com/EnergyModelsX/EnergyModelsInvestments.jl/releases/tag/v0.8.0).

### Rework of documentation

* The documentation received a significant rework.
  The rework consists of:
  * Provide webpages for the descriptions of `Area`s, `Transmission`, and `TransmissionMode` in which the fields are described more in detail as well as a description of the math.
  * Restructured both the public and internal libraries

## Version 0.10.0 (2024-08-21)

### Changed `PipeSimple` and `PipeLinepackSimple` types

* Moved away from `@kwdef` to avoid having to specify potentially all field names.
* Included an inner constructor for limiting the field directions to 1 to avoid issues in the calculations.

### Introduced `EnergyModelsInvestments` as extension

* `EnergyModelsInvestments` was switched to be an independent package in [PR #28](https://github.com/EnergyModelsX/EnergyModelsInvestments.jl/pull/28).
* This approach required `EnergyModelsGeography` to include all functions and type declarations internally.
* An extension was introduced to handle these problems.

### Introduced potential for emissions of `TransmissionMode`s

* As outlined in [Issue 9](https://github.com/EnergyModelsX/EnergyModelsGeography.jl/issues/9), there is a requirement for potential emissions from `TransmissionMode`s.
* The clean approach was not achieved within a certain timeframe, hence, a limited approach is implemented based on the initial provided branches in both [`EMB`](https://github.com/EnergyModelsX/EnergyModelsBase.jl/tree/0.7/emissions) and [`EMG`](https://github.com/EnergyModelsX/EnergyModelsGeography.jl/tree/0.9/emissions).
* The implementation is **not** tested!

## Version 0.9.1 (2024-08-19)

### Bugfix

* The variable OPEX for unidirectional transmission modes was wrongly calculated as it did not take into account the scaling provided through the optional keyword argument `op_per_strat` of `TimeStruct`.

### Other

* Use dev version of EMG for examples when running as part of tests, similar to [PR #33 of EMB](https://github.com/EnergyModelsX/EnergyModelsBase.jl/pull/33).

## Version 0.9.0 (2024-05-24)

### Update on function calls for dispatching on `modeltype`

* Introduced `modeltype` as argument for all create and constraint functions.
* Moved constraint on installed capacity to function `constraints_capacity_installed` to replicate the dispatch behaviour from `EnergyModelsBase`.

## Version 0.8.5 (2024-05-24)

* Update of dependencies and adjustment to changes in `EnergyModelsBase` v0.7.

## Version 0.8.4 (2024-05-09)

* Provided a contribution section in the documentation.
* Fixed a link in the documentation for the examples.

## Version 0.8.3 (2024-03-21)

* Fixed a bug regarding accessing the field `limit` of a `LimitedExchangeArea`.
* Moved all files declaring structures to a separate folder for improved readability.
* Allow for jumping over `TimeProfile` checks also from `EnergyModelsGeography`.
* Added possibility to provide a different type of `JuMP.Model`.

## Version 0.8.2 (2024-03-04)

* Fixed a bug when running the examples from a non-cloned version of `EnergyModelsGeography`.
* This was achieved through a separate Project.toml in the examples.

## Version 0.8.1 (2024-01-30)

* Updated the restrictions on the fields of individual types to be more restrictive.

## Version 0.8.0 (2023-12-19)

Adjusted to changes in `EnergyModelsBase` v0.6.
These changes are mainly:

* All fields of composite types are now lower case.
* An extensive number of functions to access the individual fields were included, allowing for differing definitions of the individual nodes.
* The `GeoAvailability` type does no longer require as input dictionaries for both `input` and `output`. Instead, it is now a single array corresponding to all resources.
* New function `getnodesinarea` to extract nodes connected to the `Availability` node of an area.
* Changed file structure for simplified understanding of the different types.

## Version 0.7.1 (2023-06-16)

* Updated the documentation based on the new format.

## Version 0.7.0 (2023-06-06)

### Switch to TimeStruct

* Switched the time structure representation to [`TimeStruct`](https://github.com/sintefore/TimeStruct.jl).
* `TimeStruct` is implemented with only the basis features that were available in `TimeStructures`. This implies that neither operational nor strategic uncertainty is included in the model.

## Version 0.6.1 (2023-06-02)

* Bugfix in linepacking to include multiplication with `duration(t)` for proper energy accounting

## Version 0.6.0 (2023-05-30)

* Changed the structure in which the extra field `Data` is included in the nodes.
* It is changed from `Dict{String, Data}` to `Array{data}`.

## Version 0.5.2 (2023-05-16)

* Bugfix in the example which lead to a tri*via*l solution in which no energy has to be converted.

## Version 0.5.1 (2023-04-30)

### Multiple smaller updates

* Moved the example in `user_interface.jl` into an example folder.
* Introduced checks that can be utlized to check transmission related data.
* Fixed a bug for `LimitedExchangeArea` that utilized wrong values.

## Version 0.5.0 (2023-04-27)

### Added var and fixed opex for transmision modes

* All `TransmissionMode` are updated to have fields for var and fixed opex.
* Variables `trans_opex_var` and `trans_opex_fixed`, also constraints that describes these variables.
* The function update_objective is updated in `src\model.jl` to add var and fixed opex to the objective function.

### Additional changes

* Constraints formulations are seperated into functions and moved to `src\constraint_functions.jl`, similar to how is is organized in `EnergyModelsBase` commit [26ad8740].
* Compute functions are moved to seperate file `src\compute_functions.jl`.

## Version 0.4.0 (2023-03-17)

### Change of indexing

* Variables are now indexed _*via*_ the `TransmissionMode` and the time period instead of the using a `SparseAxisArray` and indexing _*via*_ `Transmission`, time period, and `TransmissionMode`. This also improves model generation time.
* This adjustment requires the declaration of a new instance for each usage of a `TransmissionMode`, see, _e.g._, the changes in `scr\user_interface.jl`.

### Additional changes

* Change of variable generation for individual transmission modes: Variable generation _*via*_ the function `variables_trans_mode(s)` is adjusted to follow the concept introduced in `EnergyModelsBase`.
* Move of the field `Data` from `Transmission` to `TransmissionMode`. This is required for the later application of dispatching in `EnergyModelsInvestments`.

## Version 0.3.1 (2023-02-16)

### Introduction of linepacking

* Redefinition of `PipelineMode` as abstract type `PipeMode` and introduction of `PipeSimple` as a composite type corresponding to the previous `PipelineMode`.
* Introduction of a simple linepacking implementation _*via*_ the type `PipeLinepackSimple.
* Change of `Area` to `abstract type` to be able to dispatch on areas.
* Rewriting how functions for variable generation are called for easier introduction of variables for different `TransmissionMode`s.

## Version 0.3.0 (2023-02-02)

### Adjustmends to updates in EnergyModelsBase

Adjustment to version 0.3.0, namely:

* The removal of emissions from `Node` type definition that do not require them in all tests.
* Removal of the type `GlobalData` and replacement with fields in the type `OperationalModel` in all tests.

## Version 0.2.2 (2022-12-12)

### Internal release

* Updated Readme.
* Renamed with common prefix.

## Version 0.2.1 (2021-09-07)

### Changes in naming

* Major changes in both variable and parameter naming, check the commit message for an overview.
* Introduction of bidrectional flow in transmission lines.

## Version 0.2.0 (2021-08-02)

* Defined structures for `Area`s, `Transmission` corridors and `TransmissionMode`s.
* Overloading of the default availability node balance to allow for export and import.
* Added examples of plotting in maps.

## Version 0.1.0 (2021-04-19)

* Initial (skeleton) version.
