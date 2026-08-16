using Documenter
using Pyomo

makedocs(
    modules = [Pyomo],
    sitename = "Pyomo.jl",
    format = Documenter.HTML(edit_link = "master"),
    pages = [
        "Home" => "index.md",
        "API" => "api.md",
    ],
)

deploydocs(repo = "github.com/SciML/Pyomo.jl.git")
