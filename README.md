# Robust analysis of diel activity patterns

### [Neil A. Gilbert](https://gilbertecology.com), [Davide M. Dominoni](https://www.davidedominoni.com/)

This paper is a Research Highlight covering [Iannarilli et al. (2024), *A 'how-to' guide for estimating animal diel activity using hierarchical models*](https://besjournals.onlinelibrary.wiley.com/doi/full/10.1111/1365-2656.14213). 
__________________________________________________________________________________________________________________________________________

## Abstract
Diel activity patterns are ubiquitous in living organisms and have received considerable research attention with advances in the collection of time-stamped data and the recognition that organisms may respond to global change via behavior timing. Iannarilli et al. (2024) provide a roadmap for analyzing diel activity patterns with hierarchical models, specifically trigonometric generalized linear mixed-effect models and cyclic cubic spline generalized additive models. These methods are improvements over kernel density estimators, which for nearly two decades have been the status quo for analyzing activity patterns. Kernel density estimators have several drawbacks; most notably, data are typically aggregated (e.g., across locations) to achieve sufficient sample sizes, and covariates cannot be incorporated to quantify the influence of environmental variables on activity timing. Iannarilli et al. (2024) also provide a comprehensive tutorial which demonstrates how to format data, fit models, and interpret model predictions. We believe that hierarchical models will become indispensable tools for activity-timing research and envision the development of many extensions to the approaches described by Iannarilli et al. (2024).

![woth_activity_pattern](https://github.com/user-attachments/assets/08b4518c-7c7a-4630-b4b5-3f22d302f184)

## Repository Directory

### [code](./code) 
* [woth_analysis.R](./code/woth_analysis.R) Code to fit trigonometric GLMM to Wood Thrush vocal data from [BirdWeather](https://www.birdweather.com/)

### [data](./data)
* [woth.csv](./data/woth.csv) Wood Thrush data from BirdWeather. Relevant columns include "timestamp", "latitude", and "longitude"
* [woth_sites_alan.csv](./data/woth_sites_alan.csv) Artificial light at night for station coordinates (from NASA VIIRS, extracted from Google Earth Engine)
* [woth_sites.csv](./data/woth_sites.csv) Unique station coordinates (used to extract VIIRS data from Google Earth Engine)

### [results](./results)
* [woth_activity_pattern.png](./results/woth_activity_pattern.png) Marginal effects plot showing predicted activity pattern for Wood Thrush
* [woth_m1_data.RData](./results/woth_m1_data.RData) Object containing fitted model and finalized data table used to fit model  
