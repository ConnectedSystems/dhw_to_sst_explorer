"""
Tool to determine how hot (in terms of sea surface temperature; degrees celcius)
ocean water has to get to achieve a specified DHW in the Great Barrier Reef.

As noted by NOAA:

"There is a risk of coral bleaching when the DHW value reaches 4 °C-weeks.
By the time the DHW value reaches 8 °C-weeks, reef-wide coral bleaching with mortality of
heat-sensitive corals is likely. If the accumulated heat stress continues to build further
and exceeds a DHW value of 12 °C-weeks, multi-species mortality becomes likely. At a DHW
greater than or equal to 16 °C-weeks, there is a risk of severe, multi-species mortality
(in >50% of corals), and at a DHW greater than or equal to 20 °C-weeks, near complete
mortality (in >80% of corals) is likely."
https://coralreefwatch.noaa.gov/product/5km/index_5km_dhw.php

Bleaching threshold is determined as +1 degree from the average Maximum Monthly Mean.
https://coralreefwatch.noaa.gov/product/vs/description.php#graphs

The baseline reference period is 1985 - 1990 plus 1993. The Maximum of the Monthly Mean
SST climatology is then defined as the warmest of the 12 monthly mean climatology values
for each pixel around the world, indicating the upper limit of "usual" temperature.
https://coralreefwatch.noaa.gov/product/5km/methodology.php

These are specified in the data files (in the `data` directory) downloaded from
NOAA on 2025-06-12 (18:10 AEDT)

https://coralreefwatch.noaa.gov/product/vs/timeseries/great_barrier_reef.php
"""

using WGLMakie
using Bonito, Bonito.Observables
using Statistics
import GeoDataFrames as GDF

import Bonito.TailwindDashboard as D

# DHW to SST conversion constants
const MMM_THRESHOLDS = (
    gbr_farnorth=28.7694,
    gbr_north=28.7041,
    gbr_central=28.3422,
    gbr_south=27.6570
)

const REGION_NAMES = ["Far North", "North", "Central", "South"]

"""
    estimate_sst_exceedance(dhw::Real)

Calculate SST exceedance above bleaching threshold for 4, 8, and 12 week periods.
"""
function estimate_sst_exceedance(dhw::Real)
    return round.(dhw ./ [4, 8, 12]; digits=2)
end

"""
    estimate_exceedance_value(dhw::Real)

Calculates a 4x3 matrix, where rows are the four regions (north to south)
and columns are 12, 8, 4 week estimates.
"""
function estimate_exceedance_value(dhw::Real)
    tmp = zeros(4, 3)
    for (i, threshold) in enumerate(MMM_THRESHOLDS)
        tmp[i, :] = reverse(threshold .+ estimate_sst_exceedance(dhw))
    end
    return tmp
end

function load_spatial_data()
    spatial_loc = "data/spatial/GDA-2020/Great_Barrier_Reef_Marine_Park_Management_Areas_20_1685154518472315942.gpkg"
    management_areas = GDF.read(spatial_loc)
    lat_order = sortperm(GDF.centroid.(management_areas.SHAPE); rev=true, by=x -> x[2])
    return management_areas[lat_order, :]
end

"""
    region_offset()

Defines region offsets for text display.
Manually defined here to allow for quick adjustment.
"""
function region_offset()
    return ((150, 0), (150, 0), (-90, -10), (-100, -10))
end

"""
    plot_region_map!(ax, management_areas, centroids, exceedance_matrix, offsets)

Plot management area polygons and SST value labels for all three accumulation periods on a single map.
exceedance_matrix should be 4x3 where columns are [12 week, 8 week, 4 week].
"""
function plot_region_map!(ax, management_areas, centroids, exceedance_matrix, offsets)
    poly!(
        ax,
        management_areas.SHAPE;
        color=:transparent,
        strokecolor=:black,
        strokewidth=2
    )

    # Add text labels with all three periods
    for i in axes(exceedance_matrix, 1)
        label_text = string(
            "12 weeks: ", round(exceedance_matrix[i, 1]; digits=1), "°C\n",
            "8 weeks: ", round(exceedance_matrix[i, 2]; digits=1), "°C\n",
            "4 weeks: ", round(exceedance_matrix[i, 3]; digits=1), "°C\n",
            "Threshold: ", round(MMM_THRESHOLDS[i]; digits=1), "°C"
        )

        text!(
            ax, centroids[i];
            text=label_text,
            align=(:right, :center),
            fontsize=14,
            color=:black,
            offset=offsets[i]
        )
    end
end

"""
    update_map!(ax, management_areas, centroids, exceedance_matrix, offsets)

Update the map axis with new exceedance values.
"""
function update_map!(ax, management_areas, centroids, exceedance_matrix, offsets)
    empty!(ax)
    return plot_region_map!(ax, management_areas, centroids, exceedance_matrix, offsets)
end

function create_dashboard()
    # Add CSS (create this file based on db_display.css)
    # styling = Bonito.Asset(joinpath(@__DIR__, "dhw_display.css"))

    # Load spatial data
    @debug "Loading spatial data..."
    management_areas = load_spatial_data()

    # Create the app
    app = App(; title="DHW to SST") do
        # Create DHW textbox with validation
        dhw_input = TextField(
            "20.0";
            label="Target DHW"
        )

        # Observable to track validation state
        dhw_valid = Observable(true)
        dhw_value = Observable(20.0)

        # Validate input on change
        on(dhw_input.value) do input_str
            try
                val = parse(Float64, input_str)
                dhw_value[] = val
                dhw_valid[] = true
            catch
                dhw_valid[] = false
            end
        end

        # Create update button
        update_button = Button("Update")

        # Initialize calculations
        initial_dhw = dhw_value[]
        exceedance_matrix = estimate_exceedance_value(initial_dhw)

        # Create figure for visualization
        fig = Figure(; size=(800, 600))

        # Create single map plot
        ax_map = Axis(
            fig[1, 1];
            title="SST Accumulation by Region",
            aspect=DataAspect(),
            alignmode=Outside(5)
        )

        # Disable all interactions
        deregister_interaction!(ax_map, :dragpan)
        deregister_interaction!(ax_map, :scrollzoom)
        deregister_interaction!(ax_map, :rectanglezoom)
        deregister_interaction!(ax_map, :limitreset)

        # Calculate centroids and offsets once
        centroids = GDF.centroid.(management_areas.SHAPE)
        offsets = region_offset()

        # Initial plot
        plot_region_map!(ax_map, management_areas, centroids, exceedance_matrix, offsets)

        # Update display when button is clicked
        on(update_button.value) do click
            @debug "Updating plots..."

            # Only update if input is valid
            if !dhw_valid[]
                @warn "Invalid DHW value - skipping update"
                return nothing
            end

            new_matrix = estimate_exceedance_value(dhw_value[])
            update_map!(ax_map, management_areas, centroids, new_matrix, offsets)

            @debug "Plots updated!"
        end

        explanation_text = """
        This dashboard assists in determining how hot in terms of sea surface temperature
        (in °C) ocean water has to get to achieve a specified DHW across the four management
        regions of the Great Barrier Reef. The bleaching threshold methodology as described
        by NOAA is adopted here. The threshold is determined as +1°C an average historic
        Maximum Monthly Mean (MMM) for each Regional Virtual Station. The reference period
        used to determine the historic MMM is 1985 - 1990, plus 1993.

        Reported annual Maximum DHWs use a 12-week rolling mean. For the target DHW to be
        reached, the indicated temperature must be consistently maintained for any 12-week
        period over the year.

        DHW at 4 and 8°C-weeks are also reported as they correspond to ecological
        thresholds:

        - At 4°C-weeks, widespread bleaching becomes observable.
        - At 8°C-weeks, significant coral mortality begins and recovery is much less likely.

        Further detail on the methodology can be found in the links below:

        - [Methodology](https://coralreefwatch.noaa.gov/product/5km/methodology.php)
        - [Time Series](https://coralreefwatch.noaa.gov/product/vs/description.php#graphs)

        Bleaching threshold values were taken directly from NOAA datasets published here:
        - [GBR datasets](https://coralreefwatch.noaa.gov/product/vs/timeseries/great_barrier_reef.php)
        """

        # Build DOM structure
        return DOM.div(
            # styling,
            DOM.div(
                DOM.div(
                    DOM.h3("Sea Temperature to DHW"),
                    DOM.div(
                        DOM.label("Target DHW:"; class="control-label"),
                        DOM.div(
                            dhw_input;
                            style=map(
                                valid -> valid ? "" : "border: 2px solid red;",
                                dhw_valid
                            )
                        )
                    ),
                    DOM.div(update_button),
                    DOM.div(
                        DOM.h4("Explanation"),
                        DOM.label(Bonito.string_to_markdown(explanation_text))
                    );
                    class="controls-panel",
                    style="width: 300px; padding: 20px;"
                ),
                DOM.div(
                    DOM.div(fig; class="plots-container");
                    class="plots-panel",
                    style="flex: 1."
                );
                class="dashboard-container",
                style="display: flex; flex-direction: row;"
            )
        )
    end

    return app
end

# Run the dashboard
app = create_dashboard()

# port = 8080
# url = "0.0.0.0"
# server = Bonito.Server(app, url, port)
