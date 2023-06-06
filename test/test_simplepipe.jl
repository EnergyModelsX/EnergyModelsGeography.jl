struct LiquidResource{T<:Real} <: Resource
    id
    CO2Int::T
    pressure::Int
end
Base.show(io::IO, n::LiquidResource) = print(io, "$(n.id)-$(n.pressure)")

CO2 = ResourceEmit("CO2", 1.0)
Power = ResourceCarrier("Power", 0.0)

CO2_150 = LiquidResource("CO2", 1, 150)
CO2_90 = LiquidResource("CO2", 1, 90)
CO2_200 = LiquidResource("CO2", 1, 200)


"""
A test case representing a simple model of a CCS case, with a CO2 source with capture
implemented, then using a PipeSimple for transportation to the offshore storage site.
"""
function small_graph_co2_1()
    products = [Power, CO2, CO2_150, CO2_200]

    # Creation of a dictionary with entries of 0. for all resources
    𝒫₀ = Dict(k => 0 for k ∈ products)

    # Creation of the source and sink module as well as the arrays used for nodes and links
    source = RefSource("-src", FixedProfile(25), FixedProfile(10),
        FixedProfile(5), Dict(CO2_150 => 1, Power => 1), [])
    el_sink = RefSink("-el-sink", FixedProfile(0),
        Dict(:Surplus => FixedProfile(0), :Deficit => FixedProfile(1e6)), 
        Dict(Power => 1))

    sink = RefSink("-sink", FixedProfile(20),
        Dict(:Surplus => FixedProfile(0), :Deficit => FixedProfile(1e6)), 
        Dict(CO2_200 => 1))

    nodes = [GeoAvailability(1, 𝒫₀, 𝒫₀), EMG.GeoAvailability(2, 𝒫₀, 𝒫₀), source, 
        sink, el_sink]
    links = [Direct(31, nodes[3], nodes[1], Linear()),
        Direct(24, nodes[2], nodes[4], Linear()),
        Direct(15, nodes[1], nodes[5], Linear())]

    # Creation of the two areas and potential transmission lines
    areas = [RefArea(1, "Factory", 10.751, 59.921, nodes[1]),
             RefArea(2, "North Sea", 10.398, 63.4366, nodes[2])]

    pipeline = PipeSimple("pipeline", CO2_150, CO2_200, Power, FixedProfile(0.1), FixedProfile(100), FixedProfile(0.05), FixedProfile(0.05), FixedProfile(0.05), 1, [])

    transmissions = [Transmission(areas[1], areas[2], [pipeline])]

    # Creation of the time structure and the used global data
    T = TwoLevel(4, 1, SimpleTimes(4, 1))
    modeltype = OperationalModel(Dict(CO2 => StrategicProfile([450, 400, 350, 300])),
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


@testset "PipeSimple test" begin

    case, modeltype = small_graph_co2_1()

    m = optimize(case, modeltype)
    general_tests(m)

    𝒯 = case[:T]
    𝒫 = case[:products]
    𝒩 = case[:nodes]
    ℒ = case[:transmission]

    Power = 𝒫[1]
    CO2_150 = 𝒫[3]
    CO2_200 = 𝒫[4]

    area_from = case[:areas][1]
    area_to = case[:areas][2]

    a1 = 𝒩[1]
    a2 = 𝒩[2]
    source = 𝒩[3]
    sink = 𝒩[4]
    el_sink = 𝒩[5]

    transmission = case[:transmission][1]
    pipeline::EMG.PipeSimple = transmission.Modes[1]
    inlet_resource = pipeline.Inlet
    outlet_resource = pipeline.Outlet

    @testset "Energy transferred" begin     
        # Test that energy is transferred
        @test sum(value.(m[:trans_in])[pipeline, t] > 0 for t ∈ 𝒯) ==
                length(𝒯)

    end

    @testset "Resource exchange" begin
        # Check that only CO2_150 is exported from the factory area and that only 
        # CO2_200 is imported into the storage area.
        @test CO2_150 ∈ EMG.exchange_resources(ℒ, area_from)
        @test pipeline.Consuming ∈ EMG.exchange_resources(ℒ, area_from)
        @test CO2_200 ∈ EMG.exchange_resources(ℒ, area_to)
        # Both the transported and the consumed resource is exported from the area.
        @test length(EMG.exchange_resources(ℒ, area_from)) == 2
        @test length(EMG.exchange_resources(ℒ, area_to)) == 1

        # The variable :area_exchange should not have values for CO2_200 at the Factory 
        # area, and not for CO2_150 at the receiving area. This should hold for all time 
        # steps. Trying to access these variables should result in a KeyError.
        @test_throws KeyError value.(m[:area_exchange][area_from, first(𝒯), CO2_200])
        @test_throws KeyError value.(m[:area_exchange][area_to, first(𝒯), CO2_150])
        
        # The exported quantity should be negative and equal in absolute value to the 
        # trans_in (of the inlet resource).
        @test sum(value.(m[:area_exchange][area_from, t, CO2_150]) 
            == -value.(m[:trans_in][pipeline, t]) for t ∈ 𝒯) == length(𝒯)
        
        # The imported quantity should be positive and equal to trans_out of the pipeline
        # outlet resource.
        @test sum(value.(m[:area_exchange][area_to, t, CO2_200]) 
        == value.(m[:trans_out][pipeline, t]) for t ∈ 𝒯) == length(𝒯)
    end

    @testset "Consumed resource" begin
        # Test that the difference in Power at the availability node corresponds to the
        # pipeline.Consumption_rate.
        @test sum(value.(m[:flow_in][a1, t, Power]) * (1 - pipeline.Consumption_rate[t]) 
                  == value.(m[:flow_out][a1, t, Power]) for t ∈ 𝒯) == length(𝒯)

        # Test that the difference in Power in the availability node, is taken up in
        # the variable :area_exchange.
        @test sum(value.(m[:flow_in][a1, t, Power])
                  - value.(m[:flow_out][a1, t, Power]) ≈ 
                  - value(m[:area_exchange][area_from, t, Power])
                  for t ∈ 𝒯, atol=TEST_ATOL) == length(𝒯)
        
        # Check that what the source produces goes into the availability node.
        @test sum(value.(m[:flow_out][source, t, Power])
                  == value.(m[:flow_in][a1, t, Power]) for t ∈ 𝒯) == length(𝒯)
        
        # Check that what goes out of the availability node goes into the sink.
        @test sum(value.(m[:flow_out][a1, t, Power])
                  == value.(m[:flow_in][el_sink, t, Power]) for t ∈ 𝒯) == length(𝒯)
    end

    @testset "Transport accounting" begin
        # Test that the loss in transported volume is computed in the expected way.
        @test sum((1 - pipeline.Trans_loss[t]) * value.(m[:trans_in][pipeline, t])
                  ==
                  value.(m[:trans_out][pipeline, t])
                  for t in 𝒯, atol=TEST_ATOL) == length(𝒯)

        # Test that the :area_exchange variables in CO2_150 has the proper loss when transported
        # to the other area as CO2_200. The exported resource should have a negative sign.
        @test sum(-(1 - pipeline.Trans_loss[t]) * value.(m[:area_exchange][area_from, t, CO2_150])
                  ≈
                  value.(m[:area_exchange][area_to, t, CO2_200])
                  for t in 𝒯, atol=TEST_ATOL) == length(𝒯)
    end
end