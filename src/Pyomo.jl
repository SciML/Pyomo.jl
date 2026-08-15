"""
    Pyomo

Julia bindings for the Python [Pyomo](https://pyomo.readthedocs.io/) modeling package.

The package exposes Pyomo models and components through `PythonCall`, and provides symbolic
stand-ins that let Symbolics expressions refer to Pyomo variables before a concrete Python
model is available. Pyomo is installed by `CondaPkg` when the package environment is
instantiated.

# Example

```julia
using Pyomo

model = ConcreteModel()
model.x = pyomo.Var(initialize = 1.0)
model.x
```
"""
module Pyomo

import PythonCall
using PythonCall: Py, pyadd, pyconvert, pyeq, pyge, pygt, pyimport, pyle, pylt, pymul,
    pypow, pystr, pysub, pytruediv
import Symbolics
using Symbolics: Num, @register_symbolic
import NaNMath
import SymbolicUtils
import Symbolics: wrap, unwrap
import DomainSets

import Base: +, -, *, /, ^, TwicePrecision
import Base: >, >=, <, <=, ==

export SymbolicConcreteModel, ConcreteModel, SolverFactory, TransformationFactory
export ForwardEuler, BackwardEuler, MidpointEuler, LagrangeRadau, LagrangeLegendre
export PyomoVar, pyomo_getindex, pysym_getproperty
export get_results, DiscretizationMethod, is_finite_difference, method_string, scheme_string
export pyomo, dae, opt

include("concretemodel.jl")
include("symbolics.jl")
include("solver.jl")

##################################################

"""Python `pyomo.environ` module imported by the `Pyomo` module."""
const pyomo = PythonCall.pynew()

"""Python `pyomo.dae` module imported by the `Pyomo` module."""
const dae = PythonCall.pynew()

"""Python `pyomo.opt` module imported by the `Pyomo` module."""
const opt = PythonCall.pynew()
const math = PythonCall.pynew()
const compare_expressions = PythonCall.pynew()

function __init__()
    PythonCall.pycopy!(pyomo, pyimport("pyomo.environ"))
    PythonCall.pycopy!(dae, pyimport("pyomo.dae"))
    PythonCall.pycopy!(opt, pyimport("pyomo.opt"))
    PythonCall.pycopy!(math, pyimport("math"))
    return PythonCall.pycopy!(compare_expressions, pyimport("pyomo.core.expr.compare" => "compare_expressions"))
end

end # module Pyomo
