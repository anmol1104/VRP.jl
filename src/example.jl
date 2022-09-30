using VRP
using Revise
using Random

let
# Developing an optimal solution 
    # Define instance
    instance = "r101";
    # Visualize instance
    display(visualize(instance))
    # Define a random number generator
    rng = MersenneTwister(1234);
    # Define inital solution method and build the initial solution
    sₒ = initialsolution(rng, instance, :random);
    # Define ALNS parameters
    x = length(sₒ.D)+length(sₒ.C);
    n = max(100, ceil(x, digits=-(length(digits(x))-1)));
    χ = ALNSParameters(
        k̲   =   n ÷ 25                  ,
        l̲   =   2n                      ,
        l̅   =   5n                      ,
        k̅   =   10n                     ,
        Ψᵣ  =   [
                    :randomnode!    , 
                    :randomroute!   ,
                    :randomvehicle! ,
                    :relatednode!   , 
                    :relatedroute!  ,  
                    :relatedvehicle!,
                    :worstnode!     ,
                    :worstroute!    ,
                    :worstvehicle!  
                ]                       , 
        Ψᵢ  =   [
                    :best!          ,
                    :greedy!        ,
                    :regret2!       ,
                    :regret3!
                ]                       ,
        Ψₗ  =   [
                    :move!          ,
                    :intraopt!      ,
                    :interopt!      ,
                    :split!         ,
                    :swap!
                ]                       ,
        σ₁  =   15                      ,
        σ₂  =   10                      ,
        σ₃  =   3                       ,
        ω   =   0.05                    ,
        τ   =   0.5                     ,
        𝜃   =   0.99975                 ,
        C̲   =   4                       ,
        C̅   =   60                      ,
        μ̲   =   0.1                     ,
        μ̅   =   0.4                     ,
        ρ   =   0.1
    );
    # Run ALNS and fetch best solution
    S = ALNS(rng, χ, sₒ);
    s⃰ = S[end]; 
# Fetch objective function values
    println("\nObjective function value:")
    println("   Initial: $(f(sₒ; penalty=false))")
    println("   Optimal: $(f(s⃰ ; penalty=false))")
# Fetch fixed costs
    println("Fixed costs:")
    println("   Initial: $(f(sₒ; operational=false, penalty=false))")
    println("   Optimal: $(f(s⃰ ; operational=false, penalty=false))")
# Fetch operational costs
    println("Operational costs:")
    println("   Initial: $(f(sₒ; fixed=false, penalty=false))")
    println("   Optimal: $(f(s⃰ ; fixed=false, penalty=false))")
# Check if the solutions are feasible
    println("Solution feasibility:")
    println("   Initial: $(isfeasible(sₒ))")
    println("   Optimal: $(isfeasible(s⃰))")
# Optimal solution characteristics
    println("Optimal solution characteristics:")
    println("   Number of depots: $(sum([VRP.isopt(d) for d ∈ s⃰.D]))")
    println("   Number of vehicles: $(sum([VRP.isopt(v) for d ∈ s⃰.D for v ∈ d.V]))")
    println("   Number of routes: $(sum([VRP.isopt(r) for d ∈ s⃰.D for v ∈ d.V for r ∈ v.R]))")
# Visualizations
    # Visualize initial solution
    display(visualize(sₒ)) 
    # Visualize best solution
    display(visualize(s⃰))
    # Animate ALNS solution search process from inital to best solution
    display(animate(S))
    # Show convergence plot
    display(plotconv(S))
    return
end
