# [Adding investments](@id man-emi)

Investment options are added through loading the package [`EnergyModelsInvestments`](https://energymodelsx.github.io/EnergyModelsInvestments.jl/).
`EnergyModelsInvestments` was previously seen as extension package to `EnergyModelsBase`, that it was dependent on `EnergyModelsBase` and only allowed investment options in `EnergyModelsBase`.
This approach was reversed from version 0.7 onwards and `EnergyModelsInvestments` is now a standalone package and provides an extension to `EnergyModelsBase`.

As a consequence, it was not also necessary to move the `EnergyModelsGeography` extension of `EnergyModelsInvestments` to an `EnergyModelsInvestments` extension of `EnergyModelsGeography`.

## [General concept](@id man-emi-gen)

Investment options are added separately to each individual transmission mode through the field `data`.
This is similar to the approach used in
Hence, it is possible to use different prices for the same technology in different regions or allow investments only in a limited subset of technologies.

Transmission mode investments utilize the same data type [`SingleInvData`] as the majority of the node investments.
This type inludes as fields [`AbstractInvData`](@extref EnergyModelsInvestments.AbstractInvData) which can be either in the form of [`StartInvData`](@extref EnergyModelsInvestments.StartInvData) or [`NoStartInvData`](@extref EnergyModelsInvestments.NoStartInvData).
The exact description of the individual investment data and their fields can be found in the *[public library]* of `EnergyModelsInvestments`.

Investments require the application of an [`InvestmentModel`](@extref) instead of an [`OperationalModel`](@extref EnergyModelsBase.OperationalModel).
This allows us to provide two core functions with new methods, `constraints_capacity_installed` (as described on *[Constraint functions]*), `variables_trans_capex`, a function previously not declaring any variables, and the update to the objective functoin `update_objective`.

## [Added variables](@id man-emi-var)

Investment options increase the number of variables.
The individual variables are described in the *[documentation of `EnergyModelsInvestments`]*.

All transmission modes with investments use the prefix `:trans`.
