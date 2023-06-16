using Documenter

using EnergyModelsGeography

const GEO = EnergyModelsGeography

DocMeta.setdocmeta!(
    EnergyModelsGeography,
    :DocTestSetup,
    :(using EnergyModelsGeography);
    recursive = true,
)


# Copy the NEWS.md file
news = "src/manual/NEWS.md"
cp(joinpath(@__DIR__, "../NEWS.md"),
   joinpath(@__DIR__, news), force=true)


makedocs(
    modules = [EnergyModelsGeography],
    sitename = "EnergyModelsGeography.jl",
    repo = "https://gitlab.sintef.no/clean_export/energymodelsgeography.jl/blob/{commit}{path}#{line}",
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", "false") == "true",
        canonical = "https://clean_export.pages.sintef.no/energymodelsgeography.jl/",
        edit_link = "main",
        assets = String[],
    ),
    pages = [
        "Home" => "index.md",
        "Manual" => Any[
            "Quick Start" => "manual/quick-start.md",
            "Philosophy" => "manual/philosophy.md",
            "Example" => "manual/simple-example.md",
            "Release notes" => "manual/NEWS.md",
        ],
        "Library" => Any[
            "Public" => "library/public.md",
            "Internals" => Any[
                "Optimization variables" => "library/internals/optimization-variables.md",
                "Constraint functions" => "library/internals/constraint-functions.md",
                "Reference" => "library/internals/reference.md"]
        ]
    ]
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
#=deploydocs(
    repo = "<repository url>"
)=#
