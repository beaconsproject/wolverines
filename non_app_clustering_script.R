library(sf)
library(dplyr)

factors_unconstrained = st_read("www/wolverines.gpkg", "survey_factors", quiet=T)
names <- colnames(factors_unconstrained)
factors = st_read('www/wolverines.gpkg', 'survey_factors_constrained', quiet = T)
colnames(factors) <- names
# value to split between low/medium and high disturbance
split <- 30

# number of cells to sample from each disturbance group
n.sample.1 <- 40
n.sample.2 <- 60
n.sample.3 <- 40

## Change NAs to 0
factors <- factors %>% 
  mutate(
        placer_pct=ifelse(is.na(placer_pct),0,placer_pct),
        quartz_pct=ifelse(is.na(quartz_pct),0,quartz_pct),
        recent_fires_pct=ifelse(is.na(recent_fires_pct),0,recent_fires_pct),
        area500_pct=ifelse(is.na(area500_pct),0,area500_pct),
        line500_pct=ifelse(is.na(line500_pct),0,line500_pct),
        merge100_pct=ifelse(is.na(merge100_pct),0,merge100_pct),
        water_pct=ifelse(is.na(water_pct),0,water_pct),
        forest_pct=ifelse(is.na(forest_pct),0,forest_pct),
        wetland_pct=ifelse(is.na(wetland_pct),0,wetland_pct)
      )

## Split factors into 1) merge100_pct == 0, 2) 0 < merge100_pct <= 30, 
## 3) merge100_pct > 30
factors <- factors %>% 
  mutate(cluster = ifelse(test = merge100_pct == 0, yes = 1,
                          no = ifelse(test = merge100_pct > 0 & 
                                        merge100_pct <= split, 
                                      yes = 2, no = 3)))

simple3 <- factors %>%
  filter(cluster == 3)

# elev.mean <- mean(simple3$elev_median)
# elev.sd <- sd(simple3$elev_median)
# 
# wetland.median <- mean(simple3$wetland_pct)
# wetland.sd <- sd(simple3$wetland_pct)

# fire.min <- quantile(simple3$recent_fires_pct)[2]
fire.min <- 0
# fire.max <- quantile(simple3$recent_fires_pct)[4]
fire.max <- 47

simple1.all <- factors %>%
  dplyr::filter(cluster == 1) %>%
  dplyr::filter(
    # elev_median > (elev.mean - elev.sd),
    # elev_median < (elev.mean + elev.sd),
    # wetland_pct > (wetland.median - wetland.sd),
    # wetland_pct < (wetland.median + wetland.sd),
    recent_fires_pct >= fire.min,
    recent_fires_pct <= fire.max
  ) 
simple1 <- simple1.all %>%
  slice_sample(n = 40)


simple2.all <- factors %>%
  dplyr::filter(cluster == 2) %>%
  dplyr::filter(
    # elev_median > (elev.mean - elev.sd),
    # elev_median < (elev.mean + elev.sd),
    # wetland_pct > (wetland.median - wetland.sd),
    # wetland_pct < (wetland.median + wetland.sd),
    recent_fires_pct >= fire.min,
    recent_fires_pct <= (fire.max)
  ) 
simple2 <- simple2.all %>%
  dplyr::slice_sample(n = 60)

quantile(simple1.all$recent_fires_pct)
quantile(simple2.all$recent_fires_pct)
quantile(simple3$recent_fires_pct)

means.table <- tibble(elev.median = c(mean(simple1.all$elev_median), mean(simple1$elev_median), 
                                      mean(simple2.all$elev_median), mean(simple2$elev_median),
                                      mean(simple3$elev_median)),
                      elev.sd = c(mean(simple1.all$elev_sd), mean(simple1$elev_sd), 
                                  mean(simple2.all$elev_sd), mean(simple2$elev_sd), 
                                  mean(simple3$elev_sd)),
                      fires.mean = c(mean(simple1.all$recent_fires_pct), mean(simple1$recent_fires_pct), 
                                     mean(simple2.all$recent_fires_pct), 
                                     mean(simple2$recent_fires_pct), mean(simple3$recent_fires_pct)),
                      fires.sd = c(sd(simple1.all$recent_fires_pct), sd(simple1$recent_fires_pct), 
                                   sd(simple2.all$recent_fires_pct), 
                                   sd(simple2$recent_fires_pct), sd(simple3$recent_fires_pct)),
                      wetlands = c(mean(simple1.all$wetland_pct), mean(simple1$wetland_pct), 
                                   mean(simple2.all$wetland_pct),
                                   mean(simple2$wetland_pct), mean(simple3$wetland_pct)))

labels <- c('simple1.all', 'simple1', 'simple2.all', 'simple2', 'simple3')

cbind(labels, means.table)

means.table

hist(simple1$recent_fires_pct)

cluster1 <- simple1 %>%
  mutate(cluster = as.character(cluster))
cluster2a <- simple2[1:30,] %>% 
  mutate(cluster = '2a')
cluster2b <- simple2[31:60,] %>%
  mutate(cluster = '2b')
cluster3 <- simple3 %>%
  mutate(cluster = as.character(cluster))

## Compare similarity of each randomly selected set to the full distribution
ks_output <-
  tibble(
    merge100_pct = ks.test(factors$merge100_pct, simple$merge100_pct)[[1]],
    #merge500_pct = ks.test(factors$merge500_pct, simple$merge500_pct)[[1]],
    placer_pct = ks.test(factors$placer_pct, simple$placer_pct)[[1]],
    quartz_pct = ks.test(factors$quartz_pct, simple$quartz_pct)[[1]],
    recent_fires_pct = ks.test(factors$recent_fires_pct, simple$recent_fires_pct)[[1]],
    benchmark_pct = ks.test(factors$benchmark_pct, simple$benchmark_pct)[[1]],
    elev_median = ks.test(factors$elev_median, simple$elev_median)[[1]],
    elev_sd = ks.test(factors$elev_sd, simple$elev_sd)[[1]],
    forest_pct = ks.test(factors$forest_pct, simple$forest_pct)[[1]],
    wetland_pct = ks.test(factors$wetland_pct, simple$wetland_pct)[[1]],
    water_pct = ks.test(factors$water_pct, simple$water_pct)[[1]]
  )

## Compare similarity of each randomly selected set to the other 2 clusters 
## i.e. Compare merge100_pct == 0 to merge100_pct > 0 & <= 30 and merge100_pct > 30
#simple12 <- simple %>%
#  filter(cluster %in% c(1,2))
#simple23 <- simple %>% 
#  filter(cluster %in% c(2,3))
#simple13 <- simple %>% 
#  filter(cluster %in% c(1,3))

ks_output_clust1 <- 
  tibble(
    merge100_pct = ks.test(factors$merge100_pct, simple1$merge100_pct)[[1]],
    #merge500_pct = ks.test(factors$merge500_pct, simple1$merge500_pct)[[1]],
    placer_pct = ks.test(factors$placer_pct, simple1$placer_pct)[[1]],
    quartz_pct = ks.test(factors$quartz_pct, simple1$quartz_pct)[[1]],
    recent_fires_pct = ks.test(factors$recent_fires_pct, simple1$recent_fires_pct)[[1]],
    benchmark_pct = ks.test(factors$benchmark_pct, simple1$benchmark_pct)[[1]],
    elev_median = ks.test(factors$elev_median, simple1$elev_median)[[1]],
    elev_sd = ks.test(factors$elev_sd, simple1$elev_sd)[[1]],
    forest_pct = ks.test(factors$forest_pct, simple1$forest_pct)[[1]],
    wetland_pct = ks.test(factors$wetland_pct, simple1$wetland_pct)[[1]],
    water_pct = ks.test(factors$water_pct, simple1$water_pct)[[1]]
  )

ks_output_clust2 <- 
  tibble(
    merge100_pct = ks.test(factors$merge100_pct, simple2$merge100_pct)[[1]],
    #merge500_pct = ks.test(factors$merge500_pct, simple2$merge500_pct)[[1]],
    placer_pct = ks.test(factors$placer_pct, simple2$placer_pct)[[1]],
    quartz_pct = ks.test(factors$quartz_pct, simple2$quartz_pct)[[1]],
    recent_fires_pct = ks.test(factors$recent_fires_pct, simple2$recent_fires_pct)[[1]],
    benchmark_pct = ks.test(factors$benchmark_pct, simple2$benchmark_pct)[[1]],
    elev_median = ks.test(factors$elev_median, simple2$elev_median)[[1]],
    elev_sd = ks.test(factors$elev_sd, simple2$elev_sd)[[1]],
    forest_pct = ks.test(factors$forest_pct, simple2$forest_pct)[[1]],
    wetland_pct = ks.test(factors$wetland_pct, simple2$wetland_pct)[[1]],
    water_pct = ks.test(factors$water_pct, simple2$water_pct)[[1]]
  )

ks_output_clust3 <- 
  tibble(
    merge100_pct = ks.test(factors$merge100_pct, simple3$merge100_pct)[[1]],
    #merge500_pct = ks.test(factors$merge500_pct, simple3$merge500_pct)[[1]],
    placer_pct = ks.test(factors$placer_pct, simple3$placer_pct)[[1]],
    quartz_pct = ks.test(factors$quartz_pct, simple3$quartz_pct)[[1]],
    recent_fires_pct = ks.test(factors$recent_fires_pct, simple3$recent_fires_pct)[[1]],
    benchmark_pct = ks.test(factors$benchmark_pct, simple3$benchmark_pct)[[1]],
    elev_median = ks.test(factors$elev_median, simple3$elev_median)[[1]],
    elev_sd = ks.test(factors$elev_sd, simple3$elev_sd)[[1]],
    forest_pct = ks.test(factors$forest_pct, simple3$forest_pct)[[1]],
    wetland_pct = ks.test(factors$wetland_pct, simple3$wetland_pct)[[1]],
    water_pct = ks.test(factors$water_pct, simple3$water_pct)[[1]]
  )

labels <- tibble(ks_test=c('Full_sample vs All_cells', 'Clust1_sample vs All_cells', 
    'Clust2_sample vs All_cells', 'Clust3_sample vs All_cells'))
ks_tests <- bind_rows(ks_output, ks_output_clust1, ks_output_clust2, ks_output_clust3)
ks_tests <- bind_cols(labels, ks_tests)
print(ks_tests)
