using Pyomo
using Test

@testset "Precompile workload" begin
    @test isnothing(Pyomo._precompile_workload())
end
