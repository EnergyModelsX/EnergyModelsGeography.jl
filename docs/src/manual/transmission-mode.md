# TransmissionModes

```julia
julia> using EnergyModelsGeography
julia> const EMG = EnergyModelsGeography 
julia> using AbstractTrees
julia> AbstractTrees.children(x::Type) = subtypes(x)

julia> print_tree(EMG.TransmissionMode)
```

```
TransmissionMode
├─ PipeMode
│  ├─ PipeLinepackSimple
│  └─ PipeSimple
├─ RefDynamic
└─ RefStatic
```

The leaf nodes of the above type hierarchy tree are `struct`s, while the inner
vertices are `abstract type`s.
The individual nodes and their fields are explained in [the public library]((@ref sec_lib_public)).
