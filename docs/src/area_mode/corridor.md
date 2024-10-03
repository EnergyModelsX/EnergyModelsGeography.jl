# [Transmission corridors](@id area_mode-trans_corr)

The concept of transmission corridors is used to provide a common umbrella for individual transmission options between areas.
The do not have any direct application within the mathematical description, but simplify the overall framework structure.

## [Introduced type and its fields](@id area_mode-trans_corr-fields)

`EnergyModelsGeography` introduces only a single concrete type.
Hence, it is not possible to provide any additional subtype to change the behavior.

The fields of the type are given as:

- **`from::Area`** and **`to::Area`**:\
  The field `from` denotes the area in which the corridor is originating while field `to` denotes the area to which resources are transported in the corridor.
  This is especially important for unidirectional transmission.
  It does not have a meaning in the case of bidirectional transmission,.
- **`modes::Vector{<:Transmission}`**:\
  It is in general possible to include an arbitray number of *[transmission modes](@ref lib-pub-mode)* within a single corridor.
  As an example, you could consider both AC and DC power flow between area 1 and area 2.

!!! warning "Directional flow"
    The design of `EnergyModelsGeography` differentiates between bi and unidirectional flow.
    While bidirectional flow is the standard for power transmission, it is not necessarily possible to utilize it for pipeline transport.
    Hence, it is important to be certain about the `from` and `to` area with respect to the flow direction.
