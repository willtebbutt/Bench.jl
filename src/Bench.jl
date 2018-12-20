module Bench

using BenchmarkTools, MacroTools

export @benchmarkable, @bench, @benchset

import Base: haskey, getindex, setindex!, convert
import BenchmarkTools: BenchmarkGroup

mutable struct SuiteLink
    parent
    data::BenchmarkGroup
end
haskey(suite::SuiteLink, key) = haskey(suite.data, key)
getindex(suite::SuiteLink, key...) = getindex(suite.data, key...)
setindex!(suite, value, key...) = setindex!(suite.data, value, key...)
function BenchmarkGroup(suite::SuiteLink)
    group = BenchmarkGroup()
    for (key, value) in suite.data
        if value isa SuiteLink
            group[key] = BenchmarkGroup(value)
        else
            group[key] = value
        end
    end
    return group
end

# Please don't touch these.
const __SUITES = SuiteLink(nothing, BenchmarkGroup())
const __ACTIVE_SUITE = Ref(__SUITES)

get_active_suite() = __ACTIVE_SUITE[]
function set_active_suite!(suite::SuiteLink)
    __ACTIVE_SUITE[] = suite
    return nothing
end

function descend(key)
    active_suite = get_active_suite()
    if !haskey(active_suite, key)
        active_suite[key] = SuiteLink(active_suite, BenchmarkGroup())
    end
    set_active_suite!(active_suite[key])
    return nothing
end

function ascend()
    set_active_suite!(get_active_suite().parent)
    return nothing
end

function clear_suites()
    __SUITES.data = BenchmarkGroup()
    set_active_suite!(__SUITES)
end

macro bench(key, expr)
    return esc(quote
        Bench.get_active_suite()[$key] = @benchmarkable $expr
        Bench.get_active_suite()[$key]
    end)
end

macro benchset(key, code)
    return esc(quote
        Bench.descend($key)
        $code
        Bench.ascend()
        BenchmarkGroup(Bench.get_active_suite()[$key])
    end)
end

end # module
