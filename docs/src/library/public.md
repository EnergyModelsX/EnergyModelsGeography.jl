# [Public interface](@id sec_lib_public)

```@docs
Geography
```

## [`Area`](@id sec_lib_public_area)
A geographical area consist of a location and a connection to a local energy system via a specialized `Availability` node called `GeoAvailability`. Constraints related to the area keeps track of resource export import to the local system and exchange with other areas. 

```@docs
Area
```

## `Transmission`
`Transmission` occurs on specified transmission corridors `From` one area `To` another. On each corridors there can exist several `TransmissionMode`s that are transporting resources using a range of technologies.

```@docs
Transmission
```

## `TransmissionMode` 
`TransmissionMode` describes how resources are transported, for example by dynamic transmission modes on ship, truck or railway (represented generically by `RefDynamic`) or by static transmission modes on overhead power lines or gas pipelines (respresented generically by `RefStatic`). `TransmissionModes` includes capacity limits (`Trans_cap`), losses (`Trans_loss`) and directions (`Directions`) for the generic transmission modes `RefDynamic` and `RefStatic`. More specialized `TransmissionModes` such as `PipelineMode` can convert one `Inlet` resource to another `Outlet` resource. The `PipelineMode` can be `Consuming` another resource such as electricity for pumps at a `Consumption_rate` in order to transport natural gas or hydrogen.

```@docs
Geography.TransmissionMode
RefStatic
RefDynamic
PipelineMode
```
