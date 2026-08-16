"""
    ConcreteModel

Mutable Julia handle to a Python `pyomo.environ.ConcreteModel`.

Properties assigned on the Julia object are forwarded to the Python model, so Pyomo
components can be created with ordinary Julia property syntax.

# Fields

- `__py__`: Wrapped Python model object. This is an implementation field; use property
  access on the Julia handle for model components.
"""
mutable struct ConcreteModel
    __py__::Py
end

# Symbolics 7 uses the Julia type directly as the symtype, so a symbolic model is just
# `@variables m::ConcreteModel`. Kept as an alias so `@variables m::SymbolicConcreteModel`
# still reads the way it did under the Symbolics 6 `symstruct` wrapper.
"""
    SymbolicConcreteModel

Alias for [`ConcreteModel`](@ref) used as the type annotation of symbolic model variables.
Use it with `Symbolics.@variables` when property access should remain in a Symbolics
expression tree.
"""
const SymbolicConcreteModel = ConcreteModel

"""
    ConcreteModel()

Create a new [`ConcreteModel`](@ref) wrapping a fresh Python Pyomo model.

# Returns

A mutable model handle.

# Example

```julia
model = ConcreteModel()
model.x = pyomo.Var(initialize = 1.0)
```
"""
function ConcreteModel()
    return ConcreteModel(pyomo.ConcreteModel())
end

PythonCall.Py(x::ConcreteModel) = x.__py__
PythonCall.pyconvert(::Type{ConcreteModel}, x::Py) = T(x)

function Base.getproperty(model::ConcreteModel, sym::Symbol)
    return if isequal(sym, :__py__)
        getfield(model, :__py__)
    else
        getproperty(getfield(model, :__py__), sym)
    end
end

function Base.setproperty!(model::ConcreteModel, sym::Symbol, obj)
    return if isequal(sym, :__py__)
        setfield!(model, :__py__, obj)
    else
        setproperty!(model.:__py__, sym, obj)
    end
end
