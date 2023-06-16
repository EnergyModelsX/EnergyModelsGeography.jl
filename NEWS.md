Release notes
=============
Version 0.7.1 (2023-06-16)
--------------------------
 * Updated the documentation based on the new format

Version 0.7.0 (2023-06-06)
--------------------------
### Switch to TimeStruct.jl
 * Switched the time structure representation to [TimeStruct.jl](https://gitlab.sintef.no/julia-one-sintef/timestruct.jl)
 * TimeStruct.jl is implemented with only the basis features that were available in TimesStructures.jl. This implies that neither operational nor strategic uncertainty is included in the model.

Version 0.6.1 (2023-06-02)
--------------------------
 * Bugfix in linepacking to include multiplication with `duration(t)` for proper energy accounting

Version 0.6.0 (2023-05-30)
--------------------------
 * Changed the structure in which the extra field `Data` is included in the nodes
 * It is changed from `Dict{String, Data}` to `Array{data}`

Version 0.5.2 (2023-05-16)
--------------------------
* Bugfix in the example which lead to a trivial solution in which no energy has to be converted

Version 0.5.1 (2023-04-30)
--------------------------
### Multiple smaller updates
* Moved the example in `user_interface.jl` into an example folder
* Introduced checks that can be utlized to check transmission related data
* Fixed a bug for `LimitedExchangeArea` that utilized wrong values

Version 0.5.0 (2023-04-27)
--------------------------
### Added var and fixed opex for transmision modes
* All `TransmissionMode` are updated to have fields for var and fixed opex.
* Variables `trans_opex_var` and `trans_opex_fixed`, also constraints that describes these variables.
* The function update_objective is updated in `src\model.jl` to add var and fixed opex to the objective function.
### Additional changes
* Constraints formulations are seperated into functions and moved to `src\constraint_functions.jl`, similar to how is is organized in `EnergyModelsBase` commit [26ad8740].
* Compute functions are moved to seperate file `src\compute_functions.jl`.


Version 0.4.0 (2023-02-xx)
--------------------------
### Change of indexing
* Variables are now indexed _via_ the `TransmissionMode` and the time period instead of the using a `SparseAxisArray` and indexing _via_ `Transmission`, time period, and `TransmissionMode`. This also improves model generation time.
* This adjustment requires the declaration of a new instance for each usage of a `TransmissionMode`, see, _e.g._, the changes in `scr\user_interface.jl`.
### Additional changes
* Change of variable generation for individual transmission modes: Variable generation _via_ the function `variables_trans_mode(s)` is adjusted to follow the concept introduced in `EnergyModelsBase`  commit [c58804ca](https://gitlab.sintef.no/clean_export/energymodelsbase.jl/-/commit/c58804cae6415f9a3da05f2d43cfbf5c78525c91).
* Move of the field `Data` from `Transmission` to `TransmissionMode`. This is required for the later application of dispatching in `EnergyModelsInvestments`

Version 0.3.1 (2023-02-16)
--------------------------
### Introduction of linepacking
* Redefinition of `PipelineMode` as abstract type `PipeMode` and introduction of `PipeSimple` as a composite type corresponding to the previous `PipelineMode`
* Introduction of a simple linepacking implementation _via_ the type `PipeLinepackSimple
* Change of `Area` to `abstract type` to be able to dispatch on areas
* Rewriting how functions for variable generation are called for easier introduction of variables for different `TransmissionMode`s

Version 0.3.0 (2023-02-02)
--------------------------
### Adjustmends to updates in EnergyModelsBase
Adjustment to version 0.3.0, namely:
* The removal of emissions from `Node` type definition that do not require them in all tests
* Removal of the type `GlobalData` and replacement with fields in the type `OperationalModel` in all tests
Version 0.2.2 (2022-12-12)
--------------------------
### Internal release
* Updated Readme
* Renamed with common prefix

Version 0.2.1 (2021-09-07)
--------------------------
### Changes in naming
* Major changes in both variable and parameter naming, check the commit message for an overview
* Introduction of bidrectional flow in transmission lines

Version 0.2.0 (2021-08-02)
--------------------------
* Defined structures for `Area`s, `Transmission` corridors and `TransmissionMode`s
* Overloading of the default availability node balance to allow for export and import
* Added examples of plotting in maps

Version 0.1.0 (2021-04-19)
--------------------------
* Initial (skeleton) version