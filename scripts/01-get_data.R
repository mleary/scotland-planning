
# Setup -------------------------------------------------------------------

library(googleway)
library(purrr)
library(dplyr)

api_key <- Sys.getenv("google_maps_api_key")
locations <- read.csv("./data/potential_sites.csv")
loc_vec <- locations$location

# Helper functions --------------------------------------------------------


get_google_geocode <- function(location_name, api_key) {
  df <- googleway::google_geocode(
    address = paste0(location_name, ", Scotland"),
    key = api_key,
    simplify = TRUE
  )
  if (df$status == "OK") {
    df <- df$results
    return(tibble::tibble(
      search_location = location_name,
      formatted_address = df$formatted_address,
      lat = df$geometry$location$lat,
      lng = df$geometry$location$lng,
      place_id = df$place_id
    ))
  } else {
    return(paste0("Error - Google response: ", df$status))
  }
}


get_google_dist <- function(formatted_origin, formatted_destination, api_key) {
  dist_data <- googleway::google_distance(
    origins = formatted_origin,
    destinations = formatted_destination,
    mode = "driving",
    key = api_key,
    simplify = TRUE
  )

  if (dist_data$status == "OK") {
    return(
      tibble::tibble(
        origin_address = formatted_origin,
        destination_address = formatted_destination,
        distance_km = dist_data$rows$elements[[1]]$distance$text,
        distance_meters = dist_data$rows$elements[[1]]$distance$value,
        duration_mins = dist_data$rows$elements[[1]]$duration$text,
        duration_secs = dist_data$rows$elements[[1]]$duration$value
      )
    )
  } else {
    return(paste0("Error - Google response: ", df$status))
  }
}



# Prep locations & calculate distance -------------------------------------

loc_data <- purrr::map_dfr(.x = locations$location, 
                           .f = get_google_geocode, api_key) %>% 
  left_join(locations, by=c("search_location" = "location"))
  

dist_data <- purrr::map_dfr(.x = loc_data$formatted_address, 
                            .f = get_google_dist, 
                            loc_data$formatted_address, api_key)



# Write out data to parquet file ------------------------------------------


arrow::write_parquet(loc_data, "./data/prepped_location_data.parquet")
arrow::write_parquet(dist_data, './data/prepped_distance_data.parquet')
