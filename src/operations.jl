# Insert node nₒ between tail node nₜ and head node nₕ in route rₒ in solution s.
function insertnode!(nₒ::Node, nₜ::Node, nₕ::Node, rₒ::Route, s::Solution)
    vₒ = s.V[rₒ.o]
    tₑ = rₒ.tₛ - vₒ.τᵈ * rₒ.q
    # update tail node and head node indices
    isdepot(nₜ) ? rₒ.iₛ = nₒ.i : nₜ.iₕ = nₒ.i
    isdepot(nₕ) ? rₒ.iₑ = nₒ.i : nₕ.iₜ = nₒ.i
    isdepot(nₒ) ? (rₒ.iₛ, rₒ.iₑ) = (nₕ.i, nₜ.i) : (nₒ.iₕ, nₒ.iₜ) = (nₕ.i, nₜ.i)
    # update route
    if iscustomer(nₒ)
        nₒ.r  = rₒ
        rₒ.n += 1
        rₒ.q += nₒ.q
    end
    rₒ.l += s.A[(nₜ.i, nₒ.i)].l + s.A[(nₒ.i, nₕ.i)].l - s.A[(nₜ.i, nₕ.i)].l
    # update arrival and departure time
    for r ∈ vₒ.R
        if !isopt(r) continue end
        if r.tₛ < rₒ.tₛ continue end
        r.tₛ = tₑ + vₒ.τᵈ * r.q
        dₒ = s.D[vₒ.o]
        cₛ = s.C[r.iₛ]
        cₑ = s.C[r.iₑ]
        tᵈ = r.tₛ
        cₒ = cₛ
        while true
            cₒ.tₐ = tᵈ + s.A[(cₒ.iₜ, cₒ.i)].l/vₒ.s
            cₒ.tᵈ = cₒ.tₐ + max(0., cₒ.tₑ - cₒ.tₐ) + vₒ.τᶜ * cₒ.q
            if isequal(cₒ, cₑ) break end
            tᵈ = cₒ.tᵈ
            cₒ = s.C[cₒ.iₕ]
        end
        r.tₑ = cₑ.tᵈ + s.A[(cₑ.i, dₒ.i)].l/vₒ.s
        tₑ = r.tₑ
    end
    return s
end

# Remove node nₒ from its position between tail node nₜ and head node nₕ in route rₒ in solution s.
function removenode!(nₒ::Node, nₜ::Node, nₕ::Node, rₒ::Route, s::Solution)
    vₒ = s.V[rₒ.o]
    tₑ = rₒ.tₛ - vₒ.τᵈ * rₒ.q
    # update tail node and head node indices
    isdepot(nₜ) ? rₒ.iₛ = nₕ.i : nₜ.iₕ = nₕ.i
    isdepot(nₕ) ? rₒ.iₑ = nₜ.i : nₕ.iₜ = nₜ.i
    isdepot(nₒ) ? false : (nₒ.iₕ, nₒ.iₜ) = (0, 0)
    # update route
    if iscustomer(nₒ)
        nₒ.r  = NullRoute
        rₒ.n -= 1
        rₒ.q -= nₒ.q
    end
    rₒ.l -= s.A[(nₜ.i, nₒ.i)].l + s.A[(nₒ.i, nₕ.i)].l - s.A[(nₜ.i, nₕ.i)].l
    # update arrival and departure time
    for r ∈ vₒ.R
        if !isopt(r) continue end
        if r.tₛ < rₒ.tₛ continue end
        r.tₛ = tₑ + vₒ.τᵈ * r.q
        dₒ = s.D[vₒ.o]
        cₛ = s.C[r.iₛ]
        cₑ = s.C[r.iₑ]
        tᵈ = r.tₛ
        cₒ = cₛ
        while true
            cₒ.tₐ = tᵈ + s.A[(cₒ.iₜ, cₒ.i)].l/vₒ.s
            cₒ.tᵈ = cₒ.tₐ + max(0., cₒ.tₑ - cₒ.tₐ) + vₒ.τᶜ * cₒ.q
            if isequal(cₒ, cₑ) break end
            tᵈ = cₒ.tᵈ
            cₒ = s.C[cₒ.iₕ]
        end
        r.tₑ = cₑ.tᵈ + s.A[(cₑ.i, dₒ.i)].l/vₒ.s
        tₑ = r.tₑ
    end
    if iscustomer(nₒ) nₒ.tₐ, nₒ.tᵈ = Inf, Inf end
    return s
end

# Return true if vehicle v needs another route (adds conservatively)
function addroute(v::Vehicle, s::Solution)
    D = s.D
    d = D[v.o]
    # condtions when route mustn't be added
    if any(!isopt, v.R) return false end
    qᵈ = 0
    for v ∈ d.V for r ∈ v.R qᵈ += r.q end end
    if qᵈ ≥ d.q return false end
    # condition when route could be added
    if isempty(v.R) return true end
    for v ∈ d.V for r ∈ v.R if r.q > v.q return true end end end
    for d ∈ D 
        qᵈ = 0
        if isequal(v.o, d.i) continue end
        for v ∈ d.V for r ∈ v.R qᵈ += r.q end end
        if qᵈ > d.q return true end
    end
    return false
end

# Return true if route r can be deleted (deletes liberally)
function deleteroute(r::Route)
    if isopt(r) return false end
    return true
end

# Return true if depot d needs another vehicle
function addvehicle(d::DepotNode, s::Solution)
    C = s.C
    V = s.V
    # condtions when vehicle mustn't be added
    if any(!isopt, d.V) return false end
    # condition when vehicle could be added
    for c ∈ C 
        if isopen(c) continue end
        r = c.r
        v = V[r.o]
        if !isequal(v.o, d.i) continue end
        if c.tₐ > c.tₗ return true end 
    end
    return false
end

# Return false if vehicle v can be deleted
function deletevehicle(v::Vehicle)
    if isopt(v) return false end
    return true
end