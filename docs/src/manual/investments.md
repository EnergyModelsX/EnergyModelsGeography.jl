# [Adding investments](@id man-emi)

Investment options are added through loading the package [`EnergyModelsInvestments`](https://energymodelsx.github.io/EnergyModelsInvestments.jl/).
`EnergyModelsInvestments` was previously seen as an extension package to `EnergyModelsBase`, that is, it was dependent on `EnergyModelsBase` and only allowed investment options in `EnergyModelsBase`.
This approach was reversed from version 0.7 onwards and `EnergyModelsInvestments` is now a standalone package and provides an extension to `EnergyModelsBase`.

As a consequence, it was also necessary to move the `EnergyModelsGeography` extension of `EnergyModelsInvestments` to an `EnergyModelsInvestments` extension of `EnergyModelsGeography`.

## [General concept](@id man-emi-gen)

Investment options are added separately to each individual transmission mode through the field `data`.
This is similar to the approach used in `EnergyModelsBase` for nodes.
Hence, it is possible to use different prices for the same technology in different regions or allow investments only in a limited subset of technologies.

Transmission mode investments utilize the same data type [`SingleInvData`](@extref EnergyModelsBase.SingleInvData) as the majority of the node investments.
This type includes as fields [`AbstractInvData`](@extref EnergyModelsInvestments.AbstractInvData) which can be either in the form of [`StartInvData`](@extref EnergyModelsInvestments.StartInvData) or [`NoStartInvData`](@extref EnergyModelsInvestments.NoStartInvData).
The exact description of the individual investment data and their fields can be found in the *[public library](@extref EnergyModelsInvestments lib-pub)* of `EnergyModelsInvestments`.

Investments require the application of an [`InvestmentModel`](@extref EnergyModelsBase.InvestmentModel) instead of an [`OperationalModel`](@extref EnergyModelsBase.OperationalModel).
The extension provides new methods for three functions:

- `constraints_capacity_installed` (as described on *[Constraint functions](@ref man-con)*) adds the investment constraints,
- `EMB.variables_ext_data` declares the investment variables for transmission modes with `SingleInvData`, and
- `EMB.objective_invest` adds the capital expenditures of the transmission modes to the objective function.

## [Added variables](@id man-emi-var)

Investment options increase the number of variables.
The individual variables are described in the *[documentation of `EnergyModelsInvestments`](@extref EnergyModelsInvestments man-opt_var)*.

All transmission modes with investments use the prefix `:trans_cap`.
The installed capacity is given by the variable ``\texttt{trans\_cap}`` instead of a variable with the suffix `_inst`.
