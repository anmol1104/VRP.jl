# Objective function evaluation
"""
    f(s::Solution)

Objective function evaluation for solution `s`.
"""
function f(s::Solution)
    d = s.d
    z, γ = 0., 0.
    for v ∈ d.V 
        if !isopt(v) continue end
        r  = v.r
        qᵛ = r.q
        z += r.l * v.c
        γ += (qᵛ > v.q) * (qᵛ - v.q)
    end
    z += z * γ
    return z
end