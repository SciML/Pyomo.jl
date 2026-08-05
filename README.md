# Pyomo.jl

This package is an interface to Pyomo, a Python package for nonlinear optimization
and solving DAEs. More information is available at the [Pyomo docs](https://pyomo.readthedocs.io/en/stable/).

In particular, the purpose of this package is to interface Pyomo with Symbolics.jl. In this way, Symbolics can be used to build Pyomo expressions that can then be
turned into Julia functions using `Symbolics.build_function`, and then to Python
functions using `PythonCall.pyfunc`.

Please note that this repo is not affiliated with the Pyomo developers.

`pyomo.environ` is imported as `pyomo`, `pyomo.dae` is imported as `dae`, and `pyomo.opt` is imported as `opt`.

## Symbolics Example
The motivation of this package is largely that there needs to be a way to write 
a Pyomo expression as a symbolic expression if one wants to compile symbolic models
like those specified in ModelingToolkit to Pyomo. Below is a sketch of what this 
looks like.
```julia
using Pyomo, Symbolics

model = ConcreteModel()
model.t = dae.ContinuousSet(bounds = (0, 1), initialize = collect(range(0, 1, length = 11)))
model.x = pyomo.Var(model.t, initialize = 1.0)
model.y = pyomo.Var(model.t, initialize = 1.0)
model.dx = dae.DerivativeVar(model.x, wrt = model.t)
model.dy = dae.DerivativeVar(model.y, wrt = model.t)

# A symbolic stand-in for the model, plus the symbolic time index.
@variables MODEL_SYM::SymbolicConcreteModel t

# Property access and indexing on the symbolic model are deferred into the expression
# tree. The resulting symbolic values have symtype `PyomoVar`.
msym(name) = pysym_getproperty(MODEL_SYM, name)
x = pyomo_getindex(msym(:x), t)
y = pyomo_getindex(msym(:y), t)
dx = pyomo_getindex(msym(:dx), t)
dy = pyomo_getindex(msym(:dy), t)

prey = eval(Symbolics.build_function(Symbolics.unwrap(dx - (1.5x - x * y)), MODEL_SYM, t))
pred = eval(Symbolics.build_function(Symbolics.unwrap(dy - (-3y + x * y)), MODEL_SYM, t))

model.deq1 = pyomo.Constraint(model.t, rule = Pyomo.pyfunc((m, tau) -> prey(m, tau) == 0))
model.deq2 = pyomo.Constraint(model.t, rule = Pyomo.pyfunc((m, tau) -> pred(m, tau) == 0))

model.deq1[0.5].expr  # -1.5*x[0.5] + x[0.5]*y[0.5] + dx[0.5]  ==  0
```

## Solvers
Pyomo.jl exposes a few different constructors for the discretizations in Pyomo:
- BackwardEuler(): `'dae.finite_difference'` with `'BACKWARD'`
- MidpointEuler(): `'dae.finite_difference'` with `'CENTRAL'`
- ForwardEuler(): `'dae.finite_difference'` with `'FORWARD'`
- LagrangeRadau(n): `'dae.collocation'` with `'LAGRANGE-RADAU'` and `ncp = n`
- LagrangeLegendre(n): `'dae.collocation'` with `'LAGRANGE-LEGENDRE'` and `ncp = n`
