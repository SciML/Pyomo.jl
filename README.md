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

@variables t MODEL_SYM::SymbolicConcreteModel

model.t = dae.ContinuousSet(bounds = (0, 1))
model.x = pyomo.Var(model.t)
model.y = pyomo.Var(model.t)
model.dx = dae.DerivativeVar(model.x, wrt = model.t)
model.dy = dae.DerivativeVar(model.x, wrt = model.t)

# Use symbolic indexing to build Pyomo expressions returned by the functions.
# The type of variables in these equations is a Symbolic{PyomoVar}
prey_eq = model.dx[t] ~ 1.5*model.x[t] - model.x[t]*model.y[t]
predator_eq = model.dy[t] ~ -3*model.y[t] + model.x[t] * model.y[t]

prey_f = eval(Symbolics.build_function(prey_eq, MODEL_SYM, t))
pred_f = eval(Symbolics.build_function(pred_eq, MODEL_SYM, t))

model.deq1 = pyomo.Constraint(model.t, expr = Pyomo.pyfunc(prey_f))
model.deq2 = pyomo.Constraint(model.t, expr = Pyomo.pyfunc(pred_f))
...
```

## Solvers
Pyomo.jl exposes a few different constructors for the discretizations in Pyomo:
- BackwardEuler(): `'dae.finite_difference'` with `'BACKWARD'`
- MidpointEuler(): `'dae.finite_difference'` with `'CENTRAL'`
- ForwardEuler(): `'dae.finite_difference'` with `'FORWARD'`
- LagrangeRadau(n): `'dae.collocation'` with `'LAGRANGE-RADAU'` and `ncp = n`
- LagrangeLegendre(n): `'dae.collocation'` with `'LAGRANGE-LEGENDRE'` and `ncp = n`
