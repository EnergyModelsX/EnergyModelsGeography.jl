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

function PotentialLossMode(
    id::String,
    resource::T,
    trans_cap::TimeProfile,
    trans_loss::TimeProfile,
    opex_var::TimeProfile,
    opex_fixed::TimeProfile,
    loss_factor::Float64,
) where {T <: PotentialPower}
    return PotentialLossMode(
        id,
        resource,
        trans_cap,
        trans_loss,
        opex_var,
        opex_fixed,
        1,
        Data[],
        loss_factor,
    )
end

"""
    resource_flow_case_with_loss(loss_factor::Float64)

Create a two-area case with one transmission corridor carrying `PotentialPower`.
The transport itself is lossless, while `PotentialLossMode` reduces the transmitted
potential through resource-specific functions.
"""
function resource_flow_case_with_loss(loss_factor::Float64)
    pp = PotentialPower("PotentialPower", 0.0, 0.9, 1.1)
    co2 = ResourceEmit("CO2_RF", 1.0)
    products = Resource[pp, co2]

    source = RefSource(
        "pp_source",
        FixedProfile(4),
        FixedProfile(10),
        FixedProfile(0),
        Dict(pp => 1),
    )
    sink = RefSink(
        "pp_sink",
        FixedProfile(3),
        Dict(:surplus => FixedProfile(4), :deficit => FixedProfile(100)),
        Dict(pp => 1),
    )

    nodes = [GeoAvailability(1, products), GeoAvailability(2, products), source, sink]
    links = [
        Direct("src-area", source, nodes[1], Linear()),
        Direct("area-snk", nodes[2], sink, Linear()),
    ]

    areas = [
        RefArea(1, "AreaA", 10.751, 59.921, nodes[1]),
        RefArea(2, "AreaB", 10.398, 63.4366, nodes[2]),
    ]

    mode = PotentialLossMode(
        "potential_loss",
        pp,
        FixedProfile(4),
        FixedProfile(0),
        FixedProfile(0),
        FixedProfile(0),
        loss_factor,
    )
    transmissions = [Transmission(areas[1], areas[2], [mode])]

    T = TwoLevel(2, 2, SimpleTimes(5, 2); op_per_strat = 10)
    modeltype = OperationalModel(
        Dict(co2 => FixedProfile(100)),
        Dict(co2 => FixedProfile(0)),
        co2,
    )

    case = Case(
        T,
        products,
        [nodes, links, areas, transmissions],
        [[get_nodes, get_links], [get_areas, get_transmissions]],
    )
    return case, modeltype
end

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
        lower_limit(p) ≤
            energy_potential_trans_in[tm ∈ ℳᵖ, 𝒯, p ∈ intersect(inputs(tm), 𝒫)] ≤
            upper_limit(p)
    )
    @variable(
        m,
        lower_limit(p) ≤
            energy_potential_trans_out[tm ∈ ℳᵖ, 𝒯, p ∈ intersect(outputs(tm), 𝒫)] ≤
            upper_limit(p)
    )
end

function EMB.variables_flow_resource(
    m,
    𝒜::Vector{<:Area},
    𝒫::Vector{<:PotentialPower},
    𝒯,
    modeltype::EnergyModel,
)
    𝒩ᵃᵛ = [availability_node(a) for a ∈ 𝒜]
    @variable(m, lower_limit(p) ≤ energy_potential_node_in[n ∈ 𝒩ᵃᵛ, 𝒯, p ∈ 𝒫] ≤ upper_limit(p))
    @variable(m, lower_limit(p) ≤ energy_potential_node_out[n ∈ 𝒩ᵃᵛ, 𝒯, p ∈ 𝒫] ≤ upper_limit(p))
end

function EMG.constraints_trans_balance(
    m,
    tm::PotentialLossMode,
    𝒯::TimeStructure,
    modeltype::EnergyModel,
)
    @constraint(m, [t ∈ 𝒯],
        m[:trans_out][tm, t] == m[:trans_in][tm, t] - m[:trans_loss][tm, t]
    )
    @constraint(m, [t ∈ 𝒯, p ∈ outputs(tm)],
        m[:energy_potential_trans_out][tm, t, p] ==
            tm.loss_factor * m[:energy_potential_trans_in][tm, t, p]
    )
end

function EMB.constraints_couple_resource(
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

@testset "Resource flow | PotentialPower" begin
    case, modeltype = resource_flow_case_with_loss(0.9)
    pp, co2 = get_products(case)
    𝒯 = get_time_struct(case)
    n_t = length(𝒯)
    𝒜 = get_areas(case)
    ℒᵗʳᵃⁿˢ = get_transmissions(case)
    tm = modes(ℒᵗʳᵃⁿˢ)[1]
    area_from, area_to = 𝒜

    m = optimize(case, modeltype)
    general_tests(m)

    @test haskey(m, :energy_potential_trans_in)
    @test haskey(m, :energy_potential_trans_out)
    @test haskey(m, :energy_potential_node_in)
    @test haskey(m, :energy_potential_node_out)

    @test length(m[:energy_potential_trans_in]) == n_t
    @test length(m[:energy_potential_trans_out]) == n_t
    @test length(m[:energy_potential_node_in]) == 2 * n_t
    @test length(m[:energy_potential_node_out]) == 2 * n_t

    @test all(value(m[:energy_potential_trans_in][tm, t, pp]) ≥ lower_limit(pp) for t ∈ 𝒯)
    @test all(value(m[:energy_potential_trans_in][tm, t, pp]) ≤ upper_limit(pp) for t ∈ 𝒯)
    @test all(value(m[:energy_potential_trans_out][tm, t, pp]) ≥ lower_limit(pp) for t ∈ 𝒯)
    @test all(value(m[:energy_potential_trans_out][tm, t, pp]) ≤ upper_limit(pp) for t ∈ 𝒯)

    @test all(
        value(m[:energy_potential_node_out][availability_node(area_from), t, pp]) ≈
            value(m[:energy_potential_trans_in][tm, t, pp])
    for t ∈ 𝒯)
    @test all(
        value(m[:energy_potential_trans_out][tm, t, pp]) ≈
            0.9 * value(m[:energy_potential_trans_in][tm, t, pp])
    for t ∈ 𝒯)
    @test all(
        value(m[:energy_potential_node_in][availability_node(area_to), t, pp]) ≈
            value(m[:energy_potential_trans_out][tm, t, pp])
    for t ∈ 𝒯)

    @test all(
        value(m[:energy_potential_node_in][availability_node(area_to), t, pp]) <
            value(m[:energy_potential_node_out][availability_node(area_from), t, pp])
    for t ∈ 𝒯)
    @test all(value(m[:trans_in][tm, t]) ≈ value(m[:trans_out][tm, t]) for t ∈ 𝒯)
    @test all(value(m[:energy_potential_trans_in][tm, t, pp]) < value(m[:trans_in][tm, t]) for t ∈ 𝒯)
    @test all(value(m[:energy_potential_trans_out][tm, t, pp]) < value(m[:trans_out][tm, t]) for t ∈ 𝒯)
end
