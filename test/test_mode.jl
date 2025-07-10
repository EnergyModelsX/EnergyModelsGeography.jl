Power = ResourceCarrier("Power", 0.0)
H2_hp = ResourceCarrier("H2_hp", 0.0)
H2_lp = ResourceCarrier("H2_lp", 0.0)
CO2 = ResourceEmit("CO2", 1.0)

"""
    simple_geo_uni(mode::TransmissionMode)

Simple test case for testing unidirectional transport.
"""
function simple_geo_uni(mode::TransmissionMode)
    products = [Power, CO2]

    # Creation of the source and sink module as well as the arrays used for nodes and links
    source = RefSource(
        "src",
        FixedProfile(50),
        FixedProfile(0),
        FixedProfile(0),
        Dict(Power => 1),
    )
    sink = RefSink(
        "snk",
        OperationalProfile([20, 10, 5, 25]),
        Dict(:surplus => FixedProfile(0), :deficit => FixedProfile(100)),
        Dict(Power => 1),
    )

    nodes = [GeoAvailability(1, products), GeoAvailability(2, products), source, sink]
    links = [Direct(31, nodes[3], nodes[1], Linear())
             Direct(24, nodes[2], nodes[4], Linear())]

    # Creation of the two areas and potential transmission lines
    areas = [RefArea(1, "Oslo", 10.751, 59.921, nodes[1]),
             RefArea(2, "Trondheim", 10.398, 63.4366, nodes[2])]


    transmissions = [Transmission(areas[1], areas[2], [mode])]

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

"""
    simple_geo_bi(mode::TransmissionMode)

Simple test case for testing bidirectional transport.
"""
function simple_geo_bi(mode::TransmissionMode)
    products = [Power, CO2]

    src_a = RefSource(
        "src_a",
        FixedProfile(100),
        OperationalProfile([0, 100, 0, 100]),
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
        OperationalProfile([100, 0, 100, 0]),
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

    transmissions = [Transmission(areas[1], areas[2], [mode])]

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

"""
    simple_geo_pipe(mode::PipeMode; cap = FixedProfile(50))

Simple test case for testing unidirectional transport with pipeline modes.
"""
function simple_geo_pipe(mode::PipeMode; cap = FixedProfile(30))
    products = [H2_hp, H2_lp, Power, CO2]

    # Creation of the source and sink module as well as the arrays used for nodes and links
    h2_source = RefSource(
        "h2_src",
        cap,
        FixedProfile(0),
        FixedProfile(0),
        Dict(H2_hp => 1),
    )
    el_source = RefSource(
        "el_src",
        FixedProfile(3),
        FixedProfile(0),
        FixedProfile(0),
        Dict(Power => 1),
    )
    sink = RefSink(
        "snk",
        OperationalProfile([20, 10, 5, 25]),
        Dict(:surplus => FixedProfile(0), :deficit => FixedProfile(100)),
        Dict(H2_lp => 1),
    )

    nodes = [
        GeoAvailability(1, products), h2_source, el_source,
        GeoAvailability(2, products), sink]

    links = [
        Direct(31, nodes[2], nodes[1], Linear())
        Direct(31, nodes[3], nodes[1], Linear())
        Direct(24, nodes[4], nodes[5], Linear())
    ]

    # Creation of the two areas and potential transmission lines
    areas = [RefArea(1, "Oslo", 10.751, 59.921, nodes[1]),
             RefArea(2, "Trondheim", 10.398, 63.4366, nodes[4])]


    transmissions = [Transmission(areas[1], areas[2], [mode])]

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

"""
    mode_subset(; n_stat=10, n_dyn = 10, n_pipe = 10)

Function for creating a set of nodes for filtering based on the string.
"""
function mode_subset(; t=1, n_stat=10, n_dyn = 10, n_pipe = 10)
    static = [RefStatic(
        string(t) * "_static_" * string(k),
        CO2,
        FixedProfile(30.0),
        FixedProfile(0.01),
        FixedProfile(0.1),
        FixedProfile(1),
        2,
    ) for k ∈ range(1, n_stat)]
    dynamic = [RefDynamic(
        string(t) * "_dynamic_" * string(k),
        Power,
        FixedProfile(30.0),
        FixedProfile(0.01),
        FixedProfile(0.1),
        FixedProfile(1),
        2,
    ) for k ∈ range(1, n_dyn)]
    pipe = [PipeSimple(
        string(t) * "_pipe_" * string(k),
        H2_hp,
        H2_lp,
        Power,
        FixedProfile(0.05),   # Consumption rate
        FixedProfile(20),     # Capacity
        FixedProfile(0.01),   # Loss
        FixedProfile(0.1),    # Opex var
        FixedProfile(2.5),    # Opex fixed
    ) for k ∈ range(1, n_pipe)]
    return vcat(static, dynamic, pipe)
end

# Testset for the individual extraction methods incorporated in the model
@testset "Mode utilities" begin
    @testset "TransmissionMode" begin
        # Test for a RefStatic
        mode = RefStatic(
            "mode",
            Power,
            FixedProfile(30.0),
            FixedProfile(0.01),
            FixedProfile(0.1),
            FixedProfile(1),
            2,
            ExtensionData[]
        )
        case, modeltype = simple_geo_uni(mode)

        # Extract from the case structure
        ℒᵗʳᵃⁿˢ = get_transmissions(case)
        𝒯 = get_time_struct(case)
        tm = modes(ℒᵗʳᵃⁿˢ)[1]

        # Test that the identification functions are working
        @test tm == mode
        @test EMG.is_bidirectional(tm)
        @test has_opex(tm) == true
        @test EMG.has_emissions(tm) == false

        # Test that the individual functions are extracting the correct value
        @test map_trans_resource(tm) == Power

        @test capacity(tm) == FixedProfile(30.0)
        @test all(capacity(tm, t) == 30.0 for t ∈ 𝒯)

        @test inputs(tm) == [Power]
        @test outputs(tm) == [Power]

        @test opex_var(tm) == FixedProfile(0.1)
        @test all(opex_var(tm, t) == 0.1 for t ∈ 𝒯)

        @test opex_fixed(tm) == FixedProfile(1)
        @test all(opex_fixed(tm, t) == 1 for t ∈ 𝒯)

        @test loss(tm) == FixedProfile(0.01)
        @test all(loss(tm, t) == 0.01 for t ∈ 𝒯)

        @test directions(tm) == 2

        @test EMG.emit_resources(tm) == ResourceEmit[]
        @test all(EMG.emissions(mode, CO2) == FixedProfile(0))
        @test all(EMG.emissions(mode, CO2, t) == 0 for t ∈ 𝒯)


        @test mode_data(tm) == ExtensionData[]
    end

    @testset "PipeMode and PipeLinepackSimple" begin
        # Tests for a RefStatPipeLinepackSimple as refernece for `PipeMode`
        mode = PipeLinepackSimple(
            "pipeline",
            H2_hp,                # Inlet
            H2_lp,                # Outlet
            Power,                # Consuming resource
            FixedProfile(0.05),   # Consumption rate
            FixedProfile(50),     # Capacity
            FixedProfile(0.01),   # Loss
            FixedProfile(0.1),    # Opex var
            FixedProfile(1.0),    # Opex fixed
            0.1,                  # Storage capacity
        )
        case, modeltype = simple_geo_uni(mode)

        # Extract from the case structure
        ℒᵗʳᵃⁿˢ = get_transmissions(case)
        𝒯 = get_time_struct(case)
        tm = modes(ℒᵗʳᵃⁿˢ)[1]

        # Test that the identification functions are working
        @test !EMG.is_bidirectional(tm)

        # Test that the individual functions are extracting the correct value
        @test map_trans_resource(tm) == H2_hp

        @test inputs(tm) == [H2_hp, Power]
        @test outputs(tm) == [H2_lp]

        @test consumption_rate(tm) == FixedProfile(0.05)
        @test all(consumption_rate(tm, t) == 0.05 for t ∈ 𝒯)

        @test energy_share(tm) == 0.1
    end
    @testset "Subsets of modes" begin
        ℳ = mode_subset()
        @test modes_sub(ℳ, "static") == ℳ[1:10]
        @test modes_sub(ℳ, ["static_2", "static_3"]) == ℳ[2:3]
        @test modes_sub(ℳ, ["static_5", "pipe_1"]) == ℳ[[5, 21, 30]]
    end
end

# Testset for RefStatic and RefDynamic
@testset "RefStatic and RefDynamic" begin
    # Test for unidirectional transport
    @testset "Unidirectional" begin
        function uni_analysis(mode)
            case, modeltype = simple_geo_uni(mode)
            m = optimize(case, modeltype)

            # Extract from the case structure
            ℒᵗʳᵃⁿˢ = get_transmissions(case)
            𝒯 = get_time_struct(case)
            𝒯ᴵⁿᵛ = strategic_periods(𝒯)
            tm = modes(ℒᵗʳᵃⁿˢ)[1]
            snk = get_nodes(case)[4]

            # General tests (optimality and production)
            general_tests(m)
            prof = OperationalProfile([20.0, 10.0, 5.0, 20.0])
            @test all(value.(m[:trans_out][tm, t]) ≈ prof[t] for t ∈ 𝒯)

            # Test that the negative and positive contributions are not included
            # - variables_trans_mode(m, 𝒯, ℳˢᵘᵇ::Vector{<:TransmissionMode}, modeltype::EnergyModel)
            @test isempty(m[:trans_neg])
            @test isempty(m[:trans_pos])

            # Test that the capacity is bound at the upper limit
            # - constraints_capacity(m, tm::TransmissionMode, 𝒯::TimeStructure, modeltype::EnergyModel)
            @test all(value.(m[:trans_out][tm, t]) ≤ value.(m[:trans_cap][tm, t]) for t ∈ 𝒯)
            @test all(has_lower_bound(m[:trans_out][tm, t]) for t ∈ 𝒯)
            @test all(has_lower_bound(m[:trans_in][tm, t]) for t ∈ 𝒯)
            @test all(lower_bound(m[:trans_out][tm, t]) == 0 for t ∈ 𝒯)
            @test all(lower_bound(m[:trans_in][tm, t]) == 0 for t ∈ 𝒯)

            # Test that the capacity is fixed to the provided value
            # - constraints_capacity_installed(m, tm::TransmissionMode, 𝒯::TimeStructure, modeltype::EnergyModel)
            @test all(is_fixed(m[:trans_cap][tm, t]) for t ∈ 𝒯)
            @test all(value.(m[:trans_cap][tm, t]) ≈ 20 for t ∈ 𝒯)
            @test all(value.(m[:trans_cap][tm, t]) ≈ capacity(tm, t) for t ∈ 𝒯)

            # Test that the loss is correctly calculated
            # - constraints_trans_loss(m, tm::PipeMode, 𝒯::TimeStructure, modeltype::EnergyModel)
            @test all(
                value.(m[:trans_loss][tm, t]) ≈
                    value.(m[:trans_in][tm, t]) * loss(tm, t)
                for t ∈ 𝒯)
            @test all(value.(m[:trans_loss][tm, t]) * 0.99 ≈ prof[t] * 0.01 for t ∈ 𝒯)

            # Test that the balance is correctly calculated
            # - constraints_trans_balance(m, tm::TransmissionMode, 𝒯::TimeStructure, modeltype::EnergyModel)
            @test all(
                value.(m[:trans_loss][tm, t]) ≈
                    value.(m[:trans_in][tm, t]) - value.(m[:trans_out][tm, t])
            for t ∈ 𝒯)

            # Test that the OPEX values are correctly calculated
            # - constraints_opex_fixed(m, tm::TransmissionMode, 𝒯ᴵⁿᵛ, modeltype::EnergyModel)
            # - constraints_opex_var(m, tm::TransmissionMode, 𝒯ᴵⁿᵛ, modeltype::EnergyModel)
            @test all(value.(m[:trans_opex_fixed][tm, t_inv]) ≈ 2 * 20 for t_inv ∈ 𝒯ᴵⁿᵛ)
            @test all(
                value.(m[:trans_opex_fixed][tm, t_inv]) ≈
                    opex_fixed(tm, t_inv) * value.(m[:trans_cap][tm, first(t_inv)])
            for t_inv ∈ 𝒯ᴵⁿᵛ)
            @test all(
                value.(m[:trans_opex_var][tm, t_inv]) ≈ sum(2 * 0.1 * prof[t] for t ∈ t_inv)
            for t_inv ∈ 𝒯ᴵⁿᵛ)
            @test all(
                value.(m[:trans_opex_var][tm, t_inv]) ≈
                    sum(
                        value.(m[:trans_out][tm, t]) * opex_var(tm, t) * scale_op_sp(t_inv, t)
                    for t ∈ t_inv)
            for t_inv ∈ 𝒯ᴵⁿᵛ)

            # Test that the OPEX values are included in the cost function
            @test objective_value(m) ≈ -4204
            @test objective_value(m) ≈ -sum(
                value.(m[:trans_opex_fixed][tm, t_inv]) +
                 value.(m[:trans_opex_var][tm, t_inv]) +
                sum(
                    value.(m[:sink_deficit][snk, t]) * deficit_penalty(snk, t) *
                    scale_op_sp(t_inv, t)
                    for t ∈ t_inv)
            for t_inv ∈ 𝒯ᴵⁿᵛ)
        end

        # Test RefStatic
        mode = RefStatic(
            "mode",
            Power,
            FixedProfile(20),
            FixedProfile(0.01),
            FixedProfile(0.1),
            FixedProfile(2),
            1,
        )
        uni_analysis(mode)

        # Test RefDynamic
        mode = RefDynamic(
            "mode",
            Power,
            FixedProfile(20),
            FixedProfile(0.01),
            FixedProfile(0.1),
            FixedProfile(2),
            1,
        )
        uni_analysis(mode)
    end

    @testset "Bidirectional" begin
        function bi_analysis(mode)
            case, modeltype = simple_geo_bi(mode)
            m = optimize(case, modeltype)

            # Extract from the case structure
            ℒᵗʳᵃⁿˢ = get_transmissions(case)
            𝒯 = get_time_struct(case)
            𝒯ᴵⁿᵛ = strategic_periods(𝒯)
            tm = modes(ℒᵗʳᵃⁿˢ)[1]
            src_a = get_nodes(case)[2]
            src_b = get_nodes(case)[5]

            # Calculate the bidirectional value
            in_val = 20 * (1 + 0.5*0.01) / (1 - 0.5*0.01)
            bi_val = (in_val + 20)/2

            # General tests (optimality and production)
            general_tests(m)
            prof = OperationalProfile([20.0, -in_val, 20, -in_val])
            @test all(value.(m[:trans_out][tm, t]) ≈ prof[t] for t ∈ 𝒯)

            # Test that the flow variables have the same sign
            # - variables_flow(m, ℒᵗʳᵃⁿˢ::Vector{Transmission}, 𝒳ᵛᵉᶜ, 𝒯, modeltype::EnergyModel)
            @test all(
                sign(value.(m[:trans_in][tm, t])) == sign(value.(m[:trans_out][tm, t]))
            for t ∈ 𝒯)

            # Test that the negative and positive contributions are included and have a lower bound
            # - variables_trans_mode(m, 𝒯, ℳˢᵘᵇ::Vector{<:TransmissionMode}, modeltype::EnergyModel)
            @test !isempty(m[:trans_neg])
            @test !isempty(m[:trans_pos])
            @test all(has_lower_bound(m[:trans_neg][tm, t]) for t ∈ 𝒯)
            @test all(has_lower_bound(m[:trans_pos][tm, t]) for t ∈ 𝒯)
            @test all(lower_bound(m[:trans_neg][tm, t]) == 0 for t ∈ 𝒯)
            @test all(lower_bound(m[:trans_pos][tm, t]) == 0 for t ∈ 𝒯)

            # Test that the capacity is bound at the upper limit
            # - constraints_capacity(m, tm::TransmissionMode, 𝒯::TimeStructure, modeltype::EnergyModel)
            @test all(value.(m[:trans_out][tm, t]) ≤ value.(m[:trans_cap][tm, t]) for t ∈ 𝒯)
            @test all(value.(m[:trans_in][tm, t]) ≥ -value.(m[:trans_cap][tm, t]) for t ∈ 𝒯)
            @test all(!has_lower_bound(m[:trans_out][tm, t]) for t ∈ 𝒯)
            @test all(!has_lower_bound(m[:trans_in][tm, t]) for t ∈ 𝒯)

            # Test that the capacity is fixed to the provided value
            # - constraints_capacity_installed(m, tm::TransmissionMode, 𝒯::TimeStructure, modeltype::EnergyModel)
            @test all(is_fixed(m[:trans_cap][tm, t]) for t ∈ 𝒯)
            @test all(value.(m[:trans_cap][tm, t]) ≈ 20 for t ∈ 𝒯)
            @test all(value.(m[:trans_cap][tm, t]) ≈ capacity(tm, t) for t ∈ 𝒯)

            # Test that the loss is correctly calculated
            # - constraints_trans_loss(m, tm::PipeMode, 𝒯::TimeStructure, modeltype::EnergyModel)
            @test all(
                value.(m[:trans_loss][tm, t]) ≈
                    value.(m[:trans_pos][tm, t] + m[:trans_neg][tm, t]) * loss(tm, t)
            for t ∈ 𝒯)
            @test all(value.(m[:trans_loss][tm, t]) ≈ bi_val * 0.01 for t ∈ 𝒯)
            @test all(
                value.(m[:trans_pos][tm, t] - m[:trans_neg][tm, t]) ≈
                    0.5 * value.(m[:trans_in][tm, t] + m[:trans_out][tm, t])
            for t ∈ 𝒯)
            @test all(
                value.(m[:trans_pos][tm, t]) ≈ OperationalProfile([bi_val, 0, bi_val, 0])[t]
            for t ∈ 𝒯)
            @test all(
                value.(m[:trans_neg][tm, t]) ≈ OperationalProfile([0, bi_val, 0, bi_val])[t]
            for t ∈ 𝒯)

            # Test that the balance is correctly calculated
            # - constraints_trans_balance(m, tm::TransmissionMode, 𝒯::TimeStructure, modeltype::EnergyModel)
            @test all(
                value.(m[:trans_loss][tm, t]) ≈
                    value.(m[:trans_in][tm, t]) - value.(m[:trans_out][tm, t])
            for t ∈ 𝒯)

            # Test that the OPEX values are correctly calculated (fixed remains unchanged)
            # - constraints_opex_var(m, tm::TransmissionMode, 𝒯ᴵⁿᵛ, modeltype::EnergyModel)
            @test all(
                value.(m[:trans_opex_fixed][tm, t_inv]) ≈
                    opex_fixed(tm, t_inv) * value.(m[:trans_cap][tm, first(t_inv)])
            for t_inv ∈ 𝒯ᴵⁿᵛ)
            @test all(value.(m[:trans_opex_fixed][tm, t_inv]) ≈ 2 * 20 for t_inv ∈ 𝒯ᴵⁿᵛ)
            @test all(
                value.(m[:trans_opex_var][tm, t_inv]) ≈
                    sum(
                        value.((m[:trans_pos][tm, t] + m[:trans_neg][tm, t])) *
                        opex_var(tm, t) * scale_op_sp(t_inv, t)
                    for t ∈ t_inv)
            for t_inv ∈ 𝒯ᴵⁿᵛ)
            @test all(
                value.(m[:trans_opex_var][tm, t_inv]) ≈ sum(2 * 0.1 * bi_val for t ∈ t_inv)
            for t_inv ∈ 𝒯ᴵⁿᵛ)

            # Test that the OPEX values are included in the cost function
            @test objective_value(m) ≈ -24224.321608
            @test objective_value(m) ≈ -sum(
                value.(m[:trans_opex_fixed][tm, t_inv]) +
                    value.(m[:trans_opex_var][tm, t_inv]) +
                sum(
                    (
                        value.(m[:cap_use][src_a, t]) * opex_var(src_a, t) +
                        value.(m[:cap_use][src_b, t]) * opex_var(src_b, t)
                    ) * scale_op_sp(t_inv, t)
                    for t ∈ t_inv)
            for t_inv ∈ 𝒯ᴵⁿᵛ)
        end

        # Test RefStatic
        mode = RefStatic(
            "mode",
            Power,
            FixedProfile(20),
            FixedProfile(0.01),
            FixedProfile(0.1),
            FixedProfile(2),
            2,
        )
        bi_analysis(mode)

        # Test RefDynamic
        mode = RefDynamic(
            "mode",
            Power,
            FixedProfile(20),
            FixedProfile(0.01),
            FixedProfile(0.1),
            FixedProfile(2),
            2,
        )
        bi_analysis(mode)
    end

    @testset "Reversed couplings" begin
        # Test that reversed couplings are working for EMG
        tm = RefStatic(
            "mode",
            Power,
            FixedProfile(20),
            FixedProfile(0.01),
            FixedProfile(0.1),
            FixedProfile(2),
            2,
        )
        case, modeltype = simple_geo_uni(tm)
        case_rev = Case(
            get_time_struct(case),
            get_products(case),
            get_elements_vec(case),
            [[get_nodes, get_links], [get_transmissions, get_areas]],
        )
        m = optimize(case_rev, modeltype)
        general_tests(m)
    end
end

# Testset for PipeSimple
@testset "PipeSimple" begin
    mode = PipeSimple(
        "mode",
        H2_hp,
        H2_lp,
        Power,
        FixedProfile(0.05),   # Consumption rate
        FixedProfile(20),     # Capacity
        FixedProfile(0.01),   # Loss
        FixedProfile(0.1),    # Opex var
        FixedProfile(2.5),    # Opex fixed
    )
    case, modeltype = simple_geo_pipe(mode)
    m = optimize(case, modeltype)

    # Extract from the case structure
    ℒᵗʳᵃⁿˢ = get_transmissions(case)
    𝒯 = get_time_struct(case)
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)
    tm = modes(ℒᵗʳᵃⁿˢ)[1]
    H2_src = get_nodes(case)[2]
    el_src = get_nodes(case)[3]
    snk = get_nodes(case)[5]

    # General tests (optimality and production)
    general_tests(m)
    prof = OperationalProfile([20.0, 10.0, 5.0, 20.0])
    @test all(value.(m[:trans_out][tm, t]) ≈ prof[t] for t ∈ 𝒯)

    # Test that the negative and positive contributions are not included
    # - variables_trans_mode(m, 𝒯, ℳˢᵘᵇ::Vector{<:TransmissionMode}, modeltype::EnergyModel)
    @test isempty(m[:trans_neg])
    @test isempty(m[:trans_pos])

    # Test that the capacity is bound at the upper limit
    # - constraints_capacity(m, tm::PipeMode, 𝒯::TimeStructure, modeltype::EnergyModel)
    @test all(value.(m[:trans_out][tm, t]) ≤ value.(m[:trans_cap][tm, t]) for t ∈ 𝒯)
    @test all(has_lower_bound(m[:trans_out][tm, t]) for t ∈ 𝒯)
    @test all(has_lower_bound(m[:trans_in][tm, t]) for t ∈ 𝒯)
    @test all(lower_bound(m[:trans_out][tm, t]) == 0 for t ∈ 𝒯)
    @test all(lower_bound(m[:trans_in][tm, t]) == 0 for t ∈ 𝒯)

    # Test that the capacity is fixed to the provided value
    # - constraints_capacity_installed(m, tm::TransmissionMode, 𝒯::TimeStructure, modeltype::EnergyModel)
    @test all(is_fixed(m[:trans_cap][tm, t]) for t ∈ 𝒯)
    @test all(value.(m[:trans_cap][tm, t]) ≈ 20 for t ∈ 𝒯)
    @test all(value.(m[:trans_cap][tm, t]) ≈ capacity(tm, t) for t ∈ 𝒯)

    # Test that the loss is correctly calculated
    # - constraints_trans_loss(m, tm::PipeMode, 𝒯::TimeStructure, modeltype::EnergyModel)
    @test all(
        value.(m[:trans_loss][tm, t]) ≈
            value.(m[:trans_in][tm, t]) * loss(tm, t)
        for t ∈ 𝒯)
    @test all(value.(m[:trans_loss][tm, t]) * 0.99 ≈ prof[t] * 0.01 for t ∈ 𝒯)

    # Test that the balance is correctly calculated
    # - constraints_trans_balance(m, tm::TransmissionMode, 𝒯::TimeStructure, modeltype::EnergyModel)
    @test all(
        value.(m[:trans_loss][tm, t]) ≈
            value.(m[:trans_in][tm, t]) - value.(m[:trans_out][tm, t])
    for t ∈ 𝒯)

    # Test that the OPEX values are correctly calculated
    # - constraints_opex_fixed(m, tm::TransmissionMode, 𝒯ᴵⁿᵛ, modeltype::EnergyModel)
    # - constraints_opex_var(m, tm::TransmissionMode, 𝒯ᴵⁿᵛ, modeltype::EnergyModel)
    @test all(value.(m[:trans_opex_fixed][tm, t_inv]) ≈ 2.5 * 20 for t_inv ∈ 𝒯ᴵⁿᵛ)
    @test all(
        value.(m[:trans_opex_fixed][tm, t_inv]) ≈
            opex_fixed(tm, t_inv) * value.(m[:trans_cap][tm, first(t_inv)])
    for t_inv ∈ 𝒯ᴵⁿᵛ)
    @test all(
        value.(m[:trans_opex_var][tm, t_inv]) ≈ sum(2 * 0.1 * prof[t] for t ∈ t_inv)
    for t_inv ∈ 𝒯ᴵⁿᵛ)
    @test all(
        value.(m[:trans_opex_var][tm, t_inv]) ≈
            sum(
                value.(m[:trans_out][tm, t]) * opex_var(tm, t) * scale_op_sp(t_inv, t)
            for t ∈ t_inv)
    for t_inv ∈ 𝒯ᴵⁿᵛ)

    # Test that the OPEX values are included in the cost function
    @test objective_value(m) ≈ -4244
    @test objective_value(m) ≈ -sum(
        value.(m[:trans_opex_fixed][tm, t_inv]) +
        value.(m[:trans_opex_var][tm, t_inv]) +
        sum(
            value.(m[:sink_deficit][snk, t]) * deficit_penalty(snk, t) *
            scale_op_sp(t_inv, t)
            for t ∈ t_inv)
    for t_inv ∈ 𝒯ᴵⁿᵛ)
end

# Testset for PipeLinepackSimple
@testset "PipeLinepackSimple" begin
    mode = PipeLinepackSimple(
        "mode",
        H2_hp,
        H2_lp,
        Power,
        FixedProfile(0.05),   # Consumption rate
        FixedProfile(30),     # Capacity
        FixedProfile(0.01),   # Loss
        OperationalProfile([0.1, 0, 0.2, 0.3]),    # Opex var
        FixedProfile(2.5),    # Opex fixed
        0.5,                  # Storage capacity
    )
    case, modeltype = simple_geo_pipe(mode; cap = OperationalProfile([25, 5, 25, 15]))
    m = optimize(case, modeltype)

    # Extract from the case structure
    𝒯 = get_time_struct(case)
    𝒫 = get_products(case)
    𝒩 = get_nodes(case)
    ℒ = get_links(case)
    𝒜 = get_areas(case)
    ℒᵗʳᵃⁿˢ = get_transmissions(case)
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)
    tm = modes(ℒᵗʳᵃⁿˢ)[1]
    H2_src, el_src, snk = 𝒩[[2, 3, 5]]

    # General tests (optimality and production)
    general_tests(m)
    prof = OperationalProfile([20.0, 10, 5.0, 22.05])
    @test all(value.(m[:trans_out][tm, t]) ≈ prof[t] for t ∈ 𝒯)

    # Test that the capacity is bound at the upper limit
    # - constraints_capacity(m, tm::PipeLinepackSimple, 𝒯::TimeStructure, modeltype::EnergyModel)
    @test all(value.(m[:trans_out][tm, t]) ≤ value.(m[:trans_cap][tm, t]) for t ∈ 𝒯)
    @test all(
        value.(m[:linepack_stor_level][tm, t]) ≤
            value.(m[:trans_cap][tm, t]) * 0.5
    for t ∈ 𝒯)
    @test all(has_lower_bound(m[:trans_out][tm, t]) for t ∈ 𝒯)
    @test all(has_lower_bound(m[:trans_in][tm, t]) for t ∈ 𝒯)
    @test all(lower_bound(m[:trans_out][tm, t]) == 0 for t ∈ 𝒯)
    @test all(lower_bound(m[:trans_in][tm, t]) == 0 for t ∈ 𝒯)

    # Test that the balance is correctly calculated
    # - constraints_trans_balance(m, tm::PipeLinepackSimple, 𝒯::TimeStructure, modeltype::EnergyModel)
    @test all(
        value.(m[:linepack_stor_level][tm, t] - m[:linepack_stor_level][tm, t_prev])  ≈
            value.(m[:trans_in][tm, t] - m[:trans_loss][tm, t] - m[:trans_out][tm, t]) *
            duration(t)
    for t_inv ∈ 𝒯ᴵⁿᵛ for (t_prev, t) ∈ withprev(t_inv) if !isnothing(t_prev))
    @test all(
        value.(m[:linepack_stor_level][tm, first(t_inv)] - m[:linepack_stor_level][tm, last(t_inv)])  ≈
            value.(m[:trans_in][tm, first(t_inv)] - m[:trans_loss][tm, first(t_inv)] - m[:trans_out][tm, first(t_inv)]) *
            duration(first(t_inv))
    for t_inv ∈ 𝒯ᴵⁿᵛ)
    @test all(
        value.(m[:linepack_stor_level][tm, t]) ≈ OperationalProfile([10.1, 0, 15.0, 0.6])[t]
    for t ∈ 𝒯)
end
