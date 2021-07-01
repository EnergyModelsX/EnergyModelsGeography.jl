
using CSV
using DataFrames
using Plots
using Shapefile
using ZipFile

##

for dir in ["data", "downloads", "shapefiles", "output"]
    path = joinpath(pwd(), dir)
    if ~ispath(path)
        mkpath(path)
    end
end

##

normalize(vec) = [(x - minimum(vec))/(maximum(vec) - minimum(vec)) for x in vec]

##

url = "https://www.cbs.nl/-/media/cbs/dossiers/" *
      "nederland-regionaal/wijk-en-buurtstatistieken/wijkbuurtkaart_2020_v1.zip"
name_zipfile = split(url, "/")[end]
path_zipfile = joinpath(pwd(), "downloads", name_zipfile)
if ~isfile(path_zipfile)
    download(url, path_zipfile)
end

##

path_shapefile = joinpath(pwd(), "shapefiles", "gemeente_2020_v1.shp")
if ~isfile(path_shapefile)
    r = ZipFile.Reader(path_zipfile)
    for file in r.files
        open(joinpath(pwd(), "shapefiles", file.name), "w") do io
            write(io, read(file))
        end
    end
end


##


# read shapefile
table = Shapefile.Table(path_shapefile)

# create dataframe
df = table |> DataFrame
df.Shape = Shapefile.shapes(table)

# filter for land (i.e. not water)
row_filter = df.H2O .== "NEE"

# apply filter
municipality = df[row_filter, :]


##

url = "https://data.rivm.nl/covid-19/COVID-19_aantallen_gemeente_per_dag.csv"
file_path = joinpath(pwd(), "data", split(url, "/")[end])
download(url, joinpath(pwd(), "data", file_path))

##

covid = CSV.File(file_path) |> DataFrame

##

# select most recent data
actuals = covid[
    .&(.~ismissing.(covid.Municipality_name),
        covid.Date_of_publication .== maximum(covid.Date_of_publication)
        ),
    [:Municipality_name, :Total_reported, :Hospital_admission, :Deceased]
]

##

actuals = combine(
    groupby(actuals, :Municipality_name),
    names(actuals)[2:end] .=> sum .=> names(actuals)[2:end]
)

##

covid = leftjoin(municipality, actuals, on="GM_NAAM"=>"Municipality_name")

##

covid.Total_reported_per_100000 = covid.Total_reported .* (100_000 ./ covid.AANT_INW)
covid = covid[completecases(covid),:]

##

# values to plot
values = covid[:, :Total_reported_per_100000]
normalized_values = normalize(values)

# colors to plot
colormap = :heat
colors = Array([cgrad(colormap)[value] for value in normalized_values])

plot(size=(500, 600), axis=false, ticks=false)

for i = 1:nrow(covid)
    plot!(covid[i, :Shape], color=colors[i])
end

savefig(joinpath(pwd(), "output", "thematic_map.svg"))
