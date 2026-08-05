using Pyomo
using Symbolics
using PythonCall: pyconvert, Py
import NaNMath
using Test

# Pyomo `==` on expressions builds a relational expression rather than a `Bool`, so
# structural comparison has to go through Pyomo's own comparison helper.
same_expr(a, b) = pyconvert(Bool, Pyomo.compare_expressions(a, b))

@testset "Pyomo smoke test" begin
    model = ConcreteModel()
    @test model isa ConcreteModel
end

@testset "Symbolic model building" begin
    m = ConcreteModel()
    m.u_idxs = pyomo.RangeSet(1, 2)
    m.t = dae.ContinuousSet(initialize = [0.0, 0.5, 1.0], bounds = (0.0, 1.0))
    m.U = pyomo.Var(m.u_idxs, m.t, initialize = 0.0)
    m.dU = dae.DerivativeVar(m.U, wrt = m.t, initialize = 0)

    @variables MODEL_SYM::SymbolicConcreteModel T_SYM
    @test Symbolics.symtype(Symbolics.unwrap(MODEL_SYM)) === ConcreteModel

    U = pysym_getproperty(MODEL_SYM, :U)
    @test Symbolics.symtype(Symbolics.unwrap(U)) === PyomoVar

    x = pyomo_getindex(U, 1, T_SYM)
    @test Symbolics.symtype(Symbolics.unwrap(x)) === PyomoVar

    # Symbolic Pyomo values are scalars: without a `promote_shape` method their shape is
    # `Unknown(-1)` and every scalar operation rejects them.
    @test Symbolics.symtype(Symbolics.unwrap(cos(x))) === Real
    @test Symbolics.symtype(Symbolics.unwrap(U + 1)) === PyomoVar

    # The generated function must reproduce the Pyomo expression it stands for
    f = eval(Symbolics.build_function(Symbolics.unwrap(x - 1.0), MODEL_SYM, T_SYM))
    @test pyconvert(Float64, pyomo.value(Base.invokelatest(f, m, 0.5))) ≈ -1.0

    dU = pysym_getproperty(MODEL_SYM, :dU)
    fd = eval(
        Symbolics.build_function(
            Symbolics.unwrap(pyomo_getindex(dU, 1, T_SYM)), MODEL_SYM, T_SYM
        )
    )
    @test same_expr(Base.invokelatest(fd, m, 0.5), m.dU[1, 0.5])

    # Indexing a concrete PyomoVar goes straight through to Pyomo
    @test same_expr(PyomoVar(m.U)[1, 0.5], m.U[1, 0.5])
    # All-integer indices are the case that collides with `getindex(::Number, ::Integer...)`
    @test same_expr(PyomoVar(m.U)[1, 0], m.U[1, 0])

    # SymbolicUtils queries these before choosing simplification paths; a PyomoVar wraps
    # an opaque Pyomo expression, so nothing is known about its value
    pv = PyomoVar(m.U[1, 0])
    @test !isinteger(pv)
    @test !iszero(pv)
    @test !isone(pv)
    @test isfinite(pv)
end

@testset "Registered Pyomo math functions" begin
    m = ConcreteModel()
    m.u_idxs = pyomo.RangeSet(1, 2)
    m.t = dae.ContinuousSet(initialize = [0.0, 0.5, 1.0], bounds = (0.0, 1.0))
    m.U = pyomo.Var(m.u_idxs, m.t, initialize = 0.0)

    @variables MODEL_SYM::SymbolicConcreteModel T_SYM
    x = pyomo_getindex(pysym_getproperty(MODEL_SYM, :U), 1, T_SYM)

    for (jf, pf) in [
            (sin, Pyomo.py_sin), (cos, Pyomo.py_cos), (exp, Pyomo.py_exp),
            (log, Pyomo.py_log), (sqrt, Pyomo.py_sqrt), (acos, Pyomo.py_acos),
            (asin, Pyomo.py_asin), (tan, Pyomo.py_tan), (atanh, Pyomo.py_atanh),
            (acosh, Pyomo.py_acosh), (log10, Pyomo.py_log10),
        ]
        expr = Symbolics.substitute(
            Symbolics.unwrap(jf(x)), Dict(jf => pf), fold = Val(false)
        )
        @test Symbolics.operation(expr) === pf
        f = eval(Symbolics.build_function(expr, MODEL_SYM, T_SYM))
        @test same_expr(Base.invokelatest(f, m, 0.5), pf(m.U[1, 0.5]))
    end
end

@testset "PyomoVar arithmetic and comparisons" begin
    m = ConcreteModel()
    m.x = pyomo.Var(initialize = 1.0)
    m.y = pyomo.Var(initialize = 2.0)
    v = PyomoVar(m.x)
    w = PyomoVar(m.y)

    @test same_expr(Py(-v), -m.x)
    @test same_expr(Py(v + 1.0), m.x + 1.0)
    @test same_expr(Py(v - 1.0), m.x - 1.0)
    @test same_expr(Py(v * 2.0), m.x * 2.0)
    @test same_expr(Py(v / 2.0), m.x / 2.0)
    @test same_expr(Py(v^2), m.x^2)
    @test same_expr(Py(v^2.0), m.x^2.0)

    # Comparisons must build Pyomo relational expressions, not Julia Bools
    @test same_expr(Py(v >= w), m.x >= m.y)
    @test same_expr(Py(v > w), m.x > m.y)
    @test same_expr(Py(v <= w), m.x <= m.y)
    @test same_expr(Py(v < w), m.x < m.y)
    @test same_expr(Py(v == w), m.x == m.y)

    @test isequal(v, v)
    @test !isequal(v, 1.0)

    for f in [NaNMath.sin, NaNMath.cos, NaNMath.sqrt, NaNMath.log, NaNMath.exp]
        @test PyomoVar == typeof(f(v))
    end
end
