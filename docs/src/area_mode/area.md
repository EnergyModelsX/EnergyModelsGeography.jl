# [Areas](@id area_mode-areas)

The concept of areas is introduced in `EnergyModelsGeography` to create energy systems with transmission between individual regions.
As outlined in the *[philosophy section](@ref man-phil)*, each `Area` can have a different local energy system with different units, CAPEX calculation approaches, and demands.

This page explains the fields of areas more specifically and introduces the different variables.

```@contents
Pages = [
    "area_mode/area.md",
    ]
Depth = 2
```

## [Area](@id area_mode-areas-areas)

### [Introduced types and their fields](@id area_mode-areas-areas-fields)

`EnergyModelsGeography` introduces two different areas, [`RefArea`](@ref) and [`LimitedExchangeArea`](@ref).
Both types include the following fields:

- **`id`**:\
  The field `id` is only used to provide an identifier for the area.
  This identifier can be a shortened version of the area name.
- **`name`**:\
  The name of the `area` is used for printing an area to the Julia REPL, and hence, saving of variables.
  it can be only used as string input for the functions [`corr_from`](@ref), [`corr_to`](@ref), and [`corr_from_to`](@ref).
- **`lon::Real`**:\
  The longitudinal position of the area is not directly used in `EnergyModelsGeography`.
  It is however possible for the user to provide additional functions which can utilize the longitude for distance calculations.
- **`lat::Real`**:\
  The latitudinal position of the area is not directly used in `EnergyModelsGeography`.
  It is however possible for the user to provide additional functions which can utilize the latitude for distance calculations.
- **`node::Availability`**:\
  The field `node` correspond to the `Availability` node of the `Area` that is utilized for exchanging resources with other areas.
  !!! danger "Nodal type:
  It must by a [`GeoAvailability`](@ref) (or comparable nodes in which the energy balance is not calculated in the `create_node` function) as otherwise no energy transmission between this area and other areas is possible.

  We decided to not limit it directly to `GeoAvailability` to allow the user to introduce other types of `Availability` nodes with potentially additional variables and constraints.
  It is however important to not calculate the energy balance within the `Availability` node.

[`LimitedExchangeArea`](@ref) require an additional field:

- **`limit::Dict{<:EMB.Resource, <:TimeProfile}`**:\
  The exchange limit is the maximum amount of a resource that can be exported to other areas in each operational period.
  It is still possible to import from other regions, but the overall net export can not exceed the provided value.

### [Mathematical description](@id area_mode-areas-areas-math)

In the following mathematical equations, we use the name for variables and functions used in the model.
Variables are in general represented as

``\texttt{var\_example}[index_1, index_2]``

with square brackets, while functions are represented as

``func\_example(index_1, index_2)``

with paranthesis.

In addition, we simplify the description as:

- ``n = availability\_node(a)``\
  corresponds to the availability node ``n`` in the area ``a``.
- ``P^{ex} = exchange\_resources(L^{trans}, a)``\
  correspond to the exchange resources ``P^{ex}`` of the area ``a``, that is all resources that are either consumed in energy transmission or exchanged with connected areas.
- ``L^{from}, L^{to} = trans\_sub (L^{trans}, a)``\
  are all transmission corridors that are either originating (superscript *from*) or ending (superscript *to*) in the area ``a``.

#### [Variables](@id area_mode-areas-areas-math-var)

The variables of [`Area`](@ref)s include:

- [``\texttt{area\_exchange}[a, t, p_{ex}]``](@ref man-opt_var-area)

#### [Constraints](@id area_mode-areas-areas-math-con)

The constraints for areas are calculated within the functions [`constraints_area`](@ref EnergyModelsGeography.constraints_area) and [`create_area`](@ref EnergyModelsGeography.create_area).
The function [`constraints_area`](@ref EnergyModelsGeography.constraints_area) is the core function as it links the transmission to and from an area with a local energy system while the function [`create_area`](@ref EnergyModelsGeography.create_area) allows for providing additional constraints.

##### [`constraints_area`](@id area_mode-areas-areas-math-con-con)

The overall energy balance is solved within this function.
We consider two cases:

- The resource is not an exchange resource:

  ```math
  \texttt{flow\_out}[n, t, p] = \texttt{flow\_in}[n, t, p] \qquad \forall p \in inputs(n)  \setminus P^{ex}
  ```

- The resource is an exchange resource:

  ```math
  \texttt{flow\_out}[n, t, p_{ex}] = \texttt{flow\_in}[n, t, p_{ex}] + \texttt{area\_exchange}[a, t, p_{ex}] \qquad \forall p_{ex} \in P^{ex}
  ```

In addition, we have to add constraints for the variable ``\texttt{area\_exchange}[a, t, p_{ex}]``.
This is achieved through the *compute* functions as

```math
\begin{aligned}
\texttt{area\_exchange}[a, t, p_{ex}] + & \sum_{tm \in L^{from}} compute\_trans\_in(t, p_{ex}, tm) = \\
& \sum_{tm \in L^{to}} compute\_trans\_out(t, p_{ex}, tm)
\end{aligned}
```

##### [`create_area`](@id area_mode-areas-areas-math-con-crea)

The [`RefArea`](@ref) does not introduce additional constraints.

The [`LimitedExchangeArea`](@ref) introduces additional constraints on the net export from the area.
This constraint is given by

```math
\texttt{area\_exchange}[a, t, p] \geq - exchange\_limit(a, p, t) \qquad \forall p \in limit\_resources(a)
```

## [GeoAvailability](@id area_mode-areas-availability)

The [`GeoAvailability`](@ref) node is introduced to allow the energy balance of an area being handled on the [`Area`](@ref) level.
It is in itself equivalent to the to [`GenAvailability`](@extref EnergyModelsBase.GenAvailability) node with respect to introduced fields and variables.
*[Availability node]* provides a detailed description of availability nodes.

!!! warning "Energy exchange"
    All energy exchange between different areas is routed through a [`GeoAvailability`](@ref) node.
    If you do not use a [`GeoAvailability`](@ref) node (*e.g.*, a [`GenAvailability`](@extref EnergyModelsBase.GenAvailability) node or no availability node at all), you will not have energy transmission between different regions.

### [Introduced types and their fields](@id area_mode-areas-availability-fields)

The [`GeoAvailability`](@ref) node is similar to a [`GenAvailability`](@extref EnergyModelsBase.GenAvailability).
It includes basic functionalities common to most energy system optimization models.

The fields of a [`GeoAvailability`](@ref) node are given as:

- **`id`**:\
  The field `id` is only used for providing a name to the node.
- **`input::Vector{<:Resource}`** and **`output::Vector{<:Resource}`**:\
  Both fields describe the `input` and `output` [`Resource`](@extref EnergyModelsBase.Resource)s as vectors.
  This approach is different to all other nodes, but simplifies the overall design.
  It is necessary to specify the same [`Resource`](@extref EnergyModelsBase.Resource)s to allow for capacity usage in connected nodes.

!!! tip "Constructor `GeoAvailability`"
    We require at the time being the specification of the fields `input` and `output` due to the way we identify the required
    flow and link variables.
    In practice, both fields should include the same [`Resource`](@extref EnergyModelsBase.Resource)s.
    To this end, we provide a simplified constructor in which you only have to specify one vector using the function

    ```julia
    GeoAvailability(id, 𝒫::Vector{<:Resource})
    ```

!!! note "Naming"
    We are aware that `GeoAvailability` and `GenAvailability` look similar.
    We plan to rename one of them with the additional introduction of a constructor.
    In this case, we introduce breaking changes.
    We plan to collect as many potential issues as possible before the next breaking changes.

### [Mathematical description](@id area_mode-areas-availability-math)

In the following mathematical equations, we use the name for variables and functions used in the model.
Variables are in general represented as

``\texttt{var\_example}[index_1, index_2]``

with square brackets, while functions are represented as

``func\_example(index_1, index_2)``

with paranthesis.

#### [Variables](@id area_mode-areas-availability-math-var)

The variables of [`GeoAvailability`](@ref) nodes include:

- [``\texttt{flow\_in}``](@extref EnergyModelsBase man-opt_var-flow)
- [``\texttt{flow\_out}``](@extref EnergyModelsBase man-opt_var-flow)

#### [Constraints](@id area_mode-areas-availability-math-con)

`GeoAvailability` nodes do not add any constraints.
The overall energy balance is instead calculated on the [`Area`](@ref) level as outlined above.
