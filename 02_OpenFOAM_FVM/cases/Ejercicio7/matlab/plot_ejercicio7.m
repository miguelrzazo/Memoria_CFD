%% EJERCICIO 7: ANALISIS TRANSITORIO - CILINDRO
% Dinamica de Fluidos Computacional
% Analisis de coeficientes aerodinamicos y numero de Strouhal
%
% Reynolds = 200 + 7*50 = 550 (ultima cifra DNI = 7)

clearvars; close all; clc;

%% Configuracion
script_dir = fileparts(mfilename('fullpath'));
if isempty(script_dir)
    script_dir = pwd;
end
case_dir = fullfile(script_dir, '..');
fig_dir = fullfile(script_dir, '..', '..', '..', 'figures', 'Ejercicio7');
if ~exist(fig_dir, 'dir')
    mkdir(fig_dir);
end

set(0, 'DefaultFigureColor', 'w');
set(0, 'DefaultTextInterpreter', 'latex');
set(0, 'DefaultAxesTickLabelInterpreter', 'latex');
set(0, 'DefaultLegendInterpreter', 'latex');

fprintf('=========================================================\n');
fprintf('  EJERCICIO 7: SIMULACION TRANSITORIA - CILINDRO\n');
fprintf('  Re = 550 (ultima cifra DNI = 7)\n');
fprintf('=========================================================\n\n');

%% Parametros del problema
Re = 550;           % Numero de Reynolds
D = 1.0;            % Diametro del cilindro [m]
U_inf = 1.0;        % Velocidad de corriente libre [m/s]
nu = U_inf * D / Re; % Viscosidad cinematica [m^2/s]

fprintf('Parametros:\n');
fprintf('  Re = %d\n', Re);
fprintf('  D = %.1f m\n', D);
fprintf('  U_inf = %.1f m/s\n', U_inf);
fprintf('  nu = %.6f m^2/s\n\n', nu);

%% Cargar datos de forceCoeffs
data_file = fullfile(case_dir, 'cylinder', 'postProcessing', ...
    'forceCoeffsIncompressible', '0', 'forceCoeffs.dat');

fprintf('Cargando datos de: %s\n', data_file);

% Leer archivo saltando comentarios usando textscan
fid = fopen(data_file, 'r');
% Leer todas las líneas
all_lines = {};
while ~feof(fid)
    line = fgetl(fid);
    if ischar(line)
        all_lines{end+1} = line;
    end
end
fclose(fid);

% Procesar líneas que no son comentarios
data = [];
for i = 1:length(all_lines)
    line = strtrim(all_lines{i});
    if ~startsWith(line, '#') && ~isempty(line)
        values = str2num(line);
        if ~isempty(values) && isvector(values)
            data = [data; values];
        end
    end
end

% Extraer columnas
t = data(:, 1);      % Tiempo [s]
Cm = data(:, 2);     % Coeficiente de momento
Cd = data(:, 3);     % Coeficiente de arrastre (drag)
Cl = data(:, 4);     % Coeficiente de sustentacion (lift)

fprintf('  Tiempo simulado: %.1f - %.1f s\n', min(t), max(t));
fprintf('  Numero de puntos: %d\n\n', length(t));

%% Analisis de datos - Periodo estacionario
% Descartar transitorio inicial (primeros 20 s)
t_start = 20;
idx_steady = t >= t_start;
t_steady = t(idx_steady);
Cd_steady = Cd(idx_steady);
Cl_steady = Cl(idx_steady);

fprintf('Analisis periodo estacionario (t > %.0f s):\n', t_start);
fprintf('  Cd medio = %.4f\n', mean(Cd_steady));
fprintf('  Cd min = %.4f, Cd max = %.4f\n', min(Cd_steady), max(Cd_steady));
fprintf('  Cl medio = %.4f\n', mean(Cl_steady));
fprintf('  Cl min = %.4f, Cl max = %.4f\n\n', min(Cl_steady), max(Cl_steady));

%% Valores experimentales de referencia
% Segun Roshko (1954) y Williamson (1996):
% Para Re ~ 550: Cd ~ 1.0-1.2, St ~ 0.21
Cd_exp = 1.1;       % Valor experimental aproximado
St_exp = 0.21;      % Numero de Strouhal experimental

%% Calculo del numero de Strouhal
% St = f * D / U_inf
% Usamos FFT para encontrar la frecuencia dominante del Cl

% Interpolar datos a muestreo uniforme para FFT
dt_uniform = 0.01;  % Paso de tiempo uniforme
t_uniform = t_start:dt_uniform:max(t_steady);
Cl_uniform = interp1(t_steady, Cl_steady, t_uniform, 'pchip');

% FFT
N_fft = length(Cl_uniform);
Fs = 1/dt_uniform;  % Frecuencia de muestreo
f = Fs*(0:(N_fft/2))/N_fft;
Y = fft(Cl_uniform - mean(Cl_uniform));
P = abs(Y/N_fft);
P_single = P(1:floor(N_fft/2)+1);
P_single(2:end-1) = 2*P_single(2:end-1);

% Encontrar frecuencia dominante
[~, idx_max] = max(P_single(2:end));  % Excluir componente DC
f_dominant = f(idx_max + 1);

% Numero de Strouhal
St = f_dominant * D / U_inf;

fprintf('Analisis espectral (FFT):\n');
fprintf('  Frecuencia dominante = %.4f Hz\n', f_dominant);
fprintf('  Numero de Strouhal simulado = %.4f\n', St);
fprintf('  Numero de Strouhal experimental = %.2f\n', St_exp);
fprintf('  Error relativo = %.1f%%\n\n', abs(St - St_exp)/St_exp * 100);

%% GRAFICAS

% 1. Cd vs tiempo
fig1 = figure('Position', [100, 100, 900, 500]);
plot(t, Cd, 'b-', 'LineWidth', 1);
hold on;
yline(mean(Cd_steady), 'r--', 'LineWidth', 1.5, 'DisplayName', sprintf('$\\bar{C}_d$ = %.3f', mean(Cd_steady)));
yline(Cd_exp, 'g--', 'LineWidth', 1.5, 'DisplayName', sprintf('$C_d$ exp = %.2f', Cd_exp));
xlabel('$t$ [s]', 'FontSize', 12, 'Interpreter', 'latex');
ylabel('$C_d$', 'FontSize', 12, 'Interpreter', 'latex');
title(sprintf('Coeficiente de Arrastre vs Tiempo (Re = %d)', Re), 'Interpreter', 'latex', 'FontSize', 14);
legend('$C_d(t)$', sprintf('$\\bar{C}_d$ = %.3f', mean(Cd_steady)), ...
       sprintf('$C_d$ exp = %.2f', Cd_exp), ...
       'Location', 'best', 'FontSize', 10, 'Interpreter', 'latex');
grid on;
xlim([0 max(t)]);
exportgraphics(fig1, fullfile(fig_dir, 'Cd_vs_tiempo.png'), 'Resolution', 300);
fprintf('Guardada: %s\n', fullfile(fig_dir, 'Cd_vs_tiempo.png'));

% 2. Cl vs tiempo
fig2 = figure('Position', [100, 100, 900, 500]);
plot(t, Cl, 'b-', 'LineWidth', 1);
hold on;
yline(0, 'k--', 'LineWidth', 0.5);
xlabel('$t$ [s]', 'FontSize', 12, 'Interpreter', 'latex');
ylabel('$C_l$', 'FontSize', 12, 'Interpreter', 'latex');
title(sprintf('Coeficiente de Sustentacion vs Tiempo (Re = %d)', Re), 'Interpreter', 'latex', 'FontSize', 14);
grid on;
xlim([0 max(t)]);
exportgraphics(fig2, fullfile(fig_dir, 'Cl_vs_tiempo.png'), 'Resolution', 300);
fprintf('Guardada: %s\n', fullfile(fig_dir, 'Cl_vs_tiempo.png'));

% 3. Detalle de Cd y Cl (ultimos 10 segundos)
fig3 = figure('Position', [100, 100, 900, 600]);
t_detail_start = max(t) - 10;
idx_detail = t >= t_detail_start;

subplot(2,1,1)
plot(t(idx_detail), Cd(idx_detail), 'b-', 'LineWidth', 1.5);
hold on;
yline(mean(Cd_steady), 'r--', 'LineWidth', 1.5);
xlabel('$t$ [s]', 'FontSize', 11, 'Interpreter', 'latex');
ylabel('$C_d$', 'FontSize', 11, 'Interpreter', 'latex');
title('Detalle de $C_d$ (ultimos 10 s)', 'Interpreter', 'latex', 'FontSize', 12);
grid on;

subplot(2,1,2)
plot(t(idx_detail), Cl(idx_detail), 'r-', 'LineWidth', 1.5);
hold on;
yline(0, 'k--', 'LineWidth', 0.5);
xlabel('$t$ [s]', 'FontSize', 11, 'Interpreter', 'latex');
ylabel('$C_l$', 'FontSize', 11, 'Interpreter', 'latex');
title('Detalle de $C_l$ (ultimos 10 s)', 'Interpreter', 'latex', 'FontSize', 12);
grid on;

sgtitle(sprintf('Oscilaciones de von Karman (Re = %d)', Re), 'Interpreter', 'latex', 'FontSize', 14, 'FontWeight', 'bold');
exportgraphics(fig3, fullfile(fig_dir, 'Cd_Cl_detalle.png'), 'Resolution', 300);
fprintf('Guardada: %s\n', fullfile(fig_dir, 'Cd_Cl_detalle.png'));

% 4. Espectro de Cl (Strouhal)
fig4 = figure('Position', [100, 100, 800, 500]);
plot(f, P_single, 'b-', 'LineWidth', 1.5);
hold on;
xline(f_dominant, 'r--', 'LineWidth', 1.5, 'Label', sprintf('f = %.3f Hz', f_dominant));
xline(St_exp * U_inf / D, 'g--', 'LineWidth', 1.5, 'Label', sprintf('f_{exp} = %.3f Hz', St_exp * U_inf / D));
xlabel('$f$ [Hz]', 'FontSize', 12, 'Interpreter', 'latex');
ylabel('$|C_l(f)|$', 'FontSize', 12, 'Interpreter', 'latex');
title(sprintf('Espectro de $C_l$ - Numero de Strouhal (St = %.3f)', St), ...
      'Interpreter', 'latex', 'FontSize', 14);
xlim([0 0.5]);
grid on;
legend(sprintf('Espectro $C_l$'), sprintf('$f$ sim = %.3f Hz (St = %.3f)', f_dominant, St), ...
       sprintf('$f$ exp = %.3f Hz (St = %.2f)', St_exp * U_inf / D, St_exp), ...
       'Location', 'best', 'FontSize', 10, 'Interpreter', 'latex');
exportgraphics(fig4, fullfile(fig_dir, 'Strouhal_espectro.png'), 'Resolution', 300);
fprintf('Guardada: %s\n', fullfile(fig_dir, 'Strouhal_espectro.png'));

% 5. Comparacion con valores experimentales
fig5 = figure('Position', [100, 100, 700, 500]);
bar_data = [mean(Cd_steady), Cd_exp; St, St_exp];
bar_labels = {'$C_d$', '$St$'};
b = bar(bar_data);
b(1).FaceColor = [0.2 0.4 0.8];
b(2).FaceColor = [0.8 0.4 0.2];
set(gca, 'XTickLabel', bar_labels, 'FontSize', 12);
ylabel('Valor', 'FontSize', 12, 'Interpreter', 'latex');
title(sprintf('Comparacion Simulacion vs Experimental (Re = %d)', Re), 'Interpreter', 'latex', 'FontSize', 14);
legend('Simulacion', 'Experimental', 'Location', 'best', 'FontSize', 11, 'Interpreter', 'latex');
grid on;

% Anadir valores numericos sobre las barras
for ii = 1:2
    text(ii-0.15, bar_data(ii,1)+0.03, sprintf('%.3f', bar_data(ii,1)), ...
         'FontSize', 10, 'HorizontalAlignment', 'center', 'Interpreter', 'latex');
    text(ii+0.15, bar_data(ii,2)+0.03, sprintf('%.3f', bar_data(ii,2)), ...
         'FontSize', 10, 'HorizontalAlignment', 'center', 'Interpreter', 'latex');
end
exportgraphics(fig5, fullfile(fig_dir, 'comparacion_experimental.png'), 'Resolution', 300);
fprintf('Guardada: %s\n', fullfile(fig_dir, 'comparacion_experimental.png'));

%% 6. DISTRIBUCION DE Cp SOBRE EL CILINDRO (Cuestion a del enunciado)
fprintf('\n--- Analisis de Cp sobre el cilindro ---\n');

% Parametros para Cp
q_inf = 0.5 * U_inf^2;  % Presion dinamica (rho = 1)

% Tiempos a analizar
tiempos_Cp = [25, 30, 40, 50];
labels_Cp = {'$t = 25$ s', '$t = 30$ s', '$t = 40$ s', '$t = 50$ s'};

fig6 = figure('Position', [100, 100, 900, 600]);
colors_Cp = lines(length(tiempos_Cp));

patch_dir = fullfile(case_dir, 'cylinder', 'postProcessing', 'patchSurface');

for idx_t = 1:length(tiempos_Cp)
    % Buscar directorio mas cercano al tiempo deseado
    dirs = dir(patch_dir);
    dirs = dirs([dirs.isdir]);
    dirs = dirs(~ismember({dirs.name}, {'.', '..'}));

    target_time = tiempos_Cp(idx_t);
    times_found = zeros(length(dirs), 1);
    for jj = 1:length(dirs)
        times_found(jj) = str2double(dirs(jj).name);
    end
    times_found = times_found(~isnan(times_found));
    [~, idx_closest] = min(abs(times_found - target_time));
    closest_time = times_found(idx_closest);

    % Leer archivo
    data_file_Cp = fullfile(patch_dir, num2str(closest_time), 'patch.xy');
    if ~exist(data_file_Cp, 'file')
        data_file_Cp = fullfile(patch_dir, sprintf('%.6f', closest_time), 'patch.xy');
    end
    fprintf('  Leyendo Cp de t = %.2f s\n', closest_time);

    fid = fopen(data_file_Cp, 'r');
    if fid == -1
        warning('No se pudo abrir: %s', data_file_Cp);
        continue;
    end
    fgetl(fid);  % Saltar cabecera
    data_Cp = [];
    while ~feof(fid)
        line_Cp = fgetl(fid);
        if ischar(line_Cp) && ~isempty(strtrim(line_Cp))
            values_Cp = str2num(line_Cp);
            if ~isempty(values_Cp)
                data_Cp = [data_Cp; values_Cp];
            end
        end
    end
    fclose(fid);

    % Extraer coordenadas y presion
    x_Cp = data_Cp(:, 1);
    y_Cp = data_Cp(:, 2);
    p_Cp = data_Cp(:, 4);

    % Calcular angulo theta
    theta_Cp = atan2(y_Cp, x_Cp) * 180 / pi;

    % Solo tomar puntos unicos
    [theta_unique, idx_unique] = unique(theta_Cp);
    p_unique = p_Cp(idx_unique);

    % Ordenar por angulo
    [theta_sorted, sort_idx] = sort(theta_unique);
    p_sorted = p_unique(sort_idx);

    % Calcular Cp
    Cp_surface = p_sorted / q_inf;

    % Graficar
    plot(theta_sorted, Cp_surface, '-', 'LineWidth', 1.5, 'Color', colors_Cp(idx_t,:), ...
         'DisplayName', labels_Cp{idx_t});
    hold on;
end

% Solucion teorica (flujo potencial)
theta_teo = linspace(-180, 180, 361);
Cp_teo = 1 - 4*sind(theta_teo).^2;
plot(theta_teo, Cp_teo, 'k--', 'LineWidth', 2, 'DisplayName', 'Flujo potencial');

xlabel('$\theta$ [$^\circ$]', 'FontSize', 12, 'Interpreter', 'latex');
ylabel('$C_p$', 'FontSize', 12, 'Interpreter', 'latex');
title(sprintf('Distribucion de $C_p$ sobre el cilindro (Re = %d)', Re), ...
      'Interpreter', 'latex', 'FontSize', 14);
legend('Location', 'best', 'FontSize', 10, 'Interpreter', 'latex');
grid on;
xlim([-180 180]);
set(gca, 'XTick', -180:45:180);

exportgraphics(fig6, fullfile(fig_dir, 'Cp_distribucion.png'), 'Resolution', 300);
fprintf('Guardada: %s\n', fullfile(fig_dir, 'Cp_distribucion.png'));

%% RESUMEN FINAL
fprintf('\n=========================================================\n');
fprintf('  RESUMEN DE RESULTADOS\n');
fprintf('=========================================================\n');
fprintf('  Reynolds = %d\n', Re);
fprintf('  Cd medio (simulacion) = %.4f\n', mean(Cd_steady));
fprintf('  Cd experimental = %.2f\n', Cd_exp);
fprintf('  Error Cd = %.1f%%\n', abs(mean(Cd_steady) - Cd_exp)/Cd_exp * 100);
fprintf('  St (simulacion) = %.4f\n', St);
fprintf('  St experimental = %.2f\n', St_exp);
fprintf('  Error St = %.1f%%\n', abs(St - St_exp)/St_exp * 100);
fprintf('=========================================================\n');

% Guardar resultados
save(fullfile(fig_dir, 'resultados_ejercicio7.mat'), ...
    't', 'Cd', 'Cl', 'St', 'f_dominant', 'Re', 'Cd_steady', 'Cl_steady');
fprintf('\nDatos guardados en: %s\n', fullfile(fig_dir, 'resultados_ejercicio7.mat'));

fprintf('\nAnalisis completado.\n');
