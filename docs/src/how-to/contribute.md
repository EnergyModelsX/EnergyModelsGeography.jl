# [Contribute to EnergyModelsGeography](@id how_to-con)

Contributing to `EnergyModelsGeography` can be achieved in several different ways.

## [Create new extensions](@id how_to-con-ext)

The main focus of `EnergyModelsGeography` is to provide [`EnergyModelsBase`](https://energymodelsx.github.io/EnergyModelsBase.jl/stable/) with geographical representation using the concepts of [`Area`](@ref)s, [`Transmission`](@ref) corridors, or [`TransmissionMode`](@ref)s.
Hence, a first approach to contributing to `EnergyModelsGeography` is to create a new package with, _e.g._, the introduction of new `Area`, `Transmission`, or `TransmissionMode` descriptions.
These descriptions can, _e.g._, include constraints for an `Area` or provide the model with new mathematical formulations for energy transmissions.

!!! note
    We are currently working on guidelines for the best approach for `EnergyModelsGeography`, similar to the section [_Extensions to the model_](https://energymodelsx.github.io/EnergyModelsBase.jl/stable/manual/philosophy/#sec_phil_ext) in `EnergyModelsBase`.
    This section will provide you eventually with additional information regarding to how you can develop new `Area`, `Transmission`, or `TransmissionMode` descriptions.

## [File a bug report](@id how_to-con-bug_rep)

Another approach to contributing to `EnergyModelsGeography` is through filing a bug report as an [_issue_](https://github.com/EnergyModelsX/EnergyModelsGeography.jl/issues/new) when unexpected behaviour is occuring.

When filing a bug report, please follow the following guidelines:

1. Be certain that the bug is a bug and originating in `EnergyModelsGeography`:
    - If the problem is within the results of the optimization problem, please check first that the nodes are correctly linked with each other.
      Frequently, missing links (or wrongly defined links) restrict the transport of energy/mass.
      If you are certain that all links are set correctly, it is most likely a bug in `EnergyModelsGeography` and should be reported.
    - If you observe no transfer of mass between geographical regions, please check first that you use a `GeoAvailability` node as the description is different from a `GenAvailability` node.
      In addition, please check that the `Transmission` corridors and `TransmissionMode`s are set correctly as well as there is a demand or suppy in both areas of the transported `Resource`.
    - If the problem occurs in model construction, it is most likely a bug in either `EnergyModelsBase` or `EnergyModelsGeography` and should be reported in the respective package.
      The error message of Julia should provide you with the failing function and whether the failing function is located in `EnergyModelsBase` or `EnergyModelsGeography`.
      It can occur, that the last shown failing function is within `JuMP` or `MathOptInterface`.
      In this case, it is best to trace the error to the last called `EnergyModelsBase` or `EnergyModelsGeography` function.
    - If the problem is only appearing for specific solvers, it is most likely not a bug in `EnergyModelsGeography`, but instead a problem of the solver wrapper for `MathOptInterface`.
      In this case, please contact the developers of the corresponding solver wrapper.
2. Label the issue as bug, and
3. Provide a minimum working example of a case in which the bug occurs.

!!! note
    We are aware that certain design choices within `EnergyModelsGeography` can lead to method ambiguities.
    Our aim is to extend the documentation to improve the description on how to best extend the base functionality as well as which caveats can occur.

    In order to improve the code, we welcome any reports of potential method ambiguities to help us improving the structure of the framework.

## [Feature requests](@id how_to-con-feat_req)

Although `EnergyModelsGeography` was designed with the aim of flexibility, it sometimes still requires additional features to account for potential extensions.
Feature requests for `EnergyModelsGeography` should follow the guidelines developed for [_`EnergyModelsBase`_](https://energymodelsx.github.io/EnergyModelsBase.jl/stable/how-to/contribute/).

!!! note
    `EnergyModelsGeography` should not include everything.

    The aim of the framework is to be lightweight and extensible by the user.
    Hence, feature requests should only include basic requirements for the core structure, and not, _e.g._, the description of new `Area`s description.
    These should be developed outside of `EnergyModelsGeography`.
