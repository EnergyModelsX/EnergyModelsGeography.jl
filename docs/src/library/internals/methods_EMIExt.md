# [Internals - EnergyModelsInvestment extension](@id lib-int-EMIext)

## [Index](@id lib-int-EMIext-idx)

```@index
Pages = ["methods_EMIExt.md"]
```

```@meta
CurrentModule =
    Base.get_extension(EMG, :EMIExt)
```

## [EnergyModelsGeography](@id lib-int-EMIext-EMG)

### [Methods](@id lib-int-EMIext-EMG-met)

```@docs
EMG.update_objective(m, 𝒯, ℳ, modeltype::EMB.AbstractInvestmentModel)
EMG.constraints_capacity_installed(m, tm::TransmissionMode, 𝒯::TimeStructure, modeltype::EMB.AbstractInvestmentModel)
EMG.variables_trans_capex(m, 𝒯, ℳ, modeltype::EMB.AbstractInvestmentModel)
```

## [EnergyModelsInvestments](@id lib-int-EMIext-EMI)

### [Methods](@id lib-int-EMIext-met)

```@docs
EMI.get_var_inst
EMI.has_investment
EMI.investment_data
```
