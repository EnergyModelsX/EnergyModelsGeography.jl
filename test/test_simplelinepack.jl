CO2 = ResourceEmit("CO2", 1.0)
H2  = ResourceCarrier("H2", 0.0)
Power = ResourceCarrier("Power", 0.0)


"""
    small_graph_linepack()

A test case representing a simple model of a linepack case in which only a source and a sink
exist.
"""
function small_graph_linepack()
    products = [Power, H2, CO2]

    # Creation of the source and sink nodes as well as the arrays used for nodes and links
    source = RefSource(
        "-src",
        FixedProfile(25),
        OperationalProfile([10, 10, 10, 10, 100, 10, 10, 10, 10, 100]),
        FixedProfile(0),
        Dict(H2 => 1))

    sink = RefSink(
        "-sink",
        FixedProfile(15),
        Dict(:surplus => FixedProfile(0), :deficit => FixedProfile(1e6)),
        Dict(H2 => 1),
    )

    nodes = [GeoAvailability(1, products), EMG.GeoAvailability(2, products), source,
        sink]
    links = [Direct(31, nodes[3], nodes[1], Linear()),
        Direct(24, nodes[2], nodes[4], Linear()),
        ]

    # Creation of the two areas and potential transmission lines
    areas = [RefArea(1, "Factory", 10.751, 59.921, nodes[1]),
             RefArea(2, "North Sea", 10.398, 63.4366, nodes[2])]

    pipeline = PipeLinepackSimple(
        "pipeline",
        H2,                   # Inlet
        H2,                   # Outlet
        Power,                # Consuming resource
        FixedProfile(0),      # Consumption rate
        FixedProfile(50),     # Capacity
        FixedProfile(0.05),   # Loss
        FixedProfile(0.05),   # Opex var
        FixedProfile(0.05),   # Opex fixed
        0.1,                  # Energy share
        )

    transmissions = [Transmission(areas[1], areas[2], [pipeline])]

    # Creation of the time structure and the used global data
    T = TwoLevel(1, 1, SimpleTimes(10, 1))
    modeltype = OperationalModel(
                                Dict(CO2 => FixedProfile(1e4)),
                                Dict(CO2 => FixedProfile(0)),
                                CO2
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

case, modeltype = small_graph_linepack()

m = optimize(case, modeltype)
general_tests(m)

𝒯 = get_time_struct(case)
𝒫 = get_products(case)
𝒩 = get_nodes(case)
ℒ = get_transmissions(case)
𝒜 = get_areas(case)

Power = 𝒫[1]
area_from = 𝒜[1]
area_to = 𝒜[2]

source = 𝒩[3]
sink = 𝒩[4]

transmission = ℒ[1]
pipeline = modes(transmission)[1]

# Defining the required sets
𝒯ᴵⁿᵛ = strategic_periods(𝒯)

@testset "Energy transferred" begin
    # Test that energy is transferred
    @test sum(value.(m[:trans_out])[pipeline, t] > 0 for t ∈ 𝒯) ==
            length(𝒯)

end

@testset "Energy stored in linepack" begin

    # Check that no more energy is stored than is available in the pipeline
    @test sum(value.(m[:linepack_stor_level][pipeline, t])
        <=
        energy_share(pipeline) * value.(m[:trans_cap][pipeline, t]) for t ∈ 𝒯) == length(𝒯)

    # Check that the linepack level increase equals the difference between inlet and outlet flow
    @test sum(sum(
            isapprox(
                (value.(m[:trans_in][pipeline, t])*(1 - loss(pipeline, t)) -
                    value.(m[:trans_out][pipeline, t]))*duration(t),
                value.(m[:linepack_stor_level][pipeline, t]) -
                    (isnothing(t_prev) ?
                        value.(m[:linepack_stor_level][pipeline, last(t_inv)]) :
                        value.(m[:linepack_stor_level][pipeline, t_prev])
                    ),
                atol=TEST_ATOL
                )
            for (t_prev, t) ∈ withprev(t_inv)) for t_inv ∈ 𝒯ᴵⁿᵛ)  == length(𝒯)
end

@testset "Transport accounting" begin
    # Test that the overall system with line packing does not result in unaccounted energy
    @test sum((1 - loss(pipeline, t)) * value.(m[:trans_in][pipeline, t]) for t in 𝒯) ≈
                sum(value.(m[:trans_out][pipeline, t]) for t in 𝒯)  atol=TEST_ATOL
end
