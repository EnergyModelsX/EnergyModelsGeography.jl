
"""
    check_data(case, modeltype, check_timeprofiles::Bool)

Check if the case data is consistent. Use the `@assert_or_log` macro when testing.
Currently, not checking data except that the case dictionary follows the required structure.
"""
function check_data(case, modeltype, check_timeprofiles::Bool)

    global EMB.logs = []
    log_by_element = Dict()

    # Check the case data. If the case data is not in the correct format, the overall check
    # is cancelled as extractions would not be possible
    check_case_data(case)
    log_by_element["Case data"] = EMB.logs
    if EMB.ASSERTS_AS_LOG
        EMB.compile_logs(case, log_by_element)
    end

    𝒜 = case[:areas]
    ℒᵗʳᵃⁿˢ = case[:transmission]
    𝒫 = case[:products]
    𝒯 = case[:T]

    for a ∈ 𝒜
        check_area(a, 𝒯, 𝒫, modeltype, check_timeprofiles)
        # Put all log messages that emerged during the check, in a dictionary with the
        # area as key.
        log_by_element[a] = EMB.logs
    end
    for l ∈ ℒᵗʳᵃⁿˢ
        check_transmission(l, 𝒯, 𝒫, modeltype, check_timeprofiles)

        ℳ = modes(l)
        for m ∈ ℳ
            check_mode(m, 𝒯, 𝒫, modeltype, check_timeprofiles)
            if check_timeprofiles
                check_time_structure(m, 𝒯)
            end
        # Put all log messages that emerged during the check, in a dictionary with the
        # corridor as key.
        log_by_element[l] = EMB.logs
        end
    end

    if EMB.ASSERTS_AS_LOG
        EMB.compile_logs(case, log_by_element)
    end
end

"""
    check_case_data(case)

Checks the `case` dictionary is in the correct format. The function is only checking the
new, additional data as we do not yet consider dispatch on the case data.

## Checks
- The dictionary requires the keys `:areas` and `:transmission`.
- The individual keys are of the correct type, that is
  - `:areas::Area` and
  - `:transmission::Vector{<:Transmission}`.
"""
function check_case_data(case)

    case_keys = [:areas, :transmission]
    key_map = Dict(
        :areas => Vector{<:Area},
        :transmission => Vector{<:Transmission},
    )
    for key ∈ case_keys
        @assert_or_log(
            haskey(case, key),
            "The `case` dictionary requires the key `:" * string(key) * "` which is " *
            "not included."
        )
        if haskey(case, key)
            @assert_or_log(
                isa(case[key], key_map[key]),
                "The key `" * string(key) * "` in the `case` dictionary contains " *
                "other types than the allowed."
            )
        end
    end
end

"""
    check_area(a::Area, 𝒯, 𝒫, modeltype::EnergyModel, check_timeprofiles::Bool)

Check that the fields of an `Area` corresponds to required structure.
"""
function check_area(a::Area, 𝒯, 𝒫, modeltype::EnergyModel, check_timeprofiles::Bool)
end

"""
    check_transmission(l::Transmission, 𝒯, 𝒫, modeltype::EnergyModel, check_timeprofiles::Bool)

Check that the fields of a `Transmission` corridor corresponds to required structure.
"""
function check_transmission(l::Transmission, 𝒯, 𝒫, modeltype::EnergyModel, check_timeprofiles::Bool)
end


"""
    check_mode(m::TransmissionMode, 𝒯, 𝒫, modeltype::EnergyModel, check_timeprofiles::Bool)

Check that the fields of a `TransmissionMode` corresponds to required structure.
"""
function check_mode(l::TransmissionMode, 𝒯, 𝒫, modeltype::EnergyModel, check_timeprofiles::Bool)
end

"""
    check_time_structure(m::TransmissionMode, 𝒯)

Check that all fields of a `TransmissionMode` that are of type `TimeProfile` correspond to
the time structure `𝒯`.
"""
function check_time_structure(m::TransmissionMode, 𝒯)
    for fieldname ∈ fieldnames(typeof(m))
        value = getfield(m, fieldname)
        if isa(value, TimeProfile)
            EMB.check_profile(fieldname, value, 𝒯)
        end
    end
end
