
# Setup -------------------------------------------------------------------

library(shiny)
library(arrow)
library(dplyr)
library(glue)
library(leaflet)

locations_list <- read.csv("./data/potential_sites.csv") %>% 
  dplyr::filter(type != "Airport") %>% 
  dplyr::arrange(type) %>% 
  mutate(display_name = glue::glue("{location} ({type})")) %>% 
  dplyr::pull(display_name) %>% 
  as.list()

airport_vec <- read.csv("./data/potential_sites.csv") %>% 
  dplyr::filter(type == "Airport") %>% 
  dplyr::pull(location)

# UI ----------------------------------------------------------------------

ui <- fluidPage(
## Title Panel & layout  --------------------------------------------------
  titlePanel("Scotland Trip Planner"),
  sidebarLayout(
## Sidebar layout ---------------------------------------------------------
    sidebarPanel(
      checkboxGroupInput(
        inputId = "location_boxes",
        label = "Potential Destinations",
        choices = locations_list,
        selected = locations_list
      ),
      selectInput(
        inputId = "arrivalAirport",
        label = "Arrival Airport",
        choices = airport_vec
      ),
      selectInput(
        inputId = "departAirport",
        label = "Departure Airport",
        choices = airport_vec
      )
    ),

## Main Panel --------------------------------------------------------------

    mainPanel(
      leafletOutput("scotlandMap")
    )
  )
)


# Server ------------------------------------------------------------------

server <- function(input, output, session) {
  
  df_locations <- arrow::read_parquet("./data/prepped_location_data.parquet")
  
  pal <- colorFactor(c("black", "red", "green", "darkblue", "darkgoldenrod4" ),
                     domain = c("Airport",  "Football", "Hiking", "Photos","Scotch"))
  
  # icon_list <- awesomeIconList(
  #   Airport  = makeAwesomeIcon(icon = "plane-departure", library = "fa"),
  #   Football = makeAwesomeIcon(icon = "futbol", library= "fa"),
  #   Photos   = makeAwesomeIcon(icon = "camera", library= "fa"),
  #   Hiking   = makeAwesomeIcon(icon = "person-hiking", library= "fa"),
  #   Scotch   = makeAwesomeIcon(icon = "whiskey-glass", library= "fa"),
  # )

  
  output$scotlandMap <- renderLeaflet({
    df_locations %>% 
      leaflet() %>% 
      addTiles() %>%
      addCircleMarkers(lng = ~lng,
                 lat = ~lat, 
                 popup = ~search_location,
                 label = ~search_location,
                 color = ~pal(type)) %>% 
      addLegend(pal = pal, values = ~type, group = "circles", position = "bottomleft") 
  })
}

shinyApp(ui, server)
