Release notes
=============

Version 0.3.0 (2023-02-02)
--------------------------
### Adjustmends to updates in EnergyModelsBase
Adjustment to version 0.3.0, namely:
* The removal of emissions from `Node` type definition that do not require them in all tests
* Removal of the type `GlobalData` and replacement with fields in the type `OperationalModel` in all tests
### Introduction of linepacking
* Redefinition of `PipelineMode` as abstract type `PipeMode` and introduction of `PipeSimple` as a composite type corresponding to the previous `PipelineMode`
* Introduction of a simple linepacking implementation _via_ the type `PipeLinepackSimple`

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
* Defined structures for areas, transmission and transmission modes
* Overloading of the default availability node balance to allow for export and import
* Added examples of plotting in maps

Version 0.1.0 (2021-04-19)
--------------------------
* Initial (skeleton) version