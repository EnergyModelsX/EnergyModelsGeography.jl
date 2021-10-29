# Definition of the individual resources used in the simple system
NG      = ResourceEmit("NG", 0.2)
CO2     = ResourceEmit("CO2", 1.)
Power   = ResourceCarrier("Power", 0.)
Coal    = ResourceCarrier("Coal", 0.35)

ROUND_DIGITS = 8


function small_graph(source=nothing, sink=nothing)
    # products = [NG, Coal, Power, CO2]
    products = [NG, Power, CO2, Coal]

    # Creation of a dictionary with entries of 0. for all resources
    𝒫₀ = Dict(k  => 0 for k ∈ products)

    # Creation of a dictionary with entries of 0. for all emission resources
    𝒫ᵉᵐ₀ = Dict(k  => 0. for k ∈ products if typeof(k) == ResourceEmit{Float64})
    𝒫ᵉᵐ₀[CO2] = 0.0

    # Creation of the source and sink module as well as the arrays used for nodes and links
    if isnothing(source)
        source = EMB.RefSource("-src", FixedProfile(25), FixedProfile(10), 
            FixedProfile(5), Dict(Power => 1), 𝒫ᵉᵐ₀, Dict(""=>EMB.EmptyData()))
    end

    if isnothing(sink)
        sink = EMB.RefSink("-snk", FixedProfile(20), Dict(:Surplus => 0, :Deficit => 1e6), Dict(Power => 1), 𝒫ᵉᵐ₀)
    end

    nodes = [GEO.GeoAvailability(1, 𝒫₀, 𝒫₀), GEO.GeoAvailability(1, 𝒫₀, 𝒫₀), source, sink]
    links = [EMB.Direct(31, nodes[3], nodes[1], EMB.Linear())
             EMB.Direct(24, nodes[2], nodes[4], EMB.Linear())]
    
    # Creation of the two areas and potential transmission lines
    areas = [GEO.Area(1, "Oslo", 10.751, 59.921, nodes[1]), 
             GEO.Area(2, "Trondheim", 10.398, 63.4366, nodes[2])]        

    transmission_line = GEO.RefStatic("transline", Power, 100, 0.1, 1)
    transmissions = [GEO.Transmission(areas[1], areas[2], [transmission_line],[Dict(""=> EMB.EmptyData())]),
                     GEO.Transmission(areas[2], areas[1], [transmission_line],[Dict(""=> EMB.EmptyData())])]

    # Creation of the time structure and the used global data
    T = UniformTwoLevel(1, 4, 1, UniformTimes(1, 4, 1))
    global_data = EMB.GlobalData(Dict(CO2 => StrategicFixedProfile([450, 400, 350, 300]),
                                      NG  => FixedProfile(1e6)
                                      ))


    # Creation of the case dictionary
    case = Dict(:nodes          => nodes,
                :links          => links,
                :products       => products,
                :areas          => areas,
                :transmission   => transmissions,
                :T              => T,
                :global_data    => global_data,
                )
    return case
end

function optimize(case)
    model = EMB.OperationalModel()
    m = GEO.create_model(case, model)
    optimizer = GLPK.Optimizer
    set_optimizer(m, optimizer)
    optimize!(m)
    return m
end


function general_tests(m)
    # Check if the solution is optimal.
    @testset "optimal solution" begin
        @test termination_status(m) == MOI.OPTIMAL

        if termination_status(m) != MOI.OPTIMAL
            @show termination_status(m)
        end
    end
end

@testset "Unidirectional transmission" begin
    
    # Creation and run of the model
    case = small_graph()
    m    = optimize(case)

    # Extraction of relevant data from the model
    source  = case[:nodes][3]
    sink    = case[:nodes][4]
    𝒯       = case[:T]
    Power   = case[:products][2]

    tr_osl_trd, tr_trd_osl  = case[:transmission]
    trans_mode              = case[:transmission][1].Modes[1]
    areas                   = case[:areas]

    # Run of the generalized tests
    general_tests(m)
    
    @testset "Test transmission" begin
        
        loss = trans_mode.Trans_loss
        if sum(value.(m[:cap_inst][source, t]) ≥ value.(m[:cap_inst][sink, t]) for t ∈ 𝒯) == length(𝒯)
            # If the source has the needed capacity, it should cover the usage in the sink exactly.
            @test sum(round(value.(m[:cap_use][source, t]) * (1 - loss), digits = ROUND_DIGITS) 
                == round(value.(m[:cap_use][sink, t]), digits = ROUND_DIGITS) for t ∈ 𝒯) == length(𝒯)
   
            # TODO: check that the correct amount is transmitted.
        end
        
        # Check that the transmission loss is computed correctly.
        @test sum(round(value.(m[:trans_loss][tr_osl_trd, t, trans_mode]), digits = ROUND_DIGITS) 
            == round(loss * value.(m[:trans_in][tr_osl_trd, t, trans_mode]), digits = ROUND_DIGITS) for t ∈ 𝒯) == length(𝒯)

        for t ∈ 𝒯
            @test value.(m[:trans_in][tr_osl_trd, t, trans_mode]) >= 0
            @test value.(m[:trans_in][tr_trd_osl, t, case[:transmission][2].Modes[1]]) == 0
        end
    end

end