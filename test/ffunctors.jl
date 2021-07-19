using FlexibleFunctors; const FF = FlexibleFunctors

# Standard struct with constant parameters
struct Foo{X,Y,PS<:Tuple}
    x::X
    y::Y
    ps::PS
end
FF.parameters(f::Foo) = f.ps

@testset "Parameters" begin
    @test FF.parameters([1, 2]) === ()
    A = [Ref(1), Ref(2)]
    @test FF.parameters(A) === A
    @test FF.parameters((1, 2)) == (1, 2)
    @test FF.parameters((a=1, b=2)) == (a=1, b=2)

    p0, re = ffunctor([1, 2])
    @test p0 === ()

    p0, re = ffunctor(A)
    @test p0 === A
end

@testset "FlexibleFunctors" begin
    # No parameters
    mf1 = Foo(1, 2, ())
    p0, re = ffunctor(mf1)
    @test re(()) == mf1

    # One parameters
    mf2 = Foo(1.0, 2, (:x, ))
    p0, re = ffunctor(mf2)
    @test re(p0) == mf2                         # Reconstruct self

    _, re2 = destructure(mf2)
    @test re2([1]) == Foo(1, 2, (:x,))          # Change type on Foo.x from Float64 to Int

    # Both fields as parameters
    mf3 = Foo(22.0, 3.14, (:x, :y))
    p0, re = destructure(mf3)
    @test re(p0) == mf3
    @test re(reverse(p0)) == Foo(3.14, 22.0, (:x, :y)) # Swap the fields

    # Nested parameters
    mf4 = Foo(Foo(1, 2, (:y,)), 3, (:x, :y))
    p0, re = destructure(mf4)
    @test re(p0) == mf4
    @test re(["hello", -1]) == Foo(Foo(1, "hello", (:y,)), -1, (:x, :y))
end

@testset "fieldmap" begin
    mf1 = Foo(3.0, 2, (:x,))
    @test fieldmap((x) -> x^2, mf1) == Foo(9.0, 2, (:x,))

    mf2 = Foo(-22.0, 3.14, (:x, :y))
    @test fieldmap(abs, mf2) == Foo(22.0, 3.14, (:x, :y))

    mf3 = Foo(Foo(1, 2, (:y,)), 3, (:x, :y))
    @test fieldmap(sqrt, mf3) == Foo(Foo(1, sqrt(2), (:y,)), sqrt(3), (:x, :y))
end

module MyMod
    import FlexibleFunctors
    struct Bar{A,B,PS<:Tuple}
        a::A
        b::B
        parameters::PS
    end
    FlexibleFunctors.parameters(b::Bar) = b.parameters
end
import .MyMod

@testset "Reconstruction of Module-Specific Type" begin
    mb = MyMod.Bar(1, 2, (:a,))
    p0, re = destructure(mb)
    @test re(p0) == mb
    @test re([3]) == MyMod.Bar(3, 2, (:a,))
end
