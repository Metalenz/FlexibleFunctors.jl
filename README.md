# FlexibleFunctors.jl

`FlexibleFunctors.jl` adds the ability to specify individual fields of a type as parameters. These parameters indicate fields which can be retrieved to obtain a flat vector representation of the struct parameters through `destructure`. Additionally, `destructure` returns a `re` function which reconstructs an instance of the original type. `re` operates as a function of a flat vector representation, but the reconstructed parameter values are drawn from this vector while non-parameter fields are left unchanged.

`ffunctor` (named for FlexibleFunctor) takes a struct instance with a `parameters` method and returns a `NamedTuple` representation of the parameters. `ffunctor` also returns a `re` function for reconstructing the `struct` from the `NamedTuple` representation.

In either case, you must provide a `FlexibleFunctors.parameters(::YourType)` method which return the parameters of `YourType` in a `Tuple` of `Symbol`s. This is accomplished by `import`ing `parameters` from `FlexibleFunctors.jl` to add additional methods directly to `parameters`.

If parameter fields are stored within a struct instance, re-parameterizing the type instance is possible. For this, we recommend [Setfield.jl](https://github.com/jw3126/Setfield.jl) and the `@set` macro which can easily update nested fields.

## What's Flexible about FlexibleFunctors?

The functionality provided by `FlexibleFunctors.jl` is qualitatively similar to `Functors.jl`. Both projects annotate types with special fields to convert in between flat vector representations of structs and a `re`constructed instance. However, `Functors.jl` stores this information at the type-level for each `struct`, forcing all instances to use the same fields as (what we call) parameters. 

By comparison, `FlexibleFunctors.jl` can store these parameter fields at the instance-level. For example, instead of hard-coding the returned parameters, we could add a `parameters` field to a `struct`, and then specify these `parameters` at run-time as a tuple of `Symbol`s. In this way, we can use the same types but specialize which fields are actually parameterized and liable to be changed during a `re`construction. 

Further, note that `FlexibleFunctors.jl` can reproduce similar behavior to `Functors.jl`. If `parameters(m::M) = (:some, :fixed, :tuple)`, then all instances of `M` will have the same parameters. 