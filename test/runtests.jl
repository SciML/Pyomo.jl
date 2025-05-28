using Test, CasADi
import LinearAlgebra: cross, ×, Symmetric
import Suppressor: @capture_out
using PythonCall

@testset "Chemical Engineering" begin
    V = 40     # liters
    kA = 0.5   # 1/min
    kB = 0.1   # l/min
    CAf = 2.0  # moles/liter
    
    # create a model instance
    model = pyomo.ConcreteModel()
    
    # create x and y variables in the model
    model.q = pyomo.Var()
    
    # add a model objective
    model.objective = pyomo.Objective(expr = model.q*V*kA*CAf/(model.q + V*kB)/(model.q + V*kA), sense=pyomo.maximize)
    
    # compute a solution using ipopt for nonlinear optimization
    results = pyomo.SolverFactory("ipopt").solve(model)
    model.pprint()
    
    # print solutions
    qmax = model.q()
    CBmax = model.objective()
    print("\nFlowrate at maximum CB = ", qmax, " liters per minute.")
    print("\nMaximum CB =", CBmax, " moles per liter.")
    print("\nProductivity = ", qmax*CBmax, " moles per minute.")
end
