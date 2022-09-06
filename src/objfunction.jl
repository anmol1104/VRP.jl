# Objective function evaluation
"""
    f(s::Solution)

Objective function evaluation for solution `s`.
"""
function f(s::Solution)
    πᵒ, πᵖ = 0., 0.
    for d ∈ s.D
        qᵈ = 0
        for v ∈ d.V 
            for r ∈ v.R 
                if !isopt(r) continue end
                qᵛ  = r.q
                qᵈ += qᵛ
                πᵒ += r.l * v.πᵒ
                πᵖ += (qᵛ > v.q) * (qᵛ - v.q)
            end
        end
        πᵖ += (qᵈ > d.q) * (qᵈ - d.q)
    end
    for c ∈ s.C πᵖ += isopen(c) ? 0. : (c.tᵃ > c.tˡ) * (c.tᵃ - c.tˡ) end
    z = πᵒ + πᵒ * πᵖ
    return z
end