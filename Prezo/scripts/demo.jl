using Prezo
using Random
using Printf

Random.seed!(42)

# -------------------------------------------------------------------
# Market parameters
# -------------------------------------------------------------------
# spot=100, r=5%, vol=20%, no dividends
data    = MarketData(100.0, 0.05, 0.20, 0.0)
data_q  = MarketData(100.0, 0.05, 0.20, 0.03)  # 3% dividend yield

K = 100.0
T = 1.0

# -------------------------------------------------------------------
# 1. European options: Black-Scholes vs Binomial vs Monte Carlo
# -------------------------------------------------------------------
println("=" ^ 64)
println("European options  (K=$K, T=$T, spot=100, r=5%, vol=20%, q=0)")
println("=" ^ 64)

call = EuropeanCall(K, T)
put  = EuropeanPut(K, T)

bs_call  = price(call, BlackScholes(), data)
bs_put   = price(put,  BlackScholes(), data)
bin_call = price(call, Binomial(500), data)
bin_put  = price(put,  Binomial(500), data)
mc_call  = price(call, MonteCarlo(50, 100_000), data)
mc_put   = price(put,  MonteCarlo(50, 100_000), data)

@printf "%-22s  %8s  %8s\n" "Engine" "Call" "Put"
@printf "%-22s  %8.4f  %8.4f\n" "Black-Scholes"     bs_call  bs_put
@printf "%-22s  %8.4f  %8.4f\n" "Binomial (500)"    bin_call bin_put
@printf "%-22s  %8.4f  %8.4f\n" "MonteCarlo (100k)" mc_call  mc_put

# Variance-reduced Monte Carlo
mc_anti  = price(call, MonteCarloAntithetic(50, 50_000), data)   # 100k effective
mc_strat = price(call, MonteCarloStratified(50, 100_000), data)
@printf "%-22s  %8.4f\n" "MC antithetic (call)" mc_anti
@printf "%-22s  %8.4f\n" "MC stratified (call)" mc_strat

# Put-call parity sanity check: C - P == S - K*exp(-rT)
parity_lhs = bs_call - bs_put
parity_rhs = data.spot - K * exp(-data.rate * T)
@printf "\nPut-call parity:  C - P = %.4f   S - K e^{-rT} = %.4f\n" parity_lhs parity_rhs

# -------------------------------------------------------------------
# 2. American put: Binomial vs Longstaff-Schwartz
# -------------------------------------------------------------------
println("\n" * "=" ^ 64)
println("American put  (K=$K, T=$T, spot=100, r=5%, vol=20%)")
println("=" ^ 64)

am_put = AmericanPut(K, T)

bin_am   = price(am_put, Binomial(500), data)
lsm_std  = price(am_put, LongstaffSchwartz(50, 20_000), data)
lsm_anti = price(am_put, LongstaffSchwartz(50, 10_000, 3; antithetic=true), data)

@printf "%-30s  %8.4f\n" "Binomial (500 steps)"        bin_am
@printf "%-30s  %8.4f\n" "LSM (50 steps, 20k paths)"   lsm_std
@printf "%-30s  %8.4f\n" "LSM antithetic (10k pairs)"  lsm_anti
@printf "%-30s  %8.4f  (early-exercise premium)\n" "American - European" (bin_am - bs_put)

# -------------------------------------------------------------------
# 3. Compare LSM basis functions
# -------------------------------------------------------------------
println("\n" * "=" ^ 64)
println("LSM with different basis functions  (American put)")
println("=" ^ 64)

bases = [
    ("Laguerre",  LaguerreLSM(3, 50, 10_000)),
    ("Chebyshev", ChebyshevLSM(3, 50, 10_000; domain=(50.0, 150.0))),
    ("Power",     PowerLSM(3, 50, 10_000)),
    ("Hermite",   HermiteLSM(3, 50, 10_000; mean=100.0, std=20.0)),
]

for (name, eng) in bases
    Random.seed!(42)  # same paths for fair comparison
    p = price(am_put, eng, data)
    @printf "  %-12s  %8.4f\n" name p
end

# -------------------------------------------------------------------
# 4. American call - dividends matter
# -------------------------------------------------------------------
println("\n" * "=" ^ 64)
println("American call: zero-div should match European; with div, premium")
println("=" ^ 64)

am_call = AmericanCall(K, T)
eu_call = EuropeanCall(K, T)

bin_amc_0  = price(am_call, Binomial(500), data)
bs_euc_0   = price(eu_call, BlackScholes(), data)
bin_amc_q  = price(am_call, Binomial(500), data_q)
bs_euc_q   = price(eu_call, BlackScholes(), data_q)

@printf "  q = 0%%:  American = %.4f   European = %.4f   premium = %.4f\n" bin_amc_0 bs_euc_0 (bin_amc_0 - bs_euc_0)
@printf "  q = 3%%:  American = %.4f   European = %.4f   premium = %.4f\n" bin_amc_q bs_euc_q (bin_amc_q - bs_euc_q)
