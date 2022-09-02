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
            for r ∈ v.R 
                if !isopt(r) continue end
                qᵛ  = r.q
                qᵈ += qᵛ
                z  += r.l * v.πₒ
                γ  += (qᵛ > v.q) * (qᵛ - v.q)
            end
        end
        γ += (qᵈ > d.q) * (qᵈ - d.q)
    end
    for c ∈ s.C γ += isopen(c) ? 0. : (c.tₐ > c.tₗ) * (c.tₐ - c.tₗ) end
    z += z * γ
    return z
end