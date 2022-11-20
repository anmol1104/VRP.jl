# Insert node nᵒ between tail node nᵗ and head node nʰ in route rᵒ in solution s.
function insertnode!(nᵒ::Node, nᵗ::Node, nʰ::Node, rᵒ::Route, s::Solution)
    dᵒ =  s.D[rᵒ.iᵈ]
    vᵒ = dᵒ.V[rᵒ.iᵛ]
    tⁱ = rᵒ.tⁱ
    θⁱ = rᵒ.θⁱ
    τ  = Inf
    # update tail node and head node indices
    isdepot(nᵗ) ? rᵒ.iˢ = nᵒ.iⁿ : nᵗ.iʰ = nᵒ.iⁿ
    isdepot(nʰ) ? rᵒ.iᵉ = nᵒ.iⁿ : nʰ.iᵗ = nᵒ.iⁿ
    isdepot(nᵒ) ? (rᵒ.iˢ, rᵒ.iᵉ) = (nʰ.iⁿ, nᵗ.iⁿ) : (nᵒ.iʰ, nᵒ.iᵗ) = (nʰ.iⁿ, nᵗ.iⁿ)
    # update route
    if iscustomer(nᵒ)
        rᵒ.x = (rᵒ.n * rᵒ.x + nᵒ.x)/(rᵒ.n + 1)
        rᵒ.y = (rᵒ.n * rᵒ.y + nᵒ.y)/(rᵒ.n + 1)
        nᵒ.r  = rᵒ
        rᵒ.n += 1
        rᵒ.q += nᵒ.q
    end
    rᵒ.l += s.A[(nᵗ.iⁿ, nᵒ.iⁿ)].l + s.A[(nᵒ.iⁿ, nʰ.iⁿ)].l - s.A[(nᵗ.iⁿ, nʰ.iⁿ)].l
    # update arrival and departure time
    if iszero(s.φᵀ) return s end
    for r ∈ vᵒ.R
        if r.tⁱ < rᵒ.tⁱ continue end
        if isopt(r)
            r.θⁱ = θⁱ
            r.θˢ = θⁱ + max(0., (r.l/vᵒ.l - r.θⁱ))
            r.tⁱ = tⁱ
            r.tˢ = r.tⁱ + vᵒ.τᶠ * (r.θˢ - r.θⁱ) + vᵒ.τᵈ * r.q
            cˢ = s.C[r.iˢ]
            cᵉ = s.C[r.iᵉ]
            tᵈ = r.tˢ
            cᵒ = cˢ
            while true
                cᵒ.tᵃ = tᵈ + s.A[(cᵒ.iᵗ, cᵒ.iⁿ)].l/vᵒ.s
                cᵒ.tᵈ = cᵒ.tᵃ + max(0., cᵒ.tᵉ - cᵒ.tᵃ) + vᵒ.τᶜ
                if isequal(cᵒ, cᵉ) break end
                tᵈ = cᵒ.tᵈ
                cᵒ = s.C[cᵒ.iʰ]
            end
            r.θᵉ = r.θˢ - r.l/vᵒ.l
            r.tᵉ = cᵉ.tᵈ + s.A[(cᵉ.iⁿ, dᵒ.iⁿ)].l/vᵒ.s
        else
            r.θⁱ = θⁱ
            r.θˢ = θⁱ
            r.θᵉ = θⁱ
            r.tⁱ = tⁱ
            r.tˢ = tⁱ
            r.tᵉ = tⁱ
        end
        tⁱ = r.tᵉ
        θⁱ = r.θᵉ
    end
    (vᵒ.tˢ, vᵒ.tᵉ) = isempty(vᵒ.R) ? (0., 0.) : (vᵒ.R[1].tˢ, vᵒ.R[length(vᵒ.R)].tᵉ)
    τ = min(τ, dᵒ.tᵉ - vᵒ.tᵉ)
    for r ∈ reverse(vᵒ.R)
        if !isopt(r) continue end
        cˢ = s.C[r.iˢ]
        cᵉ = s.C[r.iᵉ]
        cᵒ = cˢ
        while true
            τ  = min(τ, cᵒ.tˡ - cᵒ.tᵃ)
            if isequal(cᵒ, cᵉ) break end
            cᵒ = s.C[cᵒ.iʰ]
        end
        r.τ = τ
    end
    return s
end

# Remove node nᵒ from its position between tail node nᵗ and head node nʰ in route rᵒ in solution s.
function removenode!(nᵒ::Node, nᵗ::Node, nʰ::Node, rᵒ::Route, s::Solution)
    dᵒ =  s.D[rᵒ.iᵈ]
    vᵒ = dᵒ.V[rᵒ.iᵛ]
    tⁱ = rᵒ.tⁱ
    θⁱ = rᵒ.θⁱ
    τ  = Inf
    # update tail node and head node indices
    isdepot(nᵗ) ? rᵒ.iˢ = nʰ.iⁿ : nᵗ.iʰ = nʰ.iⁿ
    isdepot(nʰ) ? rᵒ.iᵉ = nᵗ.iⁿ : nʰ.iᵗ = nᵗ.iⁿ
    isdepot(nᵒ) ? false : (nᵒ.iʰ, nᵒ.iᵗ) = (0, 0)
    # update route
    if iscustomer(nᵒ)
        rᵒ.x = isone(rᵒ.n) ? 0. : (rᵒ.n * rᵒ.x - nᵒ.x)/(rᵒ.n - 1)
        rᵒ.y = isone(rᵒ.n) ? 0. : (rᵒ.n * rᵒ.y - nᵒ.y)/(rᵒ.n - 1)
        nᵒ.r  = NullRoute
        rᵒ.n -= 1
        rᵒ.q -= nᵒ.q
    end
    rᵒ.l -= s.A[(nᵗ.iⁿ, nᵒ.iⁿ)].l + s.A[(nᵒ.iⁿ, nʰ.iⁿ)].l - s.A[(nᵗ.iⁿ, nʰ.iⁿ)].l
    # update arrival and departure time
    if iszero(s.φᵀ) return s end
    if iscustomer(nᵒ) nᵒ.tᵃ, nᵒ.tᵈ = Inf, Inf end
    for r ∈ vᵒ.R
        if r.tⁱ < rᵒ.tⁱ continue end
        if isopt(r)
            r.θⁱ = θⁱ
            r.θˢ = θⁱ + max(0., (r.l/vᵒ.l - r.θⁱ))
            r.tⁱ = tⁱ
            r.tˢ = r.tⁱ + vᵒ.τᶠ * (r.θˢ - r.θⁱ) + vᵒ.τᵈ * r.q
            cˢ = s.C[r.iˢ]
            cᵉ = s.C[r.iᵉ]
            tᵈ = r.tˢ
            cᵒ = cˢ
            while true
                cᵒ.tᵃ = tᵈ + s.A[(cᵒ.iᵗ, cᵒ.iⁿ)].l/vᵒ.s
                cᵒ.tᵈ = cᵒ.tᵃ + max(0., cᵒ.tᵉ - cᵒ.tᵃ) + vᵒ.τᶜ
                if isequal(cᵒ, cᵉ) break end
                tᵈ = cᵒ.tᵈ
                cᵒ = s.C[cᵒ.iʰ]
            end
            r.θᵉ = r.θˢ - r.l/vᵒ.l
            r.tᵉ = cᵉ.tᵈ + s.A[(cᵉ.iⁿ, dᵒ.iⁿ)].l/vᵒ.s
        else
            r.θⁱ = θⁱ
            r.θˢ = θⁱ
            r.θᵉ = θⁱ
            r.tⁱ = tⁱ
            r.tˢ = tⁱ
            r.tᵉ = tⁱ
        end
        tⁱ = r.tᵉ
        θⁱ = r.θᵉ
    end
    (vᵒ.tˢ, vᵒ.tᵉ) = isempty(vᵒ.R) ? (0., 0.) : (vᵒ.R[1].tˢ, vᵒ.R[length(vᵒ.R)].tᵉ)
    τ = min(τ, dᵒ.tᵉ - vᵒ.tᵉ)
    for r ∈ reverse(vᵒ.R)
        if !isopt(r) continue end
        cˢ = s.C[r.iˢ]
        cᵉ = s.C[r.iᵉ]
        cᵒ = cˢ
        while true
            τ  = min(τ, cᵒ.tˡ - cᵒ.tᵃ)
            if isequal(cᵒ, cᵉ) break end
            cᵒ = s.C[cᵒ.iʰ]
        end
        r.τ = τ
    end
    return s
end

# Return true if route of type rᵒ must be added into the solution (adds conservatively)
function addroute(rᵒ::Route, s::Solution)
    dᵒ =  s.D[rᵒ.iᵈ]
    vᵒ = dᵒ.V[rᵒ.iᵛ]
    # condtions when route mustn't be added
    if isequal(length(vᵒ.R), vᵒ.r̅) return false end
    if any(!isopt, vᵒ.R) return false end
    if vᵒ.tᵉ > dᵒ.tᵉ return false end
    if (vᵒ.tᵉ - vᵒ.tˢ) > vᵒ.τʷ return false end
    qᵈ = 0
    for v ∈ dᵒ.V for r ∈ v.R qᵈ += r.q end end
    if qᵈ ≥ dᵒ.q return false end
    # condition when route could be added
    if isempty(vᵒ.R) return true end
    for v ∈ dᵒ.V for r ∈ v.R if r.q > v.q return true end end end
    for d ∈ s.D
        qᵈ = 0
        if isequal(dᵒ, d) continue end
        for v ∈ d.V for r ∈ v.R qᵈ += r.q end end
        if qᵈ > d.q return true end
    end
    return false
end

# Return true if route rᵒ can be deleted (deletes liberally)
function deleteroute(rᵒ::Route, s::Solution)
    # condtions when route mustn't be deleted
    if isopt(rᵒ) return false end
    # condition when route could be deleted
    return true
end

# Return true if vehicle of type vᵒ must be added into the solution (adds conservatively)
function addvehicle(vᵒ::Vehicle, s::Solution)
    dᵒ = s.D[vᵒ.iᵈ]
    # condtions when vehicle mustn't be added
    if any(!isopt, filter(v -> isidentical(vᵒ, v), dᵒ.V)) return false end
    qᵈ = 0
    for v ∈ dᵒ.V for r ∈ v.R qᵈ += r.q end end
    if qᵈ ≥ dᵒ.q return false end
    # condition when vehicle could be added
    if qᵈ < dᵒ.q return true end
    for v ∈ dᵒ.V
        if v.tᵉ > dᵒ.tᵉ return true end
        if (v.tᵉ - v.tˢ) > v.τʷ return true end
        for r ∈ v.R
            if !isopt(r) continue end
            cˢ = s.C[r.iˢ]
            cᵉ = s.C[r.iᵉ]
            cᵒ = cˢ
            while true
                if cᵒ.tᵃ > cᵒ.tˡ return true end
                if isequal(cᵒ, cᵉ) break end
                cᵒ = s.C[cᵒ.iʰ]
            end
        end
    end
    return false
end

# Return false if vehicle vᵒ can be deleted (deletes liberally)
function deletevehicle(vᵒ::Vehicle, s::Solution)
    dᵒ = s.D[vᵒ.iᵈ]
    # condtions when vehicle mustn't be deleted
    if isopt(vᵒ) return false end
    nʲ = 0
    for v ∈ dᵒ.V if isidentical(vᵒ, v) nʲ += 1 end end
    if isone(nʲ) return false end
    # condition when vehicle could be deleted
    return true
end

# Pre intialization procedures
function preinitialize!(s::Solution)
    for d ∈ s.D
        for v ∈ d.V
            rᵒ = Route(v, d)
            if addroute(rᵒ, s) push!(v.R, rᵒ) end
        end
    end
    return s
end

# Post intialization procedures
function postinitialize!(s::Solution)
    return s
end

# Pre insertion procedures
function preinsertion!(s::Solution)
    for d ∈ s.D
        for v ∈ d.V
            rᵒ = Route(v, d)
            if addroute(rᵒ, s) push!(v.R, rᵒ) end
            vᵒ = Vehicle(v, d)
            if addvehicle(vᵒ, s) push!(d.V, vᵒ) end
        end
    end
    return s
end

# Post insertion procedures
function postinsertion!(s::Solution)
    for d ∈ s.D
        k = 1
        while true
            v = d.V[k]
            if deletevehicle(v, s) 
                deleteat!(d.V, k)
            else
                v.iᵛ = k
                for r ∈ v.R r.iᵛ = k end
                k += 1
            end
            if k > length(d.V) break end
        end
        for v ∈ d.V
            if isempty(v.R) continue end
            k = 1
            while true
                r = v.R[k]
                if deleteroute(r, s) 
                    deleteat!(v.R, k)
                else
                    r.iʳ = k
                    k += 1
                end
                if k > length(v.R) break end
            end
        end
    end
    return s
end

# Pre removal procedures
function preremoval!(s::Solution)
    return s
end

# Post removal procedures
function postremoval!(s::Solution)
    for d ∈ s.D
        k = 1
        while true
            v = d.V[k]
            if deletevehicle(v, s) 
                deleteat!(d.V, k)
            else
                v.iᵛ = k
                for r ∈ v.R r.iᵛ = k end
                k += 1
            end
            if k > length(d.V) break end
        end
        for v ∈ d.V
            if isempty(v.R) continue end
            k = 1
            while true
                r = v.R[k]
                if deleteroute(r, s) 
                    deleteat!(v.R, k)
                else
                    r.iʳ = k
                    k += 1
                end
                if k > length(v.R) break end
            end
        end
    end
    return s
end
