mutable struct ConcreteModel
    __py__::Py
end

const SymbolicConcreteModel = Symbolics.symstruct(ConcreteModel)

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
