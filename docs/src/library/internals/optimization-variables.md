# [Optimization variables](@id optimization_variables)

## [`Area`](@ref)

 -  ``\texttt{:area\_exchange}[a, t, p]``: Keeps track of the amount of resource
    ``p`` that has been exported from or imported into area ``a``.

The sign convention is as follows: for ``\texttt{:area\_exchange}[a, t, p] > 0``, the area imports product ``p``, and for ``\texttt{:area\_exchange}[a, t, p] < 0``, the area exports product ``p``.

## [`TransmissionMode`](@ref)

!!! note "'Inheritance' of optimization variables"
    **NB:** Note that for all subtypes of [`TransmissionMode`](@ref) the
    variables created for the parent `TransmissionMode`-type will be created, in
    addition to the variables created for that type.

    This means that the type [`PipeLinepackSimple`](@ref) will not only have
    access to the optimization variable `:linepack_stor_level`, but also all the
    optimization variables created for [`TransmissionMode`](@ref).

### General

All subtypes of [`TransmissionMode`](@ref) have the following variables available:

- ``\texttt{:trans\_cap}[m, t]``: Transmission capacity of the transmission mode ``m``,
- ``\texttt{:trans\_in}[m, t]``: Transmitted **into** the transmission mode (powerline/pipeline etc.), given by the `from` field in the [`Transmission`](@ref) corridor,
- ``\texttt{:trans\_out}[m, t]``: Transmitted **out** of the transmission mode (powerline/pipeline etc.), given by the `to` field in the [`Transmission`](@ref) corridor,
- ``\texttt{:trans\_loss}[m, t]``: Transmission loss,

The following variables are created in addition, if bidirectional flow is allowed.

- ``\texttt{:trans\_pos}[m, t]``: Transmitted in the positive direction,
- ``\texttt{:trans\_neg}[m, t]``: Transmitted in the negative direction.

In addition, ``\texttt{:trans\_in}[m, t]`` and ``\texttt{:trans\_out}[m, t]`` can in this situation be both positive or negative.

### Opex variables

- ``\texttt{:trans\_opex\_var}[m, t]``: Variable OPEX for a transmission mode,
- ``\texttt{:trans\_opex\_fixed}[m, t]``: Fixed OPEX for a transmission mode.

### [`PipeLinepackSimple`](@ref) <: `Pipeline` <: `TransmissionMode`

- ``\texttt{:linepack\_stor\_level}[m, t]``: the storage level in the pipeline ``m`` at time ``t``.
