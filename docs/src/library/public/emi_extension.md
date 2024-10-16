# [`EnergymodelsInvestments` extensions](@id lib-pub-emi_ext)

`EnergyModelsGeography` requires significantly less direct interaction with `EnergyModelsInvestments` compared to `EnergyModelsBase`.
In practice, we only provide a legacy constructor.
All other functionality is handled within the internal functions.

## [Investment data](@id lib-pub-emi_ext-inv_data)

### [`InvestmentData` types](@id lib-pub-emi_ext-inv_data-types)

Transmission mode investments utilize the same investment data type ([`SingleInvData`](@extref EnergyModelsBase.SingleInvData)) as investments in node capacities.

### [Legacy constructors](@id lib-pub-emi_ext-inv_data-leg)

We provide a legacy constructor, `TransInvData`, that uses the same input as in version 0.5.x.
If you want to adjust your model to the latest changes, please refer to the section *[Update your model to the latest version of EnergyModelsInvestments](@extref EnergyModelsInvestments how_to-update-05)*.

```@docs
TransInvData
```
