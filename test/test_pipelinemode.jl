
ROUND_DIGITS = 8

struct LiquidResource{T<:Real} <: EMB.Resource
    id
    CO2Int::T
    pressure::Int
end
Base.show(io::IO, n::LiquidResource) = print(io, "$(n.id)-$(n.pressure)")

NG = ResourceEmit("NG", 0.2)
CO2 = ResourceEmit("CO2", 1.0)
Power = ResourceCarrier("Power", 0.0)
Coal = ResourceCarrier("Coal", 0.35)


CO2_150 = LiquidResource("CO2", 1, 150)
CO2_90 = LiquidResource("CO2", 1, 90)
CO2_200 = LiquidResource("CO2", 1, 200)


"""
A test case representing a simple model of a CCS case, with a CO2 source with capture
implemented, then using a PipelineMode for transportation to the offshore storage site.
"""
function small_graph_co2_1()
    products = [NG, Power, CO2, CO2_150, CO2_200]

    # Creation of a dictionary with entries of 0. for all resources
    𝒫₀ = Dict(k => 0 for k ∈ products)

    # Creation of a dictionary with entries of 0. for all emission resources
    𝒫ᵉᵐ₀ = Dict(k => 0.0 for k ∈ products if typeof(k) == ResourceEmit{Float64})

    # Creation of the source and sink module as well as the arrays used for nodes and links
    source = EMB.RefSource("-src", FixedProfile(25), FixedProfile(10),
        FixedProfile(5), Dict(CO2_150 => 1, Power => 1), 𝒫ᵉᵐ₀, Dict("" => EMB.EmptyData()))
    el_sink = EMB.RefSink("-el-sink", FixedProfile(0),
        Dict(:Surplus => 0, :Deficit => 1e6), Dict(Power => 1), 𝒫ᵉᵐ₀)

    sink = EMB.RefSink("-sink", FixedProfile(20),
        Dict(:Surplus => 0, :Deficit => 1e6), Dict(CO2_200 => 1), 𝒫ᵉᵐ₀)

    nodes = [GEO.GeoAvailability(1, 𝒫₀, 𝒫₀), GEO.GeoAvailability(2, 𝒫₀, 𝒫₀), source, 
        sink, el_sink]
    links = [EMB.Direct(31, nodes[3], nodes[1], EMB.Linear()),
        EMB.Direct(24, nodes[2], nodes[4], EMB.Linear()),
        EMB.Direct(15, nodes[1], nodes[5], EMB.Linear())]

    # Creation of the two areas and potential transmission lines
    areas = [GEO.Area(1, "Factory", 10.751, 59.921, nodes[1]),
        GEO.Area(2, "North Sea", 10.398, 63.4366, nodes[2])]

    # transmission_line = GEO.RefStatic("transline", Power, 100, 0.1, 1)
    pipeline = GEO.PipelineMode("pipeline", CO2_150, CO2_200, Power, 0.1, 100, 0.05, 1)

    transmissions = [GEO.Transmission(areas[1], areas[2], [pipeline], [Dict("" => EMB.EmptyData())])]
        #GEO.Transmission(areas[2], areas[1], [pipeline], [Dict("" => EMB.EmptyData())])]

    # Creation of the time structure and the used global data
    T = UniformTwoLevel(1, 4, 1, UniformTimes(1, 4, 1))
    global_data = EMB.GlobalData(Dict(CO2 => StrategicFixedProfile([450, 400, 350, 300]),
        NG => FixedProfile(1e6)))


    # Creation of the case dictionary
    case = Dict(:nodes => nodes,
        :links => links,
        :products => products,
        :areas => areas,
        :transmission => transmissions,
        :T => T,
        :global_data => global_data,
    )
    return case
end


@testset "PipelineMode test" begin

    case = small_graph_co2_1()
    # println(case)

    m = optimize(case)
    general_tests(m)

    """
    Tests:
    - test that the correct amount of Power is used for operating the pipeline
    - test that the same amount is transported in and out, even if
    - test that the inlet resource and outlet resource is actually different and correct,
      might use :area_exchange for this.
        - Check that the variable does not exist when it shouldnt, e.g CO2_200 at the inlet area, and CO2_150 at the outlet.
    - check that transport is above zero.
    - why doesnt it work if we remove the el_sink node?

    """
    𝒯 = case[:T]
    𝒫 = case[:products]
    𝒩 = case[:nodes]
    ℒ = case[:transmission]

    CO2_150 = 𝒫[4]
    CO2_200 = 𝒫[5]

    area_from = case[:areas][1]
    area_to = case[:areas][2]

    a1 = 𝒩[1]
    a2 = 𝒩[2]
    source = 𝒩[3]
    sink = 𝒩[4]
    el_sink = 𝒩[5]

    transmission = case[:transmission][1]
    pipeline::GEO.PipelineMode = transmission.Modes[1]
    inlet_resource = pipeline.Inlet
    outlet_resource = pipeline.Outlet

    @testset "Resource exchange" begin
        # Check that only CO2_150 is exported from the factory area and that only 
        # CO2_200 is imported into the storage area.
        @test CO2_150 ∈ GEO.exchange_resources(ℒ, area_from)
        @test CO2_200 ∈ GEO.exchange_resources(ℒ, area_to)
        @test length(GEO.exchange_resources(ℒ, area_from)) == 1
        @test length(GEO.exchange_resources(ℒ, area_to)) == 1
        
        # The exported quantity should be negative and equal in absolute value to the 
        # trans_in (of the inlet resource).
        @test sum(value.(m[:area_exchange][area_from, t, CO2_150]) 
            == -value.(m[:trans_in][transmission, t, pipeline]) for t ∈ 𝒯) == length(𝒯)
        
        # The imported quantity should be positive and equal to trans_out of the pipeline
        # outlet resource.
        @test sum(value.(m[:area_exchange][area_to, t, CO2_200]) 
        == value.(m[:trans_out][transmission, t, pipeline]) for t ∈ 𝒯) == length(𝒯)
    end

    # Test that the loss in transported volume is computed in the expected way.
    @test sum((1 - pipeline.Trans_loss) * value.(m[:trans_in][transmission, t, pipeline])
              ==
              value.(m[:trans_out][transmission, t, pipeline]) for t in 𝒯) == length(𝒯)


    for t in 𝒯
        println("trans_in: ", value.(m[:trans_in][transmission, t, pipeline]))
        println("trans_out: ", value.(m[:trans_out][transmission, t, pipeline]))
    end

    for t ∈ 𝒯
        # println("flow_out: ", value.(m[:link_out][source, t, CO2_150]))
    end


    println("\nArea exchange")
    for t ∈ 𝒯
        println("from: ", value.(m[:area_exchange][area_from, t, CO2_150]))
        println("to: ", value.(m[:area_exchange][area_to, t, CO2_200]))
    end
    
    # println("\nSink")
    # for t ∈ 𝒯
        # println("cap_use: ", value.(m[:cap_use][sink, t]))
        # # println("el cap_use: ", value.(m[:cap_use][el_sink, t]))
    # end

    println("\nAv1")
    for t ∈ 𝒯
        println("flow_in: ", value.(m[:flow_in][a1, t, CO2_150]))
        println("flow_out: ", value.(m[:flow_out][a1, t, CO2_150]))
        # println("el cap_use: ", value.(m[:cap_use][el_sink, t]))
    end


end
