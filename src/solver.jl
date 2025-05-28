function SolverFactory(solver::String)
    pyomo.SolverFactory(solver)
end

function get_results(model, sym)
    var = getproperty(model, sym)
    idxs = pyconvert(Array, var.index_set())
    [pyomo.value(var[i]) for i in idxs]
end

abstract type DiscretizationMethod end
struct ForwardEuler <: DiscretizationMethod end
struct BackwardEuler <: DiscretizationMethod end
struct MidpointEuler <: DiscretizationMethod end
struct LagrangeRadau <: DiscretizationMethod
    np::Int
end
struct LagrangeLegendre <: DiscretizationMethod
    np::Int
end

function TransformationFactory(m::DiscretizationMethod)
    pyomo.TransformationFactory(method_string(m))
end

is_finite_difference(dm::DiscretizationMethod) = dm isa Union{ForwardEuler, BackwardEuler, MidpointEuler}

method_string(dm::DiscretizationMethod) = is_finite_difference(dm) ? "dae.finite_difference" : "dae.collocation"
scheme_string(::ForwardEuler) = "FORWARD"
scheme_string(::MidpointEuler) = "CENTRAL"
scheme_string(::BackwardEuler) = "BACKWARD"
scheme_string(::LagrangeRadau) = "LAGRANGE-RADAU"
scheme_string(::LagrangeLegendre) = "LAGRANGE-LEGENDRE"
