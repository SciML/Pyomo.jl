mutable struct ConcreteModel
    __py__::Py
end

# Symbolics 7 uses the Julia type directly as the symtype, so a symbolic model is just
# `@variables m::ConcreteModel`. Kept as an alias so `@variables m::SymbolicConcreteModel`
# still reads the way it did under the Symbolics 6 `symstruct` wrapper.
const SymbolicConcreteModel = ConcreteModel

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
