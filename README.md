# FlexibleFunctors.jl

`FlexibleFunctors.jl` allows you to convert struct fields to a flat vector representation, and it also provides a function to transform similar vectors back into structs. However, `FlexibleFunctors.jl` also provides a `parameters(x)` function which can be extended to dynamically determine which fields make it into the vector and which fields are fixed.

## Example

```julia
using FlexibleFunctors, Zygote
import FlexibleFunctors: parameters

struct Model
    elements
    params
end
parameters(m::Model) = m.params

struct Square
    w
    params
end
parameters(s::Square) = s.params
area(s::Square) = s.w^2

s1 = Square(1.0, (:w,))
s2 = Square(2.0, ())
s3 = Square(3.0, (:w,))
m1 = Model([s1, s2, s3], (:elements,))
m2 = Model([s1, s2, s3], ())

p1, re1 = destructure(m1)
p2, re2 = destructure(m2)

julia> println(p1)
# [1.0, 3.0]

julia> println(p2)
# Any[]

# Replace first and third widths with vector values
julia> mapreduce((s)->area(s), +, re1([3.0, 4.0]).elements)
# 29

# Uses original widths since `m2` has no parameters
julia> mapreduce((s)->area(s), +, re2([3.0, 4.0]).elements)
# 14

# Map vector of parameters to an object for optimization
grad = Zygote.gradient((x) -> mapreduce(area, +, x.elements), re1([3.0, 4.0]));

julia> getfield.(grad[1].elements, :w)
# [6.0, 4.0, 8.0]
```

## Overview 

`FlexibleFunctors.jl` adds the ability to specify individual fields of a type as parameters. These parameters indicate fields which can be retrieved to obtain a flat vector representation of the struct parameters through `destructure`. `destructure` also returns a function, `re`, which reconstructs an instance of the original type. `re` operates as a function of the flat vector representation, but the reconstructed values of parameter fields are drawn from this vector while non-parameter fields are left unchanged.

Parameters are determined recursively. If a tagged field contains a struct with parameters of its own, those parameters are also included in the resulting vector and reconstruction.

`ffunctor` takes a struct instance with a `parameters` method and returns a `NamedTuple` representation of the parameters. `ffunctor` also returns a `re` function for reconstructing the `struct` from the `NamedTuple` representation.

In either case, you must provide a `FlexibleFunctors.parameters(::YourType)` method which return the parameters of `YourType` in a `Tuple` of `Symbol`s. This is accomplished by `import`ing `FlexibleFunctors.jl` and adding additional methods directly to `parameters`.

## What's Flexible about FlexibleFunctors?

The functionality provided by `FlexibleFunctors.jl` is similar to `Functors.jl`. Both projects annotate types with special fields to convert in between flat vector representations of structs and a `re`constructed instance. However, `Functors.jl` stores this information at the type-level for all instances of a type, forcing all instances to use identical fields as (what we call) parameters. 

`FlexibleFunctors.jl` can store these parameter fields at the instance-level. For example, instead of hard-coding the returned parameters, we could add a `parameters` field to a `struct`, and then specify these `parameters` at run-time as a tuple of `Symbol`s. In this way, we can use the same types but specialize which fields are actually parameterized and liable to be changed during a `re`construction. 

If parameter fields are stored within a struct instance, re-parameterizing the type instance is possible. For this, we recommend [Setfield.jl](https://github.com/jw3126/Setfield.jl) and the `@set` macro which can easily update nested fields.

Further, note that `FlexibleFunctors.jl` can reproduce similar behavior to `Functors.jl`. If `parameters(m::M) = (:some, :fixed, :tuple)`, then all instances of `M` will have the same parameters. 