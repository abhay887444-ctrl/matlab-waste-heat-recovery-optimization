# Thermal Analysis and Optimization of an Industrial Waste-Heat Recovery Heat Exchanger

## Project Overview

A MATLAB-based engineering study of heat recovery from a hot exhaust stream to a cold water stream using a counter-current heat exchanger.

The project applies chemical engineering principles to estimate heat recovery, evaluate operating parameters, and investigate design and economic trade-offs.

## Objectives

- Develop a steady-state heat exchanger model using the effectiveness–NTU method.
- Calculate heat duty and hot- and cold-stream outlet temperatures.
- Cross-check predictions using the log mean temperature difference (LMTD) method and energy balances.
- Investigate the effects of heat-transfer area, overall heat-transfer coefficient, and operating conditions.
- Explore fouling effects and uncertainty in model predictions.
- Formulate a constrained heat-exchanger design and illustrative economic analysis.

## Methodology

The model uses the following relationships:

- Heat-capacity rates: `Ch = mh*Cph` and `Cc = mc*Cpc`
- Maximum heat transfer: `Qmax = Cmin*(Th_in - Tc_in)`
- Number of transfer units: `NTU = U*A/Cmin`
- Actual heat transfer: `Q = effectiveness*Qmax`
- Hot outlet temperature: `Th_out = Th_in - Q/Ch`
- Cold outlet temperature: `Tc_out = Tc_in + Q/Cc`

The counter-current effectiveness–NTU relationship is used to estimate heat-exchanger performance.

## Tools and Skills

- MATLAB
- Chemical engineering heat-transfer calculations
- Numerical modeling and validation
- Parametric and sensitivity analysis
- Design optimization
- Fouling and uncertainty analysis

## How to Run

1. Download `main_waste_heat_recovery.m`.
2. Open it in MATLAB.
3. Run the script from the beginning.
4. Review the command-window outputs, generated CSV files, and plots.

No special MATLAB toolbox is intended to be required.

## Assumptions and Limitations

- The model represents steady-state heat-exchanger operation.
- Fluid properties are treated as constant.
- The model uses illustrative parameters rather than measured plant data.
- Fouling and uncertainty ranges are simplified engineering assumptions.
- Economic results depend on assumed operating hours, energy value, capital cost, and maintenance cost.
- Results are model predictions, not experimentally verified industrial performance.

## Results

Add the actual results produced by your MATLAB script here, including baseline heat duty, outlet temperatures, optimization results, and validation checks.

## Future Work

- Compare model predictions with experimental or plant data.
- Improve the model using temperature-dependent properties and pressure-drop calculations.
- Investigate more realistic fouling behavior and economic assumptions.

## Author

Chemical Engineering student interested in process modeling, heat transfer, energy efficiency, and optimization.
