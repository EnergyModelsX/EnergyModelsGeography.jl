
# Nodes
struct Area
	id
	lon::Real
	lat::Real
	an::EMB.Availability
end

Base.show(io::IO, a::Area) = print(io, "$(a.id)")


# Transmission
struct Transmission
    id
    from::Area
    to::Area
    formulation::EMB.Formulation
	#capacity::Dict{EMB.Resource} #TODO: Use this param to limit transmission between areas
end

Base.show(io::IO, t::Transmission) = print(io, "$(t.from)-$(t.to)")

function trans_sub(ℒ, a::Area)
    return [ℒ[findall(x -> x.from == a, ℒ)],
            ℒ[findall(x -> x.to   == a, ℒ)]]
end

function trans_res(l::Transmission)
    return intersect(keys(l.to.an.input), keys(l.from.an.output))
end

# Map example (go.Scattermapbox at bottom of page)
# https://plotly.com/python/hover-text-and-formatting/