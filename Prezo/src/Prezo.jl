module Prezo

# struct MarketData
#     rate::Float64
#     vol::Float64
#     div::Float64
# end

include("data.jl")
include("options.jl")
include("engines.jl")

export MarketData
export VanillaOption, EuropeanOption, EuropeanCall, EuropeanPut, AmericanOption, AmericanCall, AmericanPut, payoff
export BlackScholes, Binomial, MonteCarlo, asset_paths, plot_paths, price

end # module Prezo
