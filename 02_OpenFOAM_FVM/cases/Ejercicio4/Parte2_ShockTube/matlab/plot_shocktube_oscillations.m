%% ========================================================================
% PLOT_SHOCKTUBE_OSCILLATIONS.M - Analisis de oscilaciones numericas
% Ejercicio 4 - Parte 2: Comparacion de esquemas numericos
% Universidad de Leon - Master en Ingenieria Aeronautica
% =========================================================================
% Este script muestra las oscilaciones numericas en los resultados de OpenFOAM
% comparando esquemas de alto y bajo orden sin normalizacion de datos.
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
rho_L = 1.0;        % kg/m^3 (densidad izquierda)
p_L = 100000;       % Pa (presion izquierda)
gamma = 1.4;        % Coeficiente adiabatico
L = 10;             % Longitud total del dominio (m)
a_L = sqrt(gamma * p_L / rho_L);  % = 374.17 m/s

%% Funcion para leer datos de OpenFOAM postProcessing
read_of_data = @(case_path, time) readOpenFOAMLine(fullfile(case_path, ...
    'postProcessing', 'graph', time, 'line.xy'));

%% Cargar datos numericos
highorder_path = fullfile(case_base, 'shockTube_highorder');
loworder_path = fullfile(case_base, 'shockTube_loworder');

% Tiempo de comparacion (t* = 0.15 -> t = 0.00401 s)
t_cmp_of = '0.004';

fprintf('Cargando datos de OpenFOAM para mostrar oscilaciones...\n');
[x_hi, T_hi, U_hi, p_hi] = read_of_data(highorder_path, t_cmp_of);
[x_lo, T_lo, U_lo, p_lo] = read_of_data(loworder_path, t_cmp_of);

% Calcular densidad desde ecuacion de estado
R = 287;  % J/(kg*K)
rho_hi = p_hi ./ (R * T_hi);
rho_lo = p_lo ./ (R * T_lo);

fprintf('Datos cargados correctamente.\n\n');

%% Configuracion de graficas
set(0, 'DefaultAxesFontSize', 11);
set(0, 'DefaultLineLineWidth', 1.5);
set(0, 'DefaultTextInterpreter', 'latex');
set(0, 'DefaultAxesTickLabelInterpreter', 'latex');
set(0, 'DefaultLegendInterpreter', 'latex');

% Colores
c_high = [0 0.447 0.741];   % Azul - alto orden
c_low = [0.850 0.325 0.098]; % Naranja - bajo orden

%% FIGURA 1: Comparacion de densidad con oscilaciones visibles
fig1 = figure('Position', [100 100 1000 600], 'Color', 'w');

subplot(2,1,1);
plot(x_hi, rho_hi, '-', 'Color', c_high, 'LineWidth', 2, 'DisplayName', 'Crank-Nicolson + linearUpwind');
hold on;
plot(x_lo, rho_lo, '-', 'Color', c_low, 'LineWidth', 2, 'DisplayName', 'Euler + upwind');
hold off;
xlabel('$x$ [m]');
ylabel('$\rho$ [kg/m$^3$]');
title('Densidad - Valores absolutos (oscilaciones visibles)');
legend('Location', 'northeast');
grid on;
xlim([-2 2]);

subplot(2,1,2);
plot(x_hi, rho_hi, '-', 'Color', c_high, 'LineWidth', 2, 'DisplayName', 'Crank-Nicolson + linearUpwind');
hold on;
plot(x_lo, rho_lo, '-', 'Color', c_low, 'LineWidth', 2, 'DisplayName', 'Euler + upwind');
hold off;
xlabel('$x$ [m]');
ylabel('$\rho$ [kg/m$^3$]');
title('Densidad - Zoom en la zona de contacto (oscilaciones amplificadas)');
legend('Location', 'northeast');
grid on;
xlim([-0.5 0.5]);  % Zoom en zona critica

sgtitle('Comparación de oscilaciones numéricas en densidad ($t^* = 0.15$)', ...
    'Interpreter', 'latex', 'FontSize', 14);

% Guardar figura
print(fig1, fullfile(fig_dir, 'shocktube_oscilaciones_densidad.png'), '-dpng', '-r300');
fprintf('Guardada: shocktube_oscilaciones_densidad.png\n');

%% FIGURA 2: Comparacion de presion con oscilaciones visibles
fig2 = figure('Position', [100 100 1000 600], 'Color', 'w');

subplot(2,1,1);
plot(x_hi, p_hi/1000, '-', 'Color', c_high, 'LineWidth', 2, 'DisplayName', 'Crank-Nicolson + linearUpwind');
hold on;
plot(x_lo, p_lo/1000, '-', 'Color', c_low, 'LineWidth', 2, 'DisplayName', 'Euler + upwind');
hold off;
xlabel('$x$ [m]');
ylabel('$p$ [kPa]');
title('Presión - Valores absolutos (oscilaciones visibles)');
legend('Location', 'northeast');
grid on;
xlim([-2 2]);

subplot(2,1,2);
plot(x_hi, p_hi/1000, '-', 'Color', c_high, 'LineWidth', 2, 'DisplayName', 'Crank-Nicolson + linearUpwind');
hold on;
plot(x_lo, p_lo/1000, '-', 'Color', c_low, 'LineWidth', 2, 'DisplayName', 'Euler + upwind');
hold off;
xlabel('$x$ [m]');
ylabel('$p$ [kPa]');
title('Presión - Zoom en la zona de contacto (oscilaciones amplificadas)');
legend('Location', 'northeast');
grid on;
xlim([-0.5 0.5]);  % Zoom en zona critica

sgtitle('Comparación de oscilaciones numéricas en presión ($t^* = 0.15$)', ...
    'Interpreter', 'latex', 'FontSize', 14);

% Guardar figura
print(fig2, fullfile(fig_dir, 'shocktube_oscilaciones_presion.png'), '-dpng', '-r300');
fprintf('Guardada: shocktube_oscilaciones_presion.png\n');

%% FIGURA 3: Comparacion de velocidad con oscilaciones visibles
fig3 = figure('Position', [100 100 1000 600], 'Color', 'w');

subplot(2,1,1);
plot(x_hi, U_hi, '-', 'Color', c_high, 'LineWidth', 2, 'DisplayName', 'Crank-Nicolson + linearUpwind');
hold on;
plot(x_lo, U_lo, '-', 'Color', c_low, 'LineWidth', 2, 'DisplayName', 'Euler + upwind');
hold off;
xlabel('$x$ [m]');
ylabel('$u$ [m/s]');
title('Velocidad - Valores absolutos (oscilaciones visibles)');
legend('Location', 'northeast');
grid on;
xlim([-2 2]);

subplot(2,1,2);
plot(x_hi, U_hi, '-', 'Color', c_high, 'LineWidth', 2, 'DisplayName', 'Crank-Nicolson + linearUpwind');
hold on;
plot(x_lo, U_lo, '-', 'Color', c_low, 'LineWidth', 2, 'DisplayName', 'Euler + upwind');
hold off;
xlabel('$x$ [m]');
ylabel('$u$ [m/s]');
title('Velocidad - Zoom en la zona de contacto (oscilaciones amplificadas)');
legend('Location', 'northeast');
grid on;
xlim([-0.5 0.5]);  % Zoom en zona critica

sgtitle('Comparación de oscilaciones numéricas en velocidad ($t^* = 0.15$)', ...
    'Interpreter', 'latex', 'FontSize', 14);

% Guardar figura
print(fig3, fullfile(fig_dir, 'shocktube_oscilaciones_velocidad.png'), '-dpng', '-r300');
fprintf('Guardada: shocktube_oscilaciones_velocidad.png\n');

%% FIGURA 4: Comparacion lado a lado de todas las variables
fig4 = figure('Position', [100 100 1400 800], 'Color', 'w');

% Densidad
subplot(2,3,1);
plot(x_hi, rho_hi, '-', 'Color', c_high, 'LineWidth', 2, 'DisplayName', 'Alto orden');
hold on;
plot(x_lo, rho_lo, '-', 'Color', c_low, 'LineWidth', 2, 'DisplayName', 'Bajo orden');
hold off;
xlabel('$x$ [m]');
ylabel('$\rho$ [kg/m$^3$]');
title('Densidad');
legend('Location', 'northeast');
grid on;
xlim([-2 2]);

% Presion
subplot(2,3,2);
plot(x_hi, p_hi/1000, '-', 'Color', c_high, 'LineWidth', 2, 'DisplayName', 'Alto orden');
hold on;
plot(x_lo, p_lo/1000, '-', 'Color', c_low, 'LineWidth', 2, 'DisplayName', 'Bajo orden');
hold off;
xlabel('$x$ [m]');
ylabel('$p$ [kPa]');
title('Presión');
legend('Location', 'northeast');
grid on;
xlim([-2 2]);

% Velocidad
subplot(2,3,3);
plot(x_hi, U_hi, '-', 'Color', c_high, 'LineWidth', 2, 'DisplayName', 'Alto orden');
hold on;
plot(x_lo, U_lo, '-', 'Color', c_low, 'LineWidth', 2, 'DisplayName', 'Bajo orden');
hold off;
xlabel('$x$ [m]');
ylabel('$u$ [m/s]');
title('Velocidad');
legend('Location', 'northeast');
grid on;
xlim([-2 2]);

% Zoom en zona critica - Densidad
subplot(2,3,4);
plot(x_hi, rho_hi, '-', 'Color', c_high, 'LineWidth', 2, 'DisplayName', 'Alto orden');
hold on;
plot(x_lo, rho_lo, '-', 'Color', c_low, 'LineWidth', 2, 'DisplayName', 'Bajo orden');
hold off;
xlabel('$x$ [m]');
ylabel('$\rho$ [kg/m$^3$]');
title('Densidad (zoom zona crítica)');
legend('Location', 'northeast');
grid on;
xlim([-0.5 0.5]);

% Zoom en zona critica - Presion
subplot(2,3,5);
plot(x_hi, p_hi/1000, '-', 'Color', c_high, 'LineWidth', 2, 'DisplayName', 'Alto orden');
hold on;
plot(x_lo, p_lo/1000, '-', 'Color', c_low, 'LineWidth', 2, 'DisplayName', 'Bajo orden');
hold off;
xlabel('$x$ [m]');
ylabel('$p$ [kPa]');
title('Presión (zoom zona crítica)');
legend('Location', 'northeast');
grid on;
xlim([-0.5 0.5]);

% Zoom en zona critica - Velocidad
subplot(2,3,6);
plot(x_hi, U_hi, '-', 'Color', c_high, 'LineWidth', 2, 'DisplayName', 'Alto orden');
hold on;
plot(x_lo, U_lo, '-', 'Color', c_low, 'LineWidth', 2, 'DisplayName', 'Bajo orden');
hold off;
xlabel('$x$ [m]');
ylabel('$u$ [m/s]');
title('Velocidad (zoom zona crítica)');
legend('Location', 'northeast');
grid on;
xlim([-0.5 0.5]);

sgtitle('Análisis completo de oscilaciones numéricas ($t^* = 0.15$)', ...
    'Interpreter', 'latex', 'FontSize', 16);

% Guardar figura
print(fig4, fullfile(fig_dir, 'shocktube_oscilaciones_completo.png'), '-dpng', '-r300');
fprintf('Guardada: shocktube_oscilaciones_completo.png\n');

%% Mensaje de finalizacion
fprintf('\n=== Figuras de oscilaciones generadas correctamente ===\n');
fprintf('Directorio de salida: %s\n', fig_dir);
fprintf('Las oscilaciones son más visibles en el esquema de bajo orden (Euler + upwind)\n');
fprintf('debido a la mayor difusión numérica y menor resolución del esquema.\n');

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