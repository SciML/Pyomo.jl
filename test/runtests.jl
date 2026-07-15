using Pyomo
using Test

@testset "Pyomo smoke test" begin
    model = ConcreteModel()
    @test model isa ConcreteModel
end
