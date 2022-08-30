# Relatedness
function relatedness(c₁::CustomerNode, c₂::CustomerNode, a::Arc)
    l = a.l
    q = abs(c₁.q - c₂.q)
    ϕ = !isequal(c₁, c₂) & isequal(c₁.r, c₂.r)
    z = 1/(l - q - ϕ)
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