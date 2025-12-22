%% COMPARACION EJERCICIO 1: HESS-SMITH vs XFLR5
% Script para comparar resultados del metodo de Hess-Smith implementado
% en MATLAB con datos de XFLR5 y teoria de perfiles delgados
%
% Autor: Miguel Rosa
% Fecha: Diciembre 2025
% Asignatura: Dinamica de Fluidos Computacional

clc; clearvars; close all;

%% Configurar directorios
script_dir = fileparts(mfilename('fullpath'));
if isempty(script_dir)
    script_dir = pwd;
end

% Directorio de figuras
fig_dir = fullfile(script_dir, '..', 'figures', 'Ejercicio1');
if ~exist(fig_dir, 'dir')
    mkdir(fig_dir);
end

% Directorio de datos
data_dir = fullfile(script_dir, '..', 'data');

%% Configurar interprete LaTeX para graficos
set(groot, 'defaultAxesTickLabelInterpreter', 'latex');
set(groot, 'defaultLegendInterpreter', 'latex');
set(groot, 'defaultTextInterpreter', 'latex');
set(groot, 'defaultAxesFontSize', 11);
set(0, 'DefaultFigureColor', 'w');

fprintf('=====================================================\n');
fprintf('COMPARACION EJERCICIO 1: HESS-SMITH vs XFLR5\n');
fprintf('=====================================================\n\n');

%% 1. CARGAR DATOS DE MATLAB (Hess-Smith)
fprintf('[1/4] Cargando datos de MATLAB...\n');
data_matlab = readtable(fullfile(data_dir, 'Resultados_HessSmith.csv'));
alpha_matlab = data_matlab.Alpha_deg;
CL_matlab = data_matlab.CL;
CM_O_matlab = data_matlab.CM_O;
CM_c4_matlab = data_matlab.CM_c4;

fprintf('      Rango de alpha: %.1f a %.1f grados\n', min(alpha_matlab), max(alpha_matlab));
fprintf('      Numero de puntos: %d\n\n', length(alpha_matlab));

%% 2. CARGAR DATOS DE XFLR5
fprintf('[2/4] Cargando datos de XFLR5...\n');

% Ruta al archivo de polares XFLR5
xflr5_file = fullfile(script_dir, '..', '..', '03_XFLR5', 'xflr5_projects', ...
                      'HessSmith', 'T1_Re1.000_M0.00_N3.0.csv');

% Leer archivo XFLR5 (saltar las 10 primeras lineas de cabecera)
opts = detectImportOptions(xflr5_file, 'NumHeaderLines', 10);
data_xflr5 = readtable(xflr5_file, opts);

% Extraer columnas relevantes
alpha_xflr5 = data_xflr5{:,1};  % alpha
CL_xflr5 = data_xflr5{:,2};     % CL
CM_xflr5 = data_xflr5{:,5};     % Cm (columna 5)

% Limpiar NaN si hay
valid_idx = ~isnan(alpha_xflr5) & ~isnan(CL_xflr5);
alpha_xflr5 = alpha_xflr5(valid_idx);
CL_xflr5 = CL_xflr5(valid_idx);
CM_xflr5 = CM_xflr5(valid_idx);

xflr5_disponible = true;
fprintf('      Archivo XFLR5 cargado: %s\n', xflr5_file);
fprintf('      Puntos de datos: %d\n', length(alpha_xflr5));
fprintf('      Rango de alpha: %.1f a %.1f grados\n\n', min(alpha_xflr5), max(alpha_xflr5));

%% 3. CALCULOS COMPARATIVOS
fprintf('[3/4] Calculando metricas de comparacion...\n');

% Pendiente de sustentacion MATLAB (dCL/dalpha)
% Ajuste lineal en zona lineal (-5 a 10 grados)
idx_lineal_matlab = (alpha_matlab >= -5) & (alpha_matlab <= 10);
p_matlab = polyfit(alpha_matlab(idx_lineal_matlab), CL_matlab(idx_lineal_matlab), 1);
dCL_dalpha_matlab = p_matlab(1);  % pendiente en 1/grado
dCL_dalpha_matlab_rad = dCL_dalpha_matlab * 180 / pi;

% Pendiente de sustentacion XFLR5
idx_lineal_xflr5 = (alpha_xflr5 >= -5) & (alpha_xflr5 <= 10);
p_xflr5 = polyfit(alpha_xflr5(idx_lineal_xflr5), CL_xflr5(idx_lineal_xflr5), 1);
dCL_dalpha_xflr5 = p_xflr5(1);  % pendiente en 1/grado
dCL_dalpha_xflr5_rad = dCL_dalpha_xflr5 * 180 / pi;

% Teoria de perfiles delgados: dCL/dalpha = 2*pi rad^-1
dCL_dalpha_teoria = 2 * pi;

% Angulo de sustentacion nula
alpha_L0_matlab = -p_matlab(2) / p_matlab(1);
alpha_L0_xflr5 = -p_xflr5(2) / p_xflr5(1);

fprintf('\n      Pendiente de sustentacion:\n');
fprintf('        MATLAB (Hess-Smith): %.4f rad^{-1} (%.4f deg^{-1})\n', ...
        dCL_dalpha_matlab_rad, dCL_dalpha_matlab);
fprintf('        XFLR5:               %.4f rad^{-1} (%.4f deg^{-1})\n', ...
        dCL_dalpha_xflr5_rad, dCL_dalpha_xflr5);
fprintf('        Teoria (2*pi):       %.4f rad^{-1}\n', dCL_dalpha_teoria);
fprintf('        Diferencia MATLAB vs XFLR5: %.1f%%\n', ...
        100*(dCL_dalpha_matlab_rad - dCL_dalpha_xflr5_rad)/dCL_dalpha_xflr5_rad);
fprintf('\n      Angulo de sustentacion nula:\n');
fprintf('        MATLAB: alpha_L0 = %.2f grados\n', alpha_L0_matlab);
fprintf('        XFLR5:  alpha_L0 = %.2f grados\n', alpha_L0_xflr5);

%% 4. GENERAR FIGURAS DE COMPARACION
fprintf('\n[4/4] Generando figuras de comparacion...\n');

% =========================================================================
% FIGURA 1: CL vs Alpha - Comparacion
% =========================================================================
fig1 = figure('Position', [100, 100, 900, 600]);
hold on;

% Datos MATLAB
plot(alpha_matlab, CL_matlab, 'b-o', 'LineWidth', 2, 'MarkerSize', 6, ...
     'MarkerFaceColor', 'b', 'DisplayName', 'MATLAB (Hess-Smith)');

% Datos XFLR5
plot(alpha_xflr5, CL_xflr5, 'r-s', 'LineWidth', 2, 'MarkerSize', 6, ...
     'MarkerFaceColor', 'r', 'DisplayName', 'XFLR5');

% Linea CL = 0
yline(0, 'k--', 'LineWidth', 0.5);

% Configuracion
xlabel('$\alpha$ [deg]', 'FontSize', 14);
ylabel('$C_L$', 'FontSize', 14);
title('Coeficiente de Sustentacion vs Angulo de Ataque','Interpreter', 'latex', 'FontSize', 14);
legend('Location', 'southeast', 'FontSize', 11);
grid on;
xlim([min(alpha_matlab)-1, max(alpha_matlab)+1]);

exportgraphics(fig1, fullfile(fig_dir, 'comparacion_CL_xflr5.png'), 'Resolution', 300);
fprintf('      Guardada: comparacion_CL_xflr5.png\n');

% =========================================================================
% FIGURA 2: CM vs Alpha - Comparacion
% =========================================================================
fig2 = figure('Position', [100, 100, 900, 600]);
hold on;

% CM respecto al origen
plot(alpha_matlab, CM_O_matlab, 'b-o', 'LineWidth', 2, 'MarkerSize', 6, ...
     'MarkerFaceColor', 'b', 'DisplayName', 'MATLAB $C_{M,O}$ (B.A.)');

% CM respecto al c/4
plot(alpha_matlab, CM_c4_matlab, 'g-^', 'LineWidth', 2, 'MarkerSize', 6, ...
     'MarkerFaceColor', 'g', 'DisplayName', 'MATLAB $C_{M,c/4}$');

% Datos XFLR5
plot(alpha_xflr5, CM_xflr5, 'r-s', 'LineWidth', 2, 'MarkerSize', 6, ...
     'MarkerFaceColor', 'r', 'DisplayName', 'XFLR5 $C_M$');

% Configuracion
xlabel('$\alpha$ [deg]', 'FontSize', 14);
ylabel('$C_M$', 'FontSize', 14);
title('Coeficientes de Momento vs Angulo de Ataque', 'Interpreter', 'latex', 'FontSize', 14);
legend('Location', 'best', 'FontSize', 11);
grid on;
xlim([min(alpha_matlab)-1, max(alpha_matlab)+1]);

exportgraphics(fig2, fullfile(fig_dir, 'comparacion_CM_xflr5.png'), 'Resolution', 300);
fprintf('      Guardada: comparacion_CM_xflr5.png\n');

% =========================================================================
% FIGURA 3: Pendiente de sustentacion - Comparacion con teoria
% =========================================================================
fig3 = figure('Position', [100, 100, 800, 500]);

% Datos para grafico de barras
metodos = categorical({'MATLAB', 'XFLR5', 'Teoria ($2\pi$)'});
metodos = reordercats(metodos, {'MATLAB', 'XFLR5', 'Teoria ($2\pi$)'});
pendientes = [dCL_dalpha_matlab_rad, dCL_dalpha_xflr5_rad, dCL_dalpha_teoria];
colores = [0.3 0.5 0.8; 0.8 0.3 0.3; 0.3 0.7 0.3];

b = bar(metodos, pendientes, 0.6);
b.FaceColor = 'flat';
b.CData = colores;
hold on;

% Linea de referencia teoria
yline(dCL_dalpha_teoria, 'g--', 'LineWidth', 2, 'Label', '$2\pi$', 'Interpreter', 'latex');

% Etiquetas de valor
text(1, dCL_dalpha_matlab_rad + 0.15, sprintf('%.3f', dCL_dalpha_matlab_rad), ...
     'HorizontalAlignment', 'center', 'FontSize', 11);
text(2, dCL_dalpha_xflr5_rad + 0.15, sprintf('%.3f', dCL_dalpha_xflr5_rad), ...
     'HorizontalAlignment', 'center', 'FontSize', 11);
text(3, dCL_dalpha_teoria + 0.15, sprintf('%.3f', dCL_dalpha_teoria), ...
     'HorizontalAlignment', 'center', 'FontSize', 11);

ylabel('$dC_L/d\alpha$ [rad$^{-1}$]', 'FontSize', 14);
title('Comparacion de Pendiente de Sustentacion', 'Interpreter', 'latex', 'FontSize', 14);
grid on;
ylim([0, 7.5]);

exportgraphics(fig3, fullfile(fig_dir, 'comparacion_pendiente_CL.png'), 'Resolution', 300);
fprintf('      Guardada: comparacion_pendiente_CL.png\n');

% =========================================================================
% FIGURA 4: Tabla resumen (como figura)
% =========================================================================
fig4 = figure('Position', [100, 100, 700, 400]);
axis off;

% Crear tabla de texto
str = {
    '\textbf{RESUMEN COMPARATIVO - EJERCICIO 1}', ...
    '', ...
    '\textbf{Pendiente de sustentacion ($dC_L/d\alpha$):}', ...
    sprintf('  MATLAB (Hess-Smith): %.4f rad$^{-1}$', dCL_dalpha_matlab_rad), ...
    sprintf('  XFLR5:               %.4f rad$^{-1}$', dCL_dalpha_xflr5_rad), ...
    sprintf('  Teoria ($2\\pi$):     %.4f rad$^{-1}$', dCL_dalpha_teoria), ...
    sprintf('  Diferencia MATLAB vs XFLR5: %.1f\\%%', 100*abs(dCL_dalpha_matlab_rad - dCL_dalpha_xflr5_rad)/dCL_dalpha_xflr5_rad), ...
    '', ...
    '\textbf{Angulo de sustentacion nula ($\alpha_{L=0}$):}', ...
    sprintf('  MATLAB: %.2f$^\\circ$', alpha_L0_matlab), ...
    sprintf('  XFLR5:  %.2f$^\\circ$', alpha_L0_xflr5), ...
    '', ...
    '\textbf{Numero de paneles MATLAB:} 80 (40 extrados + 40 intrados)'
};

text(0.1, 0.9, str, 'FontSize', 12, 'VerticalAlignment', 'top', ...
     'Interpreter', 'latex', 'Units', 'normalized');

exportgraphics(fig4, fullfile(fig_dir, 'resumen_comparativo.png'), 'Resolution', 300);
fprintf('      Guardada: resumen_comparativo.png\n');

%% MENSAJE FINAL
fprintf('\n=====================================================\n');
fprintf('COMPARACION COMPLETADA\n');
fprintf('=====================================================\n');
fprintf('\nFiguras generadas en: %s\n', fig_dir);
fprintf('\nArchivos generados:\n');
fprintf('  - comparacion_CL_xflr5.png\n');
fprintf('  - comparacion_CM_xflr5.png\n');
fprintf('  - comparacion_pendiente_CL.png\n');
fprintf('  - resumen_comparativo.png\n');

fprintf('\nDatos de XFLR5 utilizados: %s\n', xflr5_file);

%% Restaurar configuracion por defecto
set(groot, 'defaultAxesTickLabelInterpreter', 'default');
set(groot, 'defaultLegendInterpreter', 'default');
set(groot, 'defaultTextInterpreter', 'default');
