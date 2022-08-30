"""
    remove!([rng], q::Int64, s::Solution, method::Symbol)

Return solution removing q customer nodes from solution s using the given `method`.

Available methods include,
- Random Node Removal       : `:randomnode!`
- Random Route Removal      : `:randomroute!`
- Related Node Removal      : `:relatednode!`
- Related Route removal     : `:relatedroute!`
- Worst Node Removal        : `:worstnode!`
- Worst Route Removal       : `:worstroute!`

Optionally specify a random number generator `rng` as the first argument
(defaults to `Random.GLOBAL_RNG`).
"""
remove!(rng::AbstractRNG, q::Int64, s::Solution, method::Symbol)::Solution = getfield(VRP, method)(rng, q, s)
remove!(q::Int64, s::Solution, method::Symbol) = remove!(Random.GLOBAL_RNG, q, s, method)

# -------------------------------------------------- NODE REMOVAL --------------------------------------------------
# Random Node Removal
# Randomly select q customer nodes to remove
function randomnode!(rng::AbstractRNG, q::Int64, s::Solution)
    D = s.D
    C = s.C
    V = s.V
    # Step 1: Randomly select customer nodes to remove until q customer nodes have been removed
    n = 0
    w = isclose.(C)
    while n < q
        i = sample(rng, eachindex(C), OffsetWeights(w))
        c = C[i]
        if isopen(c) continue end
        r = c.r
        v = V[r.o]
        nₜ = isequal(r.iₛ, c.i) ? D[c.iₜ] : C[c.iₜ]
        nₕ = isequal(r.iₑ, c.i) ? D[c.iₕ] : C[c.iₕ]
        removenode!(c, nₜ, nₕ, r, s)
        n += 1
        w[i] = 0
    end
    # Step 2: Return solution
    return s
end

# Related Node Removal (related to pivot)
# For a randomly selected customer node, remove q most related customer nodes
function relatednode!(rng::AbstractRNG, q::Int64, s::Solution)
    D = s.D
    C = s.C
    A = s.A
    V = s.V
    # Step 1: Randomly select a pivot customer node
    j = rand(rng, eachindex(C))
    # Step 2: For each customer node, evaluate relatedness to this pivot customer node
    x = fill(-Inf, eachindex(C))    # x[i]: relatedness of customer node C[i] with customer node C[j]  
    for i ∈ eachindex(C) x[i] = relatedness(C[i], C[j], A[(i,j)]) end
    # Step 3: Remove q most related customer nodes
    n = 0
    while n < q
        i = argmax(x)
        c = C[i]
        r = c.r
        v = V[r.o]
        nₜ = isequal(r.iₛ, c.i) ? D[c.iₜ] : C[c.iₜ]
        nₕ = isequal(r.iₑ, c.i) ? D[c.iₕ] : C[c.iₕ]
        removenode!(c, nₜ, nₕ, r, s)
        n += 1
        x[i] = -Inf
    end
    # Step 4: Return solution
    return s
end

# Worst Node Removal
# Remove q customer nodes with highest removal cost (savings)
function worstnode!(rng::AbstractRNG, q::Int64, s::Solution)
    D = s.D
    C = s.C
    V = s.V
    I = eachindex(C)
    J = eachindex(V)
    x = fill(-Inf, I)               # x[i]: removal cost of customer node C[i]
    ϕ = ones(Int64, J)              # ϕ[j]: selection weight for vehicle V[j]
    # Step 1: Iterate until q customer nodes have been removed
    n = 0
    while n < q
        # Step 1.1: For every closed customer node evaluate removal cost
        zᵒ = f(s)
        for (i,c) ∈ pairs(C)
            r = c.r
            j = r.o
            if isopen(c) continue end
            if iszero(ϕ[j]) continue end
            # Step 1.1.1: Remove closed customer node c between tail node nₜ and head node nₕ in route r
            nₜ = isequal(r.iₛ, c.i) ? D[c.iₜ] : C[c.iₜ]
            nₕ = isequal(r.iₑ, c.i) ? D[c.iₕ] : C[c.iₕ]
            removenode!(c, nₜ, nₕ, r, s)
            # Step 1.1.2: Evaluate the removal cost
            z⁻ = f(s)
            Δ  = z⁻ - zᵒ
            x[i] = -Δ
            # Step 1.1.3: Re-insert customer node c between tail node nₜ and head node nₕ in route r
            insertnode!(c, nₜ, nₕ, r, s)
        end
        # Step 1.2: Remove the customer node with highest removal cost (savings)
        i = argmax(x)
        c = C[i]
        r = c.r
        v = V[r.o]
        nₜ = isequal(r.iₛ, c.i) ? D[c.iₜ] : C[c.iₜ]
        nₕ = isequal(r.iₑ, c.i) ? D[c.iₕ] : C[c.iₕ]
        removenode!(c, nₜ, nₕ, r, s)
        n += 1
        # Step 1.3: Update cost and selection weight vectors
        x[i] = -Inf
        for (j,v) ∈ pairs(V) ϕ[j] = isequal(r.o, v.i) ? 1 : 0 end
    end
    # Step 2: Return solution
    return s
end

# -------------------------------------------------- ROUTE REMOVAL --------------------------------------------------
# Random Route Removal
# Iteratively select a random route and remove customer nodes from it until at least q customer nodes are removed
function randomroute!(rng::AbstractRNG, q::Int64, s::Solution)
    D = s.D
    C = s.C
    V = s.V
    R = [v.r for v ∈ V]
    # Step 1: Iteratively select a random route and remove customer nodes from it until at least q customer nodes are removed
    n = 0
    w = isopt.(R)
    while n < q
        if isone(sum(w)) break end
        i = sample(rng, eachindex(R), Weights(w))
        r = R[i]
        v = V[r.o]
        d = D[v.o]
        while true
            nₜ = d
            c  = C[r.iₛ]
            nₕ = isequal(r.iₑ, c.i) ? D[c.iₕ] : C[c.iₕ]
            removenode!(c, nₜ, nₕ, r, s)
            n += 1
            if isequal(nₕ, d) break end
        end
        w[i] = 0
    end
    # Step 2: Return solution
    return s
end

# Related Route Removal
# For a randomly selected route, remove customer nodes from most related route until q customer nodes are removed
function relatedroute!(rng::AbstractRNG, q::Int64, s::Solution)
    D = s.D
    C = s.C
    V = s.V
    R = [v.r for v ∈ V]
    # Step 1: Randomly select a pivot route
    j = sample(rng, eachindex(R), Weights(isopt.(R)))  
    # Step 2: For each route, evaluate relatedness to this pivot route
    x = fill(-Inf, eachindex(R))
    for (i,r) ∈ pairs(R) x[i] = !isopt(r) ? -Inf : relatedness(R[i], R[j]) end
    # Step 3: Remove at least q customers from most related route to this pivot route
    n = 0
    w = isopt.(R)
    while n < q
        if isone(sum(w)) break end
        i = argmax(x)
        r = R[i]
        v = V[r.o]
        d = D[v.o]
        while true
            nₜ = d
            c  = C[r.iₛ]
            nₕ = isequal(r.iₑ, c.i) ? D[c.iₕ] : C[c.iₕ]
            removenode!(c, nₜ, nₕ, r, s)
            n += 1
            if isequal(nₕ, d) break end
        end 
        x[i] = -Inf
        w[i] = 0
    end
    # Step 4: Return solution
    return s
end

# Worst Route Removal
# Iteratively select low-utilization route and remove customer nodes from it until at least q customer nodes are removed
function worstroute!(rng::AbstractRNG, q::Int64, s::Solution)
    D = s.D
    C = s.C
    V = s.V
    R = [v.r for v ∈ V]
    # Step 1: Evaluate utilization of each route
    x = fill(Inf, eachindex(R))
    for (i,r) ∈ pairs(R)
        if !isopt(r) continue end
        v = V[r.o]
        u = r.q/v.q
        x[i] = u
    end
    # Step 2: Iteratively select low-utilization route and remove customer nodes from it until at least q customer nodes are removed
    n = 0
    w = isopt.(R)
    while n < q
        if isone(sum(w)) break end
        i = argmin(x)
        r = R[i]
        v = V[r.o]
        d = D[v.o]
        while true
            nₜ = d
            c  = C[r.iₛ]
            nₕ = isequal(r.iₑ, c.i) ? D[c.iₕ] : C[c.iₕ]
            removenode!(c, nₜ, nₕ, r, s)
            n += 1
            if isequal(nₕ, d) break end
        end
        x[i] = Inf
        w[i] = 0
    end
    # Step 3: Return solution
    return s
end