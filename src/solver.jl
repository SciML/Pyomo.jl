"""
    SolverFactory(solver)

Construct a Python Pyomo solver object by name.

# Arguments

- `solver`: Pyomo solver name, such as `"ipopt"` or `"glpk"`.

# Returns

The Python object returned by `pyomo.opt.SolverFactory`.

# Example

```julia
solver = SolverFactory("ipopt")
```
"""
function SolverFactory(solver::String)
    return pyomo.SolverFactory(solver)
end

"""
    get_results(model, sym)

Collect the values of a Pyomo indexed component after solving a model.

# Arguments

- `model`: A [`ConcreteModel`](@ref) containing the component.
- `sym`: Symbol naming an indexed Pyomo variable or component.

# Returns

A Julia vector containing `pyomo.value` for every index in the component's index set.

# Example

```julia
values = get_results(model, :x)
```
"""
function get_results(model, sym)
    var = getproperty(model, sym)
    idxs = pyconvert(Array, var.index_set())
    return [pyomo.value(var[i]) for i in idxs]
end

"""
    DiscretizationMethod

Abstract interface for Pyomo DAE discretization methods.

Concrete subtypes must implement [`is_finite_difference`](@ref), [`method_string`](@ref),
and `scheme_string`. `method_string` must return the Pyomo transformation name, while
`scheme_string` must return the Pyomo scheme name used when configuring that transformation.
Implementations should be stateless except for the collocation point count needed by their
constructor.

# Interface contract

For a custom subtype `M <: DiscretizationMethod`:

1. Define `is_finite_difference(::M)` as `true` for finite-difference methods and `false`
   for collocation methods.
2. Ensure `method_string(::M)` returns the corresponding Pyomo transformation family.
   The default implementation derives this from `is_finite_difference`.
3. Define `scheme_string(::M)` to return the exact scheme identifier accepted by Pyomo.

These functions are the stable developer interface used by
[`TransformationFactory`](@ref); callers should not inspect the concrete type or construct
the underlying Python transformation directly.
"""
abstract type DiscretizationMethod end

"""Forward Euler finite-difference discretization."""
struct ForwardEuler <: DiscretizationMethod end

"""Backward Euler finite-difference discretization."""
struct BackwardEuler <: DiscretizationMethod end

"""Centered (midpoint) finite-difference discretization."""
struct MidpointEuler <: DiscretizationMethod end
"""
    LagrangeRadau(np)

Lagrange-Radau collocation discretization with `np` collocation points.

# Fields

- `np`: Number of collocation points passed to Pyomo.
"""
struct LagrangeRadau <: DiscretizationMethod
    np::Int
end
"""
    LagrangeLegendre(np)

Lagrange-Legendre collocation discretization with `np` collocation points.

# Fields

- `np`: Number of collocation points passed to Pyomo.
"""
struct LagrangeLegendre <: DiscretizationMethod
    np::Int
end

"""
    TransformationFactory(m)

Create the Python Pyomo DAE transformation for a [`DiscretizationMethod`](@ref).

# Arguments

- `m`: Discretization method selecting the transformation family and scheme.

# Returns

The Python object returned by `pyomo.TransformationFactory`.
"""
function TransformationFactory(m::DiscretizationMethod)
    return pyomo.TransformationFactory(method_string(m))
end

"""
    is_finite_difference(dm)

Report whether `dm` uses Pyomo's finite-difference transformation rather than collocation.

# Arguments

- `dm`: A [`DiscretizationMethod`](@ref).

# Returns

`true` for finite-difference methods and `false` for collocation methods. Extend this
function when defining a new method type.
"""
function is_finite_difference(dm::DiscretizationMethod)
    return dm isa Union{ForwardEuler, BackwardEuler, MidpointEuler}
end

"""
    method_string(dm)

Return the Pyomo transformation family for `dm`.

# Arguments

- `dm`: A [`DiscretizationMethod`](@ref).

# Returns

`"dae.finite_difference"` for finite-difference methods or `"dae.collocation"` for
collocation methods.
"""
function method_string(dm::DiscretizationMethod)
    return is_finite_difference(dm) ? "dae.finite_difference" : "dae.collocation"
end

"""
    scheme_string(dm::DiscretizationMethod)

Return the Pyomo scheme name for a discretization method.

This is a developer interface for configuring the object returned by
[`TransformationFactory`](@ref). A custom [`DiscretizationMethod`](@ref) should provide a
method returning the corresponding Pyomo scheme string.
"""
function scheme_string end

scheme_string(::ForwardEuler) = "FORWARD"
scheme_string(::MidpointEuler) = "CENTRAL"
scheme_string(::BackwardEuler) = "BACKWARD"
scheme_string(::LagrangeRadau) = "LAGRANGE-RADAU"
scheme_string(::LagrangeLegendre) = "LAGRANGE-LEGENDRE"
