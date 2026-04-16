# [`EnergymodelsInvestments` extensions](@id lib-pub-emi_ext)

`EnergyModelsGeography` requires significantly less direct interaction with `EnergyModelsInvestments` compared to `EnergyModelsBase`.
In practice, we only provide a legacy constructor.
All other functionality is handled within the internal functions.

## [Investment data](@id lib-pub-emi_ext-inv_data)

### [`InvestmentData` types](@id lib-pub-emi_ext-inv_data-types)

Transmission mode investments utilize the same investment data type ([`SingleInvData`](@extref EnergyModelsBase.SingleInvData)) as investments in node capacities.

### [Legacy constructors](@id lib-pub-emi_ext-inv_data-leg)

We provided a legacy constructor, `TransInvData`, that uses the same input as in version 0.5.x.
This legacy constructor was removed starting in version 0.12.

This implies you must adjust your model if you still utilize the for version.
The adjustment is explained in the section *[Update your model to the latest version of EnergyModelsInvestments](@extref EnergyModelsInvestments how_to-update-05)*.
