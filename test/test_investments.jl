using EnergyModelsInvestments
const EMI = EnergyModelsInvestments

# Declaration of the required resources
CO2 = ResourceEmit("CO2", 1.0)
Power = ResourceCarrier("Power", 0.0)
products = [Power, CO2]

"""
    small_graph_geo(; source = nothing, sink = nothing, inv_data = nothing)

Creates a simple geography test case with the potential for investments in transmission
infrastructure if provided with transmission investments through the argument `inv_data`.
"""
function small_graph_geo(; source = nothing, sink = nothing, inv_data = nothing)

    # Creation of the source and sink nodes as well as the arrays used for nodes and links
    if isnothing(source)
        source = RefSource(
            "-src",
            FixedProfile(50),
            FixedProfile(10),
            FixedProfile(5),
            Dict(Power => 1),
            Array{ExtensionData}([]),
        )
    end

    if isnothing(sink)
        sink = RefSink(
            "-snk",
            StrategicProfile([20, 25, 30, 35]),
            Dict(:surplus => FixedProfile(0), :deficit => FixedProfile(1e6)),
            Dict(Power => 1),
        )
    end

    nodes = [GeoAvailability(1, products), GeoAvailability(2, products), source, sink]
    links = [
        Direct(31, nodes[3], nodes[1], Linear())
        Direct(24, nodes[2], nodes[4], Linear())
    ]

    # Creation of the two areas and potential transmission lines
    areas = [
        RefArea(1, "Oslo", 10.751, 59.921, nodes[1]),
        RefArea(2, "Trondheim", 10.398, 63.4366, nodes[2]),
    ]

    if isnothing(inv_data)
        inv_data = ExtensionData[]
    else
        inv_data = [inv_data]
    end
    transmission_line = RefStatic(
        "transline",
        Power,
        FixedProfile(0),
        FixedProfile(0.1),
        FixedProfile(0.0),
        FixedProfile(0.0),
        1,
        inv_data,
    )

    transmissions = [Transmission(areas[1], areas[2], [transmission_line])]

    # Creation of the time structure and the used global data
    T = TwoLevel(4, 1, SimpleTimes(1, 1))
    modeltype = InvestmentModel(
        Dict(CO2 => StrategicProfile([450, 400, 350, 300])),
        Dict(CO2 => StrategicProfile([0, 0, 0, 0])),
        CO2,
        0.07,
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


# Test set for analysing the proper behaviour when no investment was included
@testset "Unidirectional transmission without investments" begin

    # Creation and run of the optimization problem
    case, modeltype = small_graph_geo()
    m               = optimize(case, modeltype)

    general_tests(m)

    # Extraction of required data
    𝒯 = get_time_struct(case)
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)
    sink = get_nodes(case)[4]
    tr_osl_trd = get_transmissions(case)[1]
    tm = modes(tr_osl_trd)[1]

    # Test identifying that the proper deficit is calculated
    @test sum(
        value.(m[:sink_deficit][sink, t]) ≈ capacity(sink, t) - capacity(tm, t) for t ∈ 𝒯
    ) == length(𝒯)

    # Test showing that no investment variables are created
    @test !haskey(m, :trans_cap_current)
    @test !haskey(m, :trans_cap_add)
    @test !haskey(m, :trans_cap_rem)
    @test !haskey(m, :trans_cap_invest_b)
    @test !haskey(m, :trans_cap_remove_b)
end

# Test set for continuous investments
@testset "Unidirectional transmission with ContinuousInvestment" begin

    # Creation and run of the optimization problem
    inv_data = SingleInvData(
        FixedProfile(10),       # capex [€/kW]
        FixedProfile(250),      # max installed capacity [kW]
        FixedProfile(0),        # initial capacity [kW]
        ContinuousInvestment(FixedProfile(0), FixedProfile(30)),
    )

    case, modeltype = small_graph_geo(;inv_data)
    m               = optimize(case, modeltype)

    general_tests(m)

    # Extraction of required data
    𝒯 = get_time_struct(case)
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)
    sink = get_nodes(case)[4]
    tr_osl_trd = get_transmissions(case)[1]
    tm = modes(tr_osl_trd)[1]
    inv_data = EMI.investment_data(tm, :cap)

    # Test identifying that there is no deficit
    @test sum(value.(m[:sink_deficit][sink, t]) == 0 for t ∈ 𝒯) == length(𝒯)

    # Test showing that the investments are as expected
    for (t_inv_prev, t_inv) ∈ withprev(𝒯ᴵⁿᵛ)
        if isnothing(t_inv_prev)
            @testset "First investment period" begin
                for t ∈ t_inv
                    @test (
                        value.(m[:trans_cap_add][tm, t_inv]) ≈
                        capacity(sink, t) - EMI.start_cap(tm, t_inv, inv_data, nothing)
                    ) atol = TEST_ATOL
                end
            end
        else
            @testset "Subsequent investment periods" begin
                for t ∈ t_inv
                    @test (
                        value.(m[:trans_cap_add][tm, t_inv]) ≈
                        capacity(sink, t) - value.(m[:trans_cap_current][tm, t_inv_prev])
                    ) atol = TEST_ATOL
                end
            end
        end
    end

end

# Test set for semicontinuous investments
@testset "Unidirectional transmission with SemiContinuousInvestment" begin

    # Creation and run of the optimization problem
    inv_data = SingleInvData(
        FixedProfile(10),       # capex [€/kW]
        FixedProfile(250),      # max installed capacity [kW]
        FixedProfile(0),        # initial capacity [kW]
        SemiContinuousInvestment(FixedProfile(10), FixedProfile(30)),
    )

    case, modeltype = small_graph_geo(;inv_data)
    m               = optimize(case, modeltype)

    general_tests(m)

    # Extraction of required data
    𝒯 = get_time_struct(case)
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)
    sink = get_nodes(case)[4]
    tr_osl_trd = get_transmissions(case)[1]
    tm = modes(tr_osl_trd)[1]
    inv_data = EMI.investment_data(tm, :cap)

    # Test identifying that there is no deficit
    @test sum(value.(m[:sink_deficit][sink, t]) == 0 for t ∈ 𝒯) == length(𝒯)

    # Test showing that the investments are as expected
    for (t_inv_prev, t_inv) ∈ withprev(𝒯ᴵⁿᵛ)
        @testset "Investment period $(t_inv.sp)" begin
            @testset "Invested capacity" begin
                if isnothing(t_inv_prev)
                    for t ∈ t_inv
                        @test (
                            value.(m[:trans_cap_add][tm, t_inv]) >= max(
                                capacity(sink, t)  - EMI.start_cap(tm, t_inv, inv_data, nothing),
                                EMI.min_add(inv_data, t) *
                                value.(m[:trans_cap_invest_b][tm, t_inv]),
                            )
                        )
                    end
                else
                    for t ∈ t_inv
                        @test (
                            value.(m[:trans_cap_add][tm, t_inv]) ⪆ max(
                                capacity(sink, t) -
                                value.(m[:trans_cap_current][tm, t_inv_prev]),
                                EMI.min_add(inv_data, t) *
                                value.(m[:trans_cap_invest_b][tm, t_inv]),
                            )
                        )
                    end
                end
            end

            # Test that the binary value is regulating the investments
            @testset "Binary value" begin
                if value.(m[:trans_cap_invest_b][tm, t_inv]) ≈ 0
                    atol = TEST_ATOL
                    @test value.(m[:trans_cap_add][tm, t_inv]) ≈ 0 atol = TEST_ATOL
                else
                    @test value.(m[:trans_cap_add][tm, t_inv]) ⪆ 0
                end
            end
        end
    end

    # Test that the variable `trans_cap_invest_b` is binary
    @test sum(is_binary(m[:trans_cap_invest_b][tm, t_inv]) for t_inv ∈ 𝒯ᴵⁿᵛ) == length(𝒯ᴵⁿᵛ)
end

# Test set for semicontinuous investments with offsets in the cost
@testset "Unidirectional transmission with SemiContinuousOffsetInvestment" begin

    # Creation and run of the optimization problem
    inv_data = SingleInvData(
        FixedProfile(10),       # capex [€/kW]
        FixedProfile(250),      # max installed capacity [kW]
        SemiContinuousOffsetInvestment(
            FixedProfile(10),
            FixedProfile(30),
            FixedProfile(10),
        ),
    )

    case, modeltype = small_graph_geo(;inv_data)
    m               = optimize(case, modeltype)

    general_tests(m)

    # Extraction of required data
    𝒯 = get_time_struct(case)
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)
    sink = get_nodes(case)[4]
    tr_osl_trd = get_transmissions(case)[1]
    tm = modes(tr_osl_trd)[1]
    inv_data = EMI.investment_data(tm, :cap)
    inv_mode = EMI.investment_mode(inv_data)

    # Test identifying that there is no deficit
    @test sum(value.(m[:sink_deficit][sink, t]) == 0 for t ∈ 𝒯) == length(𝒯)

    # Test showing that the investments are as expected
    for (t_inv_prev, t_inv) ∈ withprev(𝒯ᴵⁿᵛ)
        @testset "Investment period $(t_inv.sp)" begin
            @testset "Invested capacity" begin
                if isnothing(t_inv_prev)
                    for t ∈ t_inv
                        @test (
                            value.(m[:trans_cap_add][tm, t_inv]) ⪆ max(
                                capacity(sink, t) - EMI.start_cap(tm, t_inv, inv_data, nothing),
                                EMI.min_add(inv_data, t) *
                                value.(m[:trans_cap_invest_b][tm, t_inv]),
                            )
                        )
                    end
                else
                    for t ∈ t_inv
                        @test (
                            value.(m[:trans_cap_add][tm, t_inv]) ⪆ max(
                                capacity(sink, t) -
                                value.(m[:trans_cap_current][tm, t_inv_prev]),
                                EMI.min_add(inv_data, t) *
                                value.(m[:trans_cap_invest_b][tm, t_inv]),
                            )
                        )
                    end
                end
            end

            # Test that the binary value is regulating the investments
            @testset "Binary value" begin
                if value.(m[:trans_cap_invest_b][tm, t_inv]) ≈ 0
                    @test value.(m[:trans_cap_add][tm, t_inv]) ≈ 0 atol = TEST_ATOL
                else
                    @test value.(m[:trans_cap_add][tm, t_inv]) ⪆ 0
                end
            end
        end
    end
    @testset "Investment costs" begin
        @test sum(
            value(m[:trans_cap_add][tm, t_inv]) * EMI.capex(inv_data, t_inv) +
            EMI.capex_offset(inv_mode, t_inv) * value(m[:trans_cap_invest_b][tm, t_inv]) ≈
            value(m[:trans_cap_capex][tm, t_inv]) for t_inv ∈ 𝒯ᴵⁿᵛ, atol in TEST_ATOL
        ) == length(𝒯ᴵⁿᵛ)
    end

    # Test that the variable `trans_cap_invest_b` is binary
    @test sum(is_binary(m[:trans_cap_invest_b][tm, t_inv]) for t_inv ∈ 𝒯ᴵⁿᵛ) == length(𝒯ᴵⁿᵛ)
end

# Test set for discrete investments
@testset "Unidirectional transmission with DiscreteInvestment" begin

    # Creation and run of the optimization problem
    inv_data = SingleInvData(
        FixedProfile(10),       # capex [€/kW]
        FixedProfile(250),      # max installed capacity [kW]
        FixedProfile(0),        # initial capacity [kW]
        DiscreteInvestment(FixedProfile(5)),
    )

    case, modeltype = small_graph_geo(;inv_data)
    m               = optimize(case, modeltype)

    general_tests(m)

    # Extraction of required data
    𝒯 = get_time_struct(case)
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)
    sink = get_nodes(case)[4]
    tr_osl_trd = get_transmissions(case)[1]
    tm = modes(tr_osl_trd)[1]
    inv_data = EMI.investment_data(tm, :cap)

    # Test identifying that there is no deficit
    @test sum(value.(m[:sink_deficit][sink, t]) == 0 for t ∈ 𝒯) == length(𝒯)

    # Test showing that the investments are as expected
    for t_inv ∈ 𝒯ᴵⁿᵛ
        @testset "Invested capacity $(t_inv.sp)" begin
            if value.(m[:trans_cap_invest_b][tm, t_inv]) ≈ 0
                atol = TEST_ATOL
                @test value.(m[:trans_cap_add][tm, t_inv]) ≈ 0 atol = TEST_ATOL
            else
                @test value.(m[:trans_cap_add][tm, t_inv]) ≈
                      EMI.increment(inv_data, t_inv) *
                      value.(m[:trans_cap_invest_b][tm, t_inv])
            end
        end
    end

    # Test that the variable `trans_cap_invest_b` is an integer
    @test sum(is_integer(m[:trans_cap_invest_b][tm, t_inv]) for t_inv ∈ 𝒯ᴵⁿᵛ) ==
          length(𝒯ᴵⁿᵛ)
end
