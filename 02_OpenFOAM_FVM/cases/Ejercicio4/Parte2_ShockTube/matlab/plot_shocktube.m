%% ========================================================================
% PLOT_SHOCKTUBE.M - Analisis del tubo de choque de Sod
% Ejercicio 4 - Parte 2: Comparacion de esquemas numericos
% Universidad de Leon - Master en Ingenieria Aeronautica
% =========================================================================
% Este script genera las graficas de validacion y comparacion para el
% problema del tubo de choque de Sod simulado con OpenFOAM.
%
% Tiempos adimensionales: t* = t * a_L / L
%   - a_L = sqrt(1.4 * 100000 / 1.0) = 374.17 m/s
%   - L = 10 m (longitud del dominio)
%   - t* = 0.1 -> t = 0.00267 s (validacion)
%   - t* = 0.15 -> t = 0.004 s (comparacion)
%
% Esquemas comparados:
%   - Low order: Euler (temporal) + upwind (espacial)
%   - High order: Crank-Nicolson (temporal) + linearUpwind (espacial)
% =========================================================================

clear; close all; clc;

%% Configuracion de rutas
script_dir = fileparts(mfilename('fullpath'));
case_base = fullfile(script_dir, '..');
fig_dir = fullfile(case_base, '..', '..', '..', 'figures', 'Ejercicio4');

% Crear directorio de figuras si no existe
if ~exist(fig_dir, 'dir')
    mkdir(fig_dir);
end

%% Parametros del problema de Sod
% Condiciones iniciales
rho_L = 1.0;        % kg/m^3 (densidad izquierda)
rho_R = 0.125;      % kg/m^3 (densidad derecha)
p_L = 100000;       % Pa (presion izquierda)
p_R = 10000;        % Pa (presion derecha)
gamma = 1.4;        % Coeficiente adiabatico

% Dominio
L = 10;             % Longitud total del dominio (m)
x_diaphragm = 0;    % Posicion del diafragma (centro)

% Velocidad del sonido izquierda
a_L = sqrt(gamma * p_L / rho_L);  % = 374.17 m/s

% Tiempos adimensionales y fisicos
t_star_val = 0.1;    % t* para validacion
t_star_cmp = 0.15;   % t* para comparacion
t_star_anal = 0.245; % t* de la solucion analitica (shock en X=0.84)

t_val = t_star_val * L / a_L;   % = 0.00267 s
t_cmp = t_star_cmp * L / a_L;   % = 0.00401 s
t_anal = t_star_anal * L / a_L; % = 0.00655 s

% Tiempos disponibles en OpenFOAM (mas cercanos)
t_val_of = '0.0025';  % Mas cercano a t_val
t_cmp_of = '0.004';   % Igual a t_cmp

fprintf('Parametros del problema:\n');
fprintf('  a_L = %.2f m/s\n', a_L);
fprintf('  t* = 0.1 -> t = %.5f s (usando t_OF = %s)\n', t_val, t_val_of);
fprintf('  t* = 0.15 -> t = %.5f s (usando t_OF = %s)\n', t_cmp, t_cmp_of);
fprintf('  t* analitico = %.3f -> t = %.5f s\n\n', t_star_anal, t_anal);

%% Cargar solucion analitica
% El archivo tiene valores adimensionales en dominio [0,1]
anal_file = fullfile(case_base, 'ResultadosAnalaticos.csv');
anal_data = readtable(anal_file);

% Coordenadas normalizadas [0,1] con diafragma en 0.5
X_anal_norm = anal_data.X;

% Variables normalizadas
rho_anal_norm = anal_data.Rho;    % rho/rho_L
p_anal_norm = anal_data.P;        % p/p_L
u_anal_norm = anal_data.Vel;      % u/a_L

%% Funcion para escalar solucion analitica por auto-similaridad
% Para soluciones auto-similares: x_new = x_0 + (x - x_0) * (t_new / t_old)
scale_analytical = @(X_norm, t_target, t_anal) ...
    0.5 + (X_norm - 0.5) * (t_target / t_anal);

% Escalar para t* = 0.1 (validacion)
X_anal_t01 = scale_analytical(X_anal_norm, t_star_val, t_star_anal);
% Convertir a coordenadas fisicas [-5, 5]
x_anal_t01 = (X_anal_t01 - 0.5) * L;

% Variables fisicas
rho_anal = rho_anal_norm * rho_L;
p_anal = p_anal_norm * p_L;
u_anal = u_anal_norm * a_L;

%% Funcion para leer datos de OpenFOAM postProcessing
read_of_data = @(case_path, time) readOpenFOAMLine(fullfile(case_path, ...
    'postProcessing', 'graph', time, 'line.xy'));

%% Cargar datos numericos
highorder_path = fullfile(case_base, 'shockTube_highorder');
loworder_path = fullfile(case_base, 'shockTube_loworder');

% Datos para validacion (t* = 0.1)
fprintf('Cargando datos de OpenFOAM...\n');
[x_hi_val, T_hi_val, U_hi_val, p_hi_val] = read_of_data(highorder_path, t_val_of);
[x_lo_val, T_lo_val, U_lo_val, p_lo_val] = read_of_data(loworder_path, t_val_of);

% Calcular densidad desde ecuacion de estado
R = 287;  % J/(kg*K)
rho_hi_val = p_hi_val ./ (R * T_hi_val);
rho_lo_val = p_lo_val ./ (R * T_lo_val);

% Datos para comparacion (t* = 0.15)
[x_hi_cmp, T_hi_cmp, U_hi_cmp, p_hi_cmp] = read_of_data(highorder_path, t_cmp_of);
[x_lo_cmp, T_lo_cmp, U_lo_cmp, p_lo_cmp] = read_of_data(loworder_path, t_cmp_of);
rho_hi_cmp = p_hi_cmp ./ (R * T_hi_cmp);
rho_lo_cmp = p_lo_cmp ./ (R * T_lo_cmp);

fprintf('Datos cargados correctamente.\n\n');

%% Configuracion de graficas
set(0, 'DefaultAxesFontSize', 11);
set(0, 'DefaultLineLineWidth', 1.5);
set(0, 'DefaultTextInterpreter', 'latex');
set(0, 'DefaultAxesTickLabelInterpreter', 'latex');
set(0, 'DefaultLegendInterpreter', 'latex');

% Colores
c_anal = [0 0 0];           % Negro - analitico
c_high = [0 0.447 0.741];   % Azul - alto orden
c_low = [0.850 0.325 0.098]; % Naranja - bajo orden

%% FIGURA 1: Validacion con solucion analitica (t* = 0.1)
fig1 = figure('Position', [100 100 1200 500], 'Color', 'w');

% Calcular valores normalizados para la region de interes (-2 a 2)
x_range = x_anal_t01 >= -2 & x_anal_t01 <= 2;
rho_all = [rho_anal(x_range); rho_hi_val(x_hi_val >= -2 & x_hi_val <= 2); rho_lo_val(x_lo_val >= -2 & x_lo_val <= 2)];
p_all = [p_anal(x_range)/1000; p_hi_val(x_hi_val >= -2 & x_hi_val <= 2)/1000; p_lo_val(x_lo_val >= -2 & x_lo_val <= 2)/1000];
u_all = [u_anal(x_range); U_hi_val(x_hi_val >= -2 & x_hi_val <= 2); U_lo_val(x_lo_val >= -2 & x_lo_val <= 2)];

rho_min = min(rho_all); rho_max = max(rho_all);
p_min = min(p_all); p_max = max(p_all);
u_min = min(u_all); u_max = max(u_all);

% Subplot 1: Densidad (normalizada)
subplot(1,3,1);
plot(x_anal_t01, (rho_anal - rho_min) / (rho_max - rho_min), '-', 'Color', c_anal, 'LineWidth', 2, 'DisplayName', 'Analítico');
hold on;
plot(x_hi_val, (rho_hi_val - rho_min) / (rho_max - rho_min), '--', 'Color', c_high, 'LineWidth', 1.5, 'DisplayName', 'Crank-Nicolson + linearUpwind');
plot(x_lo_val, (rho_lo_val - rho_min) / (rho_max - rho_min), ':', 'Color', c_low, 'LineWidth', 2, 'DisplayName', 'Euler + upwind');
hold off;
xlabel('$x$ [m]');
ylabel('$\rho$ normalizada');
title('Densidad');
grid on;
xlim([-2 2]);
ylim([0 1]);

% Subplot 2: Presion (normalizada)
subplot(1,3,2);
plot(x_anal_t01, (p_anal/1000 - p_min) / (p_max - p_min), '-', 'Color', c_anal, 'LineWidth', 2, 'DisplayName', 'Analítico');
hold on;
plot(x_hi_val, (p_hi_val/1000 - p_min) / (p_max - p_min), '--', 'Color', c_high, 'LineWidth', 1.5, 'DisplayName', 'Crank-Nicolson + linearUpwind');
plot(x_lo_val, (p_lo_val/1000 - p_min) / (p_max - p_min), ':', 'Color', c_low, 'LineWidth', 2, 'DisplayName', 'Euler + upwind');
hold off;
xlabel('$x$ [m]');
ylabel('$p$ normalizada');
title('Presión');
grid on;
xlim([-2 2]);
ylim([0 1]);

% Subplot 3: Velocidad (normalizada)
subplot(1,3,3);
plot(x_anal_t01, (u_anal - u_min) / (u_max - u_min), '-', 'Color', c_anal, 'LineWidth', 2, 'DisplayName', 'Analítico');
hold on;
plot(x_hi_val, (U_hi_val - u_min) / (u_max - u_min), '--', 'Color', c_high, 'LineWidth', 1.5, 'DisplayName', 'Crank-Nicolson + linearUpwind');
plot(x_lo_val, (U_lo_val - u_min) / (u_max - u_min), ':', 'Color', c_low, 'LineWidth', 2, 'DisplayName', 'Euler + upwind');
hold off;
xlabel('$x$ [m]');
ylabel('$u$ normalizada');
title('Velocidad');
grid on;
xlim([-2 2]);
ylim([0 1]);

% Leyenda comun fuera de los subplots
lgd = legend('Orientation', 'horizontal', 'Position', [0.1 0.02 0.8 0.05]);

sgtitle(sprintf('Validación del tubo de choque de Sod '), ...
    'Interpreter', 'latex', 'FontSize', 14);

% Guardar figura
print(fig1, fullfile(fig_dir, 'shocktube_validacion.png'), '-dpng', '-r300');
fprintf('Guardada: shocktube_validacion.png\n');

%% FIGURA 2: Comparacion de esquemas (t* = 0.15)
fig2 = figure('Position', [100 100 1200 500], 'Color', 'w');

% Escalar solucion analitica para t* = 0.15
X_anal_t015 = scale_analytical(X_anal_norm, t_star_cmp, t_star_anal);
x_anal_t015 = (X_anal_t015 - 0.5) * L;

% Calcular valores normalizados para la region de interes (-2 a 2)
x_range = x_anal_t015 >= -2 & x_anal_t015 <= 2;
rho_all = [rho_anal(x_range); rho_hi_cmp(x_hi_cmp >= -2 & x_hi_cmp <= 2); rho_lo_cmp(x_lo_cmp >= -2 & x_lo_cmp <= 2)];
p_all = [p_anal(x_range)/1000; p_hi_cmp(x_hi_cmp >= -2 & x_hi_cmp <= 2)/1000; p_lo_cmp(x_lo_cmp >= -2 & x_lo_cmp <= 2)/1000];
u_all = [u_anal(x_range); U_hi_cmp(x_hi_cmp >= -2 & x_hi_cmp <= 2); U_lo_cmp(x_lo_cmp >= -2 & x_lo_cmp <= 2)];

rho_min = min(rho_all); rho_max = max(rho_all);
p_min = min(p_all); p_max = max(p_all);
u_min = min(u_all); u_max = max(u_all);

% Subplot 1: Densidad (normalizada)
subplot(1,3,1);
plot(x_anal_t015, (rho_anal - rho_min) / (rho_max - rho_min), '-', 'Color', c_anal, 'LineWidth', 2, 'DisplayName', 'Analítico');
hold on;
plot(x_hi_cmp, (rho_hi_cmp - rho_min) / (rho_max - rho_min), '--', 'Color', c_high, 'LineWidth', 1.5, 'DisplayName', 'Crank-Nicolson + linearUpwind');
plot(x_lo_cmp, (rho_lo_cmp - rho_min) / (rho_max - rho_min), ':', 'Color', c_low, 'LineWidth', 2, 'DisplayName', 'Euler + upwind');
hold off;
xlabel('$x$ [m]');
ylabel('$\rho$ normalizada');
title('Densidad');
grid on;
xlim([-2 2]);
ylim([0 1]);

% Subplot 2: Presion (normalizada)
subplot(1,3,2);
plot(x_anal_t015, (p_anal/1000 - p_min) / (p_max - p_min), '-', 'Color', c_anal, 'LineWidth', 2, 'DisplayName', 'Analítico');
hold on;
plot(x_hi_cmp, (p_hi_cmp/1000 - p_min) / (p_max - p_min), '--', 'Color', c_high, 'LineWidth', 1.5, 'DisplayName', 'Crank-Nicolson + linearUpwind');
plot(x_lo_cmp, (p_lo_cmp/1000 - p_min) / (p_max - p_min), ':', 'Color', c_low, 'LineWidth', 2, 'DisplayName', 'Euler + upwind');
hold off;
xlabel('$x$ [m]');
ylabel('$p$ normalizada');
title('Presión');
grid on;
xlim([-2 2]);
ylim([0 1]);

% Subplot 3: Velocidad (normalizada)
subplot(1,3,3);
plot(x_anal_t015, (u_anal - u_min) / (u_max - u_min), '-', 'Color', c_anal, 'LineWidth', 2, 'DisplayName', 'Analítico');
hold on;
plot(x_hi_cmp, (U_hi_cmp - u_min) / (u_max - u_min), '--', 'Color', c_high, 'LineWidth', 1.5, 'DisplayName', 'Crank-Nicolson + linearUpwind');
plot(x_lo_cmp, (U_lo_cmp - u_min) / (u_max - u_min), ':', 'Color', c_low, 'LineWidth', 2, 'DisplayName', 'Euler + upwind');
hold off;
xlabel('$x$ [m]');
ylabel('$u$ normalizada');
title('Velocidad');
grid on;
xlim([-2 2]);
ylim([0 1]);

% Leyenda comun fuera de los subplots
lgd = legend('Orientation', 'horizontal', 'Position', [0.1 0.02 0.8 0.05]);

sgtitle('Comparación de esquemas numéricos', ...
    'Interpreter', 'latex', 'FontSize', 14);

% Guardar figura
print(fig2, fullfile(fig_dir, 'shocktube_comparacion.png'), '-dpng', '-r300');
fprintf('Guardada: shocktube_comparacion.png\n');

%% FIGURA 3: Evolucion temporal de la presion
fig3 = figure('Position', [100 100 900 600], 'Color', 'w');

% Tiempos disponibles
times_of = {'0', '0.001', '0.002', '0.003', '0.004', '0.005', '0.006', '0.007'};
t_stars = [0, 0.0374, 0.0749, 0.1123, 0.1498, 0.1872, 0.2246, 0.2621];
n_times = length(times_of);
colors_time = parula(n_times);

for i = 1:n_times
    try
        [x_temp, ~, ~, p_temp] = read_of_data(highorder_path, times_of{i});
        plot(x_temp, p_temp/1000, '-', 'Color', colors_time(i,:), 'LineWidth', 1.5, ...
            'DisplayName', sprintf('$t^* = %.2f$', t_stars(i)));
        hold on;
    catch
        % Saltar tiempos no disponibles
    end
end
hold off;

xlabel('$x$ [m]');
ylabel('$p$ [kPa]');
title('Evolucion temporal de la presion (esquema de alto orden)', 'Interpreter', 'latex');
legend('Location', 'southwest', 'NumColumns', 2);
grid on;
xlim([-5 5]);
ylim([0 110]);

% Guardar figura
print(fig3, fullfile(fig_dir, 'shocktube_evolucion_presion.png'), '-dpng', '-r300');
fprintf('Guardada: shocktube_evolucion_presion.png\n');

%% FIGURA 4: Diagrama x-t conceptual
fig4 = figure('Position', [100 100 600 500], 'Color', 'w');

% Parametros del diagrama (escala de tiempo adimensional)
t_max = 0.3;  % t* maximo

% Velocidades caracteristicas normalizadas (de la teoria de Sod)
% Onda de Expansion: cabeza a -1, cola a u*-a* ~ -0.6
v_rar_head = -1.0;  % -a_L/a_L = -1
v_rar_tail = -0.38; % (u* - a*)/a_L

% Discontinuidad de contacto: u*/a_L ~ 0.93
v_contact = 0.927;

% Onda de choque: W_s/a_L ~ 1.39
v_shock = 1.386;

hold on;

% Onda de Expansion (abanico)
n_rar = 10;
v_rar = linspace(v_rar_head, v_rar_tail, n_rar);
for i = 1:n_rar
    t_line = [0 t_max];
    x_line = v_rar(i) * t_line;
    plot(x_line, t_line, '-', 'Color', [0 0.4 0.8], 'LineWidth', 0.8);
end

% Discontinuidad de contacto
t_line = [0 t_max];
x_line = v_contact * t_line;
plot(x_line, t_line, '-', 'Color', [0 0.6 0], 'LineWidth', 2);

% Onda de choque
x_line = v_shock * t_line;
plot(x_line, t_line, '-', 'Color', [0.8 0 0], 'LineWidth', 2);

% Lineas de tiempo de interes
yline(0.1, '--k', '$t^* = 0.1$', 'Interpreter', 'latex', 'LabelHorizontalAlignment', 'left');
yline(0.15, '--k', '$t^* = 0.15$', 'Interpreter', 'latex', 'LabelHorizontalAlignment', 'left');

% Etiquetas de regiones
text(-0.35, 0.2, '(1)', 'FontSize', 14, 'FontWeight', 'bold');
text(-0.1, 0.2, '(2)', 'FontSize', 14, 'FontWeight', 'bold');
text(0.15, 0.2, '(3)', 'FontSize', 14, 'FontWeight', 'bold');
text(0.45, 0.2, '(4)', 'FontSize', 14, 'FontWeight', 'bold');

% Leyenda (crear handles mientras hold on esta activo)
h = zeros(4,1);
h(1) = plot(nan, nan, '-', 'Color', [0 0.4 0.8], 'LineWidth', 2);
h(2) = plot(nan, nan, '-', 'Color', [0 0.6 0], 'LineWidth', 2);
h(3) = plot(nan, nan, '-', 'Color', [0.8 0 0], 'LineWidth', 2);
h(4) = plot(nan, nan, 'k--', 'LineWidth', 1);
legend(h, {'Expansion', 'Contacto', 'Choque', 'Tiempos analisis'}, 'Location', 'northeast');

hold off;

xlabel('$x/L$ (normalizado)');
ylabel('$t^*$ (adimensional)');
title('Diagrama $x$-$t$ del tubo de choque', 'Interpreter', 'latex');
xlim([-0.5 0.5]);
ylim([0 t_max]);
grid on;

% Guardar figura
print(fig4, fullfile(fig_dir, 'shocktube_diagrama_xt.png'), '-dpng', '-r300');
fprintf('Guardada: shocktube_diagrama_xt.png\n');

%% FIGURA 5: Comparacion con VALORES ABSOLUTOS (oscilaciones visibles)
fig5 = figure('Position', [100 100 1200 600], 'Color', 'w');

% Subplot 1: Densidad (valores absolutos)
subplot(2,3,1);
plot(x_anal_t015, rho_anal, '-', 'Color', c_anal, 'LineWidth', 2, 'DisplayName', 'Analítico');
hold on;
plot(x_hi_cmp, rho_hi_cmp, '--', 'Color', c_high, 'LineWidth', 1.5, 'DisplayName', 'Crank-Nicolson + linearUpwind');
plot(x_lo_cmp, rho_lo_cmp, ':', 'Color', c_low, 'LineWidth', 2, 'DisplayName', 'Euler + upwind');
hold off;
xlabel('$x$ [m]');
ylabel('$\rho$ [kg/m$^3$]');
title('Densidad');
grid on;
xlim([-2 2]);
legend('Location', 'northeast');

% Subplot 2: Presion (valores absolutos)
subplot(2,3,2);
plot(x_anal_t015, p_anal/1000, '-', 'Color', c_anal, 'LineWidth', 2, 'DisplayName', 'Analítico');
hold on;
plot(x_hi_cmp, p_hi_cmp/1000, '--', 'Color', c_high, 'LineWidth', 1.5, 'DisplayName', 'Crank-Nicolson + linearUpwind');
plot(x_lo_cmp, p_lo_cmp/1000, ':', 'Color', c_low, 'LineWidth', 2, 'DisplayName', 'Euler + upwind');
hold off;
xlabel('$x$ [m]');
ylabel('$p$ [kPa]');
title('Presión');
grid on;
xlim([-2 2]);
legend('Location', 'northeast');

% Subplot 3: Velocidad (valores absolutos)
subplot(2,3,3);
plot(x_anal_t015, u_anal, '-', 'Color', c_anal, 'LineWidth', 2, 'DisplayName', 'Analítico');
hold on;
plot(x_hi_cmp, U_hi_cmp, '--', 'Color', c_high, 'LineWidth', 1.5, 'DisplayName', 'Crank-Nicolson + linearUpwind');
plot(x_lo_cmp, U_lo_cmp, ':', 'Color', c_low, 'LineWidth', 2, 'DisplayName', 'Euler + upwind');
hold off;
xlabel('$x$ [m]');
ylabel('$u$ [m/s]');
title('Velocidad');
grid on;
xlim([-2 2]);
legend('Location', 'northeast');


sgtitle('Comparación de esquemas', ...
    'Interpreter', 'latex', 'FontSize', 14);

% Guardar figura
print(fig5, fullfile(fig_dir, 'shocktube_oscilaciones_absolutas.png'), '-dpng', '-r300');
fprintf('Guardada: shocktube_oscilaciones_absolutas.png\n');

%% Mensaje de finalizacion
fprintf('\n=== Todas las figuras generadas correctamente ===\n');
fprintf('Directorio de salida: %s\n', fig_dir);

%% ========================================================================
% FUNCION AUXILIAR: Leer datos de linea de OpenFOAM
% =========================================================================
function [x, T, U, p] = readOpenFOAMLine(filepath)
    % Lee archivo line.xy de OpenFOAM postProcessing
    % Formato: x  T  mag(U)  p

    if ~exist(filepath, 'file')
        error('Archivo no encontrado: %s', filepath);
    end

    % Leer datos saltando la cabecera
    data = dlmread(filepath, '', 1, 0);

    x = data(:,1);
    T = data(:,2);
    U = data(:,3);
    p = data(:,4);
end
