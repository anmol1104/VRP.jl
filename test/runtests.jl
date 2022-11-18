using VRP
using Revise
using Test
using Random

let
    # Vehicle Routing Problem
    @testset "VRP" begin
        χ   = ALNSParameters(
            n   =   4                       ,
            k   =   250                     ,
            m   =   200                     ,
            j   =   125                     ,
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
                        :intraopt!          ,
                        :interopt!          ,
                        :movecustomer!      ,
                        :swapcustomers!
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
        instances = ["m-n101-k10", "tai150a", "cmt10"]
        methods = [:cluster, :cw, :random]
        for k ∈ 1:3
            instance = instances[k]
            method = methods[k]
            println("\nSolving $instance")
            G  = build(instance)
            sₒ = initialsolution(G, method)     
            S  = ALNS(χ, sₒ)
            s⃰  = S[end]
            @test isfeasible(s⃰)
            @test f(s⃰) ≤ f(sₒ)
        end
    end

    # Vehicle Routing Problem with time-windows
    @testset "VRPTW" begin
        χ   = ALNSParameters(
            n   =   4                       ,
            k   =   250                     ,
            m   =   200                     ,
            j   =   125                     ,
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
                        :intraopt!          ,
                        :interopt!          ,
                        :movecustomer!      ,
                        :swapcustomers!
                    ]                       ,
            σ₁  =   15                      ,
            σ₂  =   10                      ,
            σ₃  =   3                       ,
            ω   =   0.05                    ,
            τ   =   0.5                     ,
            𝜃   =   0.9975                  ,
            C̲   =   4                       ,
            C̅   =   60                      ,
            μ̲   =   0.1                     ,
            μ̅   =   0.4                     ,
            ρ   =   0.1
        )
        instances = ["r101", "c101", "rc101"]
        methods = [:cluster, :cw, :random]
        for k ∈ 1:3
            instance = instances[k]
            method = methods[k]
            println("\nSolving $instance")
            G  = build(instance)
            sₒ = initialsolution(G, method)         
            S  = ALNS(χ, sₒ)
            s⃰  = S[end]
            @test isfeasible(s⃰)
            @test f(s⃰) ≤ f(sₒ)
        end
    end
    return
end
