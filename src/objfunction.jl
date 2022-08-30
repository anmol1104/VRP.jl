# Objective function evaluation
"""
    f(s::Solution)

Objective function evaluation for solution `s`.
"""
function f(s::Solution)
    z, γ = 0., 0.
    for d ∈ s.D
        qᵈ = 0
        for v ∈ d.V 
            if !isopt(v) continue end
            r  = v.r
            qᵛ = r.q
            qᵈ += qᵛ
            z  += r.l * v.c
            γ  += (qᵛ > v.q) * (qᵛ - v.q)
        end
        γ += (qᵈ > d.q) * (qᵈ - d.q)
    end
    z += z * γ
    return z
end