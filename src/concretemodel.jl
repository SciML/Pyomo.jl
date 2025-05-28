mutable struct ConcreteModel
    __py__::Py
end

@enum ObjectiveSense::Int8 maximize=-1 minimize=1

function ConcreteModel()
    ConcreteModel(pyomo.ConcreteModel())
end

PythonCall.Py(x::ConcreteModel) = x.__py__
PythonCall.pyconvert(::Type{ConcreteModel}, x::Py) = T(x)

function Set!(model::ConcreteModel, set_name::Symbol, kwargs...)
    model.__py__.set_name = pycall(pyomo.Set; kwargs...)
end

function Set(; kwargs...)
    pycall(pyomo.Set; kwargs...)
end

function Var!(model::ConcreteModel, var_name::Symbol, kwargs...)
    model.__py__.var_name = pycall(pyomo.Var; kwargs...)
end

function Var(;kwargs...)
    pycall(pyomo.Var; kwargs...)
end

function Param!(model::ConcreteModel, var_name::Symbol, kwargs...)
    model.__py__.var_name = pycall(pyomo.Param; kwargs...)
end

function Param(;kwargs...)
    pycall(pyomo.Param; kwargs...)
end

function Objective!(model::ConcreteModel, obj_name::Symbol, expr; kwargs...)
    if haskey(kwargs, :sense)
        val = get(kwargs, :sense, 1)
        merge(kwargs, (sense = Integer(val),))
    end
    model.__py__.obj_name = pycall(pyomo.Objective, expr; kwargs...)
end

function Objective(;kwargs...)
    if haskey(kwargs, :sense)
        kwargs = Dict(kwargs)
        kwargs[:sense] = Integer(kwargs[:sense])
        kwargs = pairs(NamedTuple(kwargs))
    end
    pycall(pyomo.Objective; kwargs...)
end

function Constraint!(model::ConcreteModel, cons_name::Symbol, expr)
    model.__py__.cons_name = pyomo.Constraint(expr)
end

function Constraint(args...; kwargs...)
    pycall(pyomo.Constraint, args...; kwargs...)
end

function Base.getproperty(model::ConcreteModel, sym::Symbol)
    if isequal(sym, :__py__)
        getfield(model, :__py__)
    else
        getproperty(getfield(model, :__py__), sym)
    end
end

function Base.setproperty!(model::ConcreteModel, sym::Symbol, obj)
    if isequal(sym, :__py__)
        setfield!(model, :__py__, obj)
    else
        setproperty!(model.:__py__, sym, obj)
    end
end
