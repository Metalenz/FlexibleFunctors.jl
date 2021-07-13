"""
    isleaf(x)
Return true if `x` has no children according to [`parameters`](@ref).
"""
isleaf(x) = parameters(x) === ()

"""
    parameters(x)

Returns a tuple of parameters, as marked by the user during construction
"""
parameters(x) = ()

parameters(x::Tuple) = x
parameters(x::NamedTuple) = x

parameters(x::AbstractArray) = x
parameters(x::AbstractArray{<:Number}) = ()

"""
    _parammap(f, x)

Maps `f` to each parameter (as specified by [`parameters`](@ref)) to the model `x`. Evaluates
    calls to [`ffunctor`](@ref).
"""
function parammap(f, x)
    func, re = ffunctor(x)
    return re(map(f, func))
end

"""
    _ffunctor(x::T)

Returns a flexible functor based on the chosen [`parameters`](@ref).
"""
function ffunctor(x::T) where T
    params = parameters(x)
    re = (y) -> begin
        all_args = map(fieldnames(T)) do fn
            field = fn in params ? getfield(y, fn) : getfield(x, fn)
            return field
        end
        return constructorof(T)(all_args...)
    end
    func = (; (p => getfield(x, p) for p in params)...)
    return func, re
end
ffunctor(x::AbstractArray) = x, y -> y
ffunctor(x::AbstractArray{<:Number}) = (), _ -> x

"""
    _destructure(s)

For a struct `s` which has parameters given by [`parameters`](@ref), iterates through all
    non-leaf nodes and collects the marked fields into a flat vector. This is particularly
    useful for model training or optimization, or use with `ForwardDiff`. A function which
    restructures `s` according to a flat vector is returned as the second argument.

NOTE: The flat vector representation is a `Vector{T}`. Julia will promote all entries to a
    common type if possible. This means [1, 2.0] == [1.0, 2.0] and both are Vector{Float64}.
"""
function destructure(s)
    xs = []
    _fieldmap(s) do x
        x isa AbstractArray && push!(xs, x)
        x isa Number && push!(xs, [x])
        return x
    end
    return vcat(vec.(copy(xs))...), p -> restructure(s, p)
end

"""
    _restructure(s, xs)

Given a struct `s` with parameters given by [`parameters`](@ref), restructures `s` according
    to the vector `xs`. In particular, `s == restructure(s, destructure(s)[1])`.
"""
function restructure(s, xs)
    i = 0
    _fieldmap(s) do x
        if x isa AbstractArray
            x = reshape(xs[i.+(1:length(x))], size(x))
            i += length(x)
        elseif x isa Number
            x = xs[i+1]
            i += 1
        end
        return x
    end
end

"""
    fieldmap(f, x; exlude = isleaf)

Maps the function `f` over the fields of a `FlexibleFunctor` (equivalently, the parameter
    fields of a struct `s` given by [`parameters`](@ref)).
"""
function _fieldmap(f, x; exclude = isleaf)
    y = exclude(x) ? f(x) : parammap(x -> _fieldmap(f, x; exclude = exclude), x)
    return y
end
