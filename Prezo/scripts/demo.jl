using Prezo
using Printf

# Market: spot=100, r=5%, vol=20%, no dividends
data = MarketData(100.0, 0.05, 0.20, 0.0)

# Contracts: at-the-money, 1 year to expiry
eu_put = EuropeanPut(100.0, 1.0)
am_put = AmericanPut(100.0, 1.0)

# European put across three engines
bs  = price(eu_put, BlackScholes(),         data)
bin = price(eu_put, Binomial(500),          data)
mc  = price(eu_put, MonteCarlo(50, 100_000), data)

# American put: Binomial reference + Longstaff-Schwartz Monte Carlo
am_bin = price(am_put, Binomial(500),               data)
am_lsm = price(am_put, LongstaffSchwartz(50, 20_000), data)

@printf "European put\n"
@printf "  Black-Scholes : %.4f\n" bs
@printf "  Binomial      : %.4f\n" bin
@printf "  Monte Carlo   : %.4f\n" mc

@printf "\nAmerican put\n"
@printf "  Binomial         : %.4f\n" am_bin
@printf "  Longstaff-Schwartz: %.4f\n" am_lsm
@printf "  Early-exercise premium: %.4f\n" (am_bin - bs)
