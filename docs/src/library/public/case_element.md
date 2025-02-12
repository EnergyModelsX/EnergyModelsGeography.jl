# [Case description](@id lib-pub-case)

## Index

```@index
Pages = ["case_element.md"]
```

## [Case type](@id lib-pub-case-case)

The incorporation of the [`AbstractElement`](@extref EnergyModelsBase.AbstractElement)s requires a change to the provided input.

The original design of `EnergyModelsBase` when only considering [`Node`](@extref EnergyModelsBase.Node)s and [`Link`](@extref EnergyModelsBase.Link)s is given by:

```julia
case = Case(
    T,
    products,
    [nodes, links],
    [[get_nodes, get_links]],
)
```

Including areas and transmission corridors requires to declare the case as

```julia
case = Case(
    T,
    products,
    [nodes, links, areas, transmissions],
    [[get_nodes, get_links], [get_areas, get_transmissions]],
)
```

that is including the `areas` and `transmissions` vectors in the field `elements` and adding a new vector to the field `couplings` given by the functions to access `areas` and `transmissions` vectors in the field `elements`, `get_areas` and `get_transmissions` as described below

## [Functions for accessing different information](@id lib-pub-links-fun_field)

```@docs
get_areas
get_transmissions
```
