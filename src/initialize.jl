# Initial solution
"""
    initialsolution([rng], instance, method)

Returns initial VRP solution for the given `instance` using the given `method`.

Available methods include,
- Random initialization                 : `:random`

Optionally specify a random number generator `rng` as the first argument
(defaults to `Random.GLOBAL_RNG`).
"""
initialsolution(rng::AbstractRNG, instance, method::Symbol)::Solution = getfield(VRP, method)(rng, instance)
initialsolution(instance, method::Symbol) = initialsolution(Random.GLOBAL_RNG, instance, method)

# Random Initialization
# Create initial solution with randomly selcted node-route combination until all customer nodes have been added to the solution
function random(rng::AbstractRNG, instance)
    G = build(instance)
    s = Solution(G...)
    d = s.d
    C = s.C
    V = d.V
    R = [v.r for v ∈ V]
    # Step 1: Initialize
    I = eachindex(C)
    J = eachindex(R)
    w = ones(Int64, I)                      # w[i]: selection weight for customer node C[i]
    # Step 2: Iteratively append randomly selected customer node in randomly selected route
    for _ ∈ I
        i = sample(rng, I, OffsetWeights(w))
        j = sample(rng, J)
        c = C[i]
        r = R[j]
        nₜ = d
        nₕ = isopt(r) ? C[r.iₛ] : d
        insertnode!(c, nₜ, nₕ, r, s)
        w[i] = 0
    end
    # Step 3: Return initial solution
    return s
end
