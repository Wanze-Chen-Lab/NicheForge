library(tidyverse)
library(stringr)
library(ggridges)
library(viridis)

setwd("D:/file/2TF")

file_list <- list.files(pattern = "\\.csv$", full.names = TRUE)

time_files <- list(
  Time_0 = file_list[str_detect(file_list, "Time_0")],
  Time_1 = file_list[str_detect(file_list, "Time_1")],
  Time_2 = file_list[str_detect(file_list, "Time_2")]
)


process_file <- function(file_path, pattern) {

  data <- read_csv(file_path, show_col_types = FALSE)
  

  file_name <- basename(file_path)
  

  data %>%
    filter(str_detect(Label, pattern)) %>%
    mutate(
      ROI = row_number(),  
      File_name = file_name  
    ) %>%
    select(File_name, Label, ROI, Area, Mean)
}


process_time_group <- function(file_group, group_name, pattern, marker) {

  combined_data <- map_dfr(file_group, ~process_file(.x, pattern))
  

  output_file <- sprintf("%s_%s.csv", group_name, marker)
  write_csv(combined_data, output_file)
}


walk2(time_files, names(time_files), 
      ~process_time_group(.x, .y, ":2", "GFP"))


walk2(time_files, names(time_files), 
      ~process_time_group(.x, .y, ":3", "mCherry"))

markers <- c("GFP", "mCherry")
time_points <- c("Time_0", "Time_1", "Time_2")


file_paths <- expand.grid(time = time_points, marker = markers) %>%
  mutate(path = paste0(time, "_", marker, ".csv"))


combined_data <- map_dfr(file_paths$path, ~{
  if(file.exists(.x)) {
    time_point <- str_extract(.x, "Time_[0-2]")
    marker_type <- str_extract(.x, "(?<=_)[A-Za-z]+(?=\\.csv)")
    

    df <- read_csv(.x, show_col_types = FALSE) %>%
      mutate(
        New_File_name = str_replace(File_name, "_Time_.*", "") %>% 
          str_extract(".*registered\\.tif")
      ) %>%
      select(New_File_name, ROI, Area, Mean)
    
    df %>%
      pivot_longer(
        cols = c(Area, Mean),
        names_to = "measure_type",
        values_to = "value"
      ) %>%
      mutate(
        combined_col = paste0(time_point, "_", marker_type, "_", measure_type)
      ) %>%
      select(New_File_name, ROI, combined_col, value)
  }
}) %>%
  pivot_wider(
    names_from = combined_col,
    values_from = value,
    values_fill = NA
  ) %>%
  arrange(New_File_name, ROI) %>%
  select(
    New_File_name,
    ROI,
    matches("Time_._GFP_Area"),
    matches("Time_._mCherry_Area"),
    matches("Time_._GFP_Mean"),
    matches("Time_._mCherry_Mean")
  )

write_csv(combined_data, "combined_area_mean_data.csv")

data <- read_csv("combined_area_mean_data.csv")

safe_multiply <- function(area, mean_val) {
  if_else(is.na(mean_val), area * 0, area * mean_val)
}


result <- data %>%
  mutate(
    Time_0_GFP_Area_mean = safe_multiply(Time_0_GFP_Area, Time_0_GFP_Mean),    

    Time_1_GFP_Area_mean = safe_multiply(Time_1_GFP_Area, Time_1_GFP_Mean),    

    Time_2_GFP_Area_mean = safe_multiply(Time_2_GFP_Area, Time_2_GFP_Mean),    

    Time_0_mCherry_Area_mean = safe_multiply(Time_0_mCherry_Area, Time_0_mCherry_Mean),    

    Time_1_mCherry_Area_mean = safe_multiply(Time_1_mCherry_Area, Time_1_mCherry_Mean),    

    Time_2_mCherry_Area_mean = safe_multiply(Time_2_mCherry_Area, Time_2_mCherry_Mean),

    Time_0_GFP_Area_mean_106 = Time_0_GFP_Area_mean / 1000000,
    Time_1_GFP_Area_mean_106 = Time_1_GFP_Area_mean / 1000000,
    Time_2_GFP_Area_mean_106 = Time_2_GFP_Area_mean / 1000000,
    Time_0_mCherry_Area_mean_106 = Time_0_mCherry_Area_mean / 1000000,
    Time_1_mCherry_Area_mean_106 = Time_1_mCherry_Area_mean / 1000000,
    Time_2_mCherry_Area_mean_106 = Time_2_mCherry_Area_mean / 1000000,
  ) %>%

  select(New_File_name, ROI, Time_0_GFP_Area, Time_1_GFP_Area, Time_2_GFP_Area, Time_0_mCherry_Area, 
         Time_1_mCherry_Area, Time_2_mCherry_Area, Time_0_GFP_Mean, Time_1_GFP_Mean, Time_2_GFP_Mean, Time_0_mCherry_Mean, 
         Time_1_mCherry_Mean, Time_2_mCherry_Mean, Time_0_GFP_Area_mean_106, Time_1_GFP_Area_mean_106, 
         Time_2_GFP_Area_mean_106, Time_0_mCherry_Area_mean_106, Time_1_mCherry_Area_mean_106, Time_2_mCherry_Area_mean_106
)



write_csv(result, "combined_area_mean_data_results.csv")






