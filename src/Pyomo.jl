module Pyomo

using PythonCall
using Symbolics, NaNMath
import Symbolics: wrap, Term, Struct, BasicSymbolic, Symbolic

import Base: +, -, *, /, \, ^
import Base: >, >=, <, <=, ==

export SymbolicConcreteModel, ConcreteModel, SolverFactory, TransformationFactory
export ForwardEuler, BackwardEuler, MidpointEuler, LagrangeRadau, LagrangeLegendre
export PyomoVar
export pyomo, dae, opt

include("concretemodel.jl")
include("symbolics.jl")
include("solver.jl")

##################################################

const pyomo = PythonCall.pynew()
const dae = PythonCall.pynew()
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
