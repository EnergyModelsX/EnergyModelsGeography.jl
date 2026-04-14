# [Extend Resource functionality](@id how_to-res_funct)

This guide is the `EnergyModelsGeography` counterpart to the resource functionality *[introduced in `EnergyModelsBase`](@extref EnergyModelsBase how_to-res_funct)*.
It shows how that same pattern is used for geography-specific coupling through a concrete example from `test_resource_flow.jl`: a `PotentialPower` resource with dedicated flow
variables and coupling constraints.

!!! warning
    While we allow resource variable introduction for [`Area`](@ref)s, we strongly advise against introducing new variables for an `Area`.
    It is instead easier to access in the function [`EMB.constraints_couple_resource`](@ref) the relevant `Availability` node as outlined below.

    This approach allows you to couple the local energy system with the transmission modes with respect to the extra variables.

## [Practical example: `PotentialPower`](@id how_to-res_funct-example)

The goal is to track a resource-specific "potential" flow in parallel with standard transmission flow and enforce a mode-specific loss factor.

### 1. Define the resource and mode

!!! tip
    You can use the same resource type as declared in `EnergyModelsBase` or any other package.
    This corresponds to *[step 1 in the example of `EnergyModelsBase`](@extref EnergyModelsBase how_to-res_funct-example)*.

```julia
struct PotentialPower <: Resource
    id::String
    co2_int::Float64
    potential_lower::Float64
    potential_upper::Float64
end

EMB.is_resource_emit(::PotentialPower) = false
lower_limit(p::PotentialPower) = p.potential_lower
upper_limit(p::PotentialPower) = p.potential_upper

struct PotentialLossMode{T <: PotentialPower} <: TransmissionMode
    id::String
    resource::T
    trans_cap::TimeProfile
    trans_loss::TimeProfile
    opex_var::TimeProfile
    opex_fixed::TimeProfile
    directions::Int
    data::Vector{Data}
    loss_factor::Float64
end
```

### 2. Add resource-specific variables

Implement `EMB.variables_flow_resource` for both [`Area`] and [`Node`] to introduce new variables.

```julia
function EMB.variables_flow_resource(
    m,
    ℳ::Vector{<:TransmissionMode},
    𝒫::Vector{<:PotentialPower},
    𝒯,
    modeltype::EnergyModel,
)
    ℳᵖ = filter(tm -> any(p -> p ∈ 𝒫, inputs(tm)) || any(p -> p ∈ 𝒫, outputs(tm)), ℳ)

    @variable(
        m,
        lower_limit(p) <=
            energy_potential_trans_in[tm ∈ ℳᵖ, 𝒯, p ∈ intersect(inputs(tm), 𝒫)] <=
            upper_limit(p)
    )
    @variable(
        m,
        lower_limit(p) <=
            energy_potential_trans_out[tm ∈ ℳᵖ, 𝒯, p ∈ intersect(outputs(tm), 𝒫)] <=
            upper_limit(p)
    )
end

function EMB.variables_flow_resource(
    m,
    𝒩::Vector{<:Node},
    𝒫::Vector{<:PotentialPower},
    𝒯,
    modeltype::EnergyModel,
)
    @variable(m, lower_limit(p) <= energy_potential_node_in[n ∈ 𝒩, 𝒯, p ∈ 𝒫] <= upper_limit(p))
    @variable(m, lower_limit(p) <= energy_potential_node_out[n ∈ 𝒩, 𝒯, p ∈ 𝒫] <= upper_limit(p))
end
```

### 3. Use the new variables in the function

Apply the resource-specific variable in the function [`EMB.constraints_resource`](@ref).
You must be careful when defining the internal constraints due to potential changes in the variables.

```julia
function EMB.constraints_resource(
    m,
    tm::PotentialLossMode,
    𝒯::TimeStructure,
    𝒫::Vector{<:PotentialPower},
    modeltype::EnergyModel,
)
    @constraint(m, [t ∈ 𝒯, p ∈ outputs(tm)],
        m[:energy_potential_trans_out][tm, t, p] ==
            tm.loss_factor * m[:energy_potential_trans_in][tm, t, p]
    )
end
```

### 4. Couple variables between area and transmission mode

Map area-level variables to transmission-level variables with
`EMG.constraints_couple_resource`.

```julia
function EMG.constraints_couple_resource(
    m,
    𝒜::Vector{<:Area},
    ℒᵗʳᵃⁿˢ::Vector{<:Transmission},
    𝒫::Vector{<:PotentialPower},
    𝒯,
    modeltype::EnergyModel,
)
    for a ∈ 𝒜, p ∈ 𝒫
        ℒᶠʳᵒᵐ, ℒᵗᵒ = EMG.trans_sub(ℒᵗʳᵃⁿˢ, a)
        ℳᶠʳᵒᵐ = EMG.modes_sub(ℒᶠʳᵒᵐ, p)
        ℳᵗᵒ = EMG.modes_sub(ℒᵗᵒ, p)

        if !isempty(ℳᶠʳᵒᵐ)
            @constraint(m, [t ∈ 𝒯],
                m[:energy_potential_node_out][availability_node(a), t, p] ==
                    sum(m[:energy_potential_trans_in][tm, t, p] for tm ∈ ℳᶠʳᵒᵐ)
            )
        end

        if !isempty(ℳᵗᵒ)
            @constraint(m, [t ∈ 𝒯],
                m[:energy_potential_node_in][availability_node(a), t, p] ==
                    sum(m[:energy_potential_trans_out][tm, t, p] for tm ∈ ℳᵗᵒ)
            )
        end
    end
end
```

### 5. What this gives you

- Bounded resource-specific transmission variables.
- Explicit coupling between area and transmission representation.
- Mode-specific transformations (here: potential loss factor) without changing core code.

## Other useful applications

The same extension pattern is useful whenever transport quality matters, not only quantity.

- District heating networks: track temperature state (supply/return quality) and enforce
  temperature-dependent delivery constraints.
- Natural gas networks: track pressure-related transport limits and represent gas mixtures
  (e.g., hydrogen blending constraints across corridors).
- Any carrier with quality degradation: track concentration, purity, or state-of-charge style
  attributes with resource-specific balance equations.

## See also

- [`update-models`](@ref how_to-update)
- [`Constraint functions`](@ref man-con)
