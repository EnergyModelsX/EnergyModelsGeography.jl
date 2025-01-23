
@testset "create_model" begin
    """
        small_graph_dep()

    Creates a simple geography test case for testing that the deprecation is working correctly.
    """
    function small_graph_dep()
        # Declaration of the required resources
        CO2 = ResourceEmit("CO2", 1.0)
        Power = ResourceCarrier("Power", 0.0)
        products = [Power, CO2]

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

        transmission_line = RefStatic(
            "transline",
            Power,
            FixedProfile(40),
            FixedProfile(0.1),
            FixedProfile(0.0),
            FixedProfile(0.0),
            1,
        )

        transmissions = [Transmission(areas[1], areas[2], [transmission_line])]

        # Creation of the time structure and the used global data
        T = TwoLevel(4, 1, SimpleTimes(1, 1))
        modeltype = OperationalModel(
            Dict(CO2 => StrategicProfile([450, 400, 350, 300])),
            Dict(CO2 => StrategicProfile([0, 0, 0, 0])),
            CO2,
        )

        # Input data structures
        case_old = Dict(
            :nodes => nodes,
            :links => links,
            :products => products,
            :areas => areas,
            :transmission => transmissions,
            :T => T,
        )
        case_new = Case(
            T,
            products,
            [nodes, links, areas, transmissions],
            [[get_nodes, get_links], [get_areas, get_transmissions]],
        )
        return case_new, case_old, modeltype
    end
    # Receive the case descriptions
    case_new, case_old, modeltype = small_graph_dep()

    # Create models based on both input and optimize it
    m_new = optimize(case_new, modeltype)

    m_old = EMG.create_model(case_old, modeltype)
    set_optimizer(m_old, optimizer)
    set_optimizer_attribute(m_old, MOI.Silent(), true)
    optimize!(m_old)

    # Test that the results are the same
    @test objective_value(m_old) ≈ objective_value(m_new)
    @test size(all_variables(m_old))[1] == size(all_variables(m_new))[1]
end
