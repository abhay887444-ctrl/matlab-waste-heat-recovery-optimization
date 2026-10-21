
clc;
clear;
close all;

%% PROJECT: INDUSTRIAL WASTE-HEAT RECOVERY
% Method 1: Effectiveness-NTU
% Method 2: Independent LMTD validation
% Parametric analysis and heat exchanger sizing

%% 1. INPUT PARAMETERS

Th_in = 250;       % Hot inlet temperature (deg C)
Tc_in = 25;        % Cold inlet temperature (deg C)

mh = 0.5;          % Hot mass flow rate (kg/s)
mc = 0.3;          % Cold mass flow rate (kg/s)

Cph = 1050;        % Hot specific heat (J/kg K)
Cpc = 4180;        % Cold specific heat (J/kg K)

U = 100;           % Overall heat transfer coefficient (W/m^2 K)
A = 10;            % Heat transfer area (m^2)

%% 2. BASELINE MODEL

base = solveHX(Th_in,Tc_in,mh,mc,Cph,Cpc,U,A);

fprintf('\n===== BASELINE RESULTS =====\n');
fprintf('Hot capacity rate = %.2f W/K\n',base.Ch);
fprintf('Cold capacity rate = %.2f W/K\n',base.Cc);
fprintf('Capacity ratio Cr = %.5f\n',base.Cr);
fprintf('NTU = %.5f\n',base.NTU);
fprintf('Effectiveness = %.5f\n',base.epsilon);
fprintf('Maximum heat transfer = %.4f kW\n',base.Qmax/1000);
fprintf('Heat recovered = %.4f kW\n',base.Q/1000);
fprintf('Hot outlet temperature = %.4f C\n',base.Th_out);
fprintf('Cold outlet temperature = %.4f C\n',base.Tc_out);
fprintf('LMTD = %.4f C\n',base.DTlm);

%% 3. INDEPENDENT LMTD VALIDATION

% Solve Q = U*A*LMTD(Q) using fzero.
Q_LMTD = fzero(@(q) lmtdResidual(q,Th_in,Tc_in, ...
                  base.Ch,base.Cc,U,A), ...
                  [0,base.Qmax*(1-1e-8)]);

Th_LMTD = Th_in-Q_LMTD/base.Ch;
Tc_LMTD = Tc_in+Q_LMTD/base.Cc;

Q_hot = base.Ch*(Th_in-Th_LMTD);
Q_cold = base.Cc*(Tc_LMTD-Tc_in);

DT1 = Th_in-Tc_LMTD;
DT2 = Th_LMTD-Tc_in;
DTlm = calculateLMTD(DT1,DT2);

fprintf('\n===== LMTD VALIDATION =====\n');
fprintf('NTU heat duty = %.6f kW\n',base.Q/1000);
fprintf('LMTD heat duty = %.6f kW\n',Q_LMTD/1000);
fprintf('Hot-side heat loss = %.6f kW\n',Q_hot/1000);
fprintf('Cold-side heat gain = %.6f kW\n',Q_cold/1000);
fprintf('UA*LMTD = %.6f kW\n',U*A*DTlm/1000);
fprintf('Method difference = %.8f W\n',abs(base.Q-Q_LMTD));
fprintf('Energy balance error = %.8f W\n',abs(Q_hot-Q_cold));

%% 4. STUDY A: EFFECT OF HEAT TRANSFER AREA

areaValues = 1:1:30;
nA = length(areaValues);

Q_area = zeros(nA,1);
Th_area = zeros(nA,1);
Tc_area = zeros(nA,1);

for i = 1:nA
    result = solveHX(Th_in,Tc_in,mh,mc,Cph,Cpc, ...
                     U,areaValues(i));

    Q_area(i) = result.Q/1000;
    Th_area(i) = result.Th_out;
    Tc_area(i) = result.Tc_out;
end

figure;
plot(areaValues,Q_area,'o-','LineWidth',1.5);
xlabel('Heat transfer area (m^2)');
ylabel('Heat recovered (kW)');
title('Heat Recovery vs Heat Exchanger Area');
grid on;
saveas(gcf,'plot_1_heat_duty_vs_area.png');

%% 5. STUDY B: EFFECT OF COLD STREAM FLOW RATE

mcValues = 0.10:0.05:0.80;
nM = length(mcValues);

Q_flow = zeros(nM,1);
Tc_flow = zeros(nM,1);
Th_flow = zeros(nM,1);

for i = 1:nM
    result = solveHX(Th_in,Tc_in,mh,mcValues(i), ...
                     Cph,Cpc,U,A);

    Q_flow(i) = result.Q/1000;
    Tc_flow(i) = result.Tc_out;
    Th_flow(i) = result.Th_out;
end

figure;
plot(mcValues,Q_flow,'s-','LineWidth',1.5);
xlabel('Cold stream mass flow rate (kg/s)');
ylabel('Heat recovered (kW)');
title('Heat Recovery vs Cold Stream Flow Rate');
grid on;
saveas(gcf,'plot_2_heat_duty_vs_cold_flow.png');

%% 6. STUDY C: OUTLET TEMPERATURES VS AREA

figure;
plot(areaValues,Th_area,'o-','LineWidth',1.5);
hold on;
plot(areaValues,Tc_area,'s-','LineWidth',1.5);
xlabel('Heat transfer area (m^2)');
ylabel('Outlet temperature (deg C)');
title('Outlet Temperatures vs Heat Exchanger Area');
legend('Hot outlet','Cold outlet','Location','best');
grid on;
hold off;
saveas(gcf,'plot_3_outlet_temperatures.png');

%% 7. STUDY D: AREA REQUIRED FOR A TARGET COLD OUTLET

targetTc = (40:5:90)';
nT = length(targetTc);

Q_target = zeros(nT,1);
areaRequired = zeros(nT,1);
lmtdTarget = zeros(nT,1);

for i = 1:nT

    % Heat duty needed to reach target temperature
    Q_target(i) = base.Cc*(targetTc(i)-Tc_in);

    % Calculate corresponding hot outlet temperature
    Th_target = Th_in-Q_target(i)/base.Ch;

    % Counter-current terminal temperature differences
    dT1 = Th_in-targetTc(i);
    dT2 = Th_target-Tc_in;

    if dT1 <= 0 || dT2 <= 0 || Q_target(i) >= base.Qmax
        error('Infeasible target outlet temperature.');
    end

    lmtdTarget(i) = calculateLMTD(dT1,dT2);

    % Required area for the target
    areaRequired(i) = Q_target(i)/(U*lmtdTarget(i));
end

figure;
plot(targetTc,areaRequired,'d-','LineWidth',1.5);
xlabel('Target cold outlet temperature (deg C)');
ylabel('Required area (m^2)');
title('Heat Exchanger Sizing for Target Outlet Temperature');
grid on;
saveas(gcf,'plot_4_area_vs_target_temperature.png');

%% 8. EXPORT PARAMETRIC RESULTS

Results = table(areaValues',Q_area,Th_area,Tc_area, ...
    'VariableNames',{'Area_m2','HeatDuty_kW', ...
    'HotOutlet_C','ColdOutlet_C'});

writetable(Results,'parametric_results.csv');

TargetResults = table(targetTc,Q_target/1000, ...
    lmtdTarget,areaRequired, ...
    'VariableNames',{'TargetColdOutlet_C', ...
    'HeatDuty_kW','LMTD_C','RequiredArea_m2'});

writetable(TargetResults,'target_temperature_sizing.csv');

fprintf('\n===== PROJECT COMPLETE =====\n');
fprintf('Plots and CSV files saved in the current folder.\n');

%% LOCAL FUNCTIONS

function r = solveHX(Thi,Tci,mh,mc,Cph,Cpc,U,A)

    Ch = mh*Cph;
    Cc = mc*Cpc;

    Cmin = min(Ch,Cc);
    Cmax = max(Ch,Cc);

    Cr = Cmin/Cmax;
    NTU = U*A/Cmin;

    if abs(1-Cr) < 1e-10
        epsilon = NTU/(1+NTU);
    else
        x = exp(-NTU*(1-Cr));
        epsilon = (1-x)/(1-Cr*x);
    end

    Qmax = Cmin*(Thi-Tci);
    Q = epsilon*Qmax;

    Tho = Thi-Q/Ch;
    Tco = Tci+Q/Cc;

    DT1 = Thi-Tco;
    DT2 = Tho-Tci;

    DTlm = calculateLMTD(DT1,DT2);

    r.Ch = Ch;
    r.Cc = Cc;
    r.Cr = Cr;
    r.NTU = NTU;
    r.epsilon = epsilon;
    r.Qmax = Qmax;
    r.Q = Q;
    r.Th_out = Tho;
    r.Tc_out = Tco;
    r.DTlm = DTlm;
end

function DTlm = calculateLMTD(DT1,DT2)

    if DT1 <= 0 || DT2 <= 0
        error('Invalid terminal temperature difference.');
    end

    if abs(DT1-DT2) < 1e-8
        DTlm = (DT1+DT2)/2;
    else
        DTlm = (DT1-DT2)/log(DT1/DT2);
    end
end

function residual = lmtdResidual(Q,Thi,Tci,Ch,Cc,U,A)

    Tho = Thi-Q/Ch;
    Tco = Tci+Q/Cc;

    DT1 = Thi-Tco;
    DT2 = Tho-Tci;

    DTlm = calculateLMTD(DT1,DT2);

    residual = Q-U*A*DTlm;
end

function residual = coldOutletResidual( ...
    area,Thi,Tci,mh,mc,Cph,Cpc,U,targetTc)

    result = solveHX(Thi,Tci,mh,mc,Cph,Cpc,U,area);
    residual = result.Tc_out - targetTc;

end
%% 9. SENSITIVITY ANALYSIS: EFFECT OF OVERALL HEAT TRANSFER COEFFICIENT

U_values = 50:25:300;
nU = length(U_values);

Q_U = zeros(nU,1);
Th_U = zeros(nU,1);
Tc_U = zeros(nU,1);
epsilon_U = zeros(nU,1);

for i = 1:nU
    result = solveHX(Th_in,Tc_in,mh,mc,Cph,Cpc, ...
        U_values(i),A);

    Q_U(i) = result.Q/1000;
    Th_U(i) = result.Th_out;
    Tc_U(i) = result.Tc_out;
    epsilon_U(i) = result.epsilon;
end

figure;
plot(U_values,Q_U,'o-','LineWidth',1.5);
xlabel('Overall heat transfer coefficient U (W/m^2 K)');
ylabel('Heat recovered (kW)');
title('Effect of U on Heat Recovery');
grid on;
saveas(gcf,'plot_5_heat_recovery_vs_U.png');

figure;
plot(U_values,Th_U,'o-','LineWidth',1.5);
hold on;
plot(U_values,Tc_U,'s-','LineWidth',1.5);
xlabel('Overall heat transfer coefficient U (W/m^2 K)');
ylabel('Outlet temperature (deg C)');
title('Effect of U on Outlet Temperatures');
legend('Hot outlet','Cold outlet','Location','best');
grid on;
hold off;
saveas(gcf,'plot_6_outlet_temperatures_vs_U.png');

SensitivityResults = table(U_values',Q_U,epsilon_U, ...
    Th_U,Tc_U, ...
    'VariableNames',{'U_W_m2K','HeatDuty_kW', ...
    'Effectiveness','HotOutlet_C','ColdOutlet_C'});

writetable(SensitivityResults,'U_sensitivity_results.csv');

disp(SensitivityResults);


%% 10. USEFUL ENERGY RECOVERY

operatingHoursPerDay = 16;
operatingDaysPerYear = 300;

usefulPower_kW = base.Q/1000;

dailyEnergy_kWh = usefulPower_kW*operatingHoursPerDay;

annualEnergy_kWh = dailyEnergy_kWh*operatingDaysPerYear;

fprintf('\n===== USEFUL ENERGY RECOVERY =====\n');
fprintf('Useful thermal power = %.2f kW\n',usefulPower_kW);
fprintf('Daily thermal energy = %.2f kWh_th/day\n', ...
    dailyEnergy_kWh);
fprintf('Annual thermal energy = %.2f MWh_th/year\n', ...
    annualEnergy_kWh/1000);

%% 11. CONSTRAINED OPTIMIZATION: MINIMUM AREA

targetTc = 80;       % Required cold outlet temperature (deg C)
A_min = 0.01;        % Minimum search area (m^2)
A_max = 8;           % Maximum permitted area (m^2)

% Check whether the target is achievable within the area limit
result_min = solveHX(Th_in,Tc_in,mh,mc,Cph,Cpc,U,A_min);
result_max = solveHX(Th_in,Tc_in,mh,mc,Cph,Cpc,U,A_max);

if result_min.Tc_out >= targetTc

    A_opt = A_min;

elseif result_max.Tc_out < targetTc

    error(['Target temperature cannot be reached within ', ...
        'the maximum permitted area.']);

else

    % Solve for the smallest area that meets the target
    A_opt = fzero(@(area) ...
        solveHX(Th_in,Tc_in,mh,mc,Cph,Cpc,U,area).Tc_out ...
        - targetTc, [A_min,A_max]);

end

optimal = solveHX(Th_in,Tc_in,mh,mc,Cph,Cpc,U,A_opt);

fprintf('\n===== OPTIMIZATION RESULTS =====\n');
fprintf('Target cold outlet = %.2f deg C\n',targetTc);
fprintf('Maximum allowed area = %.2f m^2\n',A_max);
fprintf('Minimum required area = %.4f m^2\n',A_opt);
fprintf('Actual cold outlet = %.4f deg C\n',optimal.Tc_out);
fprintf('Hot outlet temperature = %.4f deg C\n', ...
    optimal.Th_out);
fprintf('Recovered heat = %.4f kW\n',optimal.Q/1000);
fprintf('Area constraint satisfied = %d\n',A_opt <= A_max);
fprintf('Temperature constraint satisfied = %d\n', ...
    optimal.Tc_out >= targetTc-1e-5);

%% 12. COMPARE OPTIMAL AND BASELINE DESIGNS

Design = ["Baseline";"Optimized"];

Area_m2 = [A;A_opt];

HeatDuty_kW = [base.Q;optimal.Q]/1000;

HotOutlet_C = [base.Th_out;optimal.Th_out];

ColdOutlet_C = [base.Tc_out;optimal.Tc_out];

Comparison = table(Design,Area_m2,HeatDuty_kW, ...
    HotOutlet_C,ColdOutlet_C);

disp(Comparison);

writetable(Comparison,'design_comparison.csv');

%% 13. ENERGY RECOVERY AT OPTIMUM

optimalDailyEnergy = optimal.Q/1000*operatingHoursPerDay;

optimalAnnualEnergy = optimalDailyEnergy*operatingDaysPerYear;

fprintf('\nOptimal daily recovery = %.2f kWh_th/day\n', ...
    optimalDailyEnergy);

fprintf('Optimal annual recovery = %.2f MWh_th/year\n', ...
    optimalAnnualEnergy/1000);


%% 14. OPTIMUM AREA FOR DIFFERENT TARGET TEMPERATURES

targetValues = (50:5:90)';
requiredArea = NaN(size(targetValues));
feasible = false(size(targetValues));

for i = 1:length(targetValues)

    target = targetValues(i);

    lowResult = solveHX(Th_in,Tc_in,mh,mc,Cph,Cpc,U,A_min);
    highResult = solveHX(Th_in,Tc_in,mh,mc,Cph,Cpc,U,A_max);

    if lowResult.Tc_out >= target

        requiredArea(i) = A_min;
        feasible(i) = true;

    elseif highResult.Tc_out >= target

        requiredArea(i) = fzero(@(area) ...
            coldOutletResidual(area,Th_in,Tc_in,mh,mc, ...
            Cph,Cpc,U,target),[A_min,A_max]);

        feasible(i) = true;

    end

end

TargetStudy = table(targetValues,requiredArea,feasible, ...
    'VariableNames',{'TargetColdOutlet_C', ...
    'RequiredArea_m2','Feasible'});

disp(TargetStudy);
writetable(TargetStudy,'target_area_optimization.csv');

figure;
plot(targetValues,requiredArea,'o-','LineWidth',1.5);
xlabel('Target cold outlet temperature (deg C)');
ylabel('Minimum required area (m^2)');
title('Minimum Exchanger Area vs Target Temperature');
grid on;

saveas(gcf,'plot_7_optimum_area_vs_target.png');



%% 15. ECONOMIC ANALYSIS AND AREA OPTIMIZATION

% Illustrative economic assumptions
costPerArea = 25000;       % INR per m^2
heatValue = 2;             % INR per kWh of useful thermal energy
operatingHours = 16;       % hours/day
operatingDays = 300;       % days/year
maintenanceFraction = 0.02;
projectLife = 10;          % years
discountRate = 0.10;       % fraction per year

% Candidate exchanger areas
areaOptions = (0.5:0.5:8)';

n = length(areaOptions);

heat_kW = zeros(n,1);
coldOutlet = zeros(n,1);
capitalCost = zeros(n,1);
annualEnergy = zeros(n,1);
grossAnnualSavings = zeros(n,1);
annualMaintenance = zeros(n,1);
annualNetBenefit = zeros(n,1);
paybackYears = NaN(n,1);
NPV = zeros(n,1);
feasible = false(n,1);

% Present-worth factor for uniform annual net benefits
presentWorthFactor = ...
    (1-(1+discountRate)^(-projectLife))/discountRate;

for i = 1:n

    area = areaOptions(i);

    result = solveHX(Th_in,Tc_in,mh,mc,Cph,Cpc,U,area);

    heat_kW(i) = result.Q/1000;
    coldOutlet(i) = result.Tc_out;

    capitalCost(i) = costPerArea*area;

    annualEnergy(i) = heat_kW(i)*operatingHours* ...
                      operatingDays;

    grossAnnualSavings(i) = annualEnergy(i)*heatValue;

    annualMaintenance(i) = ...
        maintenanceFraction*capitalCost(i);

    annualNetBenefit(i) = grossAnnualSavings(i) ...
                          - annualMaintenance(i);

    if annualNetBenefit(i) > 0
        paybackYears(i) = capitalCost(i)/annualNetBenefit(i);
    end

    NPV(i) = -capitalCost(i) ...
             + annualNetBenefit(i)*presentWorthFactor;

    feasible(i) = coldOutlet(i) >= targetTc;

end

EconomicResults = table(areaOptions,heat_kW,coldOutlet, ...
    capitalCost,annualEnergy,grossAnnualSavings, ...
    annualMaintenance,annualNetBenefit,paybackYears, ...
    NPV,feasible, ...
    'VariableNames',{'Area_m2','HeatDuty_kW', ...
    'ColdOutlet_C','CapitalCost_INR', ...
    'AnnualEnergy_kWh','GrossSavings_INR_year', ...
    'Maintenance_INR_year','NetBenefit_INR_year', ...
    'Payback_years','NPV_INR','MeetsTemperatureTarget'});

disp(EconomicResults);

writetable(EconomicResults,'economic_optimization_results.csv');

%% 16. FIND BEST FEASIBLE DESIGN BY NPV

feasibleIndices = find(feasible);

if isempty(feasibleIndices)

    fprintf('\nNo candidate area meets the temperature target.\n');
    fprintf('Consider a larger area or revised operating conditions.\n');

else

    [bestNPV,localIndex] = max(NPV(feasibleIndices));
    bestIndex = feasibleIndices(localIndex);

    fprintf('\n===== BEST FEASIBLE DESIGN =====\n');
    fprintf('Area = %.2f m^2\n',areaOptions(bestIndex));
    fprintf('Cold outlet = %.2f deg C\n',coldOutlet(bestIndex));
    fprintf('Heat recovered = %.2f kW\n',heat_kW(bestIndex));
    fprintf('Capital cost = Rs %.2f\n',capitalCost(bestIndex));
    fprintf('Annual gross heat value = Rs %.2f\n', ...
        grossAnnualSavings(bestIndex));
    fprintf('Annual maintenance = Rs %.2f\n', ...
        annualMaintenance(bestIndex));
    fprintf('Annual net benefit = Rs %.2f\n', ...
        annualNetBenefit(bestIndex));
    fprintf('Simple payback = %.2f years\n', ...
        paybackYears(bestIndex));
    fprintf('NPV over %d years = Rs %.2f\n', ...
        projectLife,bestNPV);

end

%% 17. PLOT ECONOMIC TRADE-OFFS

figure;
plot(areaOptions,NPV/1000,'o-','LineWidth',1.5);
hold on;
yline(0,'--');
xlabel('Heat transfer area (m^2)');
ylabel('Net present value (thousand INR)');
title('Economic Optimization of Heat Exchanger Area');
grid on;
hold off;

saveas(gcf,'plot_8_npv_vs_area.png');

figure;
plot(areaOptions,annualEnergy/1000,'s-', ...
    'LineWidth',1.5);
xlabel('Heat transfer area (m^2)');
ylabel('Recovered thermal energy (MWh/year)');
title('Annual Useful Heat Recovery vs Area');
grid on;

saveas(gcf,'plot_9_annual_energy_vs_area.png');


%% 18. STAGE 5 ECONOMIC AUDIT

% This section assumes EconomicResults was generated in Stage 5.

energyCheck = EconomicResults.HeatDuty_kW ...
    * operatingHours * operatingDays;

energyError = max(abs( ...
    EconomicResults.AnnualEnergy_kWh - energyCheck));

maintenanceCheck = maintenanceFraction ...
    * EconomicResults.CapitalCost_INR;

maintenanceError = max(abs( ...
    EconomicResults.Maintenance_INR_year - maintenanceCheck));

npvCheck = -EconomicResults.CapitalCost_INR ...
    + EconomicResults.NetBenefit_INR_year ...
    * presentWorthFactor;

npvError = max(abs(EconomicResults.NPV_INR - npvCheck));

% Payback is meaningful only when annual net benefit is positive.
validPayback = EconomicResults.NetBenefit_INR_year > 0;

paybackError = max(abs( ...
    EconomicResults.Payback_years(validPayback) ...
    - EconomicResults.CapitalCost_INR(validPayback) ...
    ./ EconomicResults.NetBenefit_INR_year(validPayback)));

if isempty(paybackError)
    paybackError = 0;
end

fprintf('\n===== STAGE 5 ECONOMIC AUDIT =====\n');
fprintf('Annual energy calculation error = %.8f kWh/year\n', ...
    energyError);
fprintf('Maintenance calculation error = Rs %.8f/year\n', ...
    maintenanceError);
fprintf('NPV calculation error = Rs %.8f\n',npvError);
fprintf('Payback calculation error = %.8f years\n',paybackError);

fprintf('Energy check passed: %d\n',energyError < 1e-6);
fprintf('Maintenance check passed: %d\n',maintenanceError < 1e-6);
fprintf('NPV check passed: %d\n',npvError < 1e-4);
fprintf('Payback check passed: %d\n',paybackError < 1e-6);

% Only designs meeting the target should be considered feasible.
fprintf('Number of feasible candidate designs = %d\n', ...
    sum(EconomicResults.MeetsTemperatureTarget));

%% 19. FOULING MODEL

% Treat the existing U as the clean overall coefficient.
U_clean = U;

% Illustrative additional fouling resistance.
Rf = 0.001;                  % m^2 K/W

U_fouled = 1/(1/U_clean + Rf);

cleanResult = solveHX(Th_in,Tc_in,mh,mc,Cph,Cpc, ...
    U_clean,A);

fouledResult = solveHX(Th_in,Tc_in,mh,mc,Cph,Cpc, ...
    U_fouled,A);

heatClean_kW = cleanResult.Q/1000;
heatFouled_kW = fouledResult.Q/1000;

heatReduction_kW = heatClean_kW-heatFouled_kW;

reductionPercent = 100*heatReduction_kW/heatClean_kW;

dailyLostEnergy = heatReduction_kW*operatingHours;
annualLostEnergy = dailyLostEnergy*operatingDays;

annualLostValue = annualLostEnergy*heatValue;

fprintf('\n===== FOULING ANALYSIS =====\n');
fprintf('Clean U = %.2f W/(m^2 K)\n',U_clean);
fprintf('Fouling resistance = %.5f m^2 K/W\n',Rf);
fprintf('Effective fouled U = %.2f W/(m^2 K)\n',U_fouled);
fprintf('Clean heat duty = %.3f kW\n',heatClean_kW);
fprintf('Fouled heat duty = %.3f kW\n',heatFouled_kW);
fprintf('Heat duty reduction = %.3f kW\n',heatReduction_kW);
fprintf('Heat duty reduction = %.2f percent\n',reductionPercent);
fprintf('Annual useful heat lost = %.2f kWh/year\n', ...
    annualLostEnergy);
fprintf('Illustrative annual lost heat value = Rs %.2f\n', ...
    annualLostValue);

FoulingComparison = table( ...
    ["Clean";"Fouled"], ...
    [U_clean;U_fouled], ...
    [heatClean_kW;heatFouled_kW], ...
    [cleanResult.Tc_out;fouledResult.Tc_out], ...
    'VariableNames',{'Condition','U_W_m2K', ...
    'HeatDuty_kW','ColdOutlet_C'});

disp(FoulingComparison);
writetable(FoulingComparison,'fouling_comparison.csv');

figure;
bar([heatClean_kW,heatFouled_kW]);
set(gca,'XTickLabel',{'Clean','Fouled'});
ylabel('Heat recovered (kW)');
title('Effect of Fouling on Heat Recovery');
grid on;

saveas(gcf,'plot_10_clean_vs_fouled.png');

%% 20. MONTE CARLO UNCERTAINTY ANALYSIS

rng(1);                    % Reproducible results

Nsim = 1000;

Uclean_samples = 80 + (120-80)*rand(Nsim,1);

Rf_samples = 0.0005 + ...
    (0.002-0.0005)*rand(Nsim,1);

Ueffective_samples = 1 ./ ...
    (1./Uclean_samples + Rf_samples);

Qsim_kW = zeros(Nsim,1);
Tcsim_C = zeros(Nsim,1);

for i = 1:Nsim

    simResult = solveHX(Th_in,Tc_in,mh,mc,Cph,Cpc, ...
        Ueffective_samples(i),A);

    Qsim_kW(i) = simResult.Q/1000;
    Tcsim_C(i) = simResult.Tc_out;

end

% Sort values to estimate the 5th and 95th percentiles.
Qsorted = sort(Qsim_kW);
Tsorted = sort(Tcsim_C);

i05 = max(1,round(0.05*Nsim));
i50 = round(0.50*Nsim);
i95 = min(Nsim,round(0.95*Nsim));

fprintf('\n===== UNCERTAINTY RESULTS =====\n');
fprintf('Heat duty 5th percentile = %.2f kW\n',Qsorted(i05));
fprintf('Heat duty median = %.2f kW\n',Qsorted(i50));
fprintf('Heat duty 95th percentile = %.2f kW\n',Qsorted(i95));

fprintf('Cold outlet 5th percentile = %.2f C\n',Tsorted(i05));
fprintf('Cold outlet median = %.2f C\n',Tsorted(i50));
fprintf('Cold outlet 95th percentile = %.2f C\n',Tsorted(i95));

fprintf('Fraction meeting target = %.3f\n', ...
    mean(Tcsim_C >= targetTc));

UncertaintyResults = table( ...
    Uclean_samples,Rf_samples,Ueffective_samples, ...
    Qsim_kW,Tcsim_C, ...
    'VariableNames',{'Uclean_W_m2K','Rf_m2K_W', ...
    'Ueffective_W_m2K','HeatDuty_kW','ColdOutlet_C'});

writetable(UncertaintyResults,'uncertainty_simulation.csv');

figure;
histogram(Qsim_kW,25);
xlabel('Heat recovered (kW)');
ylabel('Number of simulations');
title('Uncertainty in Heat-Recovery Performance');
grid on;

saveas(gcf,'plot_11_heat_duty_uncertainty.png');

figure;
scatter(Ueffective_samples,Qsim_kW,12,'filled');
xlabel('Effective U (W/m^2 K)');
ylabel('Heat recovered (kW)');
title('Effective U vs Heat-Recovery Performance');
grid on;

saveas(gcf,'plot_12_U_vs_heat_duty.png');

%% 21. FINAL MODEL VALIDATION

fprintf('\n===== FINAL MODEL VALIDATION =====\n');

% 1. Baseline energy conservation
Q_hot_check = base.Ch*(Th_in-base.Th_out);
Q_cold_check = base.Cc*(base.Tc_out-Tc_in);

energyError = abs(Q_hot_check-Q_cold_check);

fprintf('Baseline energy balance error = %.8f W\n', ...
    energyError);
fprintf('Energy conservation passed = %d\n', ...
    energyError < 1e-4);

% 2. Physical heat-transfer limits
heatLimitPassed = base.Q >= 0 && base.Q <= base.Qmax;
temperaturePassed = base.Th_out < Th_in && ...
    base.Tc_out > Tc_in;

fprintf('Heat duty within physical limits = %d\n', ...
    heatLimitPassed);
fprintf('Outlet temperatures physically consistent = %d\n', ...
    temperaturePassed);

% 3. Fouling checks
foulingPassed = U_fouled < U_clean && ...
    fouledResult.Q < cleanResult.Q;

fprintf('Fouling reduces U and heat duty = %d\n', ...
    foulingPassed);

% 4. Monte Carlo checks
mcPassed = all(isfinite(Qsim_kW)) && ...
    all(isfinite(Tcsim_C)) && ...
    all(Qsim_kW >= 0) && ...
    all(Qsim_kW <= base.Qmax/1000);

fprintf('Monte Carlo results are finite and bounded = %d\n', ...
    mcPassed);

% 5. Economic calculation checks
economicPassed = all(isfinite(EconomicResults.NPV_INR)) && ...
    all(EconomicResults.CapitalCost_INR > 0);

fprintf('Economic values are finite = %d\n',economicPassed);

% 6. Overall status
allPassed = energyError < 1e-4 && heatLimitPassed && ...
    temperaturePassed && foulingPassed && mcPassed && ...
    economicPassed;

if allPassed
    fprintf('\nALL BASIC VALIDATION CHECKS PASSED.\n');
else
    fprintf('\nSOME CHECKS FAILED. Investigate before reporting results.\n');
end




