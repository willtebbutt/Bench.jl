module Bench

using BenchmarkTools, MacroTools

macro bench(name, expr)
    return esc(:(Bench.get_tail_suite()[$name] = @benchmarkable $expr))
end

end # module
