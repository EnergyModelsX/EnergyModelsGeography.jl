"""
    abstract type TransmissionMode

Declaration of the general type for transmission modes transporting resources between areas.
"""
abstract type TransmissionMode end
Base.show(io::IO, t::TransmissionMode) = print(io, "$(t.id)")

"""
    struct RefDynamic <: TransmissionMode

A reference dynamic `TransmissionMode`.

Generic representation of dynamic transmission modes, using for example truck, ship or railway transport.

# Fields
- **`id::String`** is the name/identifyer of the transmission mode.
- **`resource::Resource`** is the resource that is transported.
- **`trans_cap::TimeProfile`** is the capacity of the transmission mode.
- **`trans_loss::TimeProfile`** is the loss of the transported resource during
  transmission, modelled as a ratio.
- **`opex_var::TimeProfile`** is the variable operating expense per energy unit transported.
- **`opex_fixed::TimeProfile`** is the fixed operating expense per installed capacity.
- **`directions`** is the number of directions the resource can be transported,
  1 is unidirectional (A->B) or 2 is bidirectional (A<->B).
- **`data::Vector{<:ExtensionData}`** is the additional data (*e.g.*, for investments).
  The field `data` is conditional through usage of a constructor.
"""
struct RefDynamic <: TransmissionMode # *e.g.*, Trucks, ships etc.
    id::String
    resource::EMB.Resource
    trans_cap::TimeProfile
    trans_loss::TimeProfile
    opex_var::TimeProfile
    opex_fixed::TimeProfile
    directions::Int # 1: Unidirectional or 2: Bidirectional
    data::Vector{<:ExtensionData}
end
function RefDynamic(
        id::String,
        resource::EMB.Resource,
        trans_cap::TimeProfile,
        trans_loss::TimeProfile,
        opex_var::TimeProfile,
        opex_fixed::TimeProfile,
        directions::Int,
    )
    return RefDynamic(id, resource, trans_cap, trans_loss, opex_var, opex_fixed, directions, ExtensionData[])
end

struct ScheduledDynamic <: TransmissionMode 
    id::String
    resource::EMB.Resource
    trans_cap::TimeProfile
    departure::TimeProfile #  Vector of binary values
    arrival::TimeProfile #  Vector of binary values, should not overlap with departure
    trans_loss::TimeProfile
    opex_var::TimeProfile
    opex_fixed::TimeProfile
    energy_share::Float64 # Energy carried by one unit divided by charge/discharge capacity i.e charge/discharge time
    data::Vector{<:ExtensionData}
end
function ScheduledDynamic(
        id::String,
        resource::EMB.Resource,
        trans_cap::TimeProfile,
        departure::TimeProfile,
        arrival::TimeProfile,
        trans_loss::TimeProfile,
        opex_var::TimeProfile,
        opex_fixed::TimeProfile,
        energy_share::Float64,
    )
    return ScheduledDynamic(id, resource, trans_cap, departure, arrival, trans_loss, opex_var, opex_fixed, energy_share, ExtensionData[])
end

"""
    struct RefStatic <: TransmissionMode

A reference static `TransmissionMode`.

Generic representation of static transmission modes, such as overhead power lines or pipelines.

# Fields
- **`id::String`** is the name/identifyer of the transmission mode.
- **`resource::Resource`** is the resource that is transported.
- **`trans_cap::Real`** is the capacity of the transmission mode.
- **`trans_loss::Real`** is the loss of the transported resource during transmission,
  modelled as a ratio.
- **`opex_var::TimeProfile`** is the variable operating expense per energy unit transported.
- **`opex_fixed::TimeProfile`** is the fixed operating expense per installed capacity.
- **`directions`** is the number of directions the resource can be transported,
  1 is unidirectional (A->B) or 2 is bidirectional (A<->B).
- **`data::Vector{<:ExtensionData}`** is the additional data (*e.g.*, for investments).
  The field `data` is conditional through usage of a constructor.
"""
struct RefStatic <: TransmissionMode # E.g. overhead power lines, pipelines etc.
    id::String
    resource::EMB.Resource
    trans_cap::TimeProfile
    trans_loss::TimeProfile
    opex_var::TimeProfile
    opex_fixed::TimeProfile
    directions::Int
    data::Vector{<:ExtensionData}
end
function RefStatic(
        id::String,
        resource::EMB.Resource,
        trans_cap::TimeProfile,
        trans_loss::TimeProfile,
        opex_var::TimeProfile,
        opex_fixed::TimeProfile,
        directions::Int,
    )
    return RefStatic(id, resource, trans_cap, trans_loss, opex_var, opex_fixed, directions, ExtensionData[])
end


"""
    abstract type PipeMode <: TransmissionMode

`TransmissionMode` mode for additional variable potential.

`PipeMode`s are by default unidirectional. If you plan to include bidirectional pipelines,
you have to provide a new method to the function [`is_bidirectional`](@ref).
"""
abstract type PipeMode <: TransmissionMode end

"""
    struct PipeSimple <: PipeMode

This `TransmissionMode` allows for altering the transported `Resource`.

A usage of this could be, *e.g.*, by defining a subtype struct of `Resource` with the field
'pressure'. This PipelineMode can then take `SomeSubtype<:Resource` with pressure p₁ at the
inlet, and pressure p₂ at the outlet.

This type also supports consuming resources proportionally to the volume of transported
`Resource` (at the inlet). This could be used for modeling the power needed for operating
the pipeline.

Pipeline transport using `PipeSimple` is assumed to be unidirectional. It is not possible to
use `PipeSimple` for bidirectional transport as the consuming resource would in this case
be consumed at the wrong `Area`.

# Fields
- **`id::String`** is the identifier used in printed output.
- **`inlet::Resource`** is the `Resource` going into transmission.
- **`outlet::Resource`** is the `Resource` going out of the outlet of the transmission.
- **`consuming::Resource`** is the `Resource` the transmission consumes by operating.
- **`consumption_rate::TimeProfile`** the rate of which the resource `Pipeline.consuming` is
  consumed, as a ratio of the volume of the resource going into the inlet, *i.e.*:

        `consumption_rate` = consumed volume / inlet volume (per operational period)
- **`trans_cap::Real`** is the capacity of the transmission mode.
- **`trans_loss::Real`** is the loss of the transported resource during transmission,
  modelled as a ratio.
- **`opex_var::TimeProfile`** is the variable operating expense per energy unit transported.
- **`opex_fixed::TimeProfile`** is the fixed operating expense per installed capacity.
- **`data::Vector{<:ExtensionData}`** is the additional data (*e.g.*, for investments).
  The field `data` is conditional through usage of a constructor.
"""
struct PipeSimple <: PipeMode
    id::String
    inlet::EMB.Resource
    outlet::EMB.Resource
    consuming::EMB.Resource
    consumption_rate::TimeProfile
    trans_cap::TimeProfile
    trans_loss::TimeProfile
    opex_var::TimeProfile
    opex_fixed::TimeProfile
    data::Vector{<:ExtensionData}
end
function PipeSimple(
    id::String,
    inlet::EMB.Resource,
    outlet::EMB.Resource,
    consuming::EMB.Resource,
    consumption_rate::TimeProfile,
    trans_cap::TimeProfile,
    trans_loss::TimeProfile,
    opex_var::TimeProfile,
    opex_fixed::TimeProfile,
)
    PipeSimple(
        id,
        inlet,
        outlet,
        consuming,
        consumption_rate,
        trans_cap,
        trans_loss,
        opex_var,
        opex_fixed,
        ExtensionData[],
        )
end

"""
    struct PipeLinepackSimple <: PipeMode

Pipeline model with linepacking implemented as simple storage function.

# Fields
- **`id::String`** is the identifier used in printed output.
- **`inlet::Resource`** is the `Resource` going into transmission.
- **`outlet::Resource`** is the `Resource` going out of the outlet of the transmission.
- **`consuming::Resource`** is the `Resource` the transmission consumes by operating.
- **`consumption_rate::TimeProfile`** the rate of which the resource `Pipeline.consuming` is
  consumed, as a ratio of the volume of the resource going into the inlet, *i.e.*:\n
        `consumption_rate` = consumed volume / inlet volume (per operational period)
- **`trans_cap::Real`** is the capacity of the transmission mode.
- **`trans_loss::Real`** is the loss of the transported resource during transmission,
  modelled as a ratio.
- **`opex_var::TimeProfile`** is the variable operating expense per energy unit transported.
- **`opex_fixed::TimeProfile`** is the fixed operating expense per installed capacity.
- **`energy_share::Float64`** is the storage energy capacity relative to pipeline capacity.
- **`data::Array{<:ExtensionData}`** is the additional data (*e.g.*, for investments).
  The field `data` is conditional through usage of a constructor.
"""
struct PipeLinepackSimple <: PipeMode
    id::String
    inlet::EMB.Resource
    outlet::EMB.Resource
    consuming::EMB.Resource
    consumption_rate::TimeProfile
    trans_cap::TimeProfile
    trans_loss::TimeProfile
    opex_var::TimeProfile
    opex_fixed::TimeProfile
    energy_share::Float64
    data::Vector{<:ExtensionData}
end
function PipeLinepackSimple(
    id::String,
    inlet::EMB.Resource,
    outlet::EMB.Resource,
    consuming::EMB.Resource,
    consumption_rate::TimeProfile,
    trans_cap::TimeProfile,
    trans_loss::TimeProfile,
    opex_var::TimeProfile,
    opex_fixed::TimeProfile,
    energy_share::Float64,
)

    PipeLinepackSimple(
        id,
        inlet,
        outlet,
        consuming,
        consumption_rate,
        trans_cap,
        trans_loss,
        opex_var,
        opex_fixed,
        energy_share,
        ExtensionData[])
end

"""
    modes_sub(ℳ::Vector{<:TransmissionMode}, str::String)
    modes_sub(ℳ::Vector{<:TransmissionMode}, str_arr::Array{String})

Returns an array containing all [`TransmissionMode`](@ref)s that include in the name the
String `str` or any of values in the String array `str_arr`.
"""
modes_sub(ℳ::Vector{<:TransmissionMode}, str::String) =
    filter(tm -> occursin(str, tm.id), ℳ)
modes_sub(ℳ::Vector{<:TransmissionMode}, str_arr::Array{String}) =
    filter(tm -> any(occursin(str, tm.id) for str ∈ str_arr), ℳ)

"""
    map_trans_resource(tm::TransmissionMode)
    map_trans_resource(tm::PipeMode)

Returns the transported resource for a given TransmissionMode.
"""
map_trans_resource(tm::TransmissionMode) = tm.resource
map_trans_resource(tm::PipeMode) = tm.inlet

"""
    capacity(tm::TransmissionMode)
    capacity(tm::TransmissionMode, t)

Returns the capacity of transmission mode `tm` as `TimeProfile` or in operational period `t`.
"""
EMB.capacity(tm::TransmissionMode) = tm.trans_cap
EMB.capacity(tm::TransmissionMode, t) = tm.trans_cap[t]
"""
    inputs(tm::TransmissionMode)
    inputs(tm::PipeMode)

Returns the input resources of transmission mode `tm`.
"""
EMB.inputs(tm::TransmissionMode) = [tm.resource]
EMB.inputs(tm::PipeMode) = [tm.inlet, tm.consuming]

"""
    outputs(tm::TransmissionMode)
    outputs(tm::PipeMode)

Returns the output resources of transmission mode `tm`.
"""
EMB.outputs(tm::TransmissionMode) = [tm.resource]
EMB.outputs(tm::PipeMode) = [tm.outlet]

"""
    opex_var(tm::TransmissionMode)
    opex_var(tm::TransmissionMode, t)

Returns the variable OPEX of transmission mode `tm` as `TimeProfile` or in operational
period `t`.
"""
EMB.opex_var(tm::TransmissionMode) = tm.opex_var
EMB.opex_var(tm::TransmissionMode, t) = tm.opex_var[t]

"""
    opex_fixed(tm::TransmissionMode)
    opex_fixed(tm::TransmissionMode, t_inv)

Returns the variable OPEX of transmission mode `tm` as `TimeProfile` or in strategic period
`t_inv`.
"""
EMB.opex_fixed(tm::TransmissionMode) = tm.opex_fixed
EMB.opex_fixed(tm::TransmissionMode, t_inv) = tm.opex_fixed[t_inv]

"""
    loss(tm::TransmissionMode)
    loss(tm::TransmissionMode, t)

Returns the loss of transmission mode `tm` as `TimeProfile` or in operational period `t`.
"""
loss(tm::TransmissionMode) = tm.trans_loss
loss(tm::TransmissionMode, t) = tm.trans_loss[t]

"""
    directions(tm::TransmissionMode)

Returns the directions of transmission mode `tm`.
"""
directions(tm::TransmissionMode) = tm.directions

"""
    has_opex(tm::TransmissionMode)

Checks whether transmission mode `tm` has operational expenses.

By default, all transmission modes have operational expenses.
"""
EMB.has_opex(tm::TransmissionMode) = true

"""
    has_emissions(tm::TransmissionMode)

Returns whether there are emissions associated with transmission mode `tm`.
The default behaviour is no emissions.
"""
EMB.has_emissions(tm::TransmissionMode) = false

"""
    emit_resources(m::TransmissionMode)

Returns the types of emissions associated with transmission mode `tm`.
"""
emit_resources(tm::TransmissionMode) = ResourceEmit[]

"""
    emissions(tm::TransmissionMode, p::ResourceEmit)
    emissions(tm::TransmissionMode, p::ResourceEmit, t)

Returns the emission of transmission mode `tm` of a specific resource `p` as `TimeProfile`
or in operational period `t`.

!!! note "Transmission emissions"
    None of the provided `TransmissionMode`s include emissions. If you plan to include
    emissions, you have to both create a new `TransmissionMode` and dispatch on this
    function.
"""
emissions(tm::TransmissionMode, p::ResourceEmit) = FixedProfile(0)
emissions(tm::TransmissionMode, p::ResourceEmit, t) = 0

"""
    consumption_rate(tm::PipeMode)
    consumption_rate(tm::PipeMode, t)

Returns the consumption rate of pipe mode `tm` as `TimeProfile` or in operational period `t`.
"""
consumption_rate(tm::PipeMode) = tm.consumption_rate
consumption_rate(tm::PipeMode, t) = tm.consumption_rate[t]


departure(tm::ScheduledDynamic) = tm.departure
departure(tm::ScheduledDynamic, t) = tm.departure[t]

arrival(tm::ScheduledDynamic) = tm.arrival
arrival(tm::ScheduledDynamic, t) = tm.arrival[t]

"""
    energy_share(tm::PipeLinepackSimple)

Returns the energy share of PipeLinepackSimple `tm`.
"""
energy_share(tm::ScheduledDynamic) = tm.energy_share
energy_share(tm::PipeLinepackSimple) = tm.energy_share

"""
    is_bidirectional(tm::TransmissionMode)
    is_bidirectional(tm::PipeMode)

Checks whether transmission mode `tm` is bidirectional. By default, it checks whether the
the function [`directions`](@ref) returns the value 2.

[`PipeMode`](@ref)s return false.
"""
is_bidirectional(tm::TransmissionMode) = directions(tm) == 2
is_bidirectional(tm::ScheduledDynamic) = false
is_bidirectional(tm::PipeMode) = false

"""
    mode_data(tm::TransmissionMode)

Returns the [`ExtensionData`](@extref EnergyModelsBase.ExtensionData) array of transmission mode `tm`.
"""
mode_data(tm::TransmissionMode) = hasproperty(tm, :data) ? tm.data : ExtensionData
