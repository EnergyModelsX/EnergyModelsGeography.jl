# [Transmission modes](@id area_mode-trans_mode)

Transmission modes are introduced to model different approaches for transmission for resources.
These transmission modes are located within a transmission corridor.
In general, transmission modes are designed to only transport a single [`Resource`](@extref EnergyModelsBase.Resource)

```@contents
Pages = [
    "area_mode/mode.md",
    ]
Depth = 2
```

## [Introduced types and their fields](@id area_mode-trans_mode-fields)

`EnergyModelsGeography` provides multiple `TransmissionMode`s that can be introduced in models.
The hierarchy of the individual transmission modes is given by:

```REPL
TransmissionMode
├─ PipeMode
│  ├─ PipeLinepackSimple
│  └─ PipeSimple
├─ RefDynamic
└─ RefStatic
```

The individual modes use in general the same constraint functions and have the same fields with minor variations.
Hence, all transmission modes will be presented below.

The fields of the types are given as:

- **`id`**:\
  The field `id` is only used for providing a name to the transmission mode.
- Transported resource fields:
  - `RefStatic` and `RefDynamic`
    - **`resource::EMB.Resource`** :\
      The field `resource` corresponds to the transported [`Resource`](@extref EnergyModelsBase.Resource).
      The same resource is entering and leaving a transmission mode.
      Hence, pressure drop cannot be considered.
  - [`PipeMode`](@ref); `PipeSimple` and `PipeLinepackSimple`
    - **`inlet::EMB.Resource`** and **`outlet::EMB.Resource`**:\
      The implemented [`PipeMode`](@ref)s allow for a differentiation between the [`Resource`](@extref EnergyModelsBase.Resource) entering a transmission mode and the one leaving.
      This allows the incorporation of a pressure drop, albeit not through pressure drop equations but through a fixed pressure drop.
    - **`consuming::EMB.Resource`** and  **`consumption_rate::TimeProfile`**:
      [`PipeMode`](@ref)s introduce furthermore a consuming [`Resource`](@extref EnergyModelsBase.Resource).
      The `consuming` resource is required to transport the `inlet` resource.
      The proportionality is given by the value provided in the field `consumption_rate`.
    !!! note "New `PipeMode` types"
        Introducing new `PipeMode` types requires you to provide the same fields.
        Alternatively, you have to provide new methods to the functions, `EMB.inputs`, `EMB.outputs`, and `consumption_rate`.
- **`trans_cap::TimeProfile`**:\
  The installed capacity corresponds to the nominal capacity of the transmission mode.
  It is the outlet capacity and not the inlet capacity, that is after the calculation of the loss in the transmission mode.\
  If the node should contain investments through the application of [`EnergyModelsInvestments`](https://energymodelsx.github.io/EnergyModelsInvestments.jl/), it is important to note that you can only use `FixedProfile` or `StrategicProfile` for the capacity, but not `RepresentativeProfile` or `OperationalProfile`.
  In addition, all values have to be non-negative.
- **`trans_loss::TimeProfile`**:\
  The transmission loss is calculated as a ratio of the transported resource.
  It is an absolute ratio, *i.e.*, it is not dependent on the distance of the transmission corridor.
- **`opex_var::TimeProfile`**:\
  The variable operational expenses are based on the capacity utilization through the variable [`:trans_out`](@ref man-opt_var-transmission_mode).
  Hence, it is directly related to the specified `output` ratios.
  The variable operating expenses can be provided as `OperationalProfile` as well.
- **`opex_fixed::TimeProfile`**:\
  The fixed operating expenses are relative to the installed capacity (through the field `trans_cap`) and the chosen duration of a strategic period as outlined on *[Utilize `TimeStruct`](@extref EnergyModelsBase how_to-utilize_TS)*.\
  It is important to note that you can only use `FixedProfile` or `StrategicProfile` for the fixed OPEX, but not `RepresentativeProfile` or `OperationalProfile`.
  In addition, all values have to be non-negative.
- **`data::Vector{<:ExtensionData}`**:\
  An entry for providing additional data to the model.
  In the current version, it is only used for providing additional investment data when [`EnergyModelsInvestments`](https://energymodelsx.github.io/EnergyModelsInvestments.jl/) is used.
  !!! note
      The field `data` is not required as we include a constructor when the value is excluded.

[`PipeLinepackSimple`](@ref) transmission modes also introduce an additional field:

- **`energy_share:Float64`**:\
  The energy share is a value corresponding to the amount of a resource that can be stored within a [`PipeLinepackSimple`](@ref) transmission mode.
  It is a relative ratio corresponding to the maximum amount of a [`Resource`](@extref EnergyModelsBase.Resource) that can be stored within a pipeline.
  If you have, *e.g.*, a hydrogen pipeline of 13 GW and have the potential to store in this pipeline 13 GWh through linepacking, then you have to provide a value of 1 GWh/GW.

The types [`RefStatic`](@ref) and [`RefDynamic`](@ref) have furthermore the following field:

- **`directions::Int`**:\
  The direction value decides whether only unidirectional (1) or bidirectional (2) transport is allowed for the transmission mode.

!!! tip "Order of the fields"
    The order of the individual fields can be best found in the library, [`RefStatic`](@ref), [`RefDynamic`](@ref), [`PipeSimple`](@ref), and [`PipeLinepackSimple`](@ref).

## [Mathematical description](@id area_mode-trans_mode-math)

In the following mathematical equations, we use the name for variables and functions used in the model.
Variables are in general represented as

``\texttt{var\_example}[index_1, index_2]``

with square brackets, while functions are represented as

``func\_example(index_1, index_2)``

with paranthesis.

### [Variables](@id area_mode-trans_mode-math-var)

The variables of all transmission modes are described on *[optimization variables](@ref man-opt_var-transmission_mode)* and include:

- ``\texttt{trans\_opex\_var}`` if the transmission mode has a method returning `true` for the function [`EnergyModelsBase.has_opex`](@ref). By default, all transmission modes include the variable.
- ``\texttt{trans\_opex\_fixed}`` if the transmission mode has a method returning `true` for the function [`EnergyModelsBase.has_opex`](@ref). By default, all transmission modes include the variable.
- ``\texttt{trans\_cap}``
- ``\texttt{trans\_in}``
- ``\texttt{trans\_out}``
- ``\texttt{trans\_loss}``
- ``\texttt{emissions\_trans}`` if the transmission mode has a method returning `true` for the function [`EnergyModelsBase.has_emissions`](@ref). By default, no transmission mode includes the variable.

[`PipeLinepackSimple`](@ref) transmission modes include furthermore:

- ``\texttt{linepack\_stor\_level}``

Bidirectional transmission modes include furthermore:

- ``\texttt{trans\_neg}``
- ``\texttt{trans\_pos}``

### [Constraints](@id area_mode-trans_mode-math-con)

A qualitative overview of the individual constraints can be found on *[Constraint functions](@ref man-con)*.
This section focuses instead on the mathematical description of the individual constraints.
It omits the direct inclusion of the vector of transmission modes.
Instead, it is implicitly assumed that the constraints are valid ``\forall tm ∈ M`` for all [`TransmissionMode`](@ref) types if not stated differently.
In addition, all constraints are valid ``\forall t \in T`` (that is in all operational periods) or ``\forall t_{inv} \in T^{Inv}`` (that is in all strategic periods).

The following standard constraints are implemented for a [`TransmissionMode`](@ref) node.

- `constraints_capacity`:

  Unidirectional transport constrains the outlet flow to the provided capacity while simultaneously introduce lower bounds of 0 on both ``\texttt{trans\_out}`` and ``\texttt{trans\_in}``:

  ```math
  \texttt{trans\_out}[tm, t] \leq \texttt{trans\_cap}[tm, t]
  ```

  Bidirectional transport constrains both the inlet and outlet flow to the provided capacity:

  ```math
  \begin{aligned}
  \texttt{trans\_in}[tm, t] & \geq -\texttt{trans\_cap}[tm, t] \\
  \texttt{trans\_out}[tm, t] & \leq \texttt{trans\_cap}[tm, t]
  \end{aligned}
  ```

  [`PipeLinepackSimple`](@ref) transmission modes employ the same constraints as unidirectional transport, but require further constraints for the loss calculation and the storage balance:

  ```math
  \begin{aligned}
  \texttt{trans\_in}[tm, t]  & \leq \texttt{trans\_cap}[tm, t] + \texttt{trans\_loss}[tm, t] \\
  \texttt{trans\_out}[tm, t] & \leq \texttt{trans\_cap}[tm, t] \\
  \texttt{linepack\_stor\_level}[tm, t] & \leq \texttt{trans\_cap}[tm, t] \times energy\_share(tm) \\
  \end{aligned}
  ```

- `constraints_capacity_installed`:

  ```math
  \texttt{trans\_cap}[tm, t] = capacity(tm, t)
  ```

  !!! tip "Using investments"
      The function `constraints_capacity_installed` is also used in [`EnergyModelsInvestments`](https://energymodelsx.github.io/EnergyModelsInvestments.jl/) to incorporate the potential for investment.
      Nodes with investments are then no longer constrained by the parameter capacity.

- `constraints_trans_loss`:

  Unidirectional transport calculates the loss as a fraction of the inlet:

  ```math
  \texttt{trans\_loss}[tm, t] = loss(tm, t) \times \texttt{trans\_in}[tm, t]
  ```

  Bidirectional transport calculates the loss as a fraction of the positive and negative contributions:

  ```math
  \texttt{trans\_loss}[tm, t] = loss(tm, t) \times \left(\texttt{trans\_pos}[tm, t] + \texttt{trans\_neg}[tm, t]\right)
  ```

  which are in turn calculated as:

  ```math
  \texttt{trans\_pos}[tm, t] - \texttt{trans\_neg}[tm, t] = 0.5 \times
  \left(\texttt{trans\_in}[tm, t] + \texttt{trans\_out}[tm, t]\right)
  ```

  !!! todo "Loss calculations"
      It looks to me that the loss calculations are not equivalent.
      We have to change that.

- `constraints_trans_balance`:

  The overall transport balance is then given as:

  ```math
  \texttt{trans\_out}[tm, t] = \texttt{trans\_in}[tm, t] - \texttt{trans\_loss}[tm, t]
  ```

  [`PipeLinepackSimple`](@ref) uses a different approach which will be revisited as it does not support a time structure including operational scenarios or representative periods.
  Hence, it will not be included in the documentation.
  If you are interested in the mathematical formulation, feel free to look at the function
  [`constraints_trans_balance`](@ref EnergyModelsGeography.constraints_trans_balance).

- `constraints_opex_fixed`:

  ```math
  \texttt{trans\_opex\_fixed}[tm, t_{inv}] = opex\_fixed(tm, t_{inv}) \times \texttt{trans\_cap}[tm, first(t_{inv})]
  ```

  !!! tip "Why do we use `first()`"
      The variable ``\texttt{trans\_cap}`` is declared over all operational periods (see the *[variable section](@ref man-opt_var-transmission_mode)* for further explanations).
      Hence, we use the function ``first(t_{inv})`` to retrieve the installed capacity in the first operational period of a given strategic period ``t_{inv}`` in the function `constraints_opex_fixed`.

- `constraints_opex_var`:

  Unidirectional transport calculates the variable operating expenses as a fraction of the outlet flow:

  ```math
  \begin{aligned}
  \texttt{trans\_opex\_var}[tm, t_{inv}] = \sum_{t \in t_{inv}} & opex\_var(tm, t) \times \\ &
  \texttt{trans\_out}[tm, t] \times \\ &
  scale\_op\_sp(t_{inv}, t)
  \end{aligned}
  ```

  while bidirectional transport utilize again the variables ``\texttt{trans\_pos}[tm, t]`` and ``\texttt{trans\_neg}[tm, t]`` as introduced above:

  ```math
  \begin{aligned}
  \texttt{trans\_opex\_var}[tm, t_{inv}] = \sum_{t \in t_{inv}} & opex\_var(tm, t) \times \\ &
  \left(\texttt{trans\_pos}[tm, t] + \texttt{trans\_neg}[tm, t]\right) \times \\ &
  scale\_op\_sp(t_{inv}, t)
  \end{aligned}
  ```

  !!! tip "The function `scale_op_sp`"
      The function [``scale\_op\_sp(t_{inv}, t)``](@extref EnergyModelsBase.scale_op_sp) calculates the scaling factor between operational and strategic periods.
      It also takes into account potential operational scenarios and their probability as well as representative periods.

- `constraints_emissions`:

  Unidirectional transport calculates the emissions of the resourecs ``p_{em} \in emit\_resources(tm)`` as a fraction of the outlet flow:

  ```math
  \texttt{emissions\_trans}[tm, t, p_{em}] = emissions(tm, p_{em}, t) \times \texttt{trans\_out}[tm, t]
  ```

  while bidirectional transport utilize again the variables ``\texttt{trans\_pos}[tm, t]`` and ``\texttt{trans\_neg}[tm, t]`` as introduced above:

  ```math
  \texttt{emissions\_trans}[tm, t, p_{em}] = emissions(tm, p_{em}, t) \times \left(\texttt{trans\_pos}[tm, t] + \texttt{trans\_neg}[tm, t]\right)
  ```
