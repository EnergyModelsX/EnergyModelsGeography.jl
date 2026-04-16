"""
    create_model(case::Dict, modeltype::EnergyModel, m::JuMP.Model; check_timeprofiles::Bool=true)

Create the model and call all required functions. This method is a deprecated method and
should no longer be called.
"""
function create_model(
    case::Dict,
    modeltype::EnergyModel,
    m::JuMP.Model;
    check_timeprofiles::Bool=true,
    check_any_data::Bool = true,
)
    case_new = Case(
        case[:T],
        case[:products],
        [case[:nodes], case[:links], case[:areas], case[:transmission]],
        [[get_nodes, get_links], [get_areas, get_transmissions]],
    )
    return EMB.create_model(case_new, modeltype, m; check_timeprofiles, check_any_data)
end
function create_model(
    case::Dict,
    modeltype::EnergyModel;
    check_timeprofiles::Bool = true,
    check_any_data::Bool = true,
)
    m = JuMP.Model()
    create_model(case, modeltype, m; check_timeprofiles, check_any_data)
end

"""
    EMB.variables_capacity(m, ℒᵗʳᵃⁿˢ::Vector{Transmission}, 𝒳ᵛᵉᶜ, 𝒯, modeltype::EnergyModel)
    EMB.variables_capacity(m, 𝒜::Vector{<:Area}, 𝒳ᵛᵉᶜ, 𝒯, modeltype::EnergyModel)

Declaration of different capacity variables for the element type introduced in
`EnergyModelsGeography`. Due to the design of the package, the individual `TransmissionMode`s
must be extracted now in each package

!!! tip "Transmission variables"
    The capacity variables are only created for [`TransmissionMode`](@ref)s and not
    [`Transmission`](@ref) corridors. The created variable is

    - `trans_cap[tm, t]` is the installed capacity of transmission mode `tm` in operational
      period `t`.

!!! note "Area variables"
    No variables are added
"""
function EMB.variables_capacity(m, ℒᵗʳᵃⁿˢ::Vector{Transmission}, 𝒳ᵛᵉᶜ, 𝒯, modeltype::EnergyModel)
    ℳ = modes(ℒᵗʳᵃⁿˢ)
    @variable(m, trans_cap[ℳ, 𝒯] >= 0)
end
function EMB.variables_capacity(m, 𝒜::Vector{<:Area}, 𝒳ᵛᵉᶜ, 𝒯, modeltype::EnergyModel) end

"""
    EMB.variables_flow(m, ℒᵗʳᵃⁿˢ::Vector{Transmission}, 𝒳ᵛᵉᶜ, 𝒯, modeltype::EnergyModel)
    EMB.variables_flow(m, 𝒜::Vector{<:Area}, 𝒳ᵛᵉᶜ, 𝒯, modeltype::EnergyModel)

Declaration of flow variables for the element types introduced in `EnergyModelsGeography`.
`EnergyModelsGeography` introduces two elements for an energy system, and
hence, provides the user with two individual methods:

!!! tip "Transmission variables"
    The capacity variables are only created for [`TransmissionMode`](@ref)s and not
    [`Transmission`](@ref) corridors. The created variables are

    - `trans_in[tm, t]` is the flow _**into**_ mode `tm` in operational period `t`. The inflow
      resources of transmission mode `m` are extracted using the function [`inputs`](@ref).
    - `trans_out[tm, t]` is the flow _**from**_ mode `tm` in operational period `t`. The outflow
      resources of transmission mode `m` are extracted using the function [`outputs`](@ref).
    - call of the function [`EMB.variables_flow_resource`](@ref) for introducing resource
      specific flow variables.

!!! note "Area variables"
    - `area_exchange[a, t, p]` is the exchange of resource `p` by area `a` in operational
      period `t`. The exchange resources are extracted using the function
      [`exchange_resources`](@ref)
    - call of the function [`EMB.variables_flow_resource`](@ref) for introducing resource
      specific flow variables.
"""
function EMB.variables_flow(m, ℒᵗʳᵃⁿˢ::Vector{Transmission}, 𝒳ᵛᵉᶜ, 𝒫, 𝒯,  modeltype::EnergyModel)
    # Extract the individual transmission modes
    ℳ = modes(ℒᵗʳᵃⁿˢ)

    # Create the transmission mode flow variables
    @variable(m, trans_in[ℳ, 𝒯])
    @variable(m, trans_out[ℳ, 𝒯])

    # Create new flow variables for specific resource types
    for p_sub ∈ EMB.res_types_vec(𝒫)
        EMB.variables_flow_resource(m, ℳ, p_sub, 𝒯, modeltype)
    end
end
function EMB.variables_flow(m, 𝒜::Vector{<:Area}, 𝒳ᵛᵉᶜ, 𝒫, 𝒯, modeltype::EnergyModel)
    ℒᵗʳᵃⁿˢ = get_transmissions(𝒳ᵛᵉᶜ)
    @variable(m, area_exchange[a ∈ 𝒜, 𝒯, p ∈ exchange_resources(ℒᵗʳᵃⁿˢ, a)])

    # Create new flow variables for specific resource types
    for p_sub ∈ EMB.res_types_vec(𝒫)
        EMB.variables_flow_resource(m, 𝒜, p_sub, 𝒯, modeltype)
    end
end

"""
    EMB.variables_flow_resource(m, 𝒜::Vector{<:TransmissionMode}, 𝒫::Vector{<:Resource}, 𝒯, modeltype::EnergyModel)
    EMB.variables_flow_resource(m, ℒ::Vector{<:Area}, 𝒫::Vector{Resource}, 𝒯, modeltype::EnergyModel)

Declaration of flow variables for the different resource-type segments.

The methods are called from [`EMB.variables_flow`](@ref) after segmenting `𝒫` through
`EMB.res_types_vec(𝒫)`.

The default methods are empty and intended to be implemented in extension packages that add
resource-specific variables.

!!! warning "Resource flow variables for Areas"
    We strongly advise against creating new variables for `Area`s. Instead, it is prefered
    to create the variables for the respective nodes to couple the local energy system with
    th transmission corridors.
"""
function EMB.variables_flow_resource(m, 𝒜::Vector{<:TransmissionMode}, 𝒫::Vector{<:Resource}, 𝒯, modeltype::EnergyModel) end
function EMB.variables_flow_resource(m, 𝒜::Vector{<:Area}, 𝒫::Vector{<:Resource}, 𝒯, modeltype::EnergyModel) end

"""
    EMB.variables_opex(m, ℒᵗʳᵃⁿˢ::Vector{Transmission}, 𝒳ᵛᵉᶜ, 𝒯, modeltype::EnergyModel)
    EMB.variables_opex(m, 𝒜::Vector{<:Area}, 𝒳ᵛᵉᶜ, 𝒯, modeltype::EnergyModel)

Declaration of different OPEX variables for the element types introduced in
`EnergyModelsGeography`. Although `EnergyModelsGeography` introduces two elements,
only `ℒᵗʳᵃⁿˢ::Vector{Transmission}` requires operational expense variables.

!!! note "Transmission variables"
    The operating expenses variables are only created for [`TransmissionMode`](@ref)s and
    not [`Transmission`](@ref) corridors. The OPEX variables are furthermore only created
    for nodes, if the function [`has_opex(tm::TransmissionMode)`](@ref) has received an
    additional method for a given mode `m` returning the value `true`. By default, this
    corresponds to all modes.

    - `trans_opex_var[tm, t_inv]` are the variable operating expenses of node `n` in investment
      period `t_inv`. The values can be negative to account for revenue streams
    - `trans_opex_fixed[tm, t_inv]` are the fixed operating expenses of node `n` in investment
      period `t_inv`.

!!! note "Area variables"
    No variables are added
"""
function EMB.variables_opex(m, ℒᵗʳᵃⁿˢ::Vector{Transmission}, 𝒳ᵛᵉᶜ, 𝒯, modeltype::EnergyModel)
    # Extract the individual transmission modes and strategic periods
    ℳ = modes(ℒᵗʳᵃⁿˢ)
    ℳᵒᵖᵉˣ = filter(has_opex, ℳ)
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)

    # Create the transmission mode opex variables
    @variable(m, trans_opex_var[ℳᵒᵖᵉˣ, 𝒯ᴵⁿᵛ])
    @variable(m, trans_opex_fixed[ℳᵒᵖᵉˣ, 𝒯ᴵⁿᵛ] >= 0)
end
function EMB.variables_opex(m, 𝒜::Vector{<:Area}, 𝒳ᵛᵉᶜ, 𝒯, modeltype::EnergyModel) end

"""
    EMB.variables_capex(m, ℒᵗʳᵃⁿˢ::Vector{Transmission}, 𝒳ᵛᵉᶜ, 𝒯, modeltype::EnergyModel)
    EMB.variables_capex(m, 𝒜::Vector{<:Area}, 𝒳ᵛᵉᶜ, 𝒯, modeltype::EnergyModel)


Declaration of different capital expenditures variables for the element types introduced in
`EnergyModelsGeography`. `EnergyModelsGeography` introduces two elements for an energy
system, and hence, provides the user with two individual methods.

!!! note
    The function is included for legacy support but will be removed in the near future.
"""
function EMB.variables_capex(m, ℒᵗʳᵃⁿˢ::Vector{Transmission}, 𝒳ᵛᵉᶜ, 𝒯, modeltype::EnergyModel) end
function EMB.variables_capex(m, 𝒜::Vector{<:Area}, 𝒳ᵛᵉᶜ, 𝒯, modeltype::EnergyModel) end

"""
    EMB.variables_emission(m, ℒᵗʳᵃⁿˢ::Vector{Transmission}, 𝒳ᵛᵉᶜ, 𝒫, 𝒯, modeltype::EnergyModel)

Declaration of an emission variables for the element types introduced in `EnergyModelsGeography`.
Although `EnergyModelsGeography` introduces two elements, only `ℒᵗʳᵃⁿˢ::Vector{Transmission}`
requires an emission variable.

Declation of variables for the modeling of transmission emissions. These variables are only
created for transmission modes where emissions are included. All emission resources that are
not included for a type are fixed to a value of 0.

!!! note "Transmission variables"
    - `emissions_trans[tm, t, p_em]` emissions of [`ResourceEmit`](@extref EnergyModelsBase.ResourceEmit)
      of transmission mode `tm` in operational period `t`. The variable is fixed to 0 for
      `ResourceEmit` that are not within the vector returned by the function [`emit_resources`](@ref).

!!! note "Area variables"
    No variables are added
"""
function EMB.variables_emission(m, ℒᵗʳᵃⁿˢ::Vector{Transmission}, 𝒳ᵛᵉᶜ, 𝒫, 𝒯, modeltype::EnergyModel)
    ℳ = modes(ℒᵗʳᵃⁿˢ)
    ℳᵉᵐ = filter(m -> has_emissions(m), ℳ)
    𝒫ᵉᵐ  = EMB.res_sub(𝒫, ResourceEmit)

    @variable(m, emissions_trans[ℳᵉᵐ, 𝒯, 𝒫ᵉᵐ] >= 0)

    # Fix of unused emission variables to avoid free variables
    for tm ∈ ℳᵉᵐ, t ∈ 𝒯, p_em ∈ setdiff(𝒫ᵉᵐ, emit_resources(tm))
        fix(m[:emissions_trans][tm, t, p_em], 0; force = true)
    end
end
function EMB.variables_emission(m, 𝒜::Vector{<:Area}, 𝒳ᵛᵉᶜ, 𝒫, 𝒯, modeltype::EnergyModel) end

"""
    EMB.variables_elements(m, ℒᵗʳᵃⁿˢ::Vector{Transmission}, 𝒳ᵛᵉᶜ, 𝒯, modeltype::EnergyModel)

Loop through all `TransmissionMode` types present in `ℒᵗʳᵃⁿˢ::Vector{Transmission}` and
create variables specific to each type. This is done by calling the method
[`variables_trans_mode`](@ref) on all modes of each type.

The `TransmissionMode` type representing the widest category will be called first. That is,
`variables_trans_mode` will be called on a `TransmissionMode` before it is called on
`PipeMode`.
"""
function EMB.variables_elements(m, ℒᵗʳᵃⁿˢ::Vector{Transmission}, 𝒳ᵛᵉᶜ, 𝒯, modeltype::EnergyModel)

    ℳ = modes(ℒᵗʳᵃⁿˢ)
    # Vector of the unique transmission mode types in ℳ.
    mode_composite_types = unique(map(tm -> typeof(tm), ℳ))
    # Get all `TransmissionMode`-types in the type-hierarchy that the transmission modes
    # ℳ represents.
    mode_types = EMB.collect_types(mode_composite_types)
    # Sort the node-types such that a supertype will always come its subtypes.
    mode_types = EMB.sort_types(mode_types)

    for mode_type ∈ mode_types
        # All nodes of the given sub type.
        ℳˢᵘᵇ = filter(tm -> isa(tm, mode_type), ℳ)
        # Convert to a Vector of common-type instad of Any.
        ℳˢᵘᵇ = convert(Vector{mode_type}, ℳˢᵘᵇ)
        try
            variables_trans_mode(m, 𝒯, ℳˢᵘᵇ, modeltype)
        catch e
            if !isa(e, ErrorException)
                @error "Creating variables failed."
            end
            # ℳˢᵘᵇ was already registered by a call to a supertype, so just continue.
        end
    end
end

"""
    EMB.variables_element_ext_data(m, ℒᵗʳᵃⁿˢ::Vector{Transmission}, 𝒳ᵛᵉᶜ, 𝒯, 𝒫,modeltype::EnergyModel)

Loop through all data subtypes and create variables specific to each subtype. It starts
at the top level and subsequently move through the branches until it reaches a leave.

The function subsequently calls the subroutine [`variables_ext_data`](@ref EnergyModelsBase.variables_ext_data)
for creating the variables for the transmission modes that have the corresponding data types.
"""
function EMB.variables_element_ext_data(
    m,
    ℒᵗʳᵃⁿˢ::Vector{Transmission},
    𝒳ᵛᵉᶜ,
    𝒯,
    𝒫,
    modeltype::EnergyModel
)
    # Extract all ExtensionData types within all transmission modes
    ℳ = modes(ℒᵗʳᵃⁿˢ)
    𝒟 = reduce(vcat, [mode_data(tm) for tm ∈ ℳ])

    # Skip if no data is added to the individual transmission modes
    isempty(𝒟) && return

    # Vector of the unique data types in 𝒟.
    data_composite_types = unique(typeof.(𝒟))
    # Get all `ExtensionData`-types in the type-hierarchy that the nodes 𝒟 represents.
    data_types = EMB.collect_types(data_composite_types)
    # Sort the `ExtensionData`-types such that a supertype will always come before its subtypes.
    data_types = EMB.sort_types(data_types)

    for data_type ∈ data_types
        # All transmission modes with the given data sub type.
        ℳᵈᵃᵗ = filter(tm -> any(isa.(mode_data(tm), data_type)), ℳ)
        try
            EMB.variables_ext_data(m, data_type, ℳᵈᵃᵗ, 𝒯, 𝒫, modeltype)
        catch e
            # Parts of the exception message we are looking for
            pre1 = "An object of name"
            pre2 = "is already attached to this model."
            if isa(e, ErrorException)
                if occursin(pre1, e.msg) && occursin(pre2, e.msg)
                    # data_type was already registered by a call to a supertype, so just continue.
                    continue
                end
            end
            # If we make it to this point, this means some other error occured.
            # This should not be ignored.
            throw(e)
        end
    end
end

"""
    variables_trans_mode(m, 𝒯, ℳˢᵘᵇ::Vector{<:TransmissionMode}, modeltype::EnergyModel)

Default fallback method when no function is defined for a [`TransmissionMode`](@ref) type.
It introduces the variables that are required in all `TransmissionMode`s.

These variables are:
* `:trans_loss` - loss during transmission
* `:trans_loss_neg` - negative loss during transmission, helper variable if bidirectional
  transport is possible
* `:trans_loss_pos` - positive loss during transmission, helper variable if bidirectional
  transport is possible
"""
function variables_trans_mode(m, 𝒯, ℳˢᵘᵇ::Vector{<:TransmissionMode}, modeltype::EnergyModel)

    ℳ₂ = filter(is_bidirectional, ℳˢᵘᵇ)

    @variable(m, trans_loss[ℳˢᵘᵇ, 𝒯] >= 0)
    @variable(m, trans_neg[ℳ₂, 𝒯] >= 0)
    @variable(m, trans_pos[ℳ₂, 𝒯] >= 0)
end

"""
    variables_trans_mode(m, 𝒯, ℳᴸᴾ::Vector{<:PipeLinepackSimple}, modeltype::EnergyModel)

When the node vector is a `Vector{<:PipeLinepackSimple}`, we declare the variable
`:linepack_stor_level` to account for the energy stored through line packing.
"""
function variables_trans_mode(m, 𝒯, ℳᴸᴾ::Vector{<:PipeLinepackSimple}, modeltype::EnergyModel)

    @variable(m, linepack_stor_level[ℳᴸᴾ, 𝒯] >= 0)
end

"""
    variables_element(m, 𝒜ˢᵘᵇ::Vector{<:Area}, 𝒯, modeltype::EnergyModel)

Default fallback method for a vector of elements if no other method is defined for a given
vector type.
"""
function EMB.variables_element(m, 𝒜ˢᵘᵇ::Vector{<:Area}, 𝒯, modeltype::EnergyModel) end

"""
    EMB.variables_ext_data(m, _::Type{<:ExtensionData}, ℳ::Vector{<:TransmissionMode}, 𝒯, 𝒫, modeltype::EnergyModel)

Default fallback method for the variables creation for a data type of a `Vector{<:TransmissionMode}`
`ℳ` if no other method is defined. The default method does not specify any variables.
"""
function EMB.variables_ext_data(
    m,
    _::Type{<:ExtensionData},
    ℳ::Vector{<:TransmissionMode},
    𝒯,
    𝒫,
    modeltype::EnergyModel
)
end

"""
    EMB.constraints_elements(m, 𝒜::Vector{<:Area}, 𝒳ᵛᵉᶜ, 𝒫, 𝒯, modeltype::EnergyModel)
    EMB.constraints_elements(m, ℒᵗʳᵃⁿˢ::Vector{Transmission}, 𝒳ᵛᵉᶜ, 𝒫, 𝒯, modeltype::EnergyModel)

Loop through all entries of the elements vector and call a subfunction for creating the
internal constraints of the entries of the elements vector.

`EnergyModelsGeography` provides the user with two element types, [`Area`](@ref) and
[`Trasnmission`]:

- `Area` - the subfunction is [`create_area`](@ref).
- `Transmission` - the subfunction is [`create_transmission_mode`](@ref) and called for all
  [`TransmissionMode`](@ref)s within `ℒᵗʳᵃⁿˢ`.
"""
function EMB.constraints_elements(m, 𝒜::Vector{<:Area}, 𝒳ᵛᵉᶜ, 𝒫, 𝒯, modeltype::EnergyModel)
    ℒᵗʳᵃⁿˢ = get_transmissions(𝒳ᵛᵉᶜ)
    for a ∈ 𝒜
        create_area(m, a, 𝒯, ℒᵗʳᵃⁿˢ, modeltype)

        # Constraints based on the resource types
        n = availability_node(a)
        area_resources = Vector{Resource}(unique(vcat(inputs(n), outputs(n))))
        for 𝒫ˢᵘᵇ ∈ EMB.res_types_vec(area_resources)
            EMB.constraints_resource(m, a, 𝒯, 𝒫ˢᵘᵇ, modeltype)
        end
    end
end
function EMB.constraints_elements(m, ℒᵗʳᵃⁿˢ::Vector{Transmission}, 𝒳ᵛᵉᶜ, 𝒫, 𝒯, modeltype::EnergyModel)
    for tm ∈ modes(ℒᵗʳᵃⁿˢ)
        create_transmission_mode(m, tm, 𝒯, modeltype)

        # Constraints based on the resource types
        mode_resources = Vector{Resource}(unique(vcat(inputs(tm), outputs(tm))))
        for 𝒫ˢᵘᵇ ∈ EMB.res_types_vec(mode_resources)
            EMB.constraints_resource(m, tm, 𝒯, 𝒫ˢᵘᵇ, modeltype)
        end
    end
end

"""
    EMB.constraints_resource(m, a::Area, 𝒯, 𝒫::Vector{<:Resource}, modeltype::EnergyModel)
    EMB.constraints_resource(m, tm::TransmissionMode, 𝒯, 𝒫::Vector{<:Resource}, modeltype::EnergyModel)

Create constraints for the flow of resources through an
[`AbstractElement`](@extref EnergyModelsBase.AbstractElement) for specific resource types.
In `EnergyModelsGeography`, this method is provided for [`Area`](@ref) and [`TransmissionMode`](@ref).

The function is empty by default and can be implemented in extension packages.

!!! warning
    While we allow the method to be also used for [`Area`](@ref)s, we strongly advise against
    introducing new variables for an `Area` as it would require more steps to introduce new
    variables. It is instead easier to access in the function [`EMB.constraints_couple`](@ref)
    the relevant `Availability` node.

    This approach allows you to couple the local energy system with the transmission modes.
"""
function EMB.constraints_resource(m, n::Area, 𝒯, 𝒫::Vector{<:Resource}, modeltype::EnergyModel) end
function EMB.constraints_resource(m, tm::TransmissionMode, 𝒯, 𝒫::Vector{<:Resource}, modeltype::EnergyModel) end

"""
    EMB.constraints_couple(m, 𝒜::Vector{<:Area}, ℒᵗʳᵃⁿˢ::Vector{Transmission}, 𝒫, 𝒯, modeltype::EnergyModel)
    EMB.constraints_couple(m, ℒᵗʳᵃⁿˢ::Vector{Transmission}, 𝒜::Vector{<:Area}, 𝒫, 𝒯, modeltype::EnergyModel)

Create the new couple constraints in `EnergyModelsGeography`.

The couple constraints are utilizing the variables `:flow_in` and `:flow_out` in combination
with `:area_exchange` for solving the energy balance on an [`Area`](@ref) level for the
respective [`GeoAvailability`](@ref) node.

The couple is achieved through the variable `:area_exchange` which is is calculated through
the functions [`compute_trans_in`](@ref) and [`compute_trans_out`](@ref).

As a consequence, each [`Area`](@ref) can be coupled with multiple [`Transmission`](@ref)
corridors but each [`Transmission`](@ref) corridor can only be coupled to two [`Area`](@ref)s.
"""
function EMB.constraints_couple(m, 𝒜::Vector{<:Area}, ℒᵗʳᵃⁿˢ::Vector{Transmission}, 𝒫, 𝒯, modeltype::EnergyModel)
    for a ∈ 𝒜
        # Declaration of the required subsets.
        n = availability_node(a)
        𝒫ᵉˣ = exchange_resources(ℒᵗʳᵃⁿˢ, a)

        # Resource balance within an area
        for p ∈ inputs(n)
            if p ∈ 𝒫ᵉˣ
                @constraint(m, [t ∈ 𝒯],
                    m[:flow_in][n, t, p] == m[:flow_out][n, t, p] - m[:area_exchange][a, t, p])
            else
                @constraint(m, [t ∈ 𝒯],
                    m[:flow_in][n, t, p] == m[:flow_out][n, t, p])
            end
        end

        # Keep track of exchange with other areas
        ℒᶠʳᵒᵐ, ℒᵗᵒ = trans_sub(ℒᵗʳᵃⁿˢ, a)
        @constraint(m, [t ∈ 𝒯, p ∈ 𝒫ᵉˣ],
            m[:area_exchange][a, t, p] +
            sum(compute_trans_in(m, t, p, tm) for tm ∈ modes(ℒᶠʳᵒᵐ))
            ==
            sum(compute_trans_out(m, t, p, tm) for tm ∈ modes(ℒᵗᵒ))
        )
    end

    # Create new constraints for specific resource types
    for p_sub ∈ EMB.res_types_vec(𝒫)
        EMB.constraints_couple_resource(m, 𝒜, ℒᵗʳᵃⁿˢ, p_sub, 𝒯, modeltype)
    end
end
function EMB.constraints_couple(m, ℒᵗʳᵃⁿˢ::Vector{Transmission}, 𝒜::Vector{<:Area}, 𝒫, 𝒯, modeltype::EnergyModel)
    return EMB.constraints_couple(m, 𝒜, ℒᵗʳᵃⁿˢ, 𝒫, 𝒯, modeltype)
end

"""
    EMB.constraints_couple_resource(m, 𝒜::Vector{<:Area}, ℒᵗʳᵃⁿˢ::Vector{Transmission}, 𝒫::Vector{<:Resource}, 𝒯, modeltype::EnergyModel)

Create resource-specific coupling constraints.

The method is called from [`EMB.constraints_couple`](@ref) for each resource-type segment
generated by `EMB.res_types_vec(𝒫)`.

The default method is empty and intended to be implemented in extension packages.
"""
function EMB.constraints_couple_resource(m, 𝒜::Vector{<:Area}, ℒᵗʳᵃⁿˢ::Vector{<:Transmission}, 𝒫::Vector{<:Resource}, 𝒯, modeltype::EnergyModel) end

"""
    EMB.emissions_operational(m, ℒᵗʳᵃⁿˢ::Vector{Transmission}, 𝒫ᵉᵐ, 𝒯, modeltype::EnergyModel)

Create JuMP expressions indexed over the operational periods `𝒯` for different elements.
The expressions correspond to the total emissions of a given type.

By default, emissions expressions are included for:
- `𝒳 = ℒᵗʳᵃⁿˢ::Vector{Transmission}`. In the case of a vector of transmission coriddors, the
  function returns the sum of the emissions of all modes whose method of the function
  [`has_emissions`](@ref) returns true.
- `𝒳 = 𝒜::Vector{<:Area}`. In the case of a vector of areas, the method returns returns a
  value of 0 for all operational periods and emission resources.
"""
function EMB.emissions_operational(m, ℒᵗʳᵃⁿˢ::Vector{Transmission}, 𝒫ᵉᵐ, 𝒯, modeltype::EnergyModel)
    # Declaration of the required subsets
    ℳ = modes(ℒᵗʳᵃⁿˢ)
    ℳᵉᵐ = filter(m -> has_emissions(m), ℳ)

    return @expression(m, [t ∈ 𝒯, p ∈ 𝒫ᵉᵐ],
        sum(m[:emissions_trans][tm, t, p] for tm ∈ ℳᵉᵐ)
    )
end
function EMB.emissions_operational(m,  𝒜::Vector{<:Area}, 𝒫ᵉᵐ, 𝒯, modeltype::EnergyModel)
    return @expression(m, [t ∈ 𝒯, p ∈ 𝒫ᵉᵐ], 0)
end

"""
    EMB.objective_operational(m, ℒᵗʳᵃⁿˢ::Vector{Transmission}, 𝒯ᴵⁿᵛ::TS.AbstractStratPers, modeltype::EnergyModel)
    EMB.objective_operational(m, 𝒜::Vector{<:Area}, 𝒯ᴵⁿᵛ::TS.AbstractStratPers, modeltype::EnergyModel)

Create JuMP expressions indexed over the investment periods `𝒯ᴵⁿᵛ` for different elements.
The expressions correspond to the operating expenses of the different elements.
The expressions are not discounted and do not take the duration of the investment periods
into account.

By default, objective expressions are included for:
- `𝒳 = ℒᵗʳᵃⁿˢ::Vector{Transmission}`. In the case of a vector of transmission corridors, the
  method returns the sum of the variable and fixed OPEX for all modes whose method of the
  function [`has_opex`](@ref) returns true.
- `𝒳 = 𝒜::Vector{<:Area}`. In the case of a vector of areas, the method returns a value of 0
   for all investment periods.
"""
function EMB.objective_operational(
    m,
    ℒᵗʳᵃⁿˢ::Vector{Transmission},
    𝒯ᴵⁿᵛ::TS.AbstractStratPers,
    modeltype::EnergyModel,
)
    # Declaration of the required subsets
    ℳ = modes(ℒᵗʳᵃⁿˢ)
    ℳᵒᵖᵉˣ = filter(has_opex, ℳ)

    return @expression(m, [t_inv ∈ 𝒯ᴵⁿᵛ],
        sum((m[:trans_opex_var][tm, t_inv] + m[:trans_opex_fixed][tm, t_inv]) for tm ∈ ℳᵒᵖᵉˣ)
    )
end
function EMB.objective_operational(
    m,
    𝒜::Vector{<:Area},
    𝒯ᴵⁿᵛ::TS.AbstractStratPers,
    modeltype::EnergyModel,
)
    return @expression(m, [t_inv ∈ 𝒯ᴵⁿᵛ], 0)
end

"""
    EMB.create_node(m, n::GeoAvailability, 𝒯, 𝒫, modeltype::EnergyModel)

Set all constraints for a [`GeoAvailability`](@ref). The energy balance is handled in the
function [`constraints_couple`](@ref EnergyModelsBase.constraints_couple).

"""
function EMB.create_node(m, n::GeoAvailability, 𝒯, 𝒫, modeltype::EnergyModel) end

"""
    create_area(m, a::Area, 𝒯, ℒᵗʳᵃⁿˢ, modeltype)

Set all constraints for an [`Area`](@ref). Can serve as fallback option for all unspecified
subtypes of `Area`.

The default method does not add any constraints.
"""
function create_area(m, a::Area, 𝒯, ℒᵗʳᵃⁿˢ, modeltype) end

"""
    create_area(m, a::LimitedExchangeArea, 𝒯, ℒᵗʳᵃⁿˢ, modeltype)

When the area is a [`LimitedExchangeArea`](@ref), we limit the export of the specified
limit resources `p` to the providewd value.
"""
function create_area(m, a::LimitedExchangeArea, 𝒯, ℒᵗʳᵃⁿˢ, modeltype)

    ## TODO: Consider adding additional types for import or export exchange limits
    # @constraint(m, [t ∈ 𝒯, p ∈ elimit_resources(a)],
    #     m[:area_exchange][a, t, p] <= exchange_limit(a, p, t)) # Import limit

    @constraint(m, [t ∈ 𝒯, p ∈ limit_resources(a)],
        m[:area_exchange][a, t, p] >= -1 * exchange_limit(a, p, t)) # Export limit

end

"""
    create_transmission_mode(m, tm::TransmissionMode, 𝒯, modeltype::EnergyModel)

Set all constraints for a [`TransmissionMode`](@ref).

Serves as a fallback option for unspecified subtypes of `TransmissionMode`.

# Called constraint functions
- [`constraints_trans_balance`](@ref),
- [`constraints_trans_loss`](@ref),
- [`constraints_capacity`](@ref),
- [`constraints_emission`](@ref),
- [`constraints_opex_fixed`](@ref), and
- [`constraints_opex_var`](@ref).
"""
function create_transmission_mode(m, tm::TransmissionMode, 𝒯, modeltype::EnergyModel)

    # Defining the required sets
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)

    # Call of the function for tranmission balance
    # Generic trans in which each output corresponds to the input minus losses
    constraints_trans_balance(m, tm, 𝒯, modeltype)

    # Call of the functions for tranmission losses
    constraints_trans_loss(m, tm, 𝒯, modeltype)

    # Call of the function for limiting the capacity to the maximum installed capacity
    constraints_capacity(m, tm, 𝒯, modeltype)

    # Call of the functions for transmission emissions
    constraints_emission(m, tm, 𝒯, modeltype)

    # Call of the functions for both fixed and variable OPEX constraints introduction
    if has_opex(tm)
        constraints_opex_fixed(m, tm, 𝒯ᴵⁿᵛ, modeltype)
        constraints_opex_var(m, tm, 𝒯ᴵⁿᵛ, modeltype)
    end
end
