# Experimental Design and Data Structuring for Artificial Intelligence Applications in Hydrocyclones

This repository contains a simple reproducible R workflow for the hydrocyclone case study described in the chapter **Experimental Design and Data Structuring for Artificial Intelligence Applications in Hydrocyclones**.

The objective is to reproduce the statistical analysis used to compare five hydrocyclone configurations based on four attributes extracted from particle size distribution curves:

- `Q1`: particle size corresponding to 25% cumulative passing;
- `Q2`: particle size corresponding to 50% cumulative passing;
- `Q3`: particle size corresponding to 75% cumulative passing;
- `Bowley`: Bowley’s coefficient of asymmetry.

## Repository structure

```text
hydrocyclone-doe-ai-simple/
├── README.md
├── analysis.R
├── .gitignore
├── data/
│   ├── README.md
│   └── hydrocyclone_attributes_template.csv
└── outputs/
    ├── tables/
    └── figures/
```

## How to use

1. Place the analytical dataset in the `data/` folder.
2. Rename it as:

```text
data/hydrocyclone_attributes.csv
```

3. Open R or RStudio in the repository folder.
4. Run:

```r
source("analysis.R")
```

The results will be saved automatically in the `outputs/` folder.

## Required data format

The input file must contain one row per sample. The expected columns are:

| Column | Description |
|---|---|
| `SAMPLE` | Sample identifier. The name `AMOSTRA` is also accepted. |
| `CONF` | Hydrocyclone configuration. |
| `Pressure` | Feed pressure. |
| `Apex` | Apex dimension. |
| `Solids` | Percentage of solids in the pulp. |
| `Q1` | Particle size corresponding to 25% cumulative passing. |
| `Q2` | Particle size corresponding to 50% cumulative passing. |
| `Q3` | Particle size corresponding to 75% cumulative passing. |
| `Bowley` | Bowley’s coefficient of asymmetry. |

A template file is available at:

```text
data/hydrocyclone_attributes_template.csv
```

## Analysis performed

The script performs the following steps:

1. Reads and prepares the analytical dataset.
2. Calculates descriptive statistics by configuration.
3. Generates mean ± standard deviation plots.
4. Generates plots with individual sample values.
5. Performs one-way ANOVA for Q1, Q2, Q3, and Bowley.
6. Applies Tukey’s multiple comparison test when the ANOVA is significant.
7. Generates residual diagnostic plots.
8. Performs sensitivity analysis by removing samples 1 and 12.
9. Exports tables and figures.

## Main outputs

The script generates:

```text
outputs/tables/descriptive_statistics.csv
outputs/tables/anova_results.csv
outputs/tables/tukey_results.csv
outputs/tables/sensitivity_results.csv
outputs/figures/mean_sd_by_configuration.png
outputs/figures/individual_samples_by_configuration.png
outputs/figures/residuals_Q1.png
outputs/figures/residuals_Q2.png
outputs/figures/residuals_Q3.png
outputs/figures/residuals_Bowley.png
outputs/figures/sensitivity_p_values.png
```

## Methodological note

The current dataset is an initial experimental dataset. It can be used to compare the available configurations and demonstrate the preparation of data for future Artificial Intelligence applications. It should not be interpreted as sufficient for training and validating a definitive AI model or an automatic hydrocyclone control system.
