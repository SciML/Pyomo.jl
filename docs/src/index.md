# Pyomo.jl

Pyomo.jl exposes Pyomo models and symbolic Pyomo expressions to Julia and Symbolics.

```julia
using Pyomo

model = ConcreteModel()
model.x = pyomo.Var(initialize = 1.0)
```

Use [`SymbolicConcreteModel`](@ref) with Symbolics when model properties or indices must be
deferred into a symbolic expression. The [API reference](api.md) documents the model,
symbolic-value, and discretization interfaces.
