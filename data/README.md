# Data folder

Place the analytical dataset in this folder using the following name:

```text
hydrocyclone_attributes.csv
```

The file must contain one row per sample and the following columns:

```text
SAMPLE,CONF,Pressure,Apex,Solids,Q1,Q2,Q3,Bowley
```

If the sample identifier column is named `AMOSTRA`, the script will rename it automatically to `SAMPLE`.

The file `hydrocyclone_attributes_template.csv` contains only the expected header and can be used as a template.
