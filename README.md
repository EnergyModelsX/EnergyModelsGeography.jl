# EnergyModelsGeography

[![Pipeline: passing](https://gitlab.sintef.no/clean_export/energymodelsgeography.jl/badges/main/pipeline.svg)](https://gitlab.sintef.no/clean_export/energymodelsgeography.jl/-/jobs)
[![Docs: stable](https://img.shields.io/badge/docs-stable-4495d1.svg)](https://clean_export.pages.sintef.no/energymodelsgeography.jl)
<!---
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)
--->

`EnergyModelsGeography` is a package to add a geographic representation to both operational and investment models. It is developed primarily to add this functionality to `EnergyModelsBase` and `EnergyModelsInvestments`

> **Note**
> This is an internal pre-release not intended for distribution outside the project consortium. 

## Usage

Documentation is currently in development. A minimal example of how to use this package

```julia
using EnergyModelsBase
using EnergyModelsGeography
using HiGHS
using JuMP
using PrettyTables
using TimeStructures

const EMB = EnergyModelsBase
const GEO = EnergyModelsGeography

struct LiquidResource{T<:Real} <: EMB.Resource
    id::Any
    CO2Int::T
    pressure::Int
end
Base.show(io::IO, n::LiquidResource) = print(io, "$(n.id)-$(n.pressure)")

"""
A test case representing a simple model of a CCS case, with a CO2 source with capture
implemented, then using a PipelineMode for transportation to the offshore storage site.
"""
function demo_co2()
    NG = ResourceEmit("NG", 0.2)
    CO2 = ResourceEmit("CO2", 1.0)
    Power = ResourceCarrier("Power", 0.0)
    Coal = ResourceCarrier("Coal", 0.35)

    CO2_150 = LiquidResource("CO2", 1, 150)
    CO2_90 = LiquidResource("CO2", 1, 90)
    CO2_200 = LiquidResource("CO2", 1, 200)

    products = [NG, Power, CO2, CO2_150, CO2_200]

    # Create dictionary with entries of 0. for all resources
    𝒫₀ = Dict(k => 0 for k ∈ products)

    # Create dictionary with entries of 0. for all emission resources
    𝒫ᵉᵐ₀ = Dict(k => 0.0 for k ∈ products if typeof(k) == ResourceEmit{Float64})

    # Create the source and sink module as well as the arrays used for nodes and links
    source = EMB.RefSource(
        "-src",
        FixedProfile(25),
        FixedProfile(10),
        FixedProfile(5),
        Dict(CO2_150 => 1, Power => 1),
        𝒫ᵉᵐ₀,
        Dict("" => EMB.EmptyData()),
    )

    el_sink = EMB.RefSink(
        "-el-sink",
        FixedProfile(0),
        Dict(:Surplus => FixedProfile(0), :Deficit => FixedProfile(1e6)),
        Dict(Power => 1),
        𝒫ᵉᵐ₀,
    )

    sink = EMB.RefSink(
        "-sink",
        FixedProfile(20),
        Dict(:Surplus => FixedProfile(0), :Deficit => FixedProfile(1e6)),
        Dict(CO2_200 => 1),
        𝒫ᵉᵐ₀,
    )

    nodes = [
        GEO.GeoAvailability(1, 𝒫₀, 𝒫₀),
        GEO.GeoAvailability(2, 𝒫₀, 𝒫₀),
        source,
        sink,
        el_sink,
    ]

    links = [
        EMB.Direct(31, nodes[3], nodes[1], EMB.Linear()),
        EMB.Direct(24, nodes[2], nodes[4], EMB.Linear()),
        EMB.Direct(15, nodes[1], nodes[5], EMB.Linear()),
    ]

    # Create the two areas and potential transmission lines
    areas = [
        GEO.Area(1, "Factory", 10.751, 59.921, nodes[1]),
        GEO.Area(2, "North Sea", 10.398, 63.4366, nodes[2]),
    ]

    # transmission_line = GEO.RefStatic("transline", Power, 100, 0.1, 1)
    pipeline = GEO.PipelineMode("pipeline", CO2_150, CO2_200, Power, 0.1, 100, 0.05, 1)

    transmissions =
        [GEO.Transmission(areas[1], areas[2], [pipeline], Dict("" => EMB.EmptyData()))]

    # Creae the time structure and the used global data
    T = UniformTwoLevel(1, 4, 1, UniformTimes(1, 4, 1))
    global_data = EMB.GlobalData(
        Dict(CO2 => StrategicFixedProfile([450, 400, 350, 300]), NG => FixedProfile(1e6)),
    )

    # Create the case dictionary
    case = Dict(
        :nodes => nodes,
        :links => links,
        :products => products,
        :areas => areas,
        :transmission => transmissions,
        :T => T,
        :global_data => global_data,
    )

    # Build and solve model
    model = EMB.OperationalModel()
    m = GEO.create_model(case, model)
    set_optimizer(m, optimizer_with_attributes(HiGHS.Optimizer, MOI.Silent() => true))
    optimize!(m)

    # Display some results
    pretty_table(
        JuMP.Containers.rowtable(
            value,
            m[:flow_out];
            header = [:Node, :TimePeriod, :Resource, :FlowOut],
        ),
    )
end

demo_co2()
```

## Project Funding

`EnergyModelsGeography` was funded by the Norwegian Research Council in the project [Clean Export](https://www.sintef.no/en/projects/2020/cleanexport/), project number [308811](https://prosjektbanken.forskningsradet.no/project/FORISS/308811)