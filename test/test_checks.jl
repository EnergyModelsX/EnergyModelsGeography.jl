# Set the global to true to suppress the error message
EMB.TEST_ENV = true

@testset "Test checks - case dictionary" begin
    # Resources used in the analysis
    Power = ResourceCarrier("Power", 0.0)
    CO2 = ResourceEmit("CO2", 1.0)

    function small_graph()
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
            EMG.GeoAvailability(2, products),
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


        # Creation of the case dictionary
        case = Dict(:nodes => nodes,
            :links => links,
            :products => products,
            :areas => areas,
            :transmission => transmissions,
            :T => T,
        )
        return case, modeltype
    end

    # Check that the keys are present
    # - EMG.check_case_data(case)
    case, model = small_graph()
    for key ∈ [:areas, :transmission]
        case_test = deepcopy(case)
        pop!(case_test, key)
        @test_throws AssertionError EMG.create_model(case_test, model)
    end

    # Check that the keys are of the correct format and do not include any unwanted types
    # - EMG.check_case_data(case)
    case_test = deepcopy(case)
    case_test[:areas] = [case[:areas], case[:areas], 10]
    @test_throws AssertionError EMG.create_model(case_test, model)
    case_test = deepcopy(case)
    case_test[:transmission] = [case[:transmission], case[:transmission], 10]
    @test_throws AssertionError EMG.create_model(case_test, model)
end

# Set the global again to false
EMB.TEST_ENV = false
