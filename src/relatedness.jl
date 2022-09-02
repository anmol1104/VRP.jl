# Relatedness
function relatedness(c₁::CustomerNode, c₂::CustomerNode, a::Arc)
    l = a.l
    t = (abs(c₁.tₗ - c₂.tₗ) - abs(c₁.tₑ - c₂.tₑ))
    q = abs(c₁.q - c₂.q)
    ϕ = !isequal(c₁, c₂) & isequal(c₁.r, c₂.r)
    z = 1/(l - t - q - ϕ)
    return z
end
function relatedness(r₁::Route, r₂::Route)
    if !isopt(r₁) || !isopt(r₂) return -Inf end
    if isequal(r₁, r₂) return Inf end
    l = abs(r₁.l - r₂.l)
    q = abs(r₁.q - r₂.q)
    ϕ = isequal(r₁.o, r₂.o)
    z = 1/(l - q - ϕ)
    return z
end
function relatedness(v₁::Vehicle, v₂::Vehicle)
    if !isopt(v₁) || !isopt(v₂) return -Inf end
    if isequal(v₁, v₂) return Inf end
    l₁ = 0.
    q₁ = 0.
    for r ∈ v₁.R 
        l₁ += r.l
        q₁ += r.q
    end
    l₂ = 0.
    q₂ = 0.
    for r ∈ v₂.R
        l₂ += r.l
        q₂ += r.q
    end
    l = abs(l₁ - l₂)
    q = abs(q₁ - q₂)
    ϕ = isequal(v₁.o, v₂.o)
    z = 1/(l - q - ϕ)
    return z
end