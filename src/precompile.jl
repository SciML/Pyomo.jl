using PrecompileTools: @compile_workload, @setup_workload

function _precompile_workload()
    for method in (
            ForwardEuler(), BackwardEuler(), MidpointEuler(), LagrangeRadau(2),
            LagrangeLegendre(2),
        )
        is_finite_difference(method)
        method_string(method)
        scheme_string(method)
    end

    value = PyomoVar(2.0)
    -value
    value + 1.0
    value - 1.0
    value * 2.0
    value / 2.0
    value^2

    Symbolics.@variables model::SymbolicConcreteModel t
    symbolic_value = pyomo_getindex(pysym_getproperty(model, :x), t)
    unwrap(symbolic_value + 1.0)
    return nothing
end

@setup_workload begin
    @compile_workload begin
        _precompile_workload()
    end
end
