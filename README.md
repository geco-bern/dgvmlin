# Read this to understand this repo

**Huanyuan Zhang-Zheng 2024/06/19**

This repo is prepared for linearity diagnose project. This is for TRENDY v11 only. Old Trendy simulations are ![here](https://github.com/Hzhang-ouce/DGVM_density_plot)

## Important note for reproducing figures

If you just want to reproduce figures, please don't read the nc files again. We have created `gdf_Trendyv11_202406.rda` which is a variable immediately ready for figures making. Just load this one into R, then go to **Plot relationships** chapter of `DGVMLIN_trendy_v11.rmd`

## Important note for future development

Current R codes are written to enable investigation into most of the links (e.g. NPP versus GPP). However, you may wish to add or neglect a link, or to add or neglect a model. 

To neglect a link or model, you are suggested to change the corresponding nc files into fake format e.g. CABLE-POP_cLitter_fake_INIT_MEAN.nc by:  
(1) archive this real file
(2) change the file name into `fake`
(3) replace all the values in this nc file with 0 
(4) change filename in `filnams_trendy_v11_S1.csv` to tell `DGVMLIN_trendy_v11.rmd` to read the fake files
(5) In `DGVMLIN_trendy_v11.rmd`, chapter **Calculate relationships**, you will see that this variable become 0

To add a link or model, simply bring the real file back and change `filnams_trendy_v11_S1.csv` back



