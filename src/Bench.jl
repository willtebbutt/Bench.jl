module Bench

using BenchmarkTools, MacroTools

export @benchmarkable

import Base: haskey, getindex, setindex!, convert

struct SuiteLink
    parent
    data::BenchmarkGroup
end
haskey(suite::SuiteLink, key) = haskey(suite.data, key)
getindex(suite::SuiteLink, key...) = getindex(suite.data, key...)
setindex!(suite, value, key...) = setindex!(suite.data, value, key...)
function BenchmarkGroup(suite::SuiteLink)
    # recursively construct a benchmarkgroup from a SuiteLink. Essentially just throw
    # away information about parents.
end

# Please don't touch these.
const __SUITE_STACK = SuiteLink(nothing, BenchmarkGroup())
const __ACTIVE_SUITE = Ref(__SUITE_STACK)

get_active_suite() = __ACTIVE_SUITE[]
function set_active_suite!(suite)
    __ACTIVE_SUITE[] = suite
    return nothing
end

function descend(key)
    active_suite = get_active_suite()
    if !haskey(active_suite.data, key)
        active_suite.data[key] = SuiteLink(active_suite, BenchmarkGroup())
    end
    set_active_suite!(active_suite.data[key])
    return nothing
end

function ascend()
    set_active_suite!(get_active_suite().parent)
    return nothing
end

macro bench(key, expr)
    return esc(:(Bench.get_active_suite().data[$key] = @benchmarkable $expr))
end

macro benchset(key, code)
    return esc(quote
        descend($key)
        $code
        ascend()
    end)
end

end # module
