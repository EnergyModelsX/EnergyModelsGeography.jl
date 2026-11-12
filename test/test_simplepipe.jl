struct LiquidResource{T<:Real} <: Resource
    id
    co2_int::T
    pressure::Int
end
Base.show(io::IO, n::LiquidResource) = print(io, "$(n.id)-$(n.pressure)")

CO2 = ResourceEmit("CO2", 1.0)
Power = ResourceCarrier("Power", 0.0)

CO2_150 = LiquidResource("CO2", 1, 150)
CO2_90 = LiquidResource("CO2", 1, 90)
CO2_200 = LiquidResource("CO2", 1, 200)


"""
    small_graph_co2_1()

A test case representing a simple model of a CCS case, with a CO2 source with capture, using
a `PipeSimple` for transport to the offshore storage site.
"""
function small_graph_co2_1()
    products = [Power, CO2, CO2_150, CO2_200]

    # Creation of the source and sink nodes as well as the arrays used for nodes and links
    source = RefSource("-src", FixedProfile(25), FixedProfile(10),
        FixedProfile(5), Dict(CO2_150 => 1, Power => 1))
    el_sink = RefSink("-el-sink", FixedProfile(0),
        Dict(:surplus => FixedProfile(0), :deficit => FixedProfile(1e6)),
        Dict(Power => 1))

    sink = RefSink("-sink", FixedProfile(20),
        Dict(:surplus => FixedProfile(0), :deficit => FixedProfile(1e6)),
        Dict(CO2_200 => 1))

    nodes = [GeoAvailability(1, products), EMG.GeoAvailability(2, products), source,
        sink, el_sink]
    links = [Direct(31, nodes[3], nodes[1], Linear()),
        Direct(24, nodes[2], nodes[4], Linear()),
        Direct(15, nodes[1], nodes[5], Linear())]

    # Creation of the two areas and potential transmission lines
    areas = [RefArea(1, "Factory", 10.751, 59.921, nodes[1]),
             RefArea(2, "North Sea", 10.398, 63.4366, nodes[2])]

    pipeline = PipeSimple(
        "pipeline", CO2_150, CO2_200, Power, FixedProfile(0.1), FixedProfile(100),
        FixedProfile(0.05), FixedProfile(0.05), FixedProfile(0.05))

    transmissions = [Transmission(areas[1], areas[2], [pipeline])]

    # Creation of the time structure and the used global data
    T = TwoLevel(4, 1, SimpleTimes(4, 1))
    modeltype = OperationalModel(
                                Dict(CO2 => StrategicProfile([450, 400, 350, 300])),
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

case, modeltype = small_graph_co2_1()

m = optimize(case, modeltype)
general_tests(m)

𝒯 = get_time_struct(case)
𝒫 = get_products(case)
𝒩 = get_nodes(case)
ℒ = get_transmissions(case)
𝒜 = get_areas(case)

Power = 𝒫[1]
CO2_150 = 𝒫[3]
CO2_200 = 𝒫[4]

area_from = 𝒜[1]
area_to = 𝒜[2]

a1 = 𝒩[1]
a2 = 𝒩[2]
source = 𝒩[3]
sink = 𝒩[4]
el_sink = 𝒩[5]

transmission = ℒ[1]
pipeline = modes(transmission)[1]
inlet_resource = pipeline.inlet
outlet_resource = pipeline.outlet

@testset "Energy transferred" begin
    # Test that CO2 is transferred
    @test sum(value.(m[:trans_in])[pipeline, t] > 0 for t ∈ 𝒯) ==
            length(𝒯)

end

@testset "Resource exchange" begin
    # Check that only CO2_150 and the consumed Power are exported from the factory area and
    # that only CO2_200 is imported into the storage area.
    @test CO2_150 ∈ EMG.exchange_resources(ℒ, area_from)
    @test pipeline.consuming ∈ EMG.exchange_resources(ℒ, area_from)
    @test CO2_200 ∈ EMG.exchange_resources(ℒ, area_to)
    # Both the transported and the consumed resource are exported from the area.
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
    # `consumption_rate` of the pipeline.
    @test sum(value.(m[:flow_in][a1, t, Power]) * (1 - consumption_rate(pipeline, t))
                == value.(m[:flow_out][a1, t, Power]) for t ∈ 𝒯) == length(𝒯)

    # Test that the difference in Power in the availability node is taken up by
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
    @test sum((1 - loss(pipeline, t)) * value.(m[:trans_in][pipeline, t])
                ==
                value.(m[:trans_out][pipeline, t])
                for t in 𝒯, atol=TEST_ATOL) == length(𝒯)

    # Test that the :area_exchange variables in CO2_150 have the proper loss when transported
    # to the other area as CO2_200. The exported resource should have a negative sign.
    @test sum(-(1 - loss(pipeline, t)) * value.(m[:area_exchange][area_from, t, CO2_150])
                ≈
                value.(m[:area_exchange][area_to, t, CO2_200])
                for t in 𝒯, atol=TEST_ATOL) == length(𝒯)
end
