# DHW to SST Dashboard

A dashboard to help assist how hot (in terms of sea surface temperature; °C)
ocean water has to get to achieve a specified DHW in the Great Barrier Reef.

As noted by NOAA:

> There is a risk of coral bleaching when the DHW value reaches 4 °C-weeks.
> By the time the DHW value reaches 8 °C-weeks, reef-wide coral bleaching with mortality of
> heat-sensitive corals is likely. If the accumulated heat stress continues to build further
> and exceeds a DHW value of 12 °C-weeks, multi-species mortality becomes likely. At a DHW
> greater than or equal to 16 °C-weeks, there is a risk of severe, multi-species mortality
> (in >50% of corals), and at a DHW greater than or equal to 20 °C-weeks, near complete
> mortality (in >80% of corals) is likely.
\- https://coralreefwatch.noaa.gov/product/5km/index_5km_dhw.php

This dashboard assists in determining how hot (in terms of sea surface temperature;
degrees celcius) ocean water has to get to achieve a specified DHW across the
four management regions of the Great Barrier Reef. The bleaching threshold
methodology as described by NOAA is adopted here.

The baseline reference period is 1985 - 1990 plus 1993. The Maximum of the Monthly Mean
SST climatology is then defined as the warmest of the 12 monthly mean climatology values
for each pixel around the world, indicating the upper limit of "usual" temperature.

The bleaching threshold is determined as +1°C an average historic Maximum Monthly
Mean (MMM) for a particular Regional Virtual Station.

The thresholds for each region are specified in the datasets downloaded from NOAA on
2025-06-12 (18:10 AEDT), available [here](https://coralreefwatch.noaa.gov/product/vs/timeseries/great_barrier_reef.php)

Further detail on the bleaching threshold methodology can be found in the links
below:
- [Methodology](https://coralreefwatch.noaa.gov/product/5km/methodology.php)
- [Time Series](https://coralreefwatch.noaa.gov/product/vs/description.php#graphs)

Bleaching threshold values were taken directly from NOAA datasets published here:
- [GBR datasets](https://coralreefwatch.noaa.gov/product/vs/timeseries/great_barrier_reef.php)
