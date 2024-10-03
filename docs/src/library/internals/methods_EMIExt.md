# Methods - EnergyModelsInvestment extensions

## Index

```@index
Pages = ["methods_EMIExt.md"]
```

```@meta
CurrentModule =
    Base.get_extension(EMG, :EMIExt)
```

## EnergyModelsGeography

### Methods

```@docs
EMG.update_objective(m, 𝒯, ℳ, modeltype::EMB.AbstractInvestmentModel)
EMG.constraints_capacity_installed(m, tm::TransmissionMode, 𝒯::TimeStructure, modeltype::EMB.AbstractInvestmentModel)
EMG.variables_trans_capex(m, 𝒯, ℳ, modeltype::EMB.AbstractInvestmentModel)
```

## EnergyModelsInvestments

### Methods

```@docs
EMI.get_var_inst
```
