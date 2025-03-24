using Plots
using Prezo

call = EuropeanCall(40.0, 1.0)

bsm_prc = price(call, BlackScholes(), 41.0, 0.08, 0.3)
println("Black-Scholes-Merton price: $bsm_prc")

bin_prc = price(call, Binomial(100), 41.0, 0.08, 0.3)
println("Binomial price: $bin_prc")

mc_prc = price(call, MonteCarlo(1, 500_000), 41.0, 0.08, 0.3)
println("Monte Carlo price: $mc_prc")