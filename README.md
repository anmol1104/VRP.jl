[![Build Status](https://github.com/anmol1104/VRP.jl/actions/workflows/CI.yml/badge.svg?branch=master)](https://github.com/anmol1104/VRP.jl/actions/workflows/CI.yml?query=branch%3Amaster)
[![Coverage](https://codecov.io/gh/anmol1104/VRP.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/anmol1104/VRP.jl)

# Vehicle Routing Problem (VRP)

single-depot vehicle routing problem with heterogenous fleet of single-route delivery vehicles

Given, a graph `G = (d, C, A)` with 
depot node `d` with fleet `d.V`;
set of customer nodes `C` with demand `c.q` for every customer `c ∈ C`; and
set of arcs `A = {(i,j); i,j ∈ N={{d}∪C}}` with length `l` for every arc `(i,j) ∈ A`;
the objective is to develop least cost routes from depot nodes using select vehicles such that every customer node is visited exactly once while also accounting for vehicle capacities.  

This package uses Adaptive Large Neighborhood Search (ALNS) algorithm to find an optimal solution for the Locatio Routing Problem given ALNS optimization 
parameters,
- `k̲`     :   Number of ALNS iterations triggering operator probability update (segment size)
- `l̲`     :   Number of ALNS iterations triggering local search
- `l̅`     :   Number of local search iterations
- `k̅`     :   Number of ALNS iterations
- `Ψᵣ`    :   Vector of removal operators
- `Ψᵢ`    :   Vector of insertion operators
- `Ψₗ`    :   Vector of local search operators
- `σ₁`    :   Score for a new best solution
- `σ₂`    :   Score for a new better solution
- `σ₃`    :   Score for a new worse but accepted solution
- `ω`     :   Start tempertature control threshold 
- `τ`     :   Start tempertature control probability
- `𝜃`     :   Cooling rate
- `C̲`     :   Minimum customer nodes removal
- `C̅`     :   Maximum customer nodes removal
- `μ̲`     :   Minimum removal fraction
- `μ̅`     :   Maximum removal fraction
- `ρ`     :   Reaction factor

and an initial solution developed using one of the following methods,
- Random Initialization                 : `:random`

The ALNS metaheuristic iteratively removes a set of nodes using,
- Random Node Removal       : `:randomnode!`
- Random Route Removal      : `:randomroute!`
- Related Node Removal      : `:relatednode!`
- Related Route removal     : `:relatedroute!`
- Worst Node Removal        : `:worstnode!`
- Worst Route Removal       : `:worstroute!`

and consequently inserts removed nodes using,
- Best Insertion    : `best!`
- Greedy Insertion  : `greedy!`
- Regret Insertion  : `regret2!`, `regret3!`

In every few iterations, the ALNS metaheuristic performs local search with,
- Move      : `:move!`
- Inter-Opt : `:interopt!`
- Intra-Opt : `:intraopt!`
- Split     : `:split!`
- Swap      : `:swap!`

See example.jl for usage

Additional initialization, removal, insertion, and local search methods can be defined.