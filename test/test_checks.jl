# Set the global to true to suppress the error message
EMB.TEST_ENV = true

# Resources used in the checks
Power = ResourceCarrier("Power", 0.0)
CO2 = ResourceEmit("CO2", 1.0)
NG = ResourceEmit("NG", 0.2)

# Function for setting up the system for testing Area checks
function simple_graph()
    products = [Power, CO2]

    # Creation of the source and sink module as well as the arrays used for nodes and links
    source = RefSource(
        "src",
        FixedProfile(25),
        FixedProfile(10),
        FixedProfile(5),
        Dict(Power => 1),
    )
    sink = RefSink(
        "sink",
        FixedProfile(20),
        Dict(:surplus => FixedProfile(0), :deficit => FixedProfile(1e6)),
        Dict(Power => 1),
    )

    nodes = [
        GeoAvailability(1, products),
        GeoAvailability(2, products),
        source,
        sink,
    ]
    links = [
        Direct(31, nodes[3], nodes[1], Linear()),
        Direct(24, nodes[2], nodes[4], Linear()),
    ]

    # Creation of the two areas and potential transmission lines
    areas = [
        RefArea(1, "Factory", 10.751, 59.921, nodes[1]),
        RefArea(2, "North Sea", 10.398, 63.4366, nodes[2]),
    ]

    transmission_line = RefStatic(
        "Transline",
        Power,
        FixedProfile(30.0),
        FixedProfile(0.05),
        FixedProfile(0.05),
        FixedProfile(0.05),
        1,
    )
    transmissions = [Transmission(areas[1], areas[2], [transmission_line])]

    # Creation of the time structure and the used global data
    T = TwoLevel(4, 1, SimpleTimes(4, 1))
    modeltype = OperationalModel(
        Dict(CO2 => StrategicProfile([450, 400, 350, 300])),
        Dict(CO2 => FixedProfile(0)),
        CO2
    )


    # Creation of the case type
    case = Case(
        T,
        products,
        [nodes, links, areas, transmissions],
        [[get_nodes, get_links], [get_areas, get_transmissions]],
    )
    return case, modeltype, transmission_line
end

@testset "Checks - Areas" begin
    @testset "Core structure" begin
        # Test that the availability node is correctly checked
        # - check_elements(log_by_element, 𝒜::Vector{<:Area}}, 𝒳, 𝒯, modeltype::EnergyModel, check_timeprofiles::Bool)

        # Test that the Availability node is in the node vector
        case, model, trans_line = simple_graph()
        𝒫 = get_products(case)
        case.elements[3][1] = RefArea(1, "Factory", 10.751, 59.921, GeoAvailability("test", 𝒫))
        case.elements[4][1] = Transmission(case.elements[3][1], case.elements[3][2], [trans_line])
        @test_throws AssertionError create_model(case, model)

        # Test that the availability node is a GeoAvailability node
        case, model, trans_line = simple_graph()
        av = GenAvailability("test", 𝒫)
        case.elements[1][1] = av
        case.elements[3][1] = RefArea(1, "Factory", 10.751, 59.921, av)
        case.elements[2][1] = Direct(31, case.elements[1][3], case.elements[1][1], Linear())
        case.elements[4][1] = Transmission(case.elements[3][1], case.elements[3][2], [trans_line])
        @test_throws AssertionError create_model(case, model)

        # Test that the availability node includes as product the exchange resources
        case, model, trans_line = simple_graph()
        av = GeoAvailability("test", Resource[𝒫[2]])
        case.elements[1][1] = av
        case.elements[3][1] = RefArea(1, "Factory", 10.751, 59.921, av)
        case.elements[2][1] = Direct(31, case.elements[1][3], case.elements[1][1], Linear())
        case.elements[4][1] = Transmission(case.elements[3][1], case.elements[3][2], [trans_line])
        @test_throws AssertionError create_model(case, model)
    end
end

@testset "Checks - Transmission" begin
    @testset "Core structure" begin
        # Test that the from and to fields are correctly checked
        # - check_elements(log_by_element, ℒᵗʳᵃⁿˢ::Vector{<:Tranmission}}, 𝒳, 𝒯, modeltype::EnergyModel, check_timeprofiles::Bool)
        case, model, trans_line = simple_graph()
        area = RefArea(1, "TestArea", 10.751, 59.921, case.elements[1][1])
        case.elements[4][1] = Transmission(case.elements[3][1], area, [trans_line])
        @test_throws AssertionError create_model(case, model)
        case.elements[4][1] = Transmission(area, case.elements[3][1], [trans_line])
        @test_throws AssertionError create_model(case, model)
    end
end

# Set the global again to false
EMB.TEST_ENV = false
