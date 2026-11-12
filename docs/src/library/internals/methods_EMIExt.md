# [Internals - EnergyModelsInvestments extension](@id lib-int-EMIext)

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
EMG.constraints_capacity_installed(m, tm::TransmissionMode, 𝒯::TimeStructure, modeltype::EMB.AbstractInvestmentModel)
```

## [EnergyModelsBase](@id lib-int-EMIext-EMB)

### [Methods](@id lib-int-EMIext-EMB-met)

```@docs
EMB.objective_invest
EMB.variables_ext_data(m, _::Type{SingleInvData}, ℳᴵⁿᵛ::Vector{<:TransmissionMode}, 𝒯, 𝒫, modeltype::AbstractInvestmentModel)
```

## [EnergyModelsInvestments](@id lib-int-EMIext-EMI)

### [Methods](@id lib-int-EMIext-EMI-met)

```@docs
EMI.get_var_inst
EMI.has_investment
EMI.investment_data
```
