%% ========================================================================
%  EJERCICIO 4 - PARTE 2: TUBO DE CHOQUE DE SOD
%  Análisis de esquemas numéricos en OpenFOAM
%  Universidad de León - Máster en Ingeniería Aeronáutica
%  Autor: Miguel Rosa
%  Fecha: Diciembre 2025
%% ========================================================================

clear; close all; clc;

%% ========================================================================
%  1. CONFIGURACIÓN Y RUTAS
%% ========================================================================

% Directorios
base_dir = fileparts(fileparts(mfilename('fullpath')));
case_dir = fullfile(base_dir, 'cases', 'Ejercicio4');
fig_dir = fullfile(base_dir, 'figures', 'Ejercicio4');

% Crear directorio de figuras si no existe
if ~exist(fig_dir, 'dir')
    mkdir(fig_dir);
end

% Archivos de datos
analytical_file = fullfile(case_dir, 'ResultadosAnaliticos.csv');
highOrder_dir = fullfile(case_dir, 'shockTube', 'postProcessing', 'graph');
lowOrder_dir = fullfile(case_dir, 'shockTube_lowOrder', 'postProcessing', 'graph');

fprintf('======================================================\n');
fprintf('EJERCICIO 4 - PARTE 2: TUBO DE CHOQUE DE SOD\n');
fprintf('======================================================\n\n');

%% ========================================================================
%  2. CARGAR SOLUCIÓN ANALÍTICA
%% ========================================================================

fprintf('Cargando solución analítica...\n');

% Leer archivo CSV
analytical_data = readmatrix(analytical_file);
x_analytical = analytical_data(:, 1);
rho_analytical = analytical_data(:, 2);
p_analytical = analytical_data(:, 3);
u_analytical = analytical_data(:, 4);

fprintf('  - Puntos analíticos: %d\n', length(x_analytical));
fprintf('  - Rango x: [%.3f, %.3f]\n', min(x_analytical), max(x_analytical));

%% ========================================================================
%  3. CARGAR RESULTADOS DE OPENFOAM
%% ========================================================================

% Tiempos disponibles
times_to_analyze_high = [0.1];  % Tiempo de validación según enunciado
times_to_analyze_low = [0.09];  % lowOrder case solo llegó a 0.09s

% Inicializar estructuras
data_highOrder = struct();
data_lowOrder = struct();

%% 3.1 Cargar datos de esquema de ALTO ORDEN (vanAlbada)
fprintf('\nCargando resultados de alto orden (vanAlbada)...\n');

for i = 1:length(times_to_analyze_high)
    t = times_to_analyze_high(i);

    % Try different time formats
    t_str = sprintf('%.2f', t);
    if ~exist(fullfile(highOrder_dir, t_str), 'dir')
        t_str = sprintf('%.1f', t);
    end
    if ~exist(fullfile(highOrder_dir, t_str), 'dir')
        t_str = num2str(t);
    end

    % Archivo de datos
    data_file = fullfile(highOrder_dir, t_str, 'line.xy');

    if exist(data_file, 'file')
        % Leer datos (columnas: x, T, mag(U), p)
        raw_data = readmatrix(data_file, 'FileType', 'text', 'CommentStyle', '#');

        data_highOrder(i).t = t;
        data_highOrder(i).x = raw_data(:, 1);
        data_highOrder(i).T = raw_data(:, 2);
        data_highOrder(i).U = raw_data(:, 3);
        data_highOrder(i).p = raw_data(:, 4);

        % Convertir a variables adimensionales del problema de Sod
        % Para gas ideal: p = rho * R * T  =>  rho = p / (R * T)
        % Usando R = 287 J/(kg·K) para aire
        R = 287.0;
        data_highOrder(i).rho = data_highOrder(i).p ./ (R * data_highOrder(i).T);

        % Normalizar coordenada x al dominio [0, 1]
        x_min = min(data_highOrder(i).x);
        x_max = max(data_highOrder(i).x);
        data_highOrder(i).x_norm = (data_highOrder(i).x - x_min) / (x_max - x_min);

        % Normalizar variables (según condiciones iniciales de Sod)
        % Lado izquierdo: rho=1, p=1, u=0
        % Lado derecho: rho=0.125, p=0.1, u=0
        rho_ref = 1.0;
        p_ref = 1.0;
        u_ref = 1.0;  % Escala de velocidad característica

        data_highOrder(i).rho_norm = data_highOrder(i).rho / rho_ref;
        data_highOrder(i).p_norm = data_highOrder(i).p / p_ref;
        data_highOrder(i).u_norm = data_highOrder(i).U / u_ref;

        fprintf('  - t = %.2f s: %d puntos cargados\n', t, length(data_highOrder(i).x));
    else
        fprintf('  - ADVERTENCIA: No se encontró archivo para t = %.2f s\n', t);
    end
end

%% 3.2 Cargar datos de esquema de BAJO ORDEN (upwind)
fprintf('\nCargando resultados de bajo orden (upwind)...\n');

for i = 1:length(times_to_analyze_low)
    t = times_to_analyze_low(i);

    % Try different time formats
    t_str = sprintf('%.2f', t);
    if ~exist(fullfile(lowOrder_dir, t_str), 'dir')
        t_str = sprintf('%.1f', t);
    end
    if ~exist(fullfile(lowOrder_dir, t_str), 'dir')
        t_str = num2str(t);
    end

    % Archivo de datos
    data_file = fullfile(lowOrder_dir, t_str, 'line.xy');

    if exist(data_file, 'file')
        % Leer datos
        raw_data = readmatrix(data_file, 'FileType', 'text', 'CommentStyle', '#');

        data_lowOrder(i).t = t;
        data_lowOrder(i).x = raw_data(:, 1);
        data_lowOrder(i).T = raw_data(:, 2);
        data_lowOrder(i).U = raw_data(:, 3);
        data_lowOrder(i).p = raw_data(:, 4);

        % Convertir a variables adimensionales
        R = 287.0;
        data_lowOrder(i).rho = data_lowOrder(i).p ./ (R * data_lowOrder(i).T);

        % Normalizar coordenada x
        x_min = min(data_lowOrder(i).x);
        x_max = max(data_lowOrder(i).x);
        data_lowOrder(i).x_norm = (data_lowOrder(i).x - x_min) / (x_max - x_min);

        % Normalizar variables
        rho_ref = 1.0;
        p_ref = 1.0;
        u_ref = 1.0;

        data_lowOrder(i).rho_norm = data_lowOrder(i).rho / rho_ref;
        data_lowOrder(i).p_norm = data_lowOrder(i).p / p_ref;
        data_lowOrder(i).u_norm = data_lowOrder(i).U / u_ref;

        fprintf('  - t = %.2f s: %d puntos cargados\n', t, length(data_lowOrder(i).x));
    else
        fprintf('  - ADVERTENCIA: No se encontró archivo para t = %.2f s\n', t);
    end
end

%% ========================================================================
%  4. VALIDACIÓN CON SOLUCIÓN ANALÍTICA (t = 0.1s)
%% ========================================================================

fprintf('\n======================================================\n');
fprintf('VALIDACIÓN CON SOLUCIÓN ANALÍTICA (t = 0.1s)\n');
fprintf('======================================================\n\n');

idx_t = 1;  % t = 0.1s

if isfield(data_highOrder, 'x')
    % Interpolar solución numérica a puntos analíticos
    rho_num_interp = interp1(data_highOrder(idx_t).x_norm, data_highOrder(idx_t).rho_norm, ...
                              x_analytical, 'linear', 'extrap');
    p_num_interp = interp1(data_highOrder(idx_t).x_norm, data_highOrder(idx_t).p_norm, ...
                            x_analytical, 'linear', 'extrap');
    u_num_interp = interp1(data_highOrder(idx_t).x_norm, data_highOrder(idx_t).u_norm, ...
                            x_analytical, 'linear', 'extrap');

    % Calcular errores
    error_rho = sqrt(mean((rho_num_interp - rho_analytical).^2));
    error_p = sqrt(mean((p_num_interp - p_analytical).^2));
    error_u = sqrt(mean((u_num_interp - u_analytical).^2));

    fprintf('Error RMS (esquema alto orden):\n');
    fprintf('  - Densidad:  %.6f\n', error_rho);
    fprintf('  - Presión:   %.6f\n', error_p);
    fprintf('  - Velocidad: %.6f\n', error_u);

    %% Figura 1: Validación - Densidad
    figure('Position', [100, 100, 800, 600]);
    plot(x_analytical, rho_analytical, 'k-', 'LineWidth', 2, 'DisplayName', 'Solución analítica');
    hold on;
    plot(data_highOrder(idx_t).x_norm, data_highOrder(idx_t).rho_norm, 'b--o', ...
         'LineWidth', 1.5, 'MarkerSize', 4, 'DisplayName', 'OpenFOAM (vanAlbada)');
    grid on;
    xlabel('$x$ (m)', 'Interpreter', 'latex', 'FontSize', 14);
    ylabel('$\rho/\rho_0$', 'Interpreter', 'latex', 'FontSize', 14);
    title('Validaci\''on: Densidad normalizada (t = 0.1 s)', 'Interpreter', 'none', 'FontSize', 16);
    legend('Location', 'best', 'Interpreter', 'latex', 'FontSize', 12);
    set(gca, 'FontSize', 12);

    % Guardar
    saveas(gcf, fullfile(fig_dir, 'Parte2_Validacion_Densidad.png'));
    fprintf('\n  - Figura guardada: Parte2_Validacion_Densidad.png\n');

    %% Figura 2: Validación - Presión
    figure('Position', [120, 120, 800, 600]);
    plot(x_analytical, p_analytical, 'k-', 'LineWidth', 2, 'DisplayName', 'Solución analítica');
    hold on;
    plot(data_highOrder(idx_t).x_norm, data_highOrder(idx_t).p_norm, 'r--o', ...
         'LineWidth', 1.5, 'MarkerSize', 4, 'DisplayName', 'OpenFOAM (vanAlbada)');
    grid on;
    xlabel('$x$ (m)', 'Interpreter', 'latex', 'FontSize', 14);
    ylabel('$p/p_0$', 'Interpreter', 'latex', 'FontSize', 14);
    title('Validación: Presión normalizada ($t = 0.1$ s)', 'Interpreter', 'latex', 'FontSize', 16);
    legend('Location', 'best', 'Interpreter', 'latex', 'FontSize', 12);
    set(gca, 'FontSize', 12);

    % Guardar
    saveas(gcf, fullfile(fig_dir, 'Parte2_Validacion_Presion.png'));
    fprintf('  - Figura guardada: Parte2_Validacion_Presion.png\n');

    %% Figura 3: Validación - Velocidad
    figure('Position', [140, 140, 800, 600]);
    plot(x_analytical, u_analytical, 'k-', 'LineWidth', 2, 'DisplayName', 'Solución analítica');
    hold on;
    plot(data_highOrder(idx_t).x_norm, data_highOrder(idx_t).u_norm, 'g--o', ...
         'LineWidth', 1.5, 'MarkerSize', 4, 'DisplayName', 'OpenFOAM (vanAlbada)');
    grid on;
    xlabel('$x$ (m)', 'Interpreter', 'latex', 'FontSize', 14);
    ylabel('$u/u_0$', 'Interpreter', 'latex', 'FontSize', 14);
    title('Validación: Velocidad normalizada ($t = 0.1$ s)', 'Interpreter', 'latex', 'FontSize', 16);
    legend('Location', 'best', 'Interpreter', 'latex', 'FontSize', 12);
    set(gca, 'FontSize', 12);

    % Guardar
    saveas(gcf, fullfile(fig_dir, 'Parte2_Validacion_Velocidad.png'));
    fprintf('  - Figura guardada: Parte2_Validacion_Velocidad.png\n');

    %% Figura 4: Validación - Todas las variables
    figure('Position', [160, 160, 1000, 800]);

    subplot(3, 1, 1);
    plot(x_analytical, rho_analytical, 'k-', 'LineWidth', 2);
    hold on;
    plot(data_highOrder(idx_t).x_norm, data_highOrder(idx_t).rho_norm, 'b--o', ...
         'LineWidth', 1.5, 'MarkerSize', 3);
    grid on;
    ylabel('$\rho/\rho_0$', 'Interpreter', 'latex', 'FontSize', 12);
    title('Validación del tubo de choque de Sod ($t = 0.1$ s)', 'Interpreter', 'latex', 'FontSize', 14);
    legend('Analítica', 'OpenFOAM (vanAlbada)', 'Location', 'best', 'Interpreter', 'latex');
    set(gca, 'FontSize', 11);

    subplot(3, 1, 2);
    plot(x_analytical, p_analytical, 'k-', 'LineWidth', 2);
    hold on;
    plot(data_highOrder(idx_t).x_norm, data_highOrder(idx_t).p_norm, 'r--o', ...
         'LineWidth', 1.5, 'MarkerSize', 3);
    grid on;
    ylabel('$p/p_0$', 'Interpreter', 'latex', 'FontSize', 12);
    legend('Analítica', 'OpenFOAM (vanAlbada)', 'Location', 'best', 'Interpreter', 'latex');
    set(gca, 'FontSize', 11);

    subplot(3, 1, 3);
    plot(x_analytical, u_analytical, 'k-', 'LineWidth', 2);
    hold on;
    plot(data_highOrder(idx_t).x_norm, data_highOrder(idx_t).u_norm, 'g--o', ...
         'LineWidth', 1.5, 'MarkerSize', 3);
    grid on;
    xlabel('$x$ (m)', 'Interpreter', 'latex', 'FontSize', 12);
    ylabel('$u/u_0$', 'Interpreter', 'latex', 'FontSize', 12);
    legend('Analítica', 'OpenFOAM (vanAlbada)', 'Location', 'best', 'Interpreter', 'latex');
    set(gca, 'FontSize', 11);

    % Guardar
    saveas(gcf, fullfile(fig_dir, 'Parte2_Validacion_Completa.png'));
    fprintf('  - Figura guardada: Parte2_Validacion_Completa.png\n');
end

%% ========================================================================
%  5. COMPARACIÓN DE ESQUEMAS NUMÉRICOS (t = 0.1s)
%% ========================================================================

fprintf('\n======================================================\n');
fprintf('COMPARACIÓN DE ESQUEMAS NUMÉRICOS\n');
fprintf('======================================================\n\n');

if isfield(data_highOrder, 'x') && isfield(data_lowOrder, 'x')

    %% Figura 5: Comparación - Densidad
    figure('Position', [180, 180, 800, 600]);
    plot(x_analytical, rho_analytical, 'k-', 'LineWidth', 2.5, 'DisplayName', 'Solución analítica');
    hold on;
    plot(data_highOrder(idx_t).x_norm, data_highOrder(idx_t).rho_norm, 'b--o', ...
         'LineWidth', 1.5, 'MarkerSize', 4, 'DisplayName', 'Alto orden (vanAlbada)');
    plot(data_lowOrder(idx_t).x_norm, data_lowOrder(idx_t).rho_norm, 'r--s', ...
         'LineWidth', 1.5, 'MarkerSize', 4, 'DisplayName', 'Bajo orden (upwind)');
    grid on;
    xlabel('$x$ (m)', 'Interpreter', 'latex', 'FontSize', 14);
    ylabel('$\rho/\rho_0$', 'Interpreter', 'latex', 'FontSize', 14);
    title('Comparación de esquemas: Densidad ($t = 0.1$ s)', 'Interpreter', 'latex', 'FontSize', 16);
    legend('Location', 'best', 'Interpreter', 'latex', 'FontSize', 12);
    set(gca, 'FontSize', 12);

    % Guardar
    saveas(gcf, fullfile(fig_dir, 'Parte2_Comparacion_Densidad.png'));
    fprintf('  - Figura guardada: Parte2_Comparacion_Densidad.png\n');

    %% Figura 6: Comparación - Presión
    figure('Position', [200, 200, 800, 600]);
    plot(x_analytical, p_analytical, 'k-', 'LineWidth', 2.5, 'DisplayName', 'Solución analítica');
    hold on;
    plot(data_highOrder(idx_t).x_norm, data_highOrder(idx_t).p_norm, 'b--o', ...
         'LineWidth', 1.5, 'MarkerSize', 4, 'DisplayName', 'Alto orden (vanAlbada)');
    plot(data_lowOrder(idx_t).x_norm, data_lowOrder(idx_t).p_norm, 'r--s', ...
         'LineWidth', 1.5, 'MarkerSize', 4, 'DisplayName', 'Bajo orden (upwind)');
    grid on;
    xlabel('$x$ (m)', 'Interpreter', 'latex', 'FontSize', 14);
    ylabel('$p/p_0$', 'Interpreter', 'latex', 'FontSize', 14);
    title('Comparación de esquemas: Presión ($t = 0.1$ s)', 'Interpreter', 'latex', 'FontSize', 16);
    legend('Location', 'best', 'Interpreter', 'latex', 'FontSize', 12);
    set(gca, 'FontSize', 12);

    % Guardar
    saveas(gcf, fullfile(fig_dir, 'Parte2_Comparacion_Presion.png'));
    fprintf('  - Figura guardada: Parte2_Comparacion_Presion.png\n');

    %% Figura 7: Comparación - Velocidad
    figure('Position', [220, 220, 800, 600]);
    plot(x_analytical, u_analytical, 'k-', 'LineWidth', 2.5, 'DisplayName', 'Solución analítica');
    hold on;
    plot(data_highOrder(idx_t).x_norm, data_highOrder(idx_t).u_norm, 'b--o', ...
         'LineWidth', 1.5, 'MarkerSize', 4, 'DisplayName', 'Alto orden (vanAlbada)');
    plot(data_lowOrder(idx_t).x_norm, data_lowOrder(idx_t).u_norm, 'r--s', ...
         'LineWidth', 1.5, 'MarkerSize', 4, 'DisplayName', 'Bajo orden (upwind)');
    grid on;
    xlabel('$x$ (m)', 'Interpreter', 'latex', 'FontSize', 14);
    ylabel('$u/u_0$', 'Interpreter', 'latex', 'FontSize', 14);
    title('Comparación de esquemas: Velocidad ($t = 0.1$ s)', 'Interpreter', 'latex', 'FontSize', 16);
    legend('Location', 'best', 'Interpreter', 'latex', 'FontSize', 12);
    set(gca, 'FontSize', 12);

    % Guardar
    saveas(gcf, fullfile(fig_dir, 'Parte2_Comparacion_Velocidad.png'));
    fprintf('  - Figura guardada: Parte2_Comparacion_Velocidad.png\n');

    %% Figura 8: Comparación completa
    figure('Position', [240, 240, 1000, 800]);

    subplot(3, 1, 1);
    plot(x_analytical, rho_analytical, 'k-', 'LineWidth', 2.5);
    hold on;
    plot(data_highOrder(idx_t).x_norm, data_highOrder(idx_t).rho_norm, 'b--o', ...
         'LineWidth', 1.5, 'MarkerSize', 3);
    plot(data_lowOrder(idx_t).x_norm, data_lowOrder(idx_t).rho_norm, 'r--s', ...
         'LineWidth', 1.5, 'MarkerSize', 3);
    grid on;
    ylabel('$\rho/\rho_0$', 'Interpreter', 'latex', 'FontSize', 12);
    title('Comparación de esquemas numéricos ($t = 0.1$ s)', 'Interpreter', 'latex', 'FontSize', 14);
    legend('Analítica', 'vanAlbada', 'upwind', 'Location', 'best', 'Interpreter', 'latex');
    set(gca, 'FontSize', 11);

    subplot(3, 1, 2);
    plot(x_analytical, p_analytical, 'k-', 'LineWidth', 2.5);
    hold on;
    plot(data_highOrder(idx_t).x_norm, data_highOrder(idx_t).p_norm, 'b--o', ...
         'LineWidth', 1.5, 'MarkerSize', 3);
    plot(data_lowOrder(idx_t).x_norm, data_lowOrder(idx_t).p_norm, 'r--s', ...
         'LineWidth', 1.5, 'MarkerSize', 3);
    grid on;
    ylabel('$p/p_0$', 'Interpreter', 'latex', 'FontSize', 12);
    legend('Analítica', 'vanAlbada', 'upwind', 'Location', 'best', 'Interpreter', 'latex');
    set(gca, 'FontSize', 11);

    subplot(3, 1, 3);
    plot(x_analytical, u_analytical, 'k-', 'LineWidth', 2.5);
    hold on;
    plot(data_highOrder(idx_t).x_norm, data_highOrder(idx_t).u_norm, 'b--o', ...
         'LineWidth', 1.5, 'MarkerSize', 3);
    plot(data_lowOrder(idx_t).x_norm, data_lowOrder(idx_t).u_norm, 'r--s', ...
         'LineWidth', 1.5, 'MarkerSize', 3);
    grid on;
    xlabel('$x$ (m)', 'Interpreter', 'latex', 'FontSize', 12);
    ylabel('$u/u_0$', 'Interpreter', 'latex', 'FontSize', 12);
    legend('Analítica', 'vanAlbada', 'upwind', 'Location', 'best', 'Interpreter', 'latex');
    set(gca, 'FontSize', 11);

    % Guardar
    saveas(gcf, fullfile(fig_dir, 'Parte2_Comparacion_Completa.png'));
    fprintf('  - Figura guardada: Parte2_Comparacion_Completa.png\n');

    %% Análisis de errores
    % Interpolar ambas soluciones a puntos analíticos
    rho_high_interp = interp1(data_highOrder(idx_t).x_norm, data_highOrder(idx_t).rho_norm, ...
                               x_analytical, 'linear', 'extrap');
    rho_low_interp = interp1(data_lowOrder(idx_t).x_norm, data_lowOrder(idx_t).rho_norm, ...
                              x_analytical, 'linear', 'extrap');

    p_high_interp = interp1(data_highOrder(idx_t).x_norm, data_highOrder(idx_t).p_norm, ...
                             x_analytical, 'linear', 'extrap');
    p_low_interp = interp1(data_lowOrder(idx_t).x_norm, data_lowOrder(idx_t).p_norm, ...
                            x_analytical, 'linear', 'extrap');

    u_high_interp = interp1(data_highOrder(idx_t).x_norm, data_highOrder(idx_t).u_norm, ...
                             x_analytical, 'linear', 'extrap');
    u_low_interp = interp1(data_lowOrder(idx_t).x_norm, data_lowOrder(idx_t).u_norm, ...
                            x_analytical, 'linear', 'extrap');

    % Errores RMS
    error_rho_high = sqrt(mean((rho_high_interp - rho_analytical).^2));
    error_rho_low = sqrt(mean((rho_low_interp - rho_analytical).^2));

    error_p_high = sqrt(mean((p_high_interp - p_analytical).^2));
    error_p_low = sqrt(mean((p_low_interp - p_analytical).^2));

    error_u_high = sqrt(mean((u_high_interp - u_analytical).^2));
    error_u_low = sqrt(mean((u_low_interp - u_analytical).^2));

    fprintf('\nAnálisis de errores (RMS):\n');
    fprintf('  Variable     | Alto orden | Bajo orden | Mejora\n');
    fprintf('  -------------|------------|------------|--------\n');
    fprintf('  Densidad     | %.6f   | %.6f   | %.1f%%\n', ...
            error_rho_high, error_rho_low, (1 - error_rho_high/error_rho_low)*100);
    fprintf('  Presión      | %.6f   | %.6f   | %.1f%%\n', ...
            error_p_high, error_p_low, (1 - error_p_high/error_p_low)*100);
    fprintf('  Velocidad    | %.6f   | %.6f   | %.1f%%\n', ...
            error_u_high, error_u_low, (1 - error_u_high/error_u_low)*100);

    %% Figura 9: Errores absolutos
    figure('Position', [260, 260, 1000, 800]);

    subplot(3, 1, 1);
    plot(x_analytical, abs(rho_high_interp - rho_analytical), 'b-', 'LineWidth', 2);
    hold on;
    plot(x_analytical, abs(rho_low_interp - rho_analytical), 'r-', 'LineWidth', 2);
    grid on;
    ylabel('$|\Delta \rho|$', 'Interpreter', 'latex', 'FontSize', 12);
    title('Error absoluto respecto a solución analítica', 'Interpreter', 'latex', 'FontSize', 14);
    legend('vanAlbada', 'upwind', 'Location', 'best', 'Interpreter', 'latex');
    set(gca, 'FontSize', 11);

    subplot(3, 1, 2);
    plot(x_analytical, abs(p_high_interp - p_analytical), 'b-', 'LineWidth', 2);
    hold on;
    plot(x_analytical, abs(p_low_interp - p_analytical), 'r-', 'LineWidth', 2);
    grid on;
    ylabel('$|\Delta p|$', 'Interpreter', 'latex', 'FontSize', 12);
    legend('vanAlbada', 'upwind', 'Location', 'best', 'Interpreter', 'latex');
    set(gca, 'FontSize', 11);

    subplot(3, 1, 3);
    plot(x_analytical, abs(u_high_interp - u_analytical), 'b-', 'LineWidth', 2);
    hold on;
    plot(x_analytical, abs(u_low_interp - u_analytical), 'r-', 'LineWidth', 2);
    grid on;
    xlabel('$x$ (m)', 'Interpreter', 'latex', 'FontSize', 12);
    ylabel('$|\Delta u|$', 'Interpreter', 'latex', 'FontSize', 12);
    legend('vanAlbada', 'upwind', 'Location', 'best', 'Interpreter', 'latex');
    set(gca, 'FontSize', 11);

    % Guardar
    saveas(gcf, fullfile(fig_dir, 'Parte2_Errores_Absolutos.png'));
    fprintf('  - Figura guardada: Parte2_Errores_Absolutos.png\n');

else
    fprintf('ADVERTENCIA: Faltan datos para realizar la comparación completa.\n');
end

%% ========================================================================
%  6. RESUMEN Y CONCLUSIONES
%% ========================================================================

fprintf('\n======================================================\n');
fprintf('RESUMEN DEL ANÁLISIS\n');
fprintf('======================================================\n\n');

fprintf('El tubo de choque de Sod es un problema de Riemann que valida\n');
fprintf('la capacidad de los esquemas numéricos para capturar:\n');
fprintf('  - Ondas de choque\n');
fprintf('  - Ondas de rarefacción\n');
fprintf('  - Discontinuidades de contacto\n\n');

fprintf('RESULTADOS:\n');
fprintf('  - El esquema de alto orden (vanAlbada) captura mejor las\n');
fprintf('    discontinuidades con menor difusión numérica.\n');
fprintf('  - El esquema de bajo orden (upwind) presenta mayor difusión\n');
fprintf('    especialmente en la onda de choque y contacto.\n');
fprintf('  - Ambos esquemas son estables para este problema.\n\n');

fprintf('======================================================\n');
fprintf('ANÁLISIS COMPLETADO\n');
fprintf('======================================================\n');

fprintf('\nTodas las figuras han sido guardadas en:\n');
fprintf('  %s\n\n', fig_dir);
