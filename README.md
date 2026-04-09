# dgvmlin

**Huanyuan Zhang-Zheng and Beni Stocker 2025/08**

This repo contains code for the analysis, diagnosing linearity of the C cycle dynamics from TRENDY v11 model outputs. Analysis code for analyses with TRENDY v8 are ![here](https://github.com/Hzhang-ouce/DGVM_density_plot)

## Important note for reproducing figures

Figures are produced by `vignettes/DGVMLIN_trendy_v11.rmd`

## files explaination

Model outputs from Trendy v11 could not be uploaded due to file size. Model outputs are processed by matlab scripts in  `src ` folder. This will generate model outputs of the first 10 years, named 'INIT_MEAN' or the last 10 years, named 'FINAL_MEAN'. You can find these files in `data` folder. '_CHANGE' files are the annual change in the last 10 years, these are dCveg/dt (Equation 12 in the paper)

The `vignettes/DGVMLIN_trendy_v11.rmd` take in these nc files, and condense them into `gdf.rds` in section **Regrid**. This Regrid section takes several minutes to run, please be patient. `gdf.rds` is too big for github and thus it is noted in .gitignore

The `vignettes/DGVMLIN_trendy_v11.rmd` read these nc files according to `data-raw/*.csv`.

The outputs of `vignettes/DGVMLIN_trendy_v11.rmd` are figures in `fig`, and `data/supplementary_data.csv`. This csv contains all *L* and *R* values mentioned in the paper.

The `vignettes/DGVMLIN_trendy_v11.rmd` needs ancillary functions in folder `R`. Nonetheless, if you install package `rgeco` by `remotes::install_github("geco-bern/rgeco")`, you don't need ancillary functions in folder `R`.   


## for future development - how to add or neglect a link or a model 

Current R codes are written to enable investigation into most of the links (e.g. NPP versus GPP). However, you may wish to add or neglect a link, or to add or neglect a model. 

To neglect a link or model, you are suggested to change the corresponding nc files into fake format e.g. CABLE-POP_cLitter_fake_INIT_MEAN.nc by:  
(1) archive this real file
(2) change the file name into `fake`
(3) replace all the values in this nc file with 0 
(4) change filename in `filnams_trendy_v11_S1.csv` to tell `DGVMLIN_trendy_v11.rmd` to read the fake files
(5) In `DGVMLIN_trendy_v11.rmd`, chapter **Calculate relationships**, you will see that this variable become 0

To add a link or model, simply bring the real file back and change `filnams_trendy_v11_S1.csv` back




