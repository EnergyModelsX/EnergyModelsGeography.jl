# Philosophy

## General design philosophy

This package extends `EnergyModelsBase` with geographical functionalities.
The geographical representation is achieved through individual `Area`s coupled with `Transmission` corridors.
Each area can represent an individual energy system with different technology `Node`s and `Link`s between the `Node`s.
`Transmission` corridors define pathways from one `Area` to another `Area`.
Each corridor can have multiple `TransmissionMode`s used to transport resources.
The `TransmissionModes` can be static infrastructure such as `PipelineMode` or dynamic modes such as ships.
The latter is in the current stage not yet implemented.

The extension of `EnergyModelsBase` is achieved through calling on the function `create_model` within `EnergyModelsGeography`.
This corresponds to the 2nd bullet point in the list.

Each `Area` is assocoiated with corresponding latitude and longitude coordinates.
These coordinates can be utilized to calculate the distance between two `Area`s.
It is however not a necessity to base the distance on the coordinates.
The values are in practice not used directly, but can be used by the user when calculating, *e.g*, OPEX values or transmission losses.
It is in addition also not necesseary to use the same distance for individual `TransmissionMode`s within a `Transmission` corridor.
This can be beneficial for the case of power lines *vs.* pipelines which may require a different routing due to the geographical features of a region.

`EnergyModelsGeography` does not directly allow for emissions associated with transport of energy or mass.
We included in an internal version one approach to extend the emission constraints, but are not yet satisfied with the exact implementation.
This implies that including emissions in mass/energy transport is on the agenda for future improvements.

## Extensions to the model

`EnergyModelsGeography` is also designed to be extended by the user.
Extensions of `EnergyModelsGeography` are possible through

1. specialized [`Area`](@ref)s (like the [`LimitedExchangeArea`](@ref)) and
2. new [`TransmissionMode`](@ref)s.

### Specialized `Area`s

Specialized [`Area`](@ref)s are areas with additional constraints.
In general, it is possible to import and export as much as possible through the connected `Transmission` corridors.
Introducing specialized [`Area`](@ref)s allow the introduciton of additional constraints within an `Area`.
These constraints can include, among others, limits on the CO₂ emissions within an `Area`, export limits both on, *e.g.* operational or strategic periods as well as many other modifications.

### New [`TransmissionMode`](@ref)s

New [`TransmissionMode`](@ref)s may be relevant for describing a dynamic transport mechanism or for adding a distinctive description for an energy carrier.
[`TransmissionMode`](@ref)s can be developed similar to new `Node`s as described in `EnergyModelsBase`.
