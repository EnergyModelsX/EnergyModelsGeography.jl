# [Philosophy](@id man-phil)

## [General design philosophy](@id man-phil-gen)

This package extends `EnergyModelsBase` with geographical functionalities.
The geographical representation is achieved through individual `Area`s coupled with `Transmission` corridors.
Each area can represent an individual energy system with different technology `Node`s and `Link`s between the `Node`s.
`Transmission` corridors define pathways from one `Area` to another `Area`.
Each corridor can have multiple `TransmissionMode`s used to transport resources.
The `TransmissionMode`s can be static infrastructure such as a `PipeMode` or dynamic modes such as ships.
The latter is in the current stage not yet implemented.

The extension of `EnergyModelsBase` is achieved through the new elements `Area` and `Transmission` that are included in the `Case` together with their coupling.
`EnergyModelsGeography` adds methods to the functions called within `create_model` of `EnergyModelsBase` for these elements, as described in *[Create a new element](@extref EnergyModelsBase how_to-create_element)*.
It hence does not require a separate `create_model` function.

Each `Area` is associated with corresponding latitude and longitude coordinates.
These coordinates can be utilized to calculate the distance between two `Area`s.
It is however not a necessity to base the distance on the coordinates.
The values are in practice not used directly, but can be used by the user when calculating, *e.g.*, OPEX values or transmission losses.
It is in addition also not necessary to use the same distance for individual `TransmissionMode`s within a `Transmission` corridor.
This can be beneficial for the case of power lines *vs.* pipelines which may require a different routing due to the geographical features of a region.

Emissions associated with the transport of energy or mass are possible for new `TransmissionMode`s.
They require new methods for the functions [`EMB.has_emissions`](@ref), [`emit_resources`](@ref EnergyModelsGeography.emit_resources), and [`emissions`](@ref EnergyModelsGeography.emissions).
None of the provided `TransmissionMode`s include emissions.

## [Extensions to the model](@id man-phil-ext)

`EnergyModelsGeography` is also designed to be extended by the user.
Extensions of `EnergyModelsGeography` are possible through

1. specialized [`Area`](@ref)s (like the [`LimitedExchangeArea`](@ref)) and
2. new [`TransmissionMode`](@ref)s.

### [Specialized `Area`s](@id man-phil-ext-area)

Specialized [`Area`](@ref)s are areas with additional constraints.
In general, it is possible to import and export as much as possible through the connected `Transmission` corridors.
Introducing specialized [`Area`](@ref)s allows the introduction of additional constraints within an `Area`.
These constraints can include, among others, limits on the CO₂ emissions within an `Area`, export limits on, *e.g.*, operational or strategic periods as well as many other modifications.

### [New [`TransmissionMode`](@ref)s](@id man-phil-ext-transmission_mode)

New [`TransmissionMode`](@ref)s may be relevant for describing a dynamic transport mechanism or for adding a distinctive description for an energy carrier.
[`TransmissionMode`](@ref)s can be developed similarly to new `Node`s as described in `EnergyModelsBase`.
