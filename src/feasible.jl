"""
    isfeasible(s::Solution)

Is the solution feasible?
Returns true if node service constraint, node 
flow constraint, sub-tour elimination, and 
capacity constraints are not violated.
"""
function isfeasible(s::Solution)
    d = s.d
    C = s.C
    # Customer node service and flow constraints, and sub-tour elimination constraint
    x = zeros(Int64, eachindex(C))
    for v ∈ d.V
        r = v.r
        if !isopt(r) continue end
        cₛ = C[r.iₛ]
        cₑ = C[r.iₑ]
        c  = cₛ
        while true
            x[c.i] += 1
            if isequal(c, cₑ) break end
            c = C[c.iₕ]
        end
    end
    if any(!isone, x) return false end
    # Capacity constraints
    for v ∈ d.V
        r = v.r 
        if !isopt(r) continue end
        qᵛ = r.q
        if qᵛ > v.q return false end
    end
    return true
end