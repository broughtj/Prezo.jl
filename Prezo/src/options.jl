abstract type VanillaOption end
abstract type EuropeanOption <: VanillaOption end
abstract type AmericanOption <: VanillaOption end

## European Options 

struct EuropeanCall <: EuropeanOption
    strike::AbstractFloat
    expiry::AbstractFloat
end

Base.broadcastable(x::EuropeanCall) = Ref(x)

function payoff(option::EuropeanCall, spot)
    return max(0.0, spot - option.strike)
end


struct EuropeanPut <: EuropeanOption
    strike::AbstractFloat
    expiry::AbstractFloat
end

Base.broadcastable(x::EuropeanPut) = Ref(x)

function payoff(option::EuropeanPut, spot)
    return max.(0.0, option.strike - spot)
end


## American Options

struct AmericanCall <: AmericanOption
    strike::AbstractFloat
    expiry::AbstractFloat
end

Base.broadcastable(x::AmericanCall) = Ref(x)

function payoff(option::AmericanCall, spot)
    return max(0.0, spot - option.strike)
end


struct AmericanPut <: AmericanOption
    strike::AbstractFloat
    expiry::AbstractFloat
end

Base.broadcastable(x::AmericanPut) = Ref(x)

function payoff(option::AmericanPut, spot)
    return max(0.0, option.strike - spot)
end