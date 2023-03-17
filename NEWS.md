Release notes
=============

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