const TEST_ATOL = 1e-6
const ROUND_DIGITS = 8
⪆(x, y) = x > y || isapprox(x, y; atol = TEST_ATOL)

using HiGHS
optimizer = HiGHS.Optimizer

function optimize(case, modeltype)
    m = create_model(case, modeltype)
    set_optimizer(m, optimizer)
    set_optimizer_attribute(m, MOI.Silent(), true)
    optimize!(m)
    return m
end

function general_tests(m)
    # Check if the solution is optimal.
    @testset "Optimal solution" begin
        @test termination_status(m) == MOI.OPTIMAL

        if termination_status(m) != MOI.OPTIMAL
            @show termination_status(m)
        end
    end
end

"""
    simple_case_new_mode(mode, products)

Test function for the transfer of a single resource using a `mode`. Te vector products must
contain exactly 2 resources, one `ResourceEmit` and one `ResourceCarrier`.
"""
function simple_case_new_mode(mode, products)
    # Extracting of the resources
    Power = filter(!EMB.is_resource_emit, products)[1]
    CO2 = filter(EMB.is_resource_emit, products)[1]

    # Creation of the source and sink module as well as the arrays used for nodes and links
    source = RefSource(
        "-src",
        FixedProfile(50),
        FixedProfile(10),
        FixedProfile(5),
        Dict(Power => 1),
    )

    sink = RefSink(
        "-snk",
        StrategicProfile([20, 25, 30, 35]),
        Dict(:surplus => FixedProfile(0), :deficit => FixedProfile(1e6)),
        Dict(Power => 1),
    )
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
    transmissions = [Transmission(areas[1], areas[2], TransmissionMode[mode])]

    # Creation of the time structure and the used global data
    T = TwoLevel(4, 1, SimpleTimes(4, 2))
    modeltype = OperationalModel(
                                Dict(CO2 => FixedProfile(1e3)),
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
