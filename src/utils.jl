
"""
    getnodesinarea(a::Area, links)

Return a vector with all the nodes connected to the central availability node of an area.

# Arguments
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

"""
    nodes_in_area(a::Area, ℒ::Vector{<:Link}; n_nodes=1000)

Returns a vector of all nodes in area `a` connected through links `ℒ`. The approach is based
on a breadth-first-search and provides all connected nodes, contrary to the function
[getnodesinarea](@ref).

# Arguments
- **`a::Area`** is area that should be evaluated
- **`ℒ::Vector{<:Link}`** is a vector of links that should be evaluated.

# Keyword arguments
- **`n_nodes=1000`** the number of nodes added after which the loop is broken. It must be
  at least equal to the number of nodes in the area `a`.
"""
function nodes_in_area(a::Area, ℒ::Vector{<:Link}; n_nodes=1000)
    av = availability_node(a)

    # Initiate the arrays
    queue = EMB.Node[av]
    nodes = EMB.Node[av]
    links = EMB.Direct[]
    k = 1
    while !isempty(queue)
        # Extract the connected nodes
        con_nodes, con_links = connected_nodes(queue[1], ℒ, nodes)
        append!(queue, con_nodes)
        append!(nodes, con_nodes)
        append!(links, con_links)

        # Remove the current node from the queue
        deleteat!(queue, 1)

        # Update the stack overflow protection
        k += 1
        if k > n_nodes
            break
        end
    end
    return nodes, unique(links)
end

"""
    connected_nodes(n::EMB.Node, ℒ::Vector{<:Link}, nodes::Vector{EMB.Node})

Returns a vector of all unique nodes connected to node `n` through links `ℒ`.
The corresponding links are also returned.

# Arguments
- **`n::EMB.Node`** is the node from which the connections are evaluated.
- **`ℒ::Vector{<:Link}`** is a vector of links that should be evaluated.
- **`nodes::Vector{EMB.Node}`** is a vector of nodes that should not be included.
"""
function connected_nodes(n::EMB.Node, ℒ::Vector{<:Link}, nodes::Vector{<:EMB.Node})
    con_nodes = []
    con_links = []

    # Extract the links which are connecting the node `n`
    for l ∈ ℒ
        n_from = l.from
        n_to = l.to
        if n_from == n && !(n_to ∈ nodes)
            push!(con_nodes, n_to)
            push!(con_links, l)
        elseif n_to == n && !(n_from ∈ nodes)
            push!(con_nodes, n_from)
            push!(con_links, l)
        end
    end
    return unique(con_nodes), con_links
end
