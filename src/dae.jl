function ContinuousSet!(model::ConcreteModel, set_name::Symbol, kwargs...) 
    model.set_name = pycall(dae.ContinuousSet, kwargs...)
end

function DerivativeVar!(model::ConcreteModel, var_name, kwargs...)
    model.var_name = pycall(dae.DerivativeVar(), kwargs...)
end

function Integral(; kwargs...)
    pycall(dae.Integral; kwargs...)
end

struct TransformationFactory
    __py__::Py
end

function TransformationFactory(transform::String)
    pycall(pyomo.TransformationFactory(transform))
end

function apply_to!(transform::TransformationFactory, model::ConcreteModel; kwargs...)
    pycall(transform.apply_to, model; kwargs...)
end

struct Simulator
    __py__::Py
end

function simulate!(sim::Simulator; kwargs...) 
    pycall(sim.simulate; kwargs...)
end
