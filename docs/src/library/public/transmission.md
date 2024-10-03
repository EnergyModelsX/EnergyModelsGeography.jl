# [`Transmission`](@id lib-pub-transmission)

`Transmission` occurs on specified transmission corridors `from` one area `to` another. On each corridor, there can exist several `TransmissionMode`s that are transporting resources using a range of technologies.

It is important to consider the `from` and `to` `Area` when specifying a `Transmission` corridor.
The chosen direction has an influence on whether the variables ``\texttt{trans\_in}[m, t]`` and ``\texttt{trans\_out}[m, t]`` are positive or negative for exports in the case of bidirectional transport.
This is also explained on the page *[Optimization variables](@ref man-opt_var)*.

## [`Transmission` types](@id lib-pub-transmission-types)

```@docs
Transmission
```

## [Functions for accessing fields of `Transmission` types](@id lib-pub-transmission-fun_fields)

The following functions are defined for accessing fields from a `Transmission` as well as finding a subset of `Transmission` corridors:

```@docs
modes
modes_sub
corr_from
corr_to
corr_from_to
modes_of_dir
```
