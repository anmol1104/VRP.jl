using VRP
using Revise
using Test
using Random

let
    # ALNS parameters
    χ = ALNSparameters(
        j   =   50                      ,
        k   =   5                       ,
        n   =   5                       ,
        m   =   500                     ,
        Ψᵣ  =   [
                    :randomcustomer!    ,
                    :randomroute!       ,
                    :relatedcustomer!   ,
                    :relatedroute!      ,
                    :worstcustomer!     ,    
                    :worstroute!
                ]                       ,
        Ψᵢ  =   [
                    :best!              ,
                    :precise!           ,
                    :perturb!           ,
                    :regret2!           ,
                    :regret3!
                ]                       ,
        Ψₗ  =   [
                    :intramove!         ,
                    :intraswap!         ,
                    :intraopt!          ,
                    :intermove!         ,
                    :interswap!         ,
                    :interopt!
                ]                       ,
        σ₁  =   15                      ,
        σ₂  =   10                      ,
        σ₃  =   3                       ,
        μ̲   =   0.05                    ,
        c̲   =   2                       ,
        μ̅   =   0.2                     ,
        c̅   =   30                      ,
        ω̅   =   0.05                    ,
        τ̅   =   0.5                     ,
        ω̲   =   0.01                    ,
        τ̲   =   0.01                    ,
        θ   =   0.9965                  ,
        ρ   =   0.1
    );
    return
end
        
