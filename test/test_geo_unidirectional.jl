# Definition of the individual resources used in the simple system
Power   = ResourceCarrier("Power", 0.)
CO2      = ResourceEmit("CO2",1.)

ROUND_DIGITS = 8


function small_graph(source=nothing, sink=nothing)
    products = [Power, CO2]

    # Creation of a dictionary with entries of 0. for all resources
    𝒫₀ = Dict(k  => 0 for k ∈ products)

    # Creation of the source and sink module as well as the arrays used for nodes and links
    if isnothing(source)
        source = RefSource("-src", FixedProfile(25), FixedProfile(10), 
            FixedProfile(5), Dict(Power => 1), [])
    end

    if isnothing(sink)
        sink = RefSink("-snk", FixedProfile(20), 
            Dict(:Surplus => FixedProfile(0), :Deficit => FixedProfile(1e6)), 
            Dict(Power => 1))
    end

    nodes = [EMG.GeoAvailability(1, 𝒫₀, 𝒫₀), EMG.GeoAvailability(1, 𝒫₀, 𝒫₀), source, sink]
    links = [Direct(31, nodes[3], nodes[1], Linear())
             Direct(24, nodes[2], nodes[4], Linear())]
    
    # Creation of the two areas and potential transmission lines
    areas = [RefArea(1, "Oslo", 10.751, 59.921, nodes[1]), 
             RefArea(2, "Trondheim", 10.398, 63.4366, nodes[2])]        

    transmission_line_1 = EMG.RefStatic("transline1", Power, FixedProfile(100), FixedProfile(0.1), FixedProfile(0.1), FixedProfile(0.1), 1, [])
    transmission_line_2 = EMG.RefStatic("transline2", Power, FixedProfile(100), FixedProfile(0.1), FixedProfile(0.1), FixedProfile(0.1), 1, [])
    transmissions = [Transmission(areas[1], areas[2], [transmission_line_1]),
                     Transmission(areas[2], areas[1], [transmission_line_2])]

    # Creation of the time structure and the used global data
    T = TwoLevel(4, 1, SimpleTimes(4, 1))
    modeltype = OperationalModel(Dict(CO2 => StrategicProfile([450, 400, 350, 300])),
                                CO2,
                                )


    # Creation of the case dictionary
    case = Dict(:nodes          => nodes,
                :links          => links,
                :products       => products,
                :areas          => areas,
                :transmission   => transmissions,
                :T              => T,
                )
    return case, modeltype
end



function transmission_tests(m, case)
    # Extraction of relevant data from the model
    source  = case[:nodes][3]
    sink    = case[:nodes][4]
    𝒯       = case[:T]
    Power   = case[:products][1]
    
    tr_osl_trd, tr_trd_osl  = case[:transmission]
    tr_osl_trd_mode         = tr_osl_trd.Modes[1]
    tr_trd_osl_mode         = tr_trd_osl.Modes[1]
    areas                   = case[:areas]

    @testset "Test transmission" begin
        
        loss = tr_osl_trd_mode.Trans_loss
        if sum(value.(m[:cap_inst][source, t]) ≥ value.(m[:cap_inst][sink, t]) for t ∈ 𝒯) == length(𝒯)
            # If the source has the needed capacity, it should cover the usage in the sink exactly.
            @test sum(round(value.(m[:cap_use][source, t]) * (1 - loss[t]), digits = ROUND_DIGITS) 
                == round(value.(m[:cap_use][sink, t]), digits = ROUND_DIGITS) for t ∈ 𝒯) == length(𝒯)
   
            # TODO: check that the correct amount is transmitted.
        end
        
        # Test that energy is transferred
        @test sum(value.(m[:trans_in])[tr_osl_trd_mode, t] > 0 for t ∈ 𝒯) ==
                length(𝒯)

        # Check that the transmission loss is computed correctly.
        @test sum(round(value.(m[:trans_loss][tr_osl_trd_mode, t]), digits = ROUND_DIGITS) 
            == round(loss[t] * value.(m[:trans_in][tr_osl_trd_mode, t]), digits = ROUND_DIGITS) for t ∈ 𝒯) == length(𝒯)

        @test sum(value.(m[:trans_in][tr_osl_trd_mode, t]) >= 0 for t ∈ 𝒯) == length(𝒯)
        @test sum(value.(m[:trans_in][tr_trd_osl_mode, t]) == 0 for t ∈ 𝒯) == length(𝒯)
    end
end


@testset "Unidirectional transmission" begin
    
    # Creation and run of the model
    case, modeltype = small_graph()
    m    = optimize(case, modeltype)

    # Run of the generalized tests
    general_tests(m)
    transmission_tests(m, case)
end


# The PipeSimple should be equivalent to the RefStatic (and RefDynamic) if 
# * PipeSimple.Consumption_rate = 0
# * PipeSimple.Inlet == PipelinMode.Outlet
# This test uses the same tests as the transmission testscase above, but uses
# PipeSimple as the TransmissionMode instead.
@testset "Unidirectional pipeline transmission" begin
    
    case, modeltype = small_graph()

    # Replace each TransmissionMode's with a PipeSimple with identical properties.
    for transmission in case[:transmission]
        for (i, prev_tmode) in enumerate(transmission.Modes)
            pipeline = EMG.PipeSimple(prev_tmode.Name, 
                                        prev_tmode.Resource,
                                        prev_tmode.Resource,
                                        prev_tmode.Resource, # Doesn't matter when Consumption_rate = 0
                                        FixedProfile(0), 
                                        prev_tmode.Trans_cap,
                                        prev_tmode.Trans_loss,
                                        prev_tmode.Opex_var,
                                        prev_tmode.Opex_fixed,
                                        prev_tmode.Directions,
                                        [])
            @assert prev_tmode.Directions == 1 "The Dircetion mode should be 
                                                 unidirectional."
            transmission.Modes[i] = pipeline
        end
    end

    m = optimize(case, modeltype)
    general_tests(m)
    transmission_tests(m, case)
end
