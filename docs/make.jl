using Documenter

using EnergyModelsGeography

const EMG = EnergyModelsGeography

DocMeta.setdocmeta!(
    EnergyModelsGeography,
    :DocTestSetup,
    :(using EnergyModelsGeography);
    recursive = true,
)


# Copy the NEWS.md file
news = "docs/src/manual/NEWS.md"
cp(joinpath(@__DIR__, "NEWS.md"),
   joinpath(@__DIR__, news), force=true)


makedocs(
    modules = [EnergyModelsGeography],
    sitename = "EnergyModelsGeography.jl",
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", "false") == "true",
        edit_link = "main",
        assets = String[],
    ),
    pages = [
        "Home" => "index.md",
        "Manual" => Any[
            "Quick Start" => "manual/quick-start.md",
            "Philosophy" => "manual/philosophy.md",
            "Optimization variables" => "manual/optimization-variables.md",
            "Constraint functions" => "manual/constraint-functions.md",
            "TransmissionMode structure" => "manual/transmission-mode.md",
            "Example" => "manual/simple-example.md",
            "Release notes" => "manual/NEWS.md",
        ],
        "Library" => Any[
            "Public" => "library/public.md",
            "Internals" => Any[
                "Reference" => "library/internals/reference.md"]
        ]
    ]
)

deploydocs(;
    repo = "github.com/EnergyModelsX/EnergyModelsGeography.jl.git",
)
