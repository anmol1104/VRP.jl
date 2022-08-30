"""
    insert!([rng], s::Solution, method::Symbol)

Return solution inserting open customer nodes to the solution `s` using the given `method`.

Available methods include,
- Best insertion    : `:best!`
- Greedy insertion  : `:greedy!`
- Regret insertion  : `:regret2!`, `:regret3!`

Optionally specify a random number generator `rng` as the first argument
(defaults to `Random.GLOBAL_RNG`).
"""
insert!(rng::AbstractRNG, s::Solution, method::Symbol)::Solution = getfield(VRP, method)(rng, s)
insert!(s::Solution, method::Symbol) = insert!(Random.GLOBAL_RNG, s, method)

# Best insertion
# Iteratively insert randomly selected customer node at its best position until all open customer nodes have been added to the solution
function best!(rng::AbstractRNG, s::Solution)
    if all(isclose, s.C) return s end
    d = s.d
    C = s.C
    V = d.V
    R = [v.r for v ∈ V]
    L = [c for c ∈ C if isopen(c)]
    # Step 1: Initialize
    I = eachindex(L)
    J = eachindex(R)
    x = fill(Inf, (I,J))                    # x[i,j]: insertion cost of customer node L[i] at best position in route R[j]
    p = fill((0, 0), (I,J))                 # p[i,j]: best insertion postion of customer node L[i] in route R[j]
    w = ones(Int64, I)                      # w[j]  : selection weight for customer node L[i]
    ϕ = ones(Int64, J)                      # ϕ[j]  : selection weight for route R[j]
    # Step 2: Iterate until all open customer nodes have been inserted into the route
    for _ ∈ I
        # Step 2.1: Iterate through all open customer nodes and every possible insertion position in each route
        zᵒ = f(s)
        for (i,c) ∈ pairs(L)
            if !isopen(c) continue end
            for (j,r) ∈ pairs(R)
                if iszero(ϕ[j]) continue end
                nₛ = isopt(r) ? C[r.iₛ] : d
                nₑ = isopt(r) ? C[r.iₑ] : d
                nₜ = d
                nₕ = nₛ
                while true
                    # Step 2.1.1: Insert customer node c between tail node nₜ and head node nₕ in route r
                    insertnode!(c, nₜ, nₕ, r, s)
                    # Step 2.1.2: Compute the insertion cost
                    z⁺ = f(s)
                    Δ  = z⁺ - zᵒ
                    # Step 2.1.3: Revise least insertion cost in route r and the corresponding best insertion position in route r
                    if Δ < x[i,j] x[i,j], p[i,j] = Δ, (nₜ.i, nₕ.i) end
                    # Step 2.1.4: Remove customer node c from its position between tail node nₜ and head node nₕ
                    removenode!(c, nₜ, nₕ, r, s)
                    if isequal(nₜ, nₑ) break end
                    nₜ = nₕ
                    nₕ = isequal(r.iₑ, nₜ.i) ? d : C[nₜ.iₕ]
                end
            end
        end
        # Step 2.2: Randomly select a customer node to insert at its best position
        i = sample(rng, I, Weights(w))
        j = argmin(x[i,:])
        c = L[i]
        r = R[j]
        iₜ, iₕ = p[i,j]
        nₜ = isone(iₜ) ? d : C[iₜ]
        nₕ = isone(iₕ) ? d : C[iₕ]
        insertnode!(c, nₜ, nₕ, r, s)
        # Step 2.3: Revise vectors appropriately
        x[i,:] .= Inf
        x[:,j] .= Inf
        p[i,:] .= ((0, 0), )
        p[:,j] .= ((0, 0), )
        ϕ .= 0
        w[i] = 0
        ϕ[j] = 1  
    end
    # Step 3: Return initial solution
    return s
end

# Greedy insertion
# Iteratively insert customer nodes with least insertion cost until all open customer nodes have been added to the solution
function greedy!(rng::AbstractRNG, s::Solution)
    if all(isclose, s.C) return s end
    d = s.d
    C = s.C
    V = d.V
    R = [v.r for v ∈ V]
    L = [c for c ∈ C if isopen(c)]
    # Step 1: Initialize
    I = eachindex(L)
    J = eachindex(R)
    x = fill(Inf, (I,J))                    # x[i,j]: insertion cost of customer node L[i] at best position in route R[j]
    p = fill((0, 0), (I,J))                 # p[i,j]: best insertion postion of customer node L[i] in route R[j]
    ϕ = ones(Int64, J)                      # ϕ[j]  : selection weight for route R[j]
    # Step 2: Iterate until all open customer nodes have been inserted into the route
    for _ ∈ I
        # Step 2.1: Iterate through all open customer nodes and every possible insertion position in each route
        zᵒ = f(s)
        for (i,c) ∈ pairs(L)
            if !isopen(c) continue end
            for (j,r) ∈ pairs(R)
                if iszero(ϕ[j]) continue end
                nₛ = isopt(r) ? C[r.iₛ] : d
                nₑ = isopt(r) ? C[r.iₑ] : d
                nₜ = d
                nₕ = nₛ
                while true
                    # Step 2.1.1: Insert customer node c between tail node nₜ and head node nₕ in route r
                    insertnode!(c, nₜ, nₕ, r, s)
                    # Step 2.1.2: Compute the insertion cost
                    z⁺ = f(s)
                    Δ  = z⁺ - zᵒ
                    # Step 2.1.3: Revise least insertion cost in route r and the corresponding best insertion position in route r
                    if Δ < x[i,j] x[i,j], p[i,j] = Δ, (nₜ.i, nₕ.i) end
                    # Step 2.1.4: Remove customer node c from its position between tail node nₜ and head node nₕ
                    removenode!(c, nₜ, nₕ, r, s)
                    if isequal(nₜ, nₑ) break end
                    nₜ = nₕ
                    nₕ = isequal(r.iₑ, nₜ.i) ? d : C[nₜ.iₕ]
                end
            end
        end
        # Step 2.2: Randomly select a customer node to insert at its best position        
        i,j = Tuple(argmin(x))
        c = L[i]
        r = R[j]
        iₜ, iₕ = p[i,j]
        nₜ = isone(iₜ) ? d : C[iₜ]
        nₕ = isone(iₕ) ? d : C[iₕ]
        insertnode!(c, nₜ, nₕ, r, s)
        # Step 2.3: Revise vectors appropriately
        x[i,:] .= Inf
        x[:,j] .= Inf
        p[i,:] .= ((0, 0), )
        p[:,j] .= ((0, 0), )
        ϕ .= 0
        ϕ[j] = 1  
    end
    # Step 3: Return initial solution
    return s
end

# Regret-N insertion
# Iteratively add customer nodes with highest regret cost at its best position until all open customer nodes have been added to the solution
function regretN!(rng::AbstractRNG, N::Int64, s::Solution)
    if all(isclose, s.C) return s end
    d = s.d
    C = s.C
    V = d.V
    R = [v.r for v ∈ V]
    L = [c for c ∈ C if isopen(c)]
    # Step 1: Initialize
    I = eachindex(L)
    J = eachindex(R)
    x = fill(Inf, (I,J))                    # x[i,j]: insertion cost of customer node L[i] at best position in route R[j]
    p = fill((0, 0), (I,J))                 # p[i,j]: best insertion postion of customer node L[i] in route R[j]
    y = fill(Inf, (I,N))                    # y[i,n]: insertion cost of customer node L[i] at nᵗʰ best position
    w = zeros(Int64, (I,N))                 # w[i,n]: route index of customer node L[j] at nᵗʰ best position
    z = fill(-Inf, I)                       # z[i]  : regret-N cost of customer node L[i]
    ϕ = ones(Int64, J)                      # ϕ[j]  : selection weight for route R[j]
    # Step 2: Iterate until all open customer nodes have been inserted into the route
    for _ ∈ I
        # Step 2.1: Iterate through all open customer nodes and every route
        zᵒ = f(s)
        for (i,c) ∈ pairs(L)
            if !isopen(c) continue end
            for (j,r) ∈ pairs(R)
                # Step 2.1.1: Iterate through all possible insertion position in route r
                if iszero(ϕ[j]) continue end
                nₛ = isopt(r) ? C[r.iₛ] : d
                nₑ = isopt(r) ? C[r.iₑ] : d
                nₜ = d
                nₕ = nₛ
                while true
                    # Step 2.1.1.1: Insert customer node c between tail node nₜ and head node nₕ in route r, and compute the insertion cost
                    insertnode!(c, nₜ, nₕ, r, s)
                    # Step 2.1.1.2: Compute the insertion cost
                    z⁺ = f(s)
                    Δ  = z⁺ - zᵒ
                    # Step 2.1.1.3: Revise least insertion cost in route r and the corresponding best insertion position in route r
                    if Δ < x[i,j] x[i,j], p[i,j] = Δ, (nₜ.i, nₕ.i) end
                    # Step 2.1.1.4: Revise N least insertion costs
                    n̲ = 1
                    for n ∈ 1:N 
                        n̲ = n
                        if Δ < y[i,n] break end
                    end
                    for n ∈ N:-1:n̲ 
                        y[i,n] = isequal(n, n̲) ? Δ : y[i,n-1]::Float64
                        w[i,n] = isequal(n, n̲) ? r.i : w[i,n-1]::Int64
                    end
                    # Step 2.1.1.5: Remove customer node c from its position between tail node nₜ and head node nₕ in route r
                    removenode!(c, nₜ, nₕ, r, s)
                    if isequal(nₜ, nₑ) break end
                    nₜ = nₕ
                    nₕ = isequal(r.iₑ, nₜ.i) ? d : C[nₜ.iₕ]
                end
            end
            # Step 2.1.2: Compute regret cost for customer node c
            z[i] = 0.
            for n ∈ 1:N z[i] += y[i,n] - y[i,1] end
        end
        # Step 2.2: Insert customer node with highest regret cost in its best position (break ties by inserting the node with the lowest insertion cost)
        I̲ = findall(i -> i == maximum(z), z)
        i,j = Tuple(argmin(x[I̲,:]))
        i = I̲[i]
        c = L[i]
        r = R[j]
        iₜ, iₕ = p[i,j]
        nₜ = isone(iₜ) ? d : C[iₜ]
        nₕ = isone(iₕ) ? d : C[iₕ]
        insertnode!(c, nₜ, nₕ, r, s)
        # Step 2.3: Revise vectors appropriately
        x[i,:] .= Inf
        x[:,j] .= Inf
        p[i,:] .= ((0, 0), )
        p[:,j] .= ((0, 0), )
        y[i,:] .= Inf
        w[i,:] .= 0
        for (i,c) ∈ pairs(L)
            for n ∈ 1:N
                if !isequal(r.i, w[i,n]) continue end
                y[i,n] = Inf
                w[i,n] = 0
            end
            ix = sortperm(y[i,:])
            y[i,:] .= y[i,ix]
            w[i,:] .= w[i,ix]
        end
        z .= -Inf 
        ϕ .= 0
        ϕ[j] = 1  
    end
    # Step 3: Return initial solution
    return s
end
regret2!(rng::AbstractRNG, s::Solution) = regretN!(rng, Int64(2), s)
regret3!(rng::AbstractRNG, s::Solution) = regretN!(rng, Int64(3), s)
