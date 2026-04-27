###
# See https://raphaelnussbaumer.com/GeoPressureManual/geopressuretemplate-workflow.html
###

library(GeoPressureR)

## OPTION 1: Run workflow step-by-step for a single tag
id <- "A071931" # Run a single tag
geopressuretemplate_config(id)
tag <- geopressuretemplate_tag(id)
graph <- geopressuretemplate_graph(id)
geopressuretemplate_pressurepath(id)

#remember -before plotting- to load the files to the environment:
load(glue::glue("./data/interim/{id}.RData"))
plot_path(path_most_likely)
plot(marginal)
path_simulation <- graph_simulation(graph, nj = 10, quiet = TRUE)
plot(marginal, path = path_most_likely)
plot(tag, type = "map_pressure") #just plotting pressure /no movement model or light
plot(tag, type = "map_light") #just plotting light /no movement model or pressure

#once i added the wind in 3-wind.qmd, i run this:
path_most_likely <- graph_most_likely(graph, quiet = TRUE)
marginal <- graph_marginal(graph, quiet = TRUE)
path_simulation <- graph_simulation(graph, nj = 10, quiet = TRUE)
plot_path(path_simulation, plot_leaflet = FALSE)

edge_simulation <- path2edge(path_simulation, graph)
edge_most_likely <- path2edge(path_most_likely, graph)
knitr::kable(head(edge_most_likely, 3), digits = 1)

#to check the values are actually good
plot_graph_movement(graph) +
  geom_histogram(
    data = data.frame(as = abs(edge_simulation$gs - edge_simulation$ws)),
    aes(x = as, y = after_stat(count) / sum(after_stat(count))),
    color = "black", fill = NA, bins = 100
  )

#to save in the interim file the paths that contain wind,
#save PARAM at this point explicitly or it wont work for the data package part
save(
  tag,
  param,
  graph,
  path_most_likely,
  path_simulation,
  marginal,
  edge_simulation,
  edge_most_likely,
  file = glue::glue("./data/interim/{id}.RData")
)



## OPTION 2: Run entire workflow for all tags
list_id <- tail(names(yaml::yaml.load_file("config.yml", eval.expr = FALSE)), -1)

for (id in list_id){
  cli::cli_h1("Run for {id}")
  geopressuretemplate(id)
}


## OPTION 3: All tracks, step-by-step

# 1. Compute likelihood map
for (id in list_id){
  cli::cli_h1("Run tag for {id}")
  geopressuretemplate_tag(id)
}

# 2. (optional) Manual check of labeling
# geopressureviz("18LX")
# write.csv(path_geopressureviz, glue::glue("./data/interim/geopressureviz_{id}.csv", row.names = FALSE))

# 3. (optional) Add wind if not done before
for (id in list_id){
  cli::cli_h1("Run tag_download_wind for {id}")
  load(glue::glue("./data/interim/{id}.RData"))
  tag_download_wind(tag)
}

# 4. Run graph
for (id in list_id){
  cli::cli_h1("Run graph for {id}")
  geopressuretemplate_graph(id)
}

# 5. Run pressurepath
for (id in list_id){
  cli::cli_h1("Run pressurepath for {id}")
  geopressuretemplate_pressurepath(id)
}
