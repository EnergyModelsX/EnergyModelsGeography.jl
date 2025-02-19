# Declaration of a simple `EmissionMode`
struct EmissionMode <: TransmissionMode
    id::String
    resource::EMB.Resource
    trans_cap::TimeProfile
    trans_loss::TimeProfile
    opex_var::TimeProfile
    opex_fixed::TimeProfile
    emissions::Dict{<:ResourceEmit, <:TimeProfile}
    directions::Int
    data::Vector{Data}
end
EMB.has_emissions(tm::EmissionMode) = true
EMG.emit_resources(tm::EmissionMode) = keys(tm.emissions)
EMG.emissions(tm::EmissionMode, p_em::ResourceEmit, t) = tm.emissions[p_em][t]

"""
    simple_case_emissions(;directions=1, opex_a=FixedProfile(10), opex_b=FixedProfile(50))

Simple test case for testing the functionality of emissions.
"""
function simple_case_emissions(
    ;directions=1,
    opex_a=FixedProfile(10),
    opex_b=FixedProfile(50),
)
    # Creation of the individual resources
    Power = ResourceCarrier("Power", 0.0)
    CO2 = ResourceEmit("CO2", 1.0)
    NG = ResourceEmit("NG", 1.0)
    products = [Power, CO2, NG]

    # Creation of the source and sink module as well as the arrays used for nodes and links
    src_a = RefSource(
        "src_a",
        FixedProfile(100),
        opex_a,
        FixedProfile(0),
        Dict(Power => 1),
    )
    snk_a = RefSink(
        "snk_a",
        OperationalProfile([20, 25, 30, 35]),
        Dict(:surplus => FixedProfile(0), :deficit => FixedProfile(1e6)),
        Dict(Power => 1),
    )
    src_b = RefSource(
        "src_b",
        FixedProfile(100),
        opex_b,
        FixedProfile(0),
        Dict(Power => 1),
    )
    snk_b = RefSink(
        "snk_b",
        OperationalProfile([20, 25, 30, 35]),
        Dict(:surplus => FixedProfile(0), :deficit => FixedProfile(1e6)),
        Dict(Power => 1),
    )
    nodes = [
        GeoAvailability(1, products), src_a, snk_a,
        GeoAvailability(2, products), src_b, snk_b,
    ]
    links = [
        Direct(31, nodes[1], nodes[3], Linear()),
        Direct(31, nodes[2], nodes[1], Linear()),
        Direct(24, nodes[4], nodes[6], Linear()),
        Direct(24, nodes[5], nodes[4], Linear()),
    ]

    # Creation of the two areas and potential transmission lines
    areas = [
        RefArea(1, "area_a", 10.751, 59.921, nodes[1]),
        RefArea(2, "area_b", 10.398, 63.4366, nodes[4]),
    ]

    em_mode = EmissionMode(
        "emission_mode",
        Power,
        FixedProfile(40),
        FixedProfile(0),
        FixedProfile(0),
        FixedProfile(0),
        Dict(CO2 => FixedProfile(.5)),
        directions,
        Data[],
    )

    transmissions = [Transmission(areas[1], areas[2], [em_mode])]

    # Creation of the time structure and the used global data
    T = TwoLevel(4, 1, SimpleTimes(4, 2), op_per_strat=8.0)
    modeltype = OperationalModel(
        Dict(
            CO2 => StrategicProfile([125, 100, 75, 50]),
            NG => FixedProfile(0)
        ),
        Dict(CO2 => FixedProfile(0)),
        CO2
    )

    # Input data structure and optimization model design
    case = Case(
        T,
        products,
        [nodes, links, areas, transmissions],
        [[get_nodes, get_links], [get_areas, get_transmissions]],
    )
    return case, modeltype
end

@testset "Emission variable generation" begin
    case, modeltype = simple_case_emissions()
    m = create_model(case, modeltype)
    em_mode = modes(get_transmissions(case)[1])[1]
    CO2, NG = get_products(case)[[2,3]]
    𝒯 = get_time_struct(case)

    # Test that the variable for NG is fixed to 0 and the one for CO2 not
    @test all(is_fixed(m[:emissions_trans][em_mode, t, NG]) for t ∈ 𝒯)
    @test !any(is_fixed(m[:emissions_trans][em_mode, t, CO2]) for t ∈ 𝒯)
end

@testset "Unidirectional transport" begin
    case, modeltype = simple_case_emissions()
    m = optimize(case, modeltype)
    em_mode = modes(get_transmissions(case)[1])[1]
    CO2, NG = get_products(case)[[2,3]]
    𝒯 = get_time_struct(case)

    # Test that the emissions are correctly calculated, both based on the model and based on
    # the knowledge of the value
    # - constraints_emission(m, tm::TransmissionMode, 𝒯, modeltype::EnergyModel)
    @test all(
        value.(m[:emissions_trans][em_mode, t, CO2]) ≈
            value(m[:trans_out][em_mode, t]) * 0.5
    for t ∈ 𝒯)
    opers = collect(𝒯)[1:4]
    emit = OperationalProfile([20, 25, 30, 35])*.5  # Given through the transported capacity
    @test all(
        value.((m[:emissions_trans][em_mode, t, CO2])) ≈ emit[t]
    for t ∈ opers)

    # Test that the emissions are correctly included
    @test all(
        value.((m[:emissions_trans][em_mode, t, CO2])) ==
            value(m[:emissions_total][t, CO2])
    for t ∈ 𝒯)
end

@testset "Bidirectional transport" begin
    opex_a = OperationalProfile([10, 100, 10, 100])
    opex_b = OperationalProfile([100, 10, 100, 10])
    case, modeltype = simple_case_emissions(;directions=2, opex_a, opex_b)
    m = optimize(case, modeltype)
    em_mode = modes(get_transmissions(case)[1])[1]
    CO2, NG = get_products(case)[[2,3]]
    𝒯 = get_time_struct(case)

    # Test that the emissions are correctly calculated, both based on the model and based on
    # the knowledge of the value
    # - constraints_emission(m, tm::TransmissionMode, 𝒯, modeltype::EnergyModel)
    @test all(
        value.((m[:emissions_trans][em_mode, t, CO2])) ≈
            (value(m[:trans_pos][em_mode, t]) + value(m[:trans_neg][em_mode, t])) * 0.5
    for t ∈ 𝒯)
    opers = collect(𝒯)[1:4]
    emit = OperationalProfile([20, 25, 30, 35])*.5  # Given through the transported capacity
    @test all(
        value.((m[:emissions_trans][em_mode, t, CO2])) ≈ emit[t]
    for t ∈ opers)

    # Test that the emissions are correctly included
    @test all(
        value.((m[:emissions_trans][em_mode, t, CO2])) ==
            value(m[:emissions_total][t, CO2])
    for t ∈ 𝒯)
end
