# TransmissionModes

The overall structure of the individual `TransmissionMode`s can be printed to the REPL using the following code:

```julia
julia> using EnergyModelsGeography
julia> const EMG = EnergyModelsGeography
julia> using AbstractTrees
julia> AbstractTrees.children(x::Type) = subtypes(x)

julia> print_tree(EMG.TransmissionMode)
```

```REPL
TransmissionMode
├─ PipeMode
│  ├─ PipeLinepackSimple
│  └─ PipeSimple
├─ RefDynamic
└─ RefStatic
```

The leaf `TransmissionMode`s of the above type hierarchy tree are `composite type`s, while the inner
vertices are `abstract type`s.
The individual `TransmissionMode` and their fields are explained in *[the public library](@ref sec_lib_public)*.
