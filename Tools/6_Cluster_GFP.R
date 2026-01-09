library(viridisLite)
library(tidyverse)
library(cluster)
library(ggridges)
library(viridis)
library(scales) 

setwd("D:/file/2TF")
data <- read_csv("2TF_combined_area_mean_data_results_remove_block.csv") %>%
 mutate(data_number = row_number(), .before = 1) %>%  
 select(data_number, Time_0_GFP_Area_mean_106, Time_1_GFP_Area_mean_106, Time_2_GFP_Area_mean_106)

set.seed(123)
scaled_data <- scale(data[, 2:4])
kmeans_result <- kmeans(scaled_data, centers = 2, nstart = 25)
data$Cluster <- as.factor(paste("Cluster", kmeans_result$cluster)) 

plot_data <- data %>%
  pivot_longer(
    cols = starts_with("Time_"),
    names_to = "Time",
    values_to = "Area_mean_106"
  ) %>%
  mutate(Time = as.numeric(gsub("Time_|_GFP_Area_mean_106", "", Time)))
plot_data$Area_mean_106_log <- log2(plot_data$Area_mean_106+1)

centroids <- plot_data %>%
  group_by(Cluster, Time) %>%
  summarise(Mean_Area_mean_106 = mean(Area_mean_106_log), .groups = "drop")


df <- plot_data
df$Time <- factor(df$Time, levels = c(0, 1, 2))


cluster_means <- df %>%
  group_by(Cluster, Time) %>%
  summarise(cluster_mean = mean(Area_mean_106_log), .groups = 'drop')

df_with_mean <- df %>%
  left_join(cluster_means, by = c("Cluster", "Time")) %>%
  mutate(residual = Area_mean_106_log - cluster_mean)

df_plot <- df_with_mean %>%
  group_by(data_number, Cluster) %>%
  summarise(avg_resid = mean(abs(residual)), .groups = "drop") %>%
  mutate(
    color_score_raw = 1 - rescale(avg_resid),
    color_score = color_score_raw^3 
  ) %>%
  left_join(df_with_mean, by = c("data_number", "Cluster")) %>%
  arrange(color_score)  


ggplot(df_plot, aes(x = as.factor(Time), y = Area_mean_106_log, group = data_number)) +  
  

  geom_line(aes(color = color_score, alpha = color_score)) +
  

  stat_summary(
    fun = mean, 
    geom = "line", 
    aes(group = Cluster), 
    linewidth = 0.3,  
    color = "black"
  ) +  

  facet_wrap(~ Cluster, ncol = 1) +  

  scale_color_gradientn(
    colours = c("#FFFFCC", "#D9F0A3", "#ADDD8E", "#78C679", "#41AB5D", "#238443", "#006837", "#00441B"),
    name = "Residual proximity",
    guide = guide_colorbar(
      barwidth = unit(15, "lines"),  
      barheight = unit(0.8, "lines"),
      direction = "horizontal",
      title.position = "top",
      title.hjust = 0.5
    )
  ) +  

  scale_alpha_continuous(
    range = c(0.3, 0.9),  
    guide = "none"
  ) +   

  scale_x_discrete(
    name = "Time Point",
    breaks = 0:2,
    labels = c("Time 0", "Time 1", "Time 2"),
    expand = c(0.05, 0.05)
  ) +
  
  scale_y_continuous(
    name = "Cell number score (log2 scaled)",
    expand = c(0.02, 0.02)
  ) +  

  labs(
    title = "Cluster Expression Trends",
    subtitle = "Lines ordered by proximity (light first, dark last)"
  ) +
  theme(
    text = element_text(size = 7), 
    strip.text = element_text(face = "plain", size = 7), 
    panel.background = element_blank(), 
    panel.grid = element_blank(), 
    panel.spacing = unit(0.5, "lines"),
    axis.line = element_line(color = "black", size = 0.3),
    axis.ticks = element_line(color = "black", size = 0.3),
    axis.text = element_text(color = "black", size = 7),
    axis.title = element_text(color = "black", size = 7)
  )


ggsave(
  "clusters_GFP_Area_mean.png",
  width = 8,
  height = 12, 
  units = "cm",
  dpi = 600 
)

ggsave("clusters_GFP_Area_mean.pdf",  device = "pdf", 
       width = 12 , height = 12)

rawdata <- read.csv("./2TF_combined_area_mean_data_results_remove_block.csv")
rownames(rawdata) <- rawdata$data_number
rownames(data) <- data$data_number
rawdata$cluster <- data$Cluster
write.csv(rawdata,"./2TF_combined_area_mean_data_results_remove_block_cluster.csv")
cluster_stats <- data %>%
  group_by(Cluster) %>%
  summarise(
    n = n(),
    Time_0_avg = mean(Time_0_GFP_Area_mean_106),
    Time_1_avg = mean(Time_1_GFP_Area_mean_106),
    Time_2_avg = mean(Time_2_GFP_Area_mean_106)
  )

print(cluster_stats)
write_csv(cluster_stats, "2TF_combined_area_mean_data_results_remove_block_cluster_statistics.csv")


