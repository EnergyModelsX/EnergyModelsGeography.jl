"""
    simple_geo_area(mode_fun::Function)

Simple test case for testing areas and the calculations of the couplings between an area
and a transmission corridor
"""
function simple_geo_area(mode_fun::Function)
    products = [H2_hp, H2_lp, Power, CO2]

    # Creation of the source and sink module as well as the arrays used for nodes and links
    mode_a = mode_fun("mode_trd")
    mode_b = mode_fun("mode_bgo")
    demand = outputs(mode_a)[1]

    h2_src_a = RefSource(
        "h2_src",
        OperationalProfile([30, 30, 0, 0]),
        FixedProfile(0),
        FixedProfile(0),
        Dict(H2_hp => 1),
    )
    h2_src_b = RefSource(
        "h2_src",
        OperationalProfile([0, 0, 30, 30]),
        FixedProfile(0),
        FixedProfile(0),
        Dict(H2_hp => 1),
    )
    el_source = RefSource(
        "el_src",
        FixedProfile(30),
        FixedProfile(0),
        FixedProfile(0),
        Dict(Power => 1),
    )
    snk_a = RefSink(
        "snk_a",
        OperationalProfile([20, 10, 5, 25]),
        Dict(:surplus => FixedProfile(0), :deficit => FixedProfile(1000)),
        Dict(demand => 1),
    )
    snk_b = RefSink(
        "snk_b",
        OperationalProfile([5, 10, 20, 0]),
        Dict(:surplus => FixedProfile(0), :deficit => FixedProfile(100)),
        Dict(demand => 1),
    )

    nodes = [
        EMG.GeoAvailability(1, products), h2_src_a, h2_src_b, el_source,
        EMG.GeoAvailability(2, products), snk_a,
        EMG.GeoAvailability(3, products), snk_b,
    ]

    links = [
        Direct(31, nodes[2], nodes[1], Linear()),
        Direct(31, nodes[3], nodes[1], Linear()),
        Direct(31, nodes[4], nodes[1], Linear()),
        Direct(24, nodes[5], nodes[6], Linear()),
        Direct(24, nodes[7], nodes[8], Linear()),
    ]

    # Creation of the two areas and potential transmission lines
    areas = [
        RefArea(1, "Oslo", 10.751, 59.921, nodes[1]),
        RefArea(2, "Trondheim", 10.398, 63.4366, nodes[5]),
        RefArea(3, "Bergen", 5.33, 60.3894, nodes[7]),
    ]

    transmissions = [
        Transmission(areas[1], areas[2], [mode_a]),
        Transmission(areas[1], areas[3], [mode_b]),
    ]

    # Creation of the time structure and the used global data
    T = TwoLevel(4, 1, SimpleTimes(4, 2); op_per_strat=8)
    modeltype = OperationalModel(
                                Dict(CO2 => StrategicProfile([450, 400, 350, 300])),
                                Dict(CO2 => FixedProfile(0)),
                                CO2,
    )

    # Input data structure
    case = Case(
        T,
        products,
        [nodes, links, areas, transmissions],
        [[get_nodes, get_links], [get_areas, get_transmissions]],
    )
    return case, modeltype
end


# Testset for the individual extraction methods incorporated in the model
@testset "Mode utilities" begin
    mode_fun(name::String) = PipeSimple(
        name,
        H2_hp,
        H2_lp,
        Power,
        FixedProfile(0.05),   # Consumption rate
        FixedProfile(20),     # Capacity
        FixedProfile(0.01),   # Loss
        FixedProfile(0.1),    # Opex var
        FixedProfile(2.5),    # Opex fixed
    )
    case, modeltype = simple_geo_area(mode_fun)

    # Extract from the case structure
    𝒯 = get_time_struct(case)
    𝒜 = get_areas(case)
    𝒩 = get_nodes(case)
    ℒᵗʳᵃⁿˢ = get_transmissions(case)
    tm = modes(ℒᵗʳᵃⁿˢ)[1]

    # Test that the individual functions are extracting the correct value
    @test 𝒜 == get_elements_vec(case)[3]
    @test [EMG.name(a) for a ∈ 𝒜] == ["Oslo", "Trondheim", "Bergen"]
    @test [availability_node(a) for a ∈ 𝒜] == [𝒩[1], 𝒩[5], 𝒩[7]]

    @test corr_from(𝒜[1], ℒᵗʳᵃⁿˢ) == ℒᵗʳᵃⁿˢ
    @test corr_from("Oslo", ℒᵗʳᵃⁿˢ) == ℒᵗʳᵃⁿˢ
    @test corr_to(𝒜[2], ℒᵗʳᵃⁿˢ) == Transmission[ℒᵗʳᵃⁿˢ[1]]
    @test corr_to("Trondheim", ℒᵗʳᵃⁿˢ) == Transmission[ℒᵗʳᵃⁿˢ[1]]
    @test corr_to(𝒜[3], ℒᵗʳᵃⁿˢ) == Transmission[ℒᵗʳᵃⁿˢ[2]]
    @test corr_to("Bergen", ℒᵗʳᵃⁿˢ) == Transmission[ℒᵗʳᵃⁿˢ[2]]
    @test corr_from_to("Oslo", 𝒜[2], ℒᵗʳᵃⁿˢ) == Transmission[ℒᵗʳᵃⁿˢ[1]]

    @test EMG.import_resources(ℒᵗʳᵃⁿˢ, 𝒜[2]) == Resource[H2_lp]
    @test EMG.exchange_resources(ℒᵗʳᵃⁿˢ, 𝒜[2]) == Resource[H2_lp]
    @test EMG.export_resources(ℒᵗʳᵃⁿˢ, 𝒜[1]) == Resource[H2_hp, Power]
    @test EMG.exchange_resources(ℒᵗʳᵃⁿˢ, 𝒜[1]) == Resource[H2_hp, Power]
end

# Testset for RefArea
@testset "RefArea" begin
    @testset "RefStatic" begin
        mode_fun(name::String) = RefStatic(
            name,
            Power,
            FixedProfile(20),
            FixedProfile(0.01),
            FixedProfile(0.1),
            FixedProfile(2),
            1,
        )
        case, modeltype = simple_geo_area(mode_fun)
        m = optimize(case, modeltype)

        # Extract from the case structure
        𝒯 = get_time_struct(case)
        𝒜 = get_areas(case)
        𝒩 = get_nodes(case)
        ℒᵗʳᵃⁿˢ = get_transmissions(case)
        tm_trd, tm_bgo = modes(ℒᵗʳᵃⁿˢ)[1:2]
        osl, trd = 𝒜[1:2]

        # Test that `area_exchange` is only created for the correct resource
        @test !isempty(value.(m[:area_exchange][osl, :, Power]))
        @test isempty(value.(m[:area_exchange][osl, :, H2_hp]))
        @test isempty(value.(m[:area_exchange][osl, :, H2_lp]))
        @test !isempty(value.(m[:area_exchange][trd, :, Power]))
        @test isempty(value.(m[:area_exchange][trd, :, H2_hp]))
        @test isempty(value.(m[:area_exchange][trd, :, H2_lp]))

        # Test that the area exchange is correctly included in the nodal balance
        # - EMB.constraints_couple(m, 𝒜::Vector{<:Area}, ℒᵗʳᵃⁿˢ::Vector{Transmission}, 𝒫, 𝒯, modeltype::EnergyModel)
        @test all(
            value(m[:flow_in][availability_node(osl), t, Power]) ≈
                -value(m[:area_exchange][osl, t, Power])
        for t ∈ 𝒯)
        prof = [25, 20, 25, 20]
        @test all(
            value(m[:area_exchange][osl, t, Power]) ≈ -OperationalProfile(prof)[t]/0.99
        for t ∈ 𝒯)
        @test all(
            value(m[:flow_out][availability_node(trd), t, Power]) ≈
                value(m[:area_exchange][trd, t, Power])
        for t ∈ 𝒯)
        @test all(
            value(m[:area_exchange][trd, t, Power]) ≈ OperationalProfile([20, 10, 5, 20])[t]
        for t ∈ 𝒯)

        # Test that the area exchange is correctly calculated
        #  compute_trans_in() and compute_trans_out()
        @test all(
            -value(m[:area_exchange][osl, t, Power]) ≈
                value(m[:trans_in][tm_trd, t] + m[:trans_in][tm_bgo, t])
        for t ∈ 𝒯)
        @test all(
            value(m[:area_exchange][trd, t, Power]) ≈
                value(m[:trans_out][tm_trd, t])
        for t ∈ 𝒯)
    end

    @testset "PipeSimple" begin
        mode_fun(name::String) = PipeSimple(
            name,
            H2_hp,
            H2_lp,
            Power,
            FixedProfile(0.05),   # Consumption rate
            FixedProfile(20),     # Capacity
            FixedProfile(0.01),   # Loss
            FixedProfile(0.1),    # Opex var
            FixedProfile(2.5),    # Opex fixed
        )
        case, modeltype = simple_geo_area(mode_fun)
        m = optimize(case, modeltype)

        # Extract from the case structure
        𝒯 = get_time_struct(case)
        𝒜 = get_areas(case)
        𝒩 = get_nodes(case)
        ℒᵗʳᵃⁿˢ = get_transmissions(case)
        tm_trd, tm_bgo = modes(ℒᵗʳᵃⁿˢ)[1:2]
        osl, trd = 𝒜[1:2]

        # Test that `area_exchange` is only created for the correct resource
        @test !isempty(value.(m[:area_exchange][osl, :, Power]))
        @test !isempty(value.(m[:area_exchange][osl, :, H2_hp]))
        @test isempty(value.(m[:area_exchange][osl, :, H2_lp]))
        @test isempty(value.(m[:area_exchange][trd, :, Power]))
        @test isempty(value.(m[:area_exchange][trd, :, H2_hp]))
        @test !isempty(value.(m[:area_exchange][trd, :, H2_lp]))

        # Test that the area exchange is correctly included in the nodal balance
        # - EMB.constraints_couple(m, 𝒜::Vector{<:Area}, ℒᵗʳᵃⁿˢ::Vector{Transmission}, 𝒫, 𝒯, modeltype::EnergyModel)
        @test all(
            value(m[:flow_in][availability_node(osl), t, Power]) ≈
                -value(m[:area_exchange][osl, t, Power])
        for t ∈ 𝒯)
        @test all(
            value(m[:flow_in][availability_node(osl), t, H2_hp]) ≈
                -value(m[:area_exchange][osl, t, H2_hp])
        for t ∈ 𝒯)
        prof = [25, 20, 25, 20]
        @test all(
            value(m[:area_exchange][osl, t, H2_hp]) ≈ -OperationalProfile(prof)[t]/0.99
        for t ∈ 𝒯)
        @test all(
            value(m[:flow_out][availability_node(trd), t, H2_lp]) ≈
                value(m[:area_exchange][trd, t, H2_lp])
        for t ∈ 𝒯)

        # Test that the area exchange is correctly calculated
        #  compute_trans_in() and compute_trans_out()
        @test all(
            -value(m[:area_exchange][osl, t, H2_hp]) ≈
                value(m[:trans_in][tm_trd, t] + m[:trans_in][tm_bgo, t])
        for t ∈ 𝒯)
        @test all(
            value(m[:area_exchange][trd, t, H2_lp]) ≈
                value(m[:trans_out][tm_trd, t])
        for t ∈ 𝒯)
        @test all(
            -value(m[:area_exchange][osl, t, Power]) ≈
                value(m[:trans_in][tm_trd, t]) * consumption_rate(tm_trd, t) +
                value(m[:trans_in][tm_bgo, t]) * consumption_rate(tm_bgo, t)
        for t ∈ 𝒯)
        @test all(
            value(m[:area_exchange][osl, t, Power]) ≈
             -OperationalProfile(prof)[t]/0.99 * 0.05
        for t ∈ 𝒯)
    end
end

@testset "LimitedExchangeArea" begin
    mode_fun(name::String) = RefStatic(
        name,
        Power,
        FixedProfile(20),
        FixedProfile(0.01),
        FixedProfile(0.1),
        FixedProfile(2),
        1,
    )
    case, modeltype = simple_geo_area(mode_fun)

    # Extract from the case structure and update with LimitedExchangeArea
    𝒯 = get_time_struct(case)
    𝒜 = get_areas(case)
    𝒩 = get_nodes(case)
    ℒᵗʳᵃⁿˢ = get_transmissions(case)
    tm_trd, tm_bgo = modes(ℒᵗʳᵃⁿˢ)[1:2]
    osl = LimitedExchangeArea(1, "Oslo", 10.751, 59.921, 𝒩[1], Dict(Power => FixedProfile(15)))
    trd = 𝒜[2]
    case.elements[3] = [
        osl,
        𝒜[2],
        𝒜[3]
    ]
    case.elements[4] = [
        Transmission(osl, 𝒜[2], [tm_trd]),
        Transmission(osl, 𝒜[3], [tm_bgo]),
    ]

    # Optimize the model
    m = optimize(case, modeltype)

    # Test that the area exchange is correctly included in the nodal balance and that the
    # exchange limit is correctly enforced
    # - EMB.constraints_couple(m, 𝒜::Vector{<:Area}, ℒᵗʳᵃⁿˢ::Vector{Transmission}, 𝒫, 𝒯, modeltype::EnergyModel)
    # - create_area(m, a::LimitedExchangeArea, 𝒯, ℒᵗʳᵃⁿˢ, modeltype)
    @test all(
        value(m[:flow_in][availability_node(osl), t, Power]) ≈
            -value(m[:area_exchange][osl, t, Power])
    for t ∈ 𝒯)
    prof_tot = [15, 15, 15, 15]
    @test all(
        value(m[:area_exchange][osl, t, Power]) ≈ -OperationalProfile(prof_tot)[t]
    for t ∈ 𝒯)
    @test all(
        value(m[:flow_out][availability_node(trd), t, Power]) ≈
            value(m[:area_exchange][trd, t, Power])
    for t ∈ 𝒯)
    prof_trd = [15*.99, 10, 5, 15*.99]
    @test all(
        value(m[:area_exchange][trd, t, Power]) ≈ OperationalProfile(prof_trd)[t]
    for t ∈ 𝒯)
end
