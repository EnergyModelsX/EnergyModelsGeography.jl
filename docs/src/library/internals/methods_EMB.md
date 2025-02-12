# [Methods - `EnergyModelsBase`](@id lib-int-met_emb)

## [Index](@id lib-int-met_emb-idx)

```@index
Pages = ["methods_EMB.md"]
```

## [Extension methods](@id lib-int-met_emb-ext)

```@docs
EMB.create_node
EMB.objective_operational
EMB.emissions_operational
EMB.constraints_elements
EMB.constraints_couple
```

## [Variable methods](@id lib-int-met_emb-var)

```@docs
EMB.variables_capacity
EMB.variables_flow
EMB.variables_opex
EMB.variables_capex(m, ℒᵗʳᵃⁿˢ::Vector{Transmission}, 𝒳, 𝒯, modeltype::EnergyModel)
EMB.variables_elements
EMB.variables_element
EMB.variables_emission
```

## [Field extraction methods](@id lib-int-met_emb-field)

```@docs
EMB.capacity
EMB.inputs
EMB.outputs
EMB.opex_fixed
EMB.opex_var
```

## [Check methods](@id lib-int-fun-check)

```@docs
EMB.check_elements
EMB.check_time_structure
```
