# Initial solution
"""
    initialsolution([rng], instance, method)

Returns initial LRP solution for the given `instance` using the given `method`.

Available methods include,
- K-means Clustering Initialization     : `:cluster`
- Clarke and Wright Savings Algorithm   : `:cw`
- Random Initialization                 : `:random`

Optionally specify a random number generator `rng` as the first argument
(defaults to `Random.GLOBAL_RNG`).
"""
initialsolution(rng::AbstractRNG, instance, method::Symbol)::Solution = getfield(VRP, method)(rng, instance)
initialsolution(instance, method::Symbol) = initialsolution(Random.GLOBAL_RNG, instance, method)

# k-means clustering Initialization
# Create initial solution using k-means clustering algorithm
function cluster(rng::AbstractRNG, instance)
    G = build(instance)
    s = Solution(G...)
    D = s.D
    C = s.C
    V = [v for d ∈ D for v ∈ d.V]
    # Step 1: Initialize
    preinitialize!(s)
    W = zeros(4, eachindex(C))
    for (iⁿ,c) ∈ pairs(C) W[:,iⁿ] = [c.x, c.y, c.tᵉ, c.tˡ] end
    # Step 2: Cluster customer nodes
    K  = kmeans(W.parent, length(V); rng=rng)
    A  = OffsetVector(K.assignments, eachindex(C))
    Cᵒ = K.centers
    Iᵒ = 1:size(Cᵒ)[2]
    # Step 3: Build initial solution by assigning each cluster to the closest available depot node and consequently inserting customer nodes into the routes
    for iᵒ ∈ Iᵒ
        Z = fill(Inf, length(D))
        for (iⁿ,d) ∈ pairs(D)
            if all(isopt, d.V) continue end
            xᵒ = Cᵒ[1,iᵒ]
            yᵒ = Cᵒ[2,iᵒ]
            xᵈ = d.x
            yᵈ = d.y
            Z[iⁿ] = sqrt((xᵒ-xᵈ)^2 + (yᵒ-yᵈ)^2)
        end
        iⁿ = argmin(Z)
        d  = D[iⁿ]
        R  = [r for v ∈ d.V for r ∈ v.R]
        L  = filter(c -> isequal(A[c.iⁿ], iᵒ), C)
        I = eachindex(L)
        J = eachindex(R)
        X = ElasticMatrix(fill(Inf, (I,J)))     # X[i,j]: insertion cost of customer node L[i] at best position in route R[j]
        P = ElasticMatrix(fill((0, 0), (I,J)))  # P[i,j]: best insertion postion of customer node L[i] in route R[j]
        ϕ = ones(Int64, J)                      # ϕ[j]  : selection weight for route R[j]
        # Step 3.1: Iterate until all customer nodes of the cluster have been inserted into the route
        for _ ∈ I
            # Step 3.1.1: Iterate through all customer nodes of the cluster and every possible insertion position in each route
            zᵒ = f(s)
            for (i,c) ∈ pairs(L)
                if !isopen(c) continue end
                for (j,r) ∈ pairs(R)
                    if iszero(ϕ[j]) continue end
                    d  = s.D[r.iᵈ]
                    nˢ = isopt(r) ? C[r.iˢ] : D[r.iˢ]
                    nᵉ = isopt(r) ? C[r.iᵉ] : D[r.iᵉ]
                    nᵗ = d
                    nʰ = nˢ
                    while true
                        # Step 3.1.1.1: Insert customer node c between tail node nᵗ and head node nʰ in route r
                        insertnode!(c, nᵗ, nʰ, r, s)
                        # Step 3.1.1.2: Compute the insertion cost
                        z⁺ = f(s)
                        Δ  = z⁺ - zᵒ
                        # Step 3.1.1.3: Revise least insertion cost in route r and the corresponding best insertion position in route r
                        if Δ < X[i,j] X[i,j], P[i,j] = Δ, (nᵗ.iⁿ, nʰ.iⁿ) end
                        # Step 3.1.1.4: Remove customer node c from its position between tail node nᵗ and head node nʰ
                        removenode!(c, nᵗ, nʰ, r, s)
                        if isequal(nᵗ, nᵉ) break end
                        nᵗ = nʰ
                        nʰ = isequal(r.iᵉ, nᵗ.iⁿ) ? D[nᵗ.iʰ] : C[nᵗ.iʰ]
                    end
                end
            end
            # Step 3.1.2: Insert customer node with least insertion cost at its best position
            i,j = Tuple(argmin(X))
            c = L[i]
            r = R[j]
            d = s.D[r.iᵈ]
            v = d.V[r.iᵛ]
            iᵗ = P[i,j][1]
            iʰ = P[i,j][2]
            nᵗ = iᵗ ≤ length(D) ? D[iᵗ] : C[iᵗ]
            nʰ = iʰ ≤ length(D) ? D[iʰ] : C[iʰ]
            insertnode!(c, nᵗ, nʰ, r, s)
            # Step 3.1.3: Revise vectors appropriately
            X[i,:] .= Inf
            P[i,:] .= ((0, 0), )
            ϕ .= 0
            for (j,r) ∈ pairs(R) 
                if !isequal(r.iᵛ, v.iᵛ) continue end
                X[:,j] .= Inf
                P[:,j] .= ((0, 0), )
                ϕ[j] = 1  
            end
            if addroute(r, s)
                r = Route(v, d)
                push!(v.R, r) 
                push!(R, r)
                append!(X, fill(Inf, (I,1)))
                append!(P, fill((0, 0), (I,1)))
                push!(ϕ, 1)
            end
            if addvehicle(v, s)
                v = Vehicle(v, d)
                r = Route(v, d)
                push!(d.V, v)
                push!(v.R, r) 
                push!(R, r)
                append!(X, fill(Inf, (I,1)))
                append!(P, fill((0, 0), (I,1)))
                push!(ϕ, 1)
            end
        end
    end
    postinitialize!(s)
    # Step 4: Return initial solution
    return s
end

# Clarke and Wright Savings Algorithm
# Create initial solution merging routes that render the most savings until no merger can render further savings
function cw(rng::AbstractRNG, instance)
    G = build(instance)
    s = Solution(G...)
    D = s.D
    C = s.C
    V = [v for d ∈ D for v ∈ d.V]
    # Step 1: Initialize by assigning customer node to the vehicle-depot pair that results in least assignment cost
    R = Route[]
    I = eachindex(V)
    J = eachindex(C)
    X = fill(Inf, (I,J))                # X[i,j]: Cost of assigning customer node C[j] to vehicle V[i]
    # Step 2: Iterate through each customer node
    for (j,c) ∈ pairs(C)
        # Step 2.1: For customer node c, iterate through every vehicle-depot pair evaluating assignment cost
        zᵒ = f(s)
        for (i,v) ∈ pairs(V)
            # Step 2.1.1: Assign customer node c to vehicle v of depot node d
            d = D[v.iᵈ] 
            r = Route(v, d)
            push!(v.R, r)
            insertnode!(c, d, d, r, s)
            # Step 2.1.2: Compute assignment cost
            z⁺ = f(s)
            Δ  = z⁺ - zᵒ
            X[i,j] = Δ
            # Step 2.1.3: Unassign customer node c from vehicle v of depot node d
            removenode!(c, d, d, r, s)
            pop!(v.R)
        end
        # Step 2.2: Assign customer node c to vehicle v of depot node v that results in least assignment cost
        i = argmin(X[:,j])
        v = V[i]
        d = D[v.iᵈ]
        r = Route(v, d)
        push!(v.R, r)
        push!(R, r)
        insertnode!(c, d, d, r, s)
        # Step 2.3: Revise vectors appropriately
        X[:,j] .= Inf
    end
    # Step 3: Merge routes iteratively until no merger can render further savings
    K = eachindex(R)
    Y = fill(-Inf, (K,K))               # Y[i,j]: Savings from merging route R[i] into R[j] 
    ϕ = ones(Int64, K)                  # ϕ[k]  : selection weight for route R[k]  
    while true
        # Step 3.1: Iterate through every route-pair combination
        zᵒ = f(s)
        for (i,r¹) ∈ pairs(R)
            if !isopt(r¹) continue end
            for (j,r²) ∈ pairs(R)
                # Step 3.1.1: Merge route r¹ into route r²
                if !isopt(r²) continue end
                if isequal(r¹, r²) continue end
                if iszero(ϕ[i]) & iszero(ϕ[j]) continue end
                v¹, v² = V[r¹.iᵛ], V[r².iᵛ]
                d¹, d² = D[v¹.iᵈ], D[v².iᵈ]
                cˢ, cᵉ = C[r¹.iˢ], C[r¹.iᵉ]
                while true
                    c  = C[r¹.iˢ]
                    nᵗ = d¹
                    nʰ = isequal(r¹.iᵉ, c.iⁿ) ? D[c.iʰ] : C[c.iʰ]
                    removenode!(c, nᵗ, nʰ, r¹, s)
                    nᵗ = C[r².iᵉ]
                    nʰ = d²
                    insertnode!(c, nᵗ, nʰ, r², s)
                    if isequal(c, cᵉ) break end
                end
                # Step 3.1.2: Compute savings from merging route r¹ into route r²
                z⁻ = f(s)
                Δ  = z⁻ - zᵒ
                Y[i,j] = -Δ
                # Step 3.1.3: Unmerge routes r¹ and r²
                while true
                    c  = C[r².iᵉ] 
                    nᵗ = C[c.iᵗ]
                    nʰ = d²
                    removenode!(c, nᵗ, nʰ, r², s)
                    nᵗ = d¹
                    nʰ = isopt(r¹) ? C[r¹.iˢ] : D[r¹.iˢ]
                    insertnode!(c, nᵗ, nʰ, r¹, s)
                    if isequal(c, cˢ) break end
                end
            end
        end
        # Step 3.2: Merge routes that render highest savings. If no route render savings, go to step 4. 
        if maximum(Y) < 0 break end
        i,j = Tuple(argmax(Y))
        r¹, r² = R[i], R[j]
        v¹, v² = V[r¹.iᵛ], V[r².iᵛ]
        d¹, d² = D[v¹.iᵈ], D[v².iᵈ]
        cˢ, cᵉ = C[r¹.iˢ], C[r¹.iᵉ]
        while true
            c  = C[r¹.iˢ]
            nᵗ = d¹
            nʰ = isequal(r¹.iᵉ, c.iⁿ) ? D[c.iʰ] : C[c.iʰ]
            removenode!(c, nᵗ, nʰ, r¹, s)
            nᵗ = C[r².iᵉ]
            nʰ = d²
            insertnode!(c, nᵗ, nʰ, r², s)
            if isequal(c, cᵉ) break end
        end
        # Step 3.3: Revise savings and selection vectors appropriately
        Y[i,:] .= -Inf
        Y[:,i] .= -Inf
        ϕ .= 0
        for (j,r) ∈ pairs(R)
            if !isequal(r.iᵛ, v².iᵛ) continue end
            Y[j,:] .= -Inf 
            Y[:,j] .= -Inf
            ϕ[j] = 1
        end
    end
    postinitialize!(s)
    # Step 5: Return initial solution
    return s
end

# Random Initialization
# Create initial solution with randomly selcted node-route combination until all customer nodes have been added to the solution
function random(rng::AbstractRNG, instance)
    G = build(instance)
    s = Solution(G...)
    D = s.D
    C = s.C
    # Step 1: Initialize
    preinitialize!(s)
    d = sample(rng, D)
    v = sample(rng, d.V)
    r = sample(rng, v.R)
    W = ones(Int64, eachindex(C))                      # W[i]: selection weight for customer node C[i]
    # Step 2: Iteratively append randomly selected customer node in randomly selected route
    while any(isopen, C)
        c  = sample(rng, C, OffsetWeights(W))
        nᵗ = d
        nʰ = isopt(r) ? C[r.iˢ] : D[r.iˢ]
        insertnode!(c, nᵗ, nʰ, r, s)
        iⁿ = c.iⁿ
        W[iⁿ] = 0
    end
    postinitialize!(s)
    # Step 4: Return initial solution
    return s
end