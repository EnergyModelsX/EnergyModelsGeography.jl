
"""
    getnodesinarea(a::Area, links)

Return a vector with all the nodes connected to the central availability node of an area.

# Fields
- **`a::Area`**. \n
- **`links`** is a vector of all links in the model.
"""
function getnodesinarea(a::Area, links)
    av = availability_node(a)
    nodes = []

    for l ∈ links
        n1 = l.from
        n2 = l.to

        if n1 == av && !(n2 ∈ nodes)
            push!(nodes, n2)
        elseif n2 == av && !(n1 ∈ nodes)
            push!(nodes, n1)
        end
    end
    # Need to find the nodes that are not connected directly to the availability nodes.
    for _ ∈ links, l ∈ links
        n1 = l.from
        n2 = l.to

        if n1 ∈ nodes && !(n2 ∈ nodes)
            push!(nodes, n2)
        elseif n2 ∈ nodes && !(n1 ∈ nodes)
            push!(nodes, n1)
        end
    end
    return unique!(nodes)
end
