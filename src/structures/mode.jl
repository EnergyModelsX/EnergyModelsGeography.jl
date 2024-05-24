""" Declaration of the general type for transmission mode transporting resources between areas."""
abstract type TransmissionMode end
Base.show(io::IO, t::TransmissionMode) = print(io, "$(t.id)")

"""
    RefDynamic <: TransmissionMode

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
- **`data::Vector{Data}`** is the additional data (e.g. for investments). The field `data`
  is conditional through usage of a constructor.
"""
struct RefDynamic <: TransmissionMode # E.g. Trucks, ships etc.
    id::String
    resource::EMB.Resource
    trans_cap::TimeProfile
    trans_loss::TimeProfile
    opex_var::TimeProfile
    opex_fixed::TimeProfile
    directions::Int # 1: Unidirectional or 2: Bidirectional
    data::Vector{Data}
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
    return RefDynamic(id, resource, trans_cap, trans_loss, opex_var, opex_fixed, directions, Data[])
end

"""
    RefStatic <: TransmissionMode

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
- **`data::Vector{Data}`** is the additional data (e.g. for investments). The field `data`
  is conditional through usage of a constructor.
"""
struct RefStatic <: TransmissionMode # E.g. overhead power lines, pipelines etc.
    id::String
    resource::EMB.Resource
    trans_cap::TimeProfile
    trans_loss::TimeProfile
    opex_var::TimeProfile
    opex_fixed::TimeProfile
    directions::Int
    data::Vector{Data}
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
    return RefStatic(id, resource, trans_cap, trans_loss, opex_var, opex_fixed, directions, Data[])
end


"""
    PipeMode <: TransmissionMode

`TransmissionMode` mode for additional variable potential.
"""
abstract type PipeMode <: TransmissionMode end

"""
    PipeSimple <: PipeMode

This `TransmissionMode` allows for altering the transported `Resource`.

A usage of this could e.g. be by defining a subtype struct of `Resource` with the field
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
- **`consumption_rate::Real`** the rate of which the resource `Pipeline.consuming` is
  consumed, as a ratio of the volume of the resource going into the inlet, i.e.:

        `consumption_rate` = consumed volume / inlet volume (per operational period)
- **`trans_cap::Real`** is the capacity of the transmission mode.
- **`trans_loss::Real`** is the loss of the transported resource during transmission,
  modelled as a ratio.
- **`opex_var::TimeProfile`** is the variable operating expense per energy unit transported.
- **`opex_fixed::TimeProfile`** is the fixed operating expense per installed capacity.
- **`data::Vector{Data}`** is the additional data (e.g. for investments). The field `data`
  is conditional through usage of a constructor.
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
    directions::Int
    data::Vector{<:Data}

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
        data::Vector{<:Data}
    )
        new(
            id,
            inlet,
            outlet,
            consuming,
            consumption_rate,
            trans_cap,
            trans_loss,
            opex_var,
            opex_fixed,
            1,
            data,
            )
    end
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
        Data[],
        )
end

"""
    PipeLinepackSimple <: PipeMode

Pipeline model with linepacking implemented as simple storage function.

# Fields (additional to `PipeSimple`)
- **`id::String`** is the identifier used in printed output.
- **`inlet::Resource`** is the `Resource` going into transmission.
- **`outlet::Resource`** is the `Resource` going out of the outlet of the transmission.
- **`consuming::Resource`** is the `Resource` the transmission consumes by operating.
- **`consumption_rate::Real`** the rate of which the resource `Pipeline.consuming` is
  consumed, as a ratio of the volume of the resource going into the inlet, i.e.:\n
        `consumption_rate` = consumed volume / inlet volume (per operational period)
- **`trans_cap::Real`** is the capacity of the transmission mode.
- **`trans_loss::Real`** is the loss of the transported resource during transmission,
  modelled as a ratio.
- **`opex_var::TimeProfile`** is the variable operating expense per energy unit transported.
- **`opex_fixed::TimeProfile`** is the fixed operating expense per installed capacity.
- **`energy_share::Float64`** is the storage energy capacity relative to pipeline capacity.
- **`data::Array{<:Data}`** is the additional data (e.g. for investments). The field `data`
  is conditional through usage of a constructor.
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
    directions::Int
    data::Vector{<:Data}

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
        data::Vector{<:Data},
    )
        new(
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
            1,
            data,
        )
    end
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
        Data[])
end

"""
    modes_sub(ℳ::Vector{<:TransmissionMode}, string::String)

Returns all transmission modes that include in the name the `string`.
"""
function modes_sub(ℳ::Vector{<:TransmissionMode}, string::String)

    sub_modes = TransmissionMode[]
    for tm ∈ ℳ
        if isequal(string, tm.id)
            append!(sub_modes, [tm])
        end
    end

    return sub_modes
end
"""
    modes_sub(ℳ::Vector{<:TransmissionMode}, string_array::Array{String})

Returns all transmission modes that include in the name all entries of
the array `string_array`.
"""
function modes_sub(ℳ::Vector{<:TransmissionMode}, string_array::Array{String})

    sub_modes = TransmissionMode[]
    for tm ∈ ℳ
        if all(isequal(string, tm.id) for string ∈ string_array)
            append!(sub_modes, [tm])
        end
    end

    return sub_modes
end

"""
    map_trans_resource(tm::TransmissionMode)
    map_trans_resource(tm::PipeMode)

Returns the transported resource for a given TransmissionMode.
"""
map_trans_resource(tm::TransmissionMode) = tm.resource
map_trans_resource(tm::PipeMode) = tm.inlet

"""
    modes_of_dir(ℒ, dir::Int)

Return the transmission modes of dir `directions` for transmission modes `ℳ`.
"""
function modes_of_dir(ℳ::Vector{<:TransmissionMode}, dir::Int)

    return filter(x -> x.directions == dir, ℳ)
end

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
    has_emissions(tm::TransmissionMode)

Returns whether there are emissions associated with transmission mode `tm`.
Default behaviour is no emissions.
"""
has_emissions(tm::TransmissionMode) = false

"""
    emit_resources(m::TransmissionMode)

Returns the types of emissions associated with transmission mode `tm`.
"""
emit_resources(tm::TransmissionMode) = EMB.ResourceEmit[]

"""
    emission(tm::TransmissionMode, p::EMB.ResourceEmit)
    emission(tm::TransmissionMode, p::EMB.ResourceEmit, t)

Returns the emission of transmission mode `tm` of a specific resource `p` as `TimeProfile`
or in operational period `ts`.

!!! note "Transmission emissions"
    None of the provided `TransmissionMode`s include emissions. If you plan to include
    emissions, you have to both create a new `TransmissionMode` and dispatch on this
    function.
"""
emission(tm::TransmissionMode, p::EMB.ResourceEmit) = 0
emission(tm::TransmissionMode, p::EMB.ResourceEmit, t) = 0

"""
    consumption_rate(tm::PipeMode)
    consumption_rate(tm::PipeMode, t)

Returns the consumption rate of pipe mode `tm` as `TimeProfile` or in operational period `t`.
"""
consumption_rate(tm::PipeMode) = tm.consumption_rate
consumption_rate(tm::PipeMode, t) = tm.consumption_rate[t]

"""
    energy_share(tm::PipeLinepackSimple)

Returns the energy share of PipeLinepackSimple `tm`.
"""
energy_share(tm::PipeLinepackSimple) = tm.energy_share

"""
    is_bidirectional(tm::TransmissionMode)

Checks whether TransmissionMode `tm` is bidirectional.
"""
is_bidirectional(tm::TransmissionMode) = tm.directions == 2
