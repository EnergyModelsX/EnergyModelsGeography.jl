using Documenter
using DocumenterInterLinks

using EnergyModelsGeography
using EnergyModelsBase
using EnergyModelsInvestments

const EMB = EnergyModelsBase
const EMG = EnergyModelsGeography

# Copy the NEWS.md file
cp("NEWS.md", "docs/src/manual/NEWS.md"; force=true)

links = InterLinks(
    "TimeStruct" => "https://sintefore.github.io/TimeStruct.jl/stable/",
    "EnergyModelsBase" => "https://energymodelsx.github.io/EnergyModelsBase.jl/stable/",
    "EnergyModelsInvestments" => "https://energymodelsx.github.io/EnergyModelsInvestments.jl/stable/",
)

DocMeta.setdocmeta!(
    EnergyModelsGeography,
    :DocTestSetup,
    :(using EnergyModelsGeography);
    recursive = true,
)

makedocs(
    sitename = "EnergyModelsGeography",
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", "false") == "true",
        edit_link = "main",
        assets = String[],
    ),
    modules = [
        EMG,
        isdefined(Base, :get_extension) ?
        Base.get_extension(EMG, :EMIExt) :
        EMG.EMIExt
    ],
    pages = [
        "Home" => "index.md",
        "Manual" => Any[
            "Quick Start" => "manual/quick-start.md",
            "Philosophy" => "manual/philosophy.md",
            "Optimization variables" => "manual/optimization-variables.md",
            "Constraint functions" => "manual/constraint-functions.md",
            "Example" => "manual/simple-example.md",
            "Investment options"=>"manual/investments.md",
            "Release notes" => "manual/NEWS.md",
        ],
        "Areas and Modes" => Any[
            "Areas" => "area_mode/area.md",
            "Transmission corridor" => "area_mode/corridor.md",
            "Transmission modes" => "area_mode/mode.md",
        ],
        "How to" => Any[
            "Update models" => "how-to/update-models.md",
            "Contribute to EnergyModelsGeography" => "how-to/contribute.md",
        ],
        "Library" => Any[
            "Public" => Any[
                "Areas"=>"library/public/area.md",
                "Transmission"=>"library/public/transmission.md",
                "TransmissionMode"=>"library/public/mode.md",
                "EMI extension"=>"library/public/emi_extension.md",
            ],
            "Internals"=>Any[
                "Functions"=>"library/internals/functions.md",
                "Methods `EnergyModelsBase`"=>"library/internals/methods_EMB.md",
                "Methods `EnergyModelsInvestments`"=>"library/internals/methods_EMIExt.md",
            ],
        ],
    ],
    plugins=[links],
)

deploydocs(;
    repo = "github.com/EnergyModelsX/EnergyModelsGeography.jl.git",
)
