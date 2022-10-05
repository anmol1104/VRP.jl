# Objective function evaluation
"""
    f(s::Solution; fixed=true, operational=true, penalty=true)

Objective function evaluation for solution `s`. Include `fixed`, 
`operational`, and `penalty` cost for constriant violation if `true`.
"""
function f(s::Solution; fixed=true, operational=true, penalty=true)
    πᶠ, πᵒ, πᵖ = 0., 0., 0.
    φᶠ, φᵒ, φᵖ = fixed, operational, penalty
    for d ∈ s.D
        if !isopt(d) continue end 
        qᵈ = 0
        for v ∈ d.V
            πᶠ += isopt(v) * v.πᶠ
            tˢ = 0.
            tᵉ = 0.
            for r ∈ v.R 
                if !isopt(r) continue end
                qᵛ = r.q
                lᵛ = r.l
                tᵉ = r.tᵉ
                qᵈ += qᵛ
                πᵒ += r.l * v.πᵒ
                πᵖ += (qᵛ > v.q) * (qᵛ - v.q)                               # Vehicle capacity constraint
                πᵖ += (lᵛ > v.l) * (lᵛ - v.l)                               # Vehicle range constraint
            end
            tᵛ = tᵉ - tˢ
            πᵖ += (tᵛ > v.w) * (tᵛ - v.w)                                   # Working-hours constraint 
        end
        πᵖ += (qᵈ > d.q) * (qᵈ - d.q)                                       # Depot capacity constraint
    end
    for c ∈ s.C πᵖ += isopen(c) ? 0. : (c.tᵃ > c.tˡ) * (c.tᵃ - c.tˡ) end    # Time-window constraint
    z = φᶠ * πᶠ + φᵒ * πᵒ + φᵖ * πᵖ * 10^(ceil(log10(πᶠ + πᵒ)))
    return z
end