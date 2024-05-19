# [Constraint functions](@id constraint_functions)

The package provides standard constraint functions that can be use for new developed `TransmissionMode`s.
The general approach is similar to `EnergyModelsBase`.
Bidirectional transport requires at the time being the introduciton of an *if*-loop.
In later implementation, it is planned to also use dispatch for this analysis as well.

## Capacity constraints

```julia
constraints_capacity(m, tm::TransmissionMode, 𝒯::TimeStructure, modeltype::EnergyModel)
```

correponds to the constraints on the capacity usage of a transmission mode ``tm``.
It is implemented for both the `TransmissionMode` and `PipeMode` abstract types as well as `PipeLinepackSimple` concrete type.
The key difference between the former two is related that `PipeMode` does not allows for bidirectional transport.
`PipeLinepackSimple` includes in addition the maximum storage capacity for a pipeline when considering linepacking.
The implementation is still preliminary and based on a simplified potential for energy storage in a pipeline.

Within this function, the function

```julia
constraints_capacity_installed(m, tm::TransmissionMode, 𝒯::TimeStructure, modeltype::EnergyModel)
```

is called to limit the variable ``\texttt{trans\_cap\_inst}`` of transmission mode ``tm``.
This functions is also used to subsequently dispatch on model type for the introduction of investments.

!!! warning
    As the function `constraints_capacity_installed` is used for including investments for tranmission modes, it is important that it is also called when creating a new mode.
    It is not possible to only add a function for
    ```julia
    constraints_capacity_installed(m, tm::TransmissionMode, 𝒯::TimeStructure, modeltype::EnergyModel)
    ```
    without adding a function for
    ```julia
    constraints_capacity_installed(m, tm::TransmissionMode, 𝒯::TimeStructure, modeltype::EMI.AbstractInvestmentModel)
    ```
    as this can lead to a method ambiguity error.

## Transmission loss functions

```julia
constraints_trans_loss(m, tm::TransmissionMode, 𝒯ᴵⁿᵛ, modeltype::EnergyModel)
```

correponds to the constraints on the energy balance of a transmission mode ``tm``.
It is implemented for both the `TransmissionMode` and `PipeMode` abstract types.
The key difference between the two is related that `PipeMode` does not allows for bidirectional transport.
The loss is calculated for the provided `TransmissionMode`s as relative loss of the transported energy.

## Balance functions

```julia
constraints_trans_balance(m, tm::TransmissionMode, 𝒯ᴵⁿᵛ, modeltype::EnergyModel)
```

correponds to the constraints on the energy balance of a transmission mode ``tm``.
It is implemented for both the `TransmissionMode` and `PipeLinepackSimple` abstract types.
The standard approach only relies on the conservation of mass/energy, while storage is not included.
`PipeLinePackSimple` also includes the overall mass balance for the energy storage within the pipeline.

!!! note
    `PipeLinePackSimple` does not support representative periods correctly.
    In practice, seasonal energy storage through linepacking is unrealistic due to the small volume.
    The implementation is working with the assumption that the initial level in a representative period is equal to the final level in the last representative period of a strategic period.
    This implies that it does not account correctly for the remaining level at the end of a representative period.

## Operational expenditure constraints

```julia
constraints_opex_fixed(m, tm::TransmissionMode, 𝒯ᴵⁿᵛ, modeltype::EnergyModel)
```

corresponds to the constraints calculating the fixed operational costs of a transmission mode `tm`.
There is currently only a single implemented version.
It can however be extended, if desirable.

```julia
constraints_opex_var(m, tm::TransmissionMode, 𝒯ᴵⁿᵛ, modeltype::EnergyModel)
```

corresponds to the constraints calculating the variable operational costs of a transmission mode `tm`.
There is currently only a single implemented version.
It can however be extended, if desirable.
