# ============================================================
# Hydrocyclone DOE-AI Case Study
# Reproducible statistical analysis
# ============================================================

# Required packages --------------------------------------------------------
# Install them once if needed:
# install.packages(c("dplyr", "tidyr", "ggplot2"))

library(dplyr)
library(tidyr)
library(ggplot2)

# 1. Paths and settings ----------------------------------------------------

input_file <- "data/hydrocyclone_attributes.csv"

dir.create("outputs", showWarnings = FALSE)
dir.create("outputs/tables", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/figures", recursive = TRUE, showWarnings = FALSE)

responses <- c("Q1", "Q2", "Q3", "Bowley")
alpha <- 0.05

# 2. Read and prepare data -------------------------------------------------

if (!file.exists(input_file)) {
  stop(
    "Input file not found. Please place the dataset at: ",
    input_file,
    "\nUse data/hydrocyclone_attributes_template.csv as a template."
  )
}

data <- read.csv(input_file, stringsAsFactors = FALSE, check.names = FALSE)

# Accept AMOSTRA as an alternative name for SAMPLE
if ("AMOSTRA" %in% names(data) && !("SAMPLE" %in% names(data))) {
  data <- data %>% rename(SAMPLE = AMOSTRA)
}

required_cols <- c("SAMPLE", "CONF", responses)
missing_cols <- setdiff(required_cols, names(data))

if (length(missing_cols) > 0) {
  stop("Missing required columns: ", paste(missing_cols, collapse = ", "))
}

# Convert comma decimals if necessary
for (v in responses) {
  data[[v]] <- as.numeric(gsub(",", ".", as.character(data[[v]])))
}

data$CONF <- as.factor(data$CONF)

cat("\nData loaded successfully.\n")
cat("Number of rows:", nrow(data), "\n")
cat("Samples per configuration:\n")
print(table(data$CONF))

# 3. Descriptive statistics ------------------------------------------------

long_data <- data %>%
  pivot_longer(
    cols = all_of(responses),
    names_to = "Variable",
    values_to = "Value"
  )

descriptive_stats <- long_data %>%
  group_by(CONF, Variable) %>%
  summarise(
    n = n(),
    mean = mean(Value, na.rm = TRUE),
    sd = sd(Value, na.rm = TRUE),
    minimum = min(Value, na.rm = TRUE),
    maximum = max(Value, na.rm = TRUE),
    .groups = "drop"
  )

write.csv(
  descriptive_stats,
  "outputs/tables/descriptive_statistics.csv",
  row.names = FALSE
)

print(descriptive_stats)

# Mean ± standard deviation plot
p_mean_sd <- ggplot(descriptive_stats, aes(x = CONF, y = mean)) +
  geom_point(size = 3) +
  geom_errorbar(aes(ymin = mean - sd, ymax = mean + sd), width = 0.15) +
  facet_wrap(~ Variable, scales = "free_y", ncol = 2) +
  theme_minimal(base_size = 12) +
  labs(
    title = "Mean ± standard deviation by configuration",
    x = "Configuration",
    y = "Value"
  )

ggsave(
  "outputs/figures/mean_sd_by_configuration.png",
  p_mean_sd,
  width = 9,
  height = 6,
  dpi = 300
)

# Individual sample plot
p_individual <- ggplot(long_data, aes(x = CONF, y = Value)) +
  geom_point(size = 2) +
  geom_text(aes(label = SAMPLE), nudge_x = 0.12, size = 3) +
  facet_wrap(~ Variable, scales = "free_y", ncol = 2) +
  theme_minimal(base_size = 12) +
  labs(
    title = "Individual sample values by configuration",
    x = "Configuration",
    y = "Value"
  )

ggsave(
  "outputs/figures/individual_samples_by_configuration.png",
  p_individual,
  width = 9,
  height = 6,
  dpi = 300
)

# 4. ANOVA and Tukey tests -------------------------------------------------

run_anova <- function(dataset, response) {
  model <- aov(as.formula(paste(response, "~ CONF")), data = dataset)
  tab <- summary(model)[[1]]

  data.frame(
    Response = response,
    df_CONF = tab$Df[1],
    df_residual = tab$Df[2],
    F_value = tab$`F value`[1],
    p_value = tab$`Pr(>F)`[1]
  )
}

anova_results <- bind_rows(lapply(responses, function(v) run_anova(data, v)))

write.csv(
  anova_results,
  "outputs/tables/anova_results.csv",
  row.names = FALSE
)

print(anova_results)

# Tukey test for significant ANOVAs
tukey_results <- data.frame()

for (v in responses) {
  p_value <- anova_results$p_value[anova_results$Response == v]

  if (!is.na(p_value) && p_value < alpha) {
    model <- aov(as.formula(paste(v, "~ CONF")), data = data)
    tukey <- as.data.frame(TukeyHSD(model)$CONF)
    tukey$Comparison <- rownames(tukey)
    tukey$Response <- v
    rownames(tukey) <- NULL
    tukey_results <- bind_rows(tukey_results, tukey)
  }
}

if (nrow(tukey_results) > 0) {
  tukey_results <- tukey_results %>%
    select(Response, Comparison, diff, lwr, upr, `p adj`)

  write.csv(
    tukey_results,
    "outputs/tables/tukey_results.csv",
    row.names = FALSE
  )

  print(tukey_results)
} else {
  cat("\nNo Tukey tests were exported because no ANOVA was significant.\n")
}

# 5. Residual diagnostics --------------------------------------------------

for (v in responses) {
  model <- aov(as.formula(paste(v, "~ CONF")), data = data)

  png(
    filename = paste0("outputs/figures/residuals_", v, ".png"),
    width = 1400,
    height = 1000,
    res = 150
  )
  par(mfrow = c(2, 2))
  plot(model, main = paste("Residual diagnostics -", v))
  par(mfrow = c(1, 1))
  dev.off()
}

# 6. Sensitivity analysis --------------------------------------------------

run_sensitivity <- function(dataset, scenario_name) {
  bind_rows(lapply(responses, function(v) {
    out <- run_anova(dataset, v)
    out$Scenario <- scenario_name
    out
  }))
}

sensitivity_results <- run_sensitivity(data, "Complete dataset")

if ("SAMPLE" %in% names(data)) {
  data_without_1 <- data %>% filter(SAMPLE != 1)
  data_without_12 <- data %>% filter(SAMPLE != 12)
  data_without_1_12 <- data %>% filter(!(SAMPLE %in% c(1, 12)))

  sensitivity_results <- bind_rows(
    sensitivity_results,
    run_sensitivity(data_without_1, "Without sample 1"),
    run_sensitivity(data_without_12, "Without sample 12"),
    run_sensitivity(data_without_1_12, "Without samples 1 and 12")
  )
}

sensitivity_results <- sensitivity_results %>%
  select(Scenario, Response, df_CONF, df_residual, F_value, p_value)

write.csv(
  sensitivity_results,
  "outputs/tables/sensitivity_results.csv",
  row.names = FALSE
)

print(sensitivity_results)

# Sensitivity p-value plot
p_sensitivity <- ggplot(sensitivity_results, aes(x = Scenario, y = p_value)) +
  geom_hline(yintercept = alpha, linetype = "dashed") +
  geom_point(size = 3) +
  facet_wrap(~ Response, scales = "free_y", ncol = 2) +
  scale_y_log10() +
  theme_minimal(base_size = 12) +
  theme(axis.text.x = element_text(angle = 25, hjust = 1)) +
  labs(
    title = "Sensitivity analysis of ANOVA p-values",
    subtitle = "Dashed line indicates the 5% significance level",
    x = NULL,
    y = "p-value, log scale"
  )

ggsave(
  "outputs/figures/sensitivity_p_values.png",
  p_sensitivity,
  width = 9,
  height = 6,
  dpi = 300
)

cat("\nAnalysis completed. Check the outputs/ folder.\n")
