"""
    build(instance::String; dir=joinpath(dirname(@__DIR__), "instances"))
    
Returns a tuple of depot nodes, customer nodes, and arcs for the `instance`.

Note, `dir` locates the the folder containing instance files as sub-folders,
as follows,

    <dir>
    |-<instance>
        |-arcs.csv
        |-customer_nodes.csv
        |-depot_nodes.csv
        |-fuelstation_nodes.csv
        |-vehicles.csv
"""
function build(instance::String; dir=joinpath(dirname(@__DIR__), "instances"))
    # Fuel Station Nodes
    df = DataFrame(CSV.File(joinpath(dir, "$instance/fuelstation_nodes.csv")))
    F  = Vector{FuelStationNode}(undef, nrow(df))
    for k ∈ 1:nrow(df)
        iⁿ = df[k,1]
        jⁿ = df[k,2]
        x  = df[k,3]
        y  = df[k,4]
        τᵛ = df[k,5]
        πᵒ = df[k,6]
        πᶠ = df[k,7]
        ω  = 0.
        f  = FuelStationNode(iⁿ, jⁿ, x, y, τᵛ, πᵒ, πᶠ, ω)
        F[iⁿ] = f
    end
    # Depot Nodes
    df = DataFrame(CSV.File(joinpath(dir, "$instance/depot_nodes.csv")))
    I  = (df[1,1]:df[nrow(df),1])::UnitRange{Int64}
    D  = OffsetVector{DepotNode}(undef, I)
    for k ∈ 1:nrow(df)
        iⁿ = df[k,1]
        x  = df[k,2]
        y  = df[k,3]
        tˢ = df[k,4]
        tᵉ = df[k,5]
        πᵒ = df[k,6]
        πᶠ = df[k,7]
        Fᵈ = FuelStationNode[]
        V  = Vehicle[]
        n  = 0
        d  = DepotNode(iⁿ, x, y, tˢ, tᵉ, πᵒ, πᶠ, Fᵈ, V, n)
        D[iⁿ] = d
    end
    # Vehicles
    df = DataFrame(CSV.File(joinpath(dir, "$instance/vehicles.csv")))
    for k ∈ 1:nrow(df)
        d  = D[df[k,4]]
        iᵛ = df[k,1]
        jᵛ = df[k,2]
        jᶠ = df[k,3]
        iᵈ = df[k,4]
        qᵛ = df[k,5]
        ωᵛ = df[k,6]
        lᵛ = df[k,7]
        sᵛ = df[k,8]
        θ̲  = df[k,9]
        θ̅  = df[k,10]
        τᶜ = df[k,11]
        τʷ = df[k,12]
        πᵈ = df[k,13]
        πᵗ = df[k,14]
        πᶠ = df[k,15]
        r  = NullRoute
        v  = Vehicle(iᵛ, jᵛ, jᶠ, iᵈ, qᵛ, ωᵛ, lᵛ, sᵛ, θ̲, θ̅, τᶜ, τʷ, πᵈ, πᵗ, πᶠ, r)
        x  = 0.
        y  = 0. 
        iˢ = iᵈ
        iᵉ = iᵈ
        tˢ = d.tˢ
        tᵉ = d.tˢ
        θ̲  = 0.
        θ  = 1.
        ω  = 0.
        δ  = 0.
        n  = 0
        l  = 0.
        v.r= Route(iᵛ, iᵈ, x, y, iˢ, iᵉ, tˢ, tᵉ, θ̲, θ, ω, δ, n, l)
        push!(d.V, v)
    end
    # Customer Nodes
    df = DataFrame(CSV.File(joinpath(dir, "$instance/customer_nodes.csv")))
    I  = (df[1,1]:df[nrow(df),1])::UnitRange{Int64}
    C  = OffsetVector{CustomerNode}(undef, I)
    for k ∈ 1:nrow(df)
        iⁿ = df[k,1]
        jⁿ = df[k,2]
        x  = df[k,3]
        y  = df[k,4]
        qᶜ = df[k,5]
        τᶜ = df[k,6]
        tᵉ = df[k,7]
        tˡ = df[k,8]
        Fᶜ = FuelStationNode[]
        iᵗ = 0
        iʰ = 0
        tᵃ = qᶜ > 0. ? tˡ : tᵉ
        tᵈ = tᵃ + τᶜ
        q  = 0.
        θ̲  = 0.
        θ  = 1.
        ω  = 0.
        δ  = 0.
        r  = NullRoute
        c  = CustomerNode(iⁿ, jⁿ, x, y, qᶜ, τᶜ, tᵉ, tˡ, Fᶜ, iᵗ, iʰ, tᵃ, tᵈ, q, θ̲, θ, ω, δ, r)
        C[iⁿ] = c
    end
    # Arcs
    df = DataFrame(CSV.File(joinpath(dir, "$instance/arcs.csv"), header=false))
    A  = Dict{Tuple{Int,Int},Arc}()
    n  = lastindex(C)
    for iᵗ ∈ 1:n
        for iʰ ∈ 1:n
            l = df[iᵗ,iʰ] 
            a = Arc(iᵗ, iʰ, l)
            A[(iᵗ,iʰ)] = a
        end
    end
    V  = [v for d ∈ D for v ∈ d.V]
    Jᶠ = eachindex(unique(getproperty.(V, :jᶠ)))
    for (iᵗ,d) ∈ pairs(D)
        Iᶠ = zeros(Int, Jᶠ)
        Lᶠ = fill(Inf, Jᶠ)
        for (iʰ,f) ∈ pairs(F)
            jᵛ = f.jⁿ
            a  = A[(iᵗ,iʰ)]
            l  = Lᶠ[jᵛ]
            l′ = a.l
            Lᶠ[jᵛ] = l′ < l ? l′ : Lᶠ[jᵛ]
            Iᶠ[jᵛ] = l′ < l ? iʰ : Iᶠ[jᵛ]
        end
        d.F = [F[iⁿ] for iⁿ ∈ Iᶠ]
    end
    for (iᵗ,c) ∈ pairs(C)
        Iᶠ = zeros(Int, Jᶠ)
        Lᶠ = fill(Inf, Jᶠ)
        for (iʰ,f) ∈ pairs(F)
            jᵛ = f.jⁿ
            a  = A[(iᵗ,iʰ)]
            l  = Lᶠ[jᵛ]
            l′ = a.l
            Lᶠ[jᵛ] = l′ < l ? l′ : Lᶠ[jᵛ]
            Iᶠ[jᵛ] = l′ < l ? iʰ : Iᶠ[jᵛ]
        end
        c.F = [F[iⁿ] for iⁿ ∈ Iᶠ]
    end
    G = (F, D, C, A)
    return G
end


"""
    regret([rng::AbstractRNG], instance::String; dir=joinpath(dirname(@__DIR__), "instances"))

Returns initial `Solution` using regret-2 insertion method. 

Note, `dir` locates the the folder containing instance files as sub-folders,
as follows,

    <dir>
    |-<instance>
        |-arcs.csv
        |-customer_nodes.csv
        |-depot_nodes.csv
        |-fuelstation_nodes.csv
        |-vehicles.csv

Optionally specify a random number generator `rng` as the first argument
(defaults to `Random.GLOBAL_RNG`).
"""
function regret(rng::AbstractRNG, instance::String; dir=joinpath(dirname(@__DIR__), "instances"))
    # Step 1: Initialize
    k̅ = 2
    G = build(instance; dir=dir)
    s = Solution(G...)
    D = s.D
    C = s.C
    R = [v.r for d ∈ D for v ∈ d.V]
    L = [c for c ∈ C if isopen(c) && isdelivery(c)]
    I = eachindex(L)
    J = eachindex(R)
    X = fill(Inf, (I,J))                                                    # X[i,j]  : insertion cost of delivery node L[i] and its associated pickup node at their best position in route R[j]
    Y = fill(Inf, (k̅,I,J))                                                  # Y[k,i,j]: insertion cost of delivery node L[i] and its associated pickup node at kᵗʰ best position in route R[j]
    Z = fill(0., I)                                                         # Z[i]    : regret-k cost of delivery node L[i] and its associated pickup node
    P = fill(((0, 0), (0, 0)), (I,J))                                       # P[i,j]  : best insertion postion of associated pickup node and the delivery node L[i] in route R[j]
    U = ["$(d.iⁿ)$(v.jᵛ)$(isopt(v.r) ? v.iᵛ : 0)" for d ∈ D for v ∈ d.V]    # U[j]    : Unique identifier for route R[j]
    ϕ = zeros(Int, J)                                                       # ϕ[j]    : binary weight for route R[j]
    for j ∈ unique(j -> U[j], J) ϕ[j] = 1 end
    # Step 2: Iterate until all open delivery nodes have been inserted into the route
    for _ ∈ I
        # Step 2.1: Iterate through all open delivery nodes (and the associated pickup nodes)
        z = f(s)
        for (i,c) ∈ pairs(L)
            if !isopen(c) continue end
            cᵖ = isdelivery(c) ? s.C[c.jⁿ] : s.C[c.iⁿ] 
            cᵈ = isdelivery(c) ? s.C[c.iⁿ] : s.C[c.jⁿ]
            for (j,r) ∈ pairs(R)
                # Step 2.1.1: Iterate through all possible insertion position in route r
                if iszero(ϕ[j]) continue end
                d   = s.D[r.iᵈ]
                nᵖˢ = isopt(r) ? C[r.iˢ] : D[r.iˢ]
                nᵖᵉ = isopt(r) ? C[r.iᵉ] : D[r.iᵉ]
                nᵖᵗ = d
                nᵖʰ = nᵖˢ
                while true
                    # Step 2.1.1.1: Insert associated pickup node cᵖ between tail node nᵖᵗ and head node nᵖʰ in route r
                    insertnode!(cᵖ, nᵖᵗ, nᵖʰ, r, s)
                    nᵈˢ = isopt(r) ? C[r.iˢ] : D[r.iˢ]
                    nᵈᵉ = isopt(r) ? C[r.iᵉ] : D[r.iᵉ]
                    nᵈᵗ = d
                    nᵈʰ = nᵈˢ
                    while true
                        # Step 2.1.1.1.1: Insert delivery node cᵈ between tail node nᵈᵗ and head node nᵈʰ in route r
                        insertnode!(cᵈ, nᵈᵗ, nᵈʰ, r, s)
                        # Step 2.1.1.1.2: Compute the insertion cost
                        z′ = f(s)
                        Δ  = z′ - z
                        # Step 2.1.1.1.3: Revise least insertion cost in route r and the corresponding best insertion position in route r
                        if Δ < X[i,j] X[i,j], P[i,j] = Δ, ((nᵖᵗ.iⁿ, nᵖʰ.iⁿ), (nᵈᵗ.iⁿ, nᵈʰ.iⁿ)) end
                        # Step 2.1.1.1.4: Revise k least insertion costs
                        k̲ = 1
                        for k ∈ 1:k̅ Δ < Y[k,i,j] ? break : k̲ += 1 end
                        for k ∈ k̅:-1:k̲ Y[k,i,j] = isequal(k, k̲) ? Δ : Y[k-1,i,j] end
                        # Step 2.1.1.1.5: Remove delivery node cᵈ from its position between tail node nᵈᵗ and head node nᵈʰ in route r
                        removenode!(cᵈ, nᵈᵗ, nᵈʰ, r, s)
                        if isequal(nᵈᵗ, nᵈᵉ) break end
                        nᵈᵗ = nᵈʰ
                        nᵈʰ = isequal(r.iᵉ, nᵈᵗ.iⁿ) ? D[nᵈᵗ.iʰ] : C[nᵈᵗ.iʰ]
                    end
                    # Step 2.1.1.2: Remove associated pickup node cᵖ between tail node nᵖᵗ and head node nᵖʰ in route r
                    removenode!(cᵖ, nᵖᵗ, nᵖʰ, r, s)
                    if isequal(nᵖᵗ, nᵖᵉ) break end
                    nᵖᵗ = nᵖʰ
                    nᵖʰ = isequal(r.iᵉ, nᵖᵗ.iⁿ) ? D[nᵖᵗ.iʰ] : C[nᵖᵗ.iʰ]
                end
            end
            # Step 2.1.2: Compute regret cost for delivery node L[i]
            W = sort(vec(Y[:,i,:]))
            for k ∈ 1:k̅ Z[i] += W[k] - W[1] end
        end
        # Step 2.2: Insert delivery node and the associated pickup node with highest regret cost in its best position (break ties by inserting the nodes with the lowest insertion cost)
        I̲   = findall(isequal.(Z, maximum(Z)))
        i,j = Tuple(argmin(X[I̲,:]))
        i   = I̲[i]
        c   = L[i]
        cᵖ  = isdelivery(c) ? s.C[c.jⁿ] : s.C[c.iⁿ] 
        cᵈ  = isdelivery(c) ? s.C[c.iⁿ] : s.C[c.jⁿ]
        r   = R[j]
        d   = s.D[r.iᵈ]
        v   = d.V[r.iᵛ]
        iᵖᵗ = P[i,j][1][1]
        iᵖʰ = P[i,j][1][2]
        iᵈᵗ = P[i,j][2][1]
        iᵈʰ = P[i,j][2][2]
        nᵖᵗ = iᵖᵗ ≤ lastindex(D) ? D[iᵖᵗ] : C[iᵖᵗ]
        nᵖʰ = iᵖʰ ≤ lastindex(D) ? D[iᵖʰ] : C[iᵖʰ]
        nᵈᵗ = iᵈᵗ ≤ lastindex(D) ? D[iᵈᵗ] : C[iᵈᵗ]
        nᵈʰ = iᵈʰ ≤ lastindex(D) ? D[iᵈʰ] : C[iᵈʰ]
        insertnode!(cᵖ, nᵖᵗ, nᵖʰ, r, s)
        insertnode!(cᵈ, nᵈᵗ, nᵈʰ, r, s)
        # Step 2.3: Revise vectors appropriately
        ϕ .= 0
        Z .= 0.
        X[i,:] .= Inf
        Y[:,i,:] .= Inf
        P[i,:] .= (((0 ,0), (0, 0)), )
        X[:,j] .= Inf
        Y[:,:,j] .= Inf
        P[:,j] .= (((0 ,0), (0, 0)), )
        U[j] = "$(d.iⁿ)$(v.jᵛ)$(v.iᵛ)"
        ϕ[j] = 1
        for j ∈ unique(j -> U[j], J) ϕ[j] = !isopt(R[j]) ? 1 : ϕ[j] end
    end
    # Step 3: Return solution
    return s
end



"""
    initialize([rng::AbstractRNG], instance::String; dir=joinpath(dirname(@__DIR__), "instances"))

Returns initial VRP `Solution` for the `instance`. 

Note, `dir` locates the the folder containing instance files as sub-folders, 
as follows,
    
    <dir>
    |-<instance>
        |-arcs.csv
        |-customer_nodes.csv
        |-depot_nodes.csv
        |-fuelstation_nodes.csv
        |-vehicles.csv
        
Optionally specify a random number generator `rng` as the first argument
(defaults to `Random.GLOBAL_RNG`).
"""
initialize(rng::AbstractRNG, instance::String; dir=joinpath(dirname(@__DIR__), "instances")) = regret(rng, instance; dir=dir)
initialize(instance::String; dir=joinpath(dirname(@__DIR__), "instances")) = initialize(Random.GLOBAL_RNG, instance; dir=dir)