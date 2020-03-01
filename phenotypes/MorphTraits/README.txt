This folder contains the raw files and output for several mophological and physiological traits for 350+ rice acccessions in drought and control conditions. The plants were imaged over a period of 20 days during the early seedling stage. At day 0, all plants were watered to feild capacity, in subsequent days water was witheld from the drought plants. The control plants were maintained at 100% feild capacity. Water was added to each pot daily to reach a chosen target weight. The experiment was repeated three times, and 1-2 replicates were included in each experiment. So in total a subset of the population should have 4 replicates in each condition (Control and LowWater). The experiments were spread across two greenhouses (smarthouses). Each smarthouse has 24 lanes, and each lane has 22(?) positions (i.e. holds 22 pots). 

Outliers_Raw.pdf: Plots of the plants flagged as outliers. The snapshot ID is included in the title and can be used as a unique plant identifier.

IdList.csv: Associates the UNL.IDs to NSFTV.IDs. NSFTV.ID is necessary for associating the accessions with the SNP data.

AllExpAllTraits.csv: Raw data for all metrixs used to derive the morphological descriptors

AllExp_MorphTraits_RAW.csv: Raw data for the morphological traits.

WUE.WU_cleaned.csv: Cleaned data set for water use and water use efficiency. The code used to generate these traits are not included in the folder. 

AllExp_WUE_Morph.csv: Morpholgical and physiological traits with outliers removed.
A description of each column in the final output file "AllExp_WUE_Morph.csv" is provided below.

Exp: Experiment (3 levels)

NSFTV.ID: Accession ID; used to associated the accession/genotype with SNP data (350+ levels)

Replicate: self explainatory (1-2 levels)

DayOfImaging: self explainatory (20 levels) 

Watering.Regime: Treatment (Control or LowWater)

Snapshot.ID.Tag: Unique pot identifier 

Smarthouse Lane: See above

Position: Pot position in the lane

Weight.Before: Weight of the pot before the addition of water.

Weight.After: Weight of the pot after the addition of water.

Water.Amount: Weight.After - Weight.Before

Density: Used as a measure of the canopy density. It is the ratio of the plants convex hull area from the top view to the total number of pixels from the top view.

GH2: Growth Habit 2; describes whether the growth pattern is upright or prostrate. Ratio of the convex hull area of the top view image and the distance from the top of the pot to the mean of the tallest plant pixel in the side view images. Larger values should represent a wider plant.

Projected.Shoot.Area: PSA; measure of shoot biomass, the sum of plant pixels from all three images (two side view images and one top view)

RGB_.Height: Mean of the distance from the top of the pot to the tallest plant pixel in the side view images

RGB_TV.Area: Pkant pixels from the top view image

RGB_TV.Convex.Hull.Area: The area of the convex hull from the top view image. The convex hull is the smallest  shape that includes all points of an object.

WU: Water use. The difference in Weight.After at time t-1 and Weight.Before at time t

WUE: The ratio of PSA to WU