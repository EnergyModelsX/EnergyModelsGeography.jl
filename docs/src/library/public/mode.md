# [`TransmissionMode`](@id lib-pub-mode)

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

## [`TransmissionMode` types](@id lib-pub-mode-types)

The following `TransmissionMode`s are implemented and exported:

```@docs
TransmissionMode
RefStatic
RefDynamic
PipeMode
PipeSimple
PipeLinepackSimple
```

## [Functions for accessing fields of `TransmissionMode` types](@id lib-pub-mode-fun_fields)

The following functions are defined and exported for accessing fields from a `TransmissionMode`:

```@docs
map_trans_resource
loss
directions
mode_data
consumption_rate
energy_share
```
