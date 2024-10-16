# [Optimization variables](@id man-opt_var)

`EnergyModelsGeography` adds additional variables to `EnergyModelsBase`.
These variables are required for being able to extend the model with geographic information.
The additional variables can be differentiated between `Area` variables and `TransmissionMode` variables.

!!! note
    As it is the case in `EnergyModelsBase`, we define almost exclusively rate variables in `EnergyModelsGeography`.
    Variables that are energy/mass based have that property highlighted in the documentation below.
    This is only the case for the storage level in a `PipeLinepackSimple`.

## [`Area`](@id man-opt_var-area)

`Area`s create only a single additional variable:

- ``\texttt{area\_exchange}[a, t, p_{ex}]``: Exchange of energy/mass from area ``a`` in operational period ``t`` for exchange resource ``p_\texttt{ex}``.

The area exchange is defined for all areas for resources that area can exchange with other areas.
This also includes also potential `Transmission` corridors in which the model can invest in.
The exchange resources are automatically deduced from the coupled `TransmissionMode`s.
The area exchange is negative when exporting energy/mass and positive when importing.
This implies that for ``\texttt{area\_exchange}[a, t, p_\texttt{ex}] > 0``, the area imports product ``p_\texttt{ex}``, and for ``\texttt{area\_exchange}[a, t, p_\texttt{ex}] < 0``, the area exports product ``p_\texttt{ex}``.

## [`TransmissionMode`](@id man-opt_var-transmission_mode)

!!! warning "'Inheritance' of optimization variables"
    Note that for all subtypes of [`TransmissionMode`](@ref) the variables created for the parent `TransmissionMode`-type will be created, in addition to the variables created for that type.

    This means that the type [`PipeLinepackSimple`](@ref) will not only have access to the optimization variable ``\texttt{linepack\_stor\_level}[m, t]``, but also all the optimization variables created for [`TransmissionMode`](@ref).

### [General variables for all `TransmissionMode`](@id man-opt_var-transmission_mode-gen)

All variables described in this section are included for all subtypes of [`TransmissionMode`](@ref).
In general, we can differentiate between capacity variables, flow variables, cost variables, and helper variables.

- ``\texttt{trans\_cap}[m, t]``: Transmission capacity of transmission mode ``m`` in operational period ``t``.

is the single capacity variable that is considered in the case of `TransmissionMode`s.

- ``\texttt{trans\_in}[m, t]``: Flow **into** the transmission mode ``m``, given by the `from` field in the [`Transmission`](@ref) corridor in operational period ``t``,
- ``\texttt{trans\_out}[m, t]``: Flow **out** of transmission mode ``m``, given by the `to` field in the [`Transmission`](@ref) corridor in operational period ``t``, and
- ``\texttt{trans\_loss}[m, t]``: Loss of transmission mode ``m`` in operational period ``t``,

are the three flow variables.
The loss is in practice not a flow variable, but can be considered as equivalent.

`TransmissionMode`s can also have operational costs.
We differentiate between variables and fixed operational costs (OPEX) as it is the case in `EnergyModelsBase`:

- ``\texttt{trans\_opex\_var}[m, t_\texttt{inv}]``: Variable OPEX of transmission mode ``m`` in strategic period ``t_\texttt{inv}`` and
- ``\texttt{trans\_opex\_fixed}[m, t_\texttt{inv}]``: Fixed OPEX of transmission mode ``m`` in strategic period ``t_\texttt{inv}``.

The definitions of both fixed and variable operational cost are similar to the definitions for `Node`s in `EnergyModelsBase`.

Bidirectional flow requires the introduction of helper variables for proper calculation of both the loss and the variable OPEX.
The following variables are hence created in addition, if bidirectional flow is allowed.

- ``\texttt{trans\_pos}[m, t]``: Flow of transmission mode ``m`` in operational period ``t`` in the **positive** direction,
- ``\texttt{trans\_neg}[m, t]``: Flow of transmission mode ``m`` in operational period ``t`` in the **negative** direction.

In addition, both ``\texttt{trans\_in}[m, t]`` and ``\texttt{trans\_out}[m, t]`` can in this situation be both positive or negative.

!!! note
    The direction of a `Transmission` corridor has an impact on whether the variables are positive or negative for export from a given `Area` as well as whether ``\texttt{trans\_in}[m, t]`` or ``\texttt{trans\_out}[m, t]`` corresponds to the inlet/outlet flow rate of a `TransmissionMode`.

    If the energy/mass is transported **in the direction** of the `Transmission` corridor, then both variables are positive and ``\texttt{trans\_in}[m, t]`` corresponds to the **inlet** to the `TransmissionMode`.

    If the energy/mass is transported  **opposite to the direction** of the `Transmission` corridor, then both variables are negative and ``\texttt{trans\_in}[m, t]`` corresponds to the **outlet** to the `TransmissionMode`.

### [[`PipeLinepackSimple`](@ref) <: `Pipeline` <: `TransmissionMode`](@id man-opt_var-transmission_mode-linepack)

`PipeLinepackSimple` adds one additional variable:

- ``\texttt{linepack\_stor\_level}[m, t]``: the storage level in the pipeline ``m`` in operational period ``t``.

Contrary to a `Storage` node, we do not add a storage capacity or rate for the simple implementation of linepacking.
In fact, storing gases through line packing is a fundamental property of the pipeline, influenced by the pipeline diameter and the properties of the stored gas.
Hence, it cannot be considered that the capacity and rate of storage are independent of each other.
