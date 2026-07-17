# Walker-beta to linearity term analysis ---------------
# This script runs a quantitative comparison of individual relationships
# from a compilation of studies from the literature (Walker et al. 2021).

## Load stuff -------------------
library(dplyr)
library(lme4)
library(lmerTest)
library(ggplot2)
library(viridis)
library(here)
library(readr)

# Manually created based on Table 2 in Walker et al. 2021 (doi:10.1111/nph.16866)
table2_walker <- readr::read_csv(here::here("data-raw/table2_walker2021.csv")) |>
  rename(X95CI_beta = `95CI_beta`) |>
  mutate(SD_beta = X95CI_beta / 1.96)

# View(table2_walker)

# Generic function for bootstrapping combinations
sample_walker <- function(id, df_x, df_y) {

  # independently sample x and y
  i <- sample(dim(df_x)[1], 1)
  j <- sample(dim(df_y)[1], 1)

  x_sample <- rnorm(1, df_x$beta[i], df_x$SD_beta[i])
  y_sample <- rnorm(1, df_y$beta[j], df_y$SD_beta[j])

  out <- tibble(
    id = id,
    x = x_sample,
    y = y_sample,
    ratio = y_sample / x_sample
  )

  return(out)
}

## Cveg-NPP ---------------------------------------------------------------------
# Select data: only from experimentally (controlled) elevated CO2 observations for
# variable that can be interpreted as NPP
df_npp <- table2_walker %>%
  filter(interpret_var %in% c("NPP"), co2 == "eCO2") %>%
  mutate(
    SD_beta = ifelse(
      is.na(SD_beta),
      mean(SD_beta, na.rm = TRUE),
      SD_beta
    )
  )

# View(df_npp)

df_cveg <- table2_walker %>%
  filter(interpret_var == "Cveg", co2 == "eCO2") %>%
  mutate(
    SD_beta = ifelse(
      is.na(SD_beta),
      mean(SD_beta, na.rm = TRUE),
      SD_beta
    )
  )

# View(df_cveg)

set.seed(123)
out_cveg_npp <- purrr::map_dfr(
  as.list(seq(1e5)),
  ~ sample_walker(., df_npp, df_cveg)
)

write_csv(out_cveg_npp, here::here("data/out_bootstrap_cveg_npp.csv"))
# out_cveg_npp <- read_csv(here::here("data/out_bootstrap_cveg_npp.csv"))

gg_scatter_cveg_npp <- out_cveg_npp |>
  ggplot(aes(x, y)) +
  geom_hex(bins = 50, show.legend = FALSE) +
  theme_classic() +
  geom_abline(intercept = 0, slope = 1, linetype = "dotted") +
  geom_hline(yintercept = 0, linetype = "dotted") +
  geom_vline(xintercept = 0, linetype = "dotted") +
  khroma::scale_fill_batlowW(trans = "log", reverse = TRUE) +
  xlim(-1, 2) +
  ylim(-1, 2) +
  labs(
    x = expression(beta[NPP]),
    y = expression(beta[Cveg])
  )

# gg_scatter_cveg_npp

# Lables for Histogram
labels <- out_cveg_npp %>%
  ungroup() %>%
  mutate(l_larger = ratio > 1) %>%
  summarise(
    n_recs = n(),
    perc_larger = round(sum(l_larger, na.rm = TRUE) / n_recs, digits = 3),
    perc_smaller = 1 - perc_larger
  )

gg_hist_cveg_npp <- out_cveg_npp |>
  ggplot(aes(ratio, after_stat(density))) +
  geom_density(fill = "grey70") +
  theme_classic() +
  geom_hline(yintercept = 0, linetype = "dotted") +
  geom_vline(xintercept = 1, linetype = "dotted") +
  xlim(-1, 2.5) +
  geom_text(
    data = labels,
    aes(x = 0.5, y = Inf, label = perc_smaller),
    vjust = 1.5
  ) +
  geom_text(
    data = labels,
    aes(x = 1.5, y = Inf, label = perc_larger),
    vjust = 1.5
  ) +
  labs(
    x = expression(paste(italic(L)[Cveg:NPP]))
  )

# gg_hist_cveg_npp

# Combine density scatter and density distribution plots
gg_cveg_npp <- cowplot::plot_grid(
  gg_scatter_cveg_npp,
  gg_hist_cveg_npp,
  align = 'h', # 'v' for vertical alignment
  axis = 'tb',
  ncol = 2,
  labels = c("a", "b")
)

mystat<-out_cveg_npp%>%
  filter(ratio > -1 & ratio <2.5)%>%
  dplyr::select(ratio)
median(mystat$ratio)

# gg_cveg_star_npp

## GPP-NPP ---------------------------------------------------------------------
df_gpp <- table2_walker %>%
  filter(interpret_var %in% c("GPP"), co2 == "eCO2") %>%
  mutate(
    SD_beta = ifelse(
      is.na(SD_beta),
      mean(SD_beta, na.rm = TRUE),
      SD_beta
    )
  )

View(df_gpp)

# This is empty -- no direct experiments-based estimate of the GPP sensitivity
# Therefore no analysis to be performend.

## Croot:Cveg ---------------------------------------------------------------------
df_cveg <- table2_walker %>%
  filter(interpret_var == "Cveg", co2 == "eCO2") %>%
  mutate(
    SD_beta = ifelse(
      is.na(SD_beta),
      mean(SD_beta, na.rm = TRUE),
      SD_beta
    )
  )

# View(df_cveg)

df_croot <- table2_walker %>%
  filter(interpret_var %in% c(
    "Croot",
    "NPProot"
  ),
  co2 == "eCO2") %>%
  mutate(
    SD_beta = ifelse(
      is.na(SD_beta),
      mean(SD_beta, na.rm = TRUE),
      SD_beta
    )
  )

# View(df_croot)

set.seed(123)
out_croot_cveg <- purrr::map_dfr(
  as.list(seq(1e5)),
  ~ sample_walker(., df_x = df_cveg, df_y = df_croot)
)

write_csv(out_croot_cveg, here::here("data/out_bootstrap_croot_cveg.csv"))
# out_cveg_npp <- read_csv(here::here("data/out_bootstrap_croot_cveg.csv"))


gg_scatter_croot_cveg <- out_croot_cveg |>
  ggplot(aes(x, y)) +
  geom_hex(bins = 50, show.legend = FALSE) +
  theme_classic() +
  geom_abline(intercept = 0, slope = 1, linetype = "dotted") +
  geom_hline(yintercept = 0, linetype = "dotted") +
  geom_vline(xintercept = 0, linetype = "dotted") +
  khroma::scale_fill_batlowW(trans = "log", reverse = TRUE) +
  xlim(-2, 4) +
  ylim(-2, 4) +
  labs(
    x = expression(beta[Cveg]),
    y = expression(beta[Croot])
  )

# gg_scatter_croot_cveg

# Lables for Histogram
labels <- out_croot_cveg %>%
  ungroup() %>%
  mutate(l_larger = ratio > 1) %>%
  summarise(
    n_recs = n(),
    perc_larger = round(sum(l_larger, na.rm = TRUE) / n_recs, digits = 3),
    perc_smaller = 1 - perc_larger
  )

gg_hist_croot_cveg <- out_croot_cveg |>
  ggplot(aes(ratio, after_stat(density))) +
  geom_density(fill = "grey70") +
  theme_classic() +
  geom_hline(yintercept = 0, linetype = "dotted") +
  geom_vline(xintercept = 1, linetype = "dotted") +
  xlim(-1, 2.5) +
  geom_text(
    data = labels,
    aes(x = 0.5, y = Inf, label = perc_smaller),
    vjust = 1.5
  ) +
  geom_text(
    data = labels,
    aes(x = 1.5, y = Inf, label = perc_larger),
    vjust = 1.5
  ) +
  labs(
    x = expression(paste(italic(L)[Croot:Cveg]))
  )

# gg_hist_croot_cveg

mystat <- out_croot_cveg %>%
  filter(ratio > -1 & ratio <2.5) %>%
  dplyr::select(ratio)

median(mystat$ratio)

# Combine density scatter and density distribution plots
gg_croot_cveg <- cowplot::plot_grid(
  gg_scatter_croot_cveg,
  gg_hist_croot_cveg,
  align = 'h', # 'v' for vertical alignment
  axis = 'tb',
  ncol = 2,
  labels = c("c", "d")
)

# gg_croot_cveg

## Cwood:Cveg ---------------------------------------------------------------------
df_cveg <- table2_walker %>%
  filter(
    interpret_var == "Cveg",
    co2 == "eCO2"
  ) %>%
  mutate(
    SD_beta = ifelse(
      is.na(SD_beta),
      mean(SD_beta, na.rm = TRUE),
      SD_beta
    )
  )

# View(df_cveg)

df_cwood <- table2_walker %>%
  filter(
    interpret_var %in% c("Cwood", "Cwood_ag"),
    co2 == "eCO2"
  ) %>%
  mutate(
    SD_beta = ifelse(
      is.na(SD_beta),
      sd(beta, na.rm = TRUE),
      SD_beta
    )
  )

# View(df_cwood)

set.seed(123)
out_cwood_cveg <- purrr::map_dfr(
  as.list(seq(1e5)),
  ~ sample_walker(., df_x = df_cveg, df_y = df_cwood)
)

write_csv(out_cwood_cveg, here::here("data/out_bootstrap_cwood_cveg.csv"))
# out_cveg_npp <- read_csv(here::here("data/out_bootstrap_cwood_cveg.csv"))

gg_scatter_cwood_cveg <- out_cwood_cveg |>
  ggplot(aes(x, y)) +
  geom_hex(bins = 50, show.legend = FALSE) +
  theme_classic() +
  geom_abline(intercept = 0, slope = 1, linetype = "dotted") +
  geom_hline(yintercept = 0, linetype = "dotted") +
  geom_vline(xintercept = 0, linetype = "dotted") +
  khroma::scale_fill_batlowW(trans = "log", reverse = TRUE) +
  xlim(-1, 2) +
  ylim(-1, 2) +
  labs(
    x = expression(beta[Cveg]),
    y = expression(beta[Cwood])
  )

# gg_scatter_cwood_cveg

# Lables for Histogram
labels <- out_cwood_cveg %>%
  ungroup() %>%
  mutate(l_larger = ratio > 1) %>%
  summarise(
    n_recs = n(),
    perc_larger = round(sum(l_larger, na.rm = TRUE) / n_recs, digits = 3),
    perc_smaller = 1 - perc_larger
  )

gg_hist_cwood_cveg <- out_cwood_cveg |>
  ggplot(aes(ratio, after_stat(density))) +
  geom_density(fill = "grey70") +
  theme_classic() +
  geom_hline(yintercept = 0, linetype = "dotted") +
  geom_vline(xintercept = 1, linetype = "dotted") +
  xlim(-1, 2.5) +
  geom_text(
    data = labels,
    aes(x = 0.5, y = Inf, label = perc_smaller),
    vjust = 1.5
  ) +
  geom_text(
    data = labels,
    aes(x = 1.5, y = Inf, label = perc_larger),
    vjust = 1.5
  ) +
  labs(
    x = expression(paste(italic(L)[Cwood:Cveg]))
  )

mystat<-out_cwood_cveg%>%
  filter(ratio > -1 & ratio <2.5)%>%
  dplyr::select(ratio)
median(mystat$ratio)


# gg_hist_cwood_cveg

# Combine density scatter and density distribution plots
gg_wood_cveg <- cowplot::plot_grid(
  gg_scatter_cwood_cveg,
  gg_hist_cwood_cveg,
  align = 'h', # 'v' for vertical alignment
  axis = 'tb',
  ncol = 2,
  labels = c("e", "f")
)



# gg_wood_cveg

## Publication figure -----------------
gg_obs <- cowplot::plot_grid(
  gg_cveg_npp,
  gg_croot_cveg,
  gg_wood_cveg,
  align = 'h', # 'v' for vertical alignment
  axis = 'tb',
  nrow = 3,
  labels = NULL
)

# gg_obs

## Publication Fig. 4

ggsave(
  here("fig/fig4_l_obs.pdf"),
  plot = gg_obs,
  width = 6,
  height = 8
)
ggsave(
  here("fig/fig4_l_obs.jpg"),
  plot = gg_obs,
  width = 6,
  height = 8
)

df_obs_overview <- bind_rows(
  df_npp,
  df_cveg,
  df_cwood,
  df_croot
) |>
  select(
    `Variable (here)` = interpret_var,
    `Variable (W21)` = variable,
    Study = study,
    `Study site` = study_site,
    Species = species,
    beta,
    `CI95(beta)` = X95CI_beta,
    `SD(beta)` = SD_beta
  )

# View(df_obs_overview)

write_csv(
  df_obs_overview,
  file = here("data/df_obs_overview.csv")
)
