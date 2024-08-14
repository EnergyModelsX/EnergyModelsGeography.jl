# [Public interface](@id lib-pub)

## [`Area`](@id lib-pub-area)

A geographical `Area` consist of a location and a connection to a local energy system *via* a specialized `Availability` node called `GeoAvailability`.
The specialized `Availability` node is required to modify the energy/mass balance to allow for imports and exports.
Constraints related to the area keep track of a resource's export and import to the local system and exchange with other areas.
Multiple dispatch is used on the `Area` type for imposing specific constraints.
Hence, other restrictions can be applied on a area level, such as electricity generation reserves, CO₂ emission limits or resource limits (wind power, natural gas etc.).

### [`Area` types](@id lib-pub-area-types)

The following types are inmplemented:

```@docs
Area
RefArea
LimitedExchangeArea
GeoAvailability
```

### [Functions for accessing fields of `Area` types](@id lib-pub-area-fun_field)

The following functions are defined for accessing fields from an `Area`:

```@docs
name
availability_node
limit_resources
exchange_limit
exchange_resources
getnodesinarea
```

## [`Transmission`](@id lib-pub-transmission)

`Transmission` occurs on specified transmission corridors `from` one area `to` another. On each corridor, there can exist several `TransmissionMode`s that are transporting resources using a range of technologies.

It is important to consider the `from` and `to` `Area` when specifying a `Transmission` corridor.
The chosen direction has an influence on whether the variables ``\texttt{trans\_in}[m, t]`` and ``\texttt{trans\_out}[m, t]`` are positive or negative for exports in the case of bidirectional transport.
This is also explained on the page *[Optimization variables](@ref man-opt_var)*.

### [`Transmission` types](@id lib-pub-transmission-types)

```@docs
Transmission
```

### [Functions for accessing fields of `Transmission` types](@id lib-pub-transmission-fun_fields)

The following functions are defined for accessing fields from a `Transmission` as well as finding a subset of `Transmission` corridors:

```@docs
modes
modes_sub
corr_from
corr_to
corr_from_to
modes_of_dir
```

## [`TransmissionMode`](@id lib-pub-transmission_mode)

`TransmissionMode` describes how resources are transported, for example by dynamic transmission modes on ship, truck or railway (represented generically by `RefDynamic`, although not implemented in the current version) or by static transmission modes on overhead power lines or gas pipelines (respresented generically by `RefStatic`).
`TransmissionMode`s includes capacity limits (`trans_cap`), losses (`trans_loss`) and directions (`directions`) for the generic transmission modes `RefDynamic` and `RefStatic`.
More specialized `TransmissionModes` such as subtypes of the abstract type `PipeMode` can convert one `inlet` resource to another `outlet` resource.
This approach can be used for representing a static pressure drop within a pipeline.
The `PipeMode` can be `consuming` another resource such as electricity for compressors at a `consumption_rate` in order to transport natural gas or hydrogen.
The `consumption_rate` is in this situation proportional to the transport of the `inlet` resource.
All `TransmissionMode`s can also include both fixed (`opex_fixed`) and variable (`opex_var`) operational expenditures (OPEX).

!!! warning
    All parameters of the implemented `TransmissionMode`s are relative (based on usage, `opex_var` and `trans_loss`, or the installed capacity, `opex_fixed`).
    They are independent of the distance.
    The reasoning for this approach is that it allows the modeller to have a non-linear, distance dependent OPEX or loss function for providing the input to the model.

### [`TransmissionMode` types](@id lib-pub-transmission_mode-types)

The following `TransmissionMode`s are implemented and exported:

```@docs
TransmissionMode
RefStatic
RefDynamic
PipeMode
PipeSimple
PipeLinepackSimple
```

### [Functions for accessing fields of `TransmissionMode` types](@id lib-pub-transmission_mode-fun_fields)

The following functions are defined and exported for accessing fields from a `TransmissionMode`:

```@docs
map_trans_resource
loss
directions
consumption_rate
energy_share
```

## [Investment data](@id lib-pub-inv_data)

### [`InvestmentData` types](@id lib-pub-inv_data-types)

Transmission mode investmentments utilize the same investment data type ([`SingleInvData]) as investments in node capacities.

### [Legacy constructors](@id lib-pub-inv_data-leg)

We provide a legacy constructor, `TransInvData`, that uses the same input as in version 0.5.x.
If you want to adjust your model to the latest changes, please refer to the section *[Update your model to the latest version of EnergyModelsInvestments](@extref EnergyModelsInvestments sec_how_to_update)*.

```@docs
TransInvData
```
