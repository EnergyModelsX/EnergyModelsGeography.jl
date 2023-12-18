# [Public interface](@id sec_lib_public)

## `Area`

A geographical `Area` consist of a location and a connection to a local energy system *via* a specialized `Availability` node called `GeoAvailability`.
The specialized `Availability` node is required to modify the energy/mass balance to allow for exports.
Constraints related to the area keep track of a resource's export and import to the local system and exchange with other areas.
Multiple dispatch is used on the `Area` type for imposing specific constraints.
Hence, other restrictions can be applied on a area level, such as electricity generation reserves, CO₂ emission limits or resource limits (wind power, natural gas etc.).

```@docs
Area
RefArea
LimitedExchangeArea
GeoAvailability
```

The following functions are defined for accessing fields from an `Area`:

```@docs
name
availability_node
limit_resources
exchange_limit
exchange_resources
```

## `Transmission`

`Transmission` occurs on specified transmission corridors `From` one area `To` another. On each corridor, there can exist several `TransmissionMode`s that are transporting resources using a range of technologies.

```@docs
Transmission
```

The following functions are defined for accessing fields from a `Transmission` as well as finding a subset of `Transmission` corridors:

```@docs
modes
modes_sub
corr_from
corr_to
corr_from_to
modes_of_dir
```

## `TransmissionMode`

`TransmissionMode` describes how resources are transported, for example by dynamic transmission modes on ship, truck or railway (represented generically by `RefDynamic`) or by static transmission modes on overhead power lines or gas pipelines (respresented generically by `RefStatic`).
`TransmissionMode`s includes capacity limits (`Trans_cap`), losses (`Trans_loss`) and directions (`Directions`) for the generic transmission modes `RefDynamic` and `RefStatic`.
More specialized `TransmissionModes` such as subtypes of the abstrac type `PipeMode` can convert one `Inlet` resource to another `Outlet` resource.
 The `PipeMode` can be `Consuming` another resource such as electricity for pumps at a `Consumption_rate` in order to transport natural gas or hydrogen.

The following `TransmissionMode`s are implemented and exported:

```@docs
TransmissionMode
RefStatic
RefDynamic
PipeMode
PipeSimple
PipeLinepackSimple
```

The following functions are defined for accessing fields from a `TransmissionMode`:

```@docs
map_trans_resource
loss
directions
consumption_rate
energy_share
```
