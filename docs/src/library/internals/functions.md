# [Internal functions](@id lib-int-fun)

## [Index](@id lib-int-fun-idx)

```@index
Pages = ["functions.md"]
```

```@meta
CurrentModule = EnergyModelsGeography
```

## [Extension functions](@id lib-int-fun-ext)

```@docs
create_area
create_model
create_transmission_mode
```

## [Constraint functions](@id lib-int-fun-con)

```@docs
constraints_capacity
constraints_capacity_installed(m, tm::TransmissionMode, 𝒯::TimeStructure, modeltype::EnergyModel)
constraints_emission
constraints_opex_fixed
constraints_opex_var
constraints_trans_balance
constraints_trans_loss
```

## [Compute functions](@id lib-int-fun-comp)

```@docs
compute_trans_in
compute_trans_out
```

## [Variable creation functions](@id lib-int-fun-var)

```@docs
variables_trans_mode
```

## [Check functions](@id lib-int-fun-check)

```@docs
check_area
check_transmission
check_mode
check_mode_default
```

## [Identification functions](@id lib-int-fun-identi)

```@docs
extract_resources
export_resources
import_resources
emit_resources
emissions
is_bidirectional
trans_sub
```

## [Utility functions](@id lib-int-fun-util)

```@docs
connected_nodes
```
