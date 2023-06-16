# [Constraint functions](@id constraint_functions)

The package provides standard constraint functions that can be use for new developed nodes.
The general approach is similar to `EnergyModelsBase`.
Bidirectional transport requires at the time being the introduciton of an *if*-loop.
In later implementation, it is planned to also use dispatch for this analysis as well.

## Capacity constraints

```julia
constraints_capacity(m, tm::TransmissionMode, 𝒯::TimeStructure)
```

correponds to the constraints on the capacity usage of a transmission mode ``tm``.
It is implemented for both the `TransmissionMode`, `PipeMode` and `PipeLinepackSimple` abstract types.
The key difference between the former two is related that `PipeMode` does not allows for bidirectional transport.
`PipeLinepackSimple` includes in addition the maximum storage capacity for a pipeline when considering linepacking.
The implementation is still preliminary and based on a simplified potential for energy storage in a pipeline.

## Transmission loss functions

```julia
constraints_trans_loss(m, tm::TransmissionMode, 𝒯ᴵⁿᵛ)
```

correponds to the constraints on the energy balance of a transmission mode ``tm``.
It is implemented for both the `TransmissionMode` and `PipeMode` abstract types.
The key difference between the two is related that `PipeMode` does not allows for bidirectional transport.
The loss are calculated as relative loss of the transported energy.

## Balance functions

```julia
constraints_trans_balance(m, tm::TransmissionMode, 𝒯ᴵⁿᵛ)
```

correponds to the constraints on the energy balance of a transmission mode ``tm``.
It is implemented for both the `TransmissionMode` and `PipeLinepackSimple` abstract types.
The standard approach 
`PipeLinePackSimple` also includes the overall mass balance for the energy storage within the pipeline.

## Operational cost constraints

```julia
constraints_opex_fixed(m, tm::TransmissionMode, 𝒯ᴵⁿᵛ)
```

corresponds to the constraints calculating the fixed operational costs of a transmission mode `tm`.
There is currently only a single implemented version.
It can however be extended, if desirable.

```julia
constraints_opex_var(m, tm::TransmissionMode, 𝒯ᴵⁿᵛ)
```

corresponds to the constraints calculating the variable operational costs of a transmission mode `tm`.
There is currently only a single implemented version.
It can however be extended, if desirable.
