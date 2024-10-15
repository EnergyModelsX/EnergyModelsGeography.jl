# Internal functions

## Index

```@index
Pages = ["functions.md"]
```

```@meta
CurrentModule = EnergyModelsGeography
```

## Extension methods

```@docs
create_area
create_model
create_transmission_mode
update_objective(m, 𝒯, ℳ, modeltype::EnergyModel)
update_total_emissions
```

## Constraint methods

```@docs
constraints_area
constraints_capacity
constraints_capacity_installed(m, tm::TransmissionMode, 𝒯::TimeStructure, modeltype::EnergyModel)
constraints_emission
constraints_opex_fixed
constraints_opex_var
constraints_trans_balance
constraints_trans_loss
constraints_transmission
```

## Compute methods

```@docs
compute_trans_in
compute_trans_out
```

## Variable creation methods

```@docs
variables_area
variables_trans_capacity
variables_trans_capex
variables_trans_emission
variables_trans_modes
variables_trans_mode
variables_trans_opex
```

## Check methods

```@docs
check_area
check_case_data
check_data
check_mode
check_time_structure
check_transmission
```

## Identification methods

```@docs
extract_resources
export_resources
import_resources
has_emissions
emission
emit_resources
is_bidirectional
trans_sub
```