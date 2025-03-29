using Distributions
using Plots
using Random

normcdf(x) = cdf(Normal(0.0, 1.0), x)


struct Binomial
    steps::Int
end

function price(option::EuropeanOption, engine::Binomial, data::MarketData)
    (; strike, expiry) = option
    (; spot, rate, vol, div) = data
    steps = engine.steps

    dt = expiry / steps
    u = exp(rate * dt + vol * sqrt(dt)) 
    d = exp(rate * dt - vol * sqrt(dt))
    pu = (exp(rate * dt) - d) / (u - d)
    pd = 1 - pu
    disc = exp(-rate * dt)

    s = zeros(steps + 1)
    x = zeros(steps + 1)

    @inbounds for i in 1:steps+1
        s[i] = spot * u^(steps + 1 - i) * d^(i - 1)
        x[i] = payoff(option, s[i])
    end

    for j in steps:-1:1
        @inbounds for i in 1:j
            x[i] = disc * (pu * x[i] + pd * x[i + 1])
        end
    end

    return x[1]
end


struct BlackScholes end

function price(option::EuropeanCall, engine::BlackScholes, data::MarketData)
    (; strike, expiry) = option
    (; spot, rate, vol, div) = data

    d1 = (log(spot / strike) + (rate + 0.5 * vol^2) * expiry) / (vol * sqrt(expiry))
    d2 = d1 - vol * sqrt(expiry)

    price = spot * normcdf(d1) - strike * exp(-rate * expiry) * normcdf(d2)

    return price 
end

function price(option::EuropeanPut, engine::BlackScholes, data::MarketData)
    (; strike, expiry) = option
    (; spot, rate, vol) = data

    d1 = (log(spot / strike) + (rate + 0.5 * vol^2) * expiry) / (vol * sqrt(expiry))
    d2 = d1 - vol * sqrt(expiry)

    price = strike * exp(-rate * expiry) * normcdf(-d2) - spot * normcdf(-d1)

    return price 
end


struct MonteCarlo
    steps::Int
    reps::Int
end

function asset_paths(engine::MonteCarlo, spot, rate, vol, expiry)
    (; steps, reps) = engine

    dt = expiry / steps
    nudt = (rate - 0.5 * vol^2) * dt
    sidt = vol * sqrt(dt)
    paths = zeros(reps, steps + 1)
    paths[:, 1] .= spot

    for i in 1:reps
        for j in 2:steps + 1
            z = rand(Normal(0.0, 1.0))
            paths[i, j] = paths[i, j - 1] * exp(nudt + sidt * z)
        end
    end

    return paths
end

function plot_paths(paths, num)
    # The second dimension is steps+1 columns, so:
    steps = size(paths, 2) - 1
    
    # Plot the first path
    plot(0:steps, paths[1, :], label="", legend=false)
    
    # Add the remaining paths (2 through 10) to the same plot
    for i in 2:num
        plot!(0:steps, paths[i, :], label="", legend=false)
    end
    
    xaxis!("Time step")
    yaxis!("Asset price")
    title!("First 10 Simulated Paths")
end

function price(option::EuropeanOption, engine::MonteCarlo, data::MarketData)
    (; strike, expiry) = option
    (; spot, rate, vol) = data
    (; steps, reps) = engine

    paths = asset_paths(engine, spot, rate, vol, expiry)
    payoffs = payoff.(option, paths[:, end])

    return exp(-rate * expiry) * mean(payoffs)
end