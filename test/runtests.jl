using Pyomo
using Symbolics
using PythonCall: pyconvert
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
