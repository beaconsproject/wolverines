# Summarize key datasets by grids
# PV 2023-01-18

library(sf)
library(dplyr)
library(terra)
library(exactextractr)

setwd('wolverines')
dropbox <- 'C:/Users/PIVER37/Dropbox (BEACONs)/wolverines/data/'

bnd <- st_read('www/wolverines.gpkg', 'bnd')
grid <- st_read('www/wolverines.gpkg', 'grids')
area <- st_read('www/wolverines.gpkg', 'areal_features')
area100 <- st_read('www/wolverines.gpkg', 'areal_features_100m')
area500 <- st_read('www/wolverines.gpkg', 'areal_features_500m')
line <- st_read('www/wolverines.gpkg', 'linear_features')
line100 <- st_read('www/wolverines.gpkg', 'linear_features_100m')
line500 <- st_read('www/wolverines.gpkg', 'linear_features_500m')
thlands <- st_read('www/wolverines.gpkg', 'th_settlement_land')

# Areal disturbances - sum area by grid
xarea <- st_union(area) # necessary to avoid double counting areas of overlap
xarea <- st_intersection(grid, xarea)
xarea <- mutate(xarea, area_m2=st_area(xarea), # recalculate area
    area_pct=round(area_m2/grid_m2*100,2),
    nts=NULL, area_m2=NULL, grid_m2=NULL) %>%
    st_drop_geometry(xarea)

xarea100 <- st_intersection(grid, area100)
xarea100 <- mutate(xarea100, area_m2=st_area(xarea100), # recalculate area
    area100_pct=round(area_m2/grid_m2*100,2),
    nts=NULL, area_m2=NULL, grid_m2=NULL) %>%
    st_drop_geometry(xarea100)

xarea500 <- st_intersection(grid, area500)
xarea500 <- mutate(xarea500, area_m2=st_area(xarea500), # recalculate area
    area500_pct=round(area_m2/grid_m2*100,2),
    nts=NULL, area_m2=NULL, grid_m2=NULL) %>%
    st_drop_geometry(xarea500)

# Linear disturbances sum length (and area for buffers)
xline <- st_union(line)
xline <- st_intersection(grid, xline)
xline <- mutate(xline, 
    line_m=round(st_length(xline),2), # recalculate length
    line_density=round((line_m/1000)/(grid_m2/100000),4), # km/km2
    line_km=units::set_units(line_m,'km'),
    nts=NULL, grid_m2=NULL, line_m=NULL) %>%
    st_drop_geometry(xline)

xline100 <- st_intersection(grid, line100)
xline100 <- mutate(xline100, area_m2=st_area(xline100), # recalculate area
    line100_pct=round(area_m2/grid_m2*100,2),
    nts=NULL, area_m2=NULL, grid_m2=NULL) %>%
    st_drop_geometry(xline100)

xline500 <- st_intersection(grid, line500)
xline500 <- mutate(xline500, area_m2=st_area(xline500), # recalculate area
    line500_pct=round(area_m2/grid_m2*100,2),
    nts=NULL, area_m2=NULL, grid_m2=NULL) %>%
    st_drop_geometry(xline500)

# Areal + linear disturbances - sum area by grid
merge100 <- st_union(area100, line100)
xmerge100 <- st_intersection(grid, merge100)
xmerge100 <- mutate(xmerge100, area_m2=st_area(xmerge100), # recalculate area
    merge100_pct=round(area_m2/grid_m2*100,2),
    nts=NULL, area_m2=NULL, grid_m2=NULL) %>%
    st_drop_geometry(xmerge100)

merge500 <- st_union(area500, line500)
xmerge500 <- st_intersection(grid, merge500)
xmerge500 <- mutate(xmerge500, area_m2=st_area(xmerge500), # recalculate area
    merge500_pct=round(area_m2/grid_m2*100,2),
    nts=NULL, area_m2=NULL, grid_m2=NULL) %>%
    st_drop_geometry(xmerge500)

# Placer claims
pc <- st_read(paste0(dropbox,'yt_placer_claims_50k.gpkg')) %>%
    st_intersection(grid)
pc <- pc %>% mutate(area_m2=st_area(pc)) # calculate area
xpc <- st_drop_geometry(pc) %>%
    group_by(id) %>%
    summarize(area_m2=sum(area_m2),
        grid_m2=mean(grid_m2)) %>%
    mutate(placer_pct=area_m2/grid_m2*100, area_m2=NULL, grid_m2=NULL)

# Quartz claims (has geometry problems)
qc <- st_read(paste0(dropbox,'yt_quartz_claims_50k.gpkg'))
qc <- st_as_sfc(qc) %>%
    lwgeom::lwgeom_make_valid() %>%
    st_as_sf() %>%
    st_intersection(grid)
qc <- qc %>% mutate(area_m2=st_area(qc)) # calculate area
xqc <- st_drop_geometry(qc) %>%
    group_by(id) %>%
    summarize(area_m2=sum(area_m2),
        grid_m2=mean(grid_m2)) %>%
    mutate(quartz_pct=area_m2/grid_m2*100, area_m2=NULL, grid_m2=NULL)

# Recent fires (1980-2021)
fires <- st_read(paste0(dropbox,'yt_fire_history.gpkg')) %>%
    filter(FIRE_YEAR>=1980 & FIRE_YEAR<=2022) %>%
    select(FIRE_ID, FIRE_YEAR)
fires <- st_as_sfc(fires) %>%
    lwgeom::lwgeom_make_valid() %>%
    st_union() %>%
    st_as_sf() %>%
    st_intersection(grid) %>%
    #st_as_sf() %>%
    st_cast("MULTIPOLYGON")
fires <- fires %>% mutate(area_m2=st_area(fires)) # calculate area
xfires <- st_drop_geometry(fires) %>%
    group_by(id) %>%
    summarize(area_m2=sum(area_m2),
        grid_m2=mean(grid_m2)) %>%
    mutate(recent_fires_pct=area_m2/grid_m2*100, area_m2=NULL, grid_m2=NULL)

# Hydrology
streams <- st_read(paste0(dropbox,'Watercourses_50k_Canvec.gdb'), 'Watercourses_50k_Canvec') %>%
    st_intersection(bnd) %>%
    st_buffer(10) %>% 
    st_union()
rivers <-  st_read(paste0(dropbox,'Waterbodies_50k_Canvec.gdb'), 'Waterbodies_50k_Canvec') %>%
    st_intersection(bnd) %>%
    st_buffer(10) %>% 
    st_union()
water <- st_union(streams, rivers) %>%
    st_transform(3578)
water <- st_intersection(grid, water)
water <- water %>% mutate(area_m2=st_area(water)) # calculate area
xwater <- st_drop_geometry(water) %>%
    group_by(id) %>%
    summarize(area_m2=sum(area_m2),
        grid_m2=mean(grid_m2)) %>%
    mutate(water_pct=area_m2/grid_m2*100, area_m2=NULL, grid_m2=NULL)

# Benchmark areas
ba <- st_read(paste0(dropbox,'benchmarks.gpkg'), quiet=T) %>%
        st_intersection(grid)
ba <- mutate(ba, area_m2=st_area(ba))
xba <- st_drop_geometry(ba) %>%
    group_by(id) %>%
    summarize(benchmark_pct=round(sum(area_m2)/sum(grid_m2)*100,1))

# TH settlement lands
lands <- st_union(thlands)
lands <- st_intersection(grid, lands)
lands <- mutate(lands, area_m2=st_area(lands), # recalculate area
    settlements_pct=round(area_m2/grid_m2*100,2),
    nts=NULL, area_m2=NULL, grid_m2=NULL) %>%
    st_drop_geometry(lands)

# Add median elevation
dem <- rast(paste0(dropbox,'dem.tif'))
xdem <- exact_extract(dem, grid, c('min','max','median','stdev'))

# Read landcover and count pixels by grid cell
lcc <- rast(paste0(dropbox,'lcc2019.tif'))
cells_count <- exact_extract(lcc, grid, 'count')

# Add %forest (classes 210, 220, 230)
forest <- classify(lcc, c(0,200,230))
forest_sum <- exact_extract(forest, grid, 'sum')

# Add %wetland (classes 80, 81) = 10415105 (10254071 cells arcmap)
wetland <- classify(lcc, matrix(c(0,79,0, 79,81,1, 81,230,0),ncol=3,byrow=T))
wetland_sum <- exact_extract(wetland, grid, 'sum')

# Create and populate results table
tib <- tibble(id=grid$id,grid_m2=grid$grid_m2)
tib <- left_join(tib, xarea) %>%
    left_join(xarea100) %>%
    left_join(xarea500) %>%
    left_join(xline) %>%
    left_join(xline100) %>%
    left_join(xline500) %>%
    left_join(xmerge100) %>%
    left_join(xmerge500) %>%
    left_join(xpc) %>%
    left_join(xqc) %>%
    left_join(xfires) %>%
    left_join(xwater) %>%
    left_join(xba) %>%
    left_join(lands)
    #mutate(placer_claims_ha = replace_na(placer_claims_ha, units::set_units(0,'ha')),
    #       quartz_claims_ha = replace_na(quartz_claims_ha, units::set_units(0,'ha')),
    #       claims_ha=placer_claims_ha+quartz_claims_ha)
    ##mutate_if(is.numeric, ~replace_na(.,0)) %>%
tib$elev_min <- xdem$min
tib$elev_max <- xdem$max
tib$elev_median <- xdem$median
tib$elev_sd <- xdem$stdev
tib$forest_pct <- round(forest_sum/cells_count*100,1)
tib$wetland_pct <- round(wetland_sum/cells_count*100,1)
tib <- tib %>% mutate(forest_pct=ifelse(forest_pct==0,NA,forest_pct),
                      wetland_pct=ifelse(wetland_pct==0,NA,wetland_pct))
                      #placer_claims_ha=ifelse(placer_claims_ha==0,NA,placer_claims_ha),
                      #quartz_claims_ha=ifelse(quartz_claims_ha==0,NA,quartz_claims_ha),
                      #claims_ha=ifelse(claims_ha==0,NA,claims_ha_pct))

# Join and save
grids <- left_join(grid, tib)
st_write(grids, 'www/wolverines.gpkg', 'survey_factors', delete_layer=T)
