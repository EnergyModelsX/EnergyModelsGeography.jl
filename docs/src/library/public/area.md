# [`Area`](@id lib-pub-area)

A geographical `Area` consist of a location and a connection to a local energy system **via** a specialized `Availability` node called `GeoAvailability`.
The specialized `Availability` node is required to modify the energy/mass balance to allow for imports and exports.
Constraints related to the area keep track of a resource's export and import to the local system and exchange with other areas.
Multiple dispatch is used on the `Area` type for imposing specific constraints.
Hence, other restrictions can be applied on a area level, such as electricity generation reserves, CO₂ emission limits or resource limits (wind power, natural gas etc.).

## [`Area` types](@id lib-pub-area-types)

The following types are inmplemented:

```@docs
Area
RefArea
LimitedExchangeArea
GeoAvailability
```

## [Functions for accessing fields of `Area` types](@id lib-pub-area-fun_field)

The following functions are defined for accessing fields from an `Area`:

```@docs
name
availability_node
limit_resources
exchange_limit
exchange_resources
getnodesinarea
```
