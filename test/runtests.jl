using VRP
using Revise
using Test
using Random

let
    # Vehicle Routing Problem
    @testset "VRP" begin
        χ   = ALNSParameters(
            k̲   =   4                       ,
            l̲   =   200                     ,
            l̅   =   500                     ,
            k̅   =   1000                    ,
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
                    ]                        , 
            Ψᵢ  =   [
                        :bestprecise!   ,
                        :bestperturb!   ,
                        :greedyprecise! ,
                        :greedyperturb! ,
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
            σ₁  =   33                      ,
            σ₂  =   9                       ,
            σ₃  =   13                      ,
            ω   =   0.05                    ,
            τ   =   0.5                     ,
            𝜃   =   0.99975                 ,
            C̲   =   30                      ,
            C̅   =   60                      ,
            μ̲   =   0.1                     ,
            μ̅   =   0.4                     ,
            ρ   =   0.1
        )
        instances = ["m-n101-k10", "tai150a", "cmt10", "x-n251-k28", "x-n303-k21"]
        for instance ∈ instances
            println("\nSolving $instance")
            sₒ = initialsolution(instance, :random)     
            S  = ALNS(χ, sₒ)
            s⃰  = S[end]
            @test isfeasible(s⃰)
            @test f(s⃰) ≤ f(sₒ)
        end
    end

    # Vehicle Routing Problem with time-windows
    @testset "VRPTW" begin
        χ   = ALNSParameters(
            k̲   =   4                       ,
            l̲   =   200                     ,
            l̅   =   500                     ,
            k̅   =   1000                    ,
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
                    ]                        , 
            Ψᵢ  =   [
                        :bestprecise!   ,
                        :bestperturb!   ,
                        :greedyprecise! ,
                        :greedyperturb! ,
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
            σ₁  =   33                      ,
            σ₂  =   9                       ,
            σ₃  =   13                      ,
            ω   =   0.05                    ,
            τ   =   0.5                     ,
            𝜃   =   0.99975                 ,
            C̲   =   30                      ,
            C̅   =   60                      ,
            μ̲   =   0.1                     ,
            μ̅   =   0.4                     ,
            ρ   =   0.1
        )
        instances = ["r101", "r201", "c101", "c201", "rc101", "rc201"]
        for instance ∈ instances
            println("\nSolving $instance")
            sₒ = initialsolution(instance, :random)     
            S  = ALNS(χ, sₒ)
            s⃰  = S[end]
            @test isfeasible(s⃰)
            @test f(s⃰) ≤ f(sₒ)
        end
    end
    return
end
