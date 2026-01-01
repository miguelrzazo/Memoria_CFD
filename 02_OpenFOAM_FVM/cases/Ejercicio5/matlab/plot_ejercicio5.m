%% ============= EJERCICIO 5: Flujo Couette Turbulento =============
% Comparacion de modelos Low-Re y High-Re (wall functions)
% Autor: Miguel Rosa
% Fecha: Enero 2026
%
% NOTA: Para la ley de la pared en flujo Couette, se mide desde la pared
% movil (y=H) porque ahi esta el mayor esfuerzo cortante.
%
% y_wall = H - y  (distancia desde pared movil)
% u_rel = U_wall - u  (velocidad relativa a la pared movil)
% u+ = u_rel / u_tau
% y+ = y_wall * u_tau / nu

clear; clc; close all;

%% ============= PARAMETROS DEL PROBLEMA ================
ultima_cifra_DNI = 7;
Re_H = 500000 + ultima_cifra_DNI * 5000;  % Re = 535000

U_wall = 10;        % m/s - velocidad de la pared superior
H = 0.1;            % m - altura del canal
rho = 1.2;          % kg/m^3 - densidad del aire
nu = U_wall * H / Re_H;  % viscosidad cinematica

fprintf('============================================\n');
fprintf(' EJERCICIO 5 - Flujo Couette Turbulento\n');
fprintf('============================================\n');
fprintf(' Ultima cifra DNI: %d\n', ultima_cifra_DNI);
fprintf(' Reynolds basado en H: Re_H = %d\n', Re_H);
fprintf(' Viscosidad cinematica: nu = %.3e m^2/s\n', nu);
fprintf(' Velocidad pared: U_wall = %.1f m/s\n', U_wall);
fprintf(' Altura canal: H = %.3f m\n', H);
fprintf('============================================\n\n');

%% ============= RUTAS ================
base_path = '/Users/miguelrosa/CFD/Practica/Memoria_CFD/02_OpenFOAM_FVM/cases/Ejercicio5';
case_lowre = fullfile(base_path, 'couetteLowRe');
case_highre = fullfile(base_path, 'couetteHighRe');
fig_path = '/Users/miguelrosa/CFD/Practica/Memoria_CFD/02_OpenFOAM_FVM/figures/Ejercicio5';

if ~exist(fig_path, 'dir'), mkdir(fig_path); end

%% ============= SOLUCION ANALITICA (Laminar) ================
y_analitico = linspace(0, H, 200);
u_analitico = U_wall * y_analitico / H;

%% ============= LECTURA DE DATOS DE OPENFOAM ================
fprintf('Leyendo datos de OpenFOAM...\n');
time_str = '4000';

% Leer perfiles de velocidad desde centros de celda (datos reales, no interpolados)
[y_low, u_low] = read_profile_cellcentre(case_lowre, time_str);
[y_high, u_high] = read_profile_cellcentre(case_highre, time_str);

fprintf('  Low-Re:  %d puntos (centros de celda)\n', length(y_low));
fprintf('  High-Re: %d puntos (centros de celda)\n', length(y_high));

% Leer wallShearStress de movingWall (donde esta el mayor esfuerzo)
tau_rho_low = read_tau_wall(case_lowre, time_str, 'movingWall');
tau_rho_high = read_tau_wall(case_highre, time_str, 'movingWall');

% Calcular u_tau = sqrt(|tau/rho|)
u_tau_low = sqrt(abs(tau_rho_low));
u_tau_high = sqrt(abs(tau_rho_high));

tau_w_low = rho * abs(tau_rho_low);
tau_w_high = rho * abs(tau_rho_high);

fprintf('\nEsfuerzo cortante en movingWall:\n');
fprintf('  Low-Re:  tau_w = %.4f Pa, u_tau = %.4f m/s\n', tau_w_low, u_tau_low);
fprintf('  High-Re: tau_w = %.4f Pa, u_tau = %.4f m/s\n', tau_w_high, u_tau_high);

% Leer y+ de OpenFOAM
yplus_low = read_yplus(case_lowre, time_str, 'movingWall');
yplus_high = read_yplus(case_highre, time_str, 'movingWall');

fprintf('\ny+ en primera celda (OpenFOAM):\n');
fprintf('  Low-Re:  y+ = %.2f (objetivo: ~1)\n', yplus_low);
fprintf('  High-Re: y+ = %.2f (objetivo: 30-300)\n', yplus_high);

%% ============= COORDENADAS ADIMENSIONALES ================
% Para flujo Couette, medir desde la pared movil (y=H)
% y_wall = H - y
% u_rel = U_wall - u

y_wall_low = H - y_low;
y_wall_high = H - y_high;

u_rel_low = U_wall - u_low;
u_rel_high = U_wall - u_high;

% y+ y u+ 
y_plus_low = y_wall_low * u_tau_low / nu;
y_plus_high = y_wall_high * u_tau_high / nu;

u_plus_low = u_rel_low / u_tau_low;
u_plus_high = u_rel_high / u_tau_high;

%% ============= LEY DE LA PARED TEORICA ================
kappa = 0.41;
B = 5.2;

% Subcapa viscosa: u+ = y+ (y+ < 5)
y_plus_visc = linspace(0.1, 11, 100);
u_plus_visc = y_plus_visc;

% Ley logaritmica: u+ = (1/kappa)*ln(y+) + B (y+ > 30)
% Extendida hasta y+ = 5000 para cubrir todo el rango de High-Re
y_plus_log = linspace(11, 5000, 300);
u_plus_log = (1/kappa) * log(y_plus_log) + B;

%% ============= FIGURA 1: Perfiles de Velocidad u(y) ================
fig1 = figure('Position', [100, 100, 900, 650], 'Color', 'w');

plot(u_analitico, y_analitico*1000, 'k-', 'LineWidth', 2, ...
    'DisplayName', 'Analitico (Laminar)');
hold on;
plot(u_low, y_low*1000, 'b-', 'LineWidth', 2, ...
    'DisplayName', 'CFD: Low-Re $k$-$\varepsilon$ (LaunderSharma)');
plot(u_high, y_high*1000, 'r--', 'LineWidth', 2, ...
    'DisplayName', 'CFD: High-Re $k$-$\varepsilon$ (Wall Functions)');
hold off;

xlabel('Velocidad $u$ [m/s]', 'Interpreter', 'latex', 'FontSize', 14);
ylabel('Altura $y$ [mm]', 'Interpreter', 'latex', 'FontSize', 14);
title(['Perfiles de Velocidad - Flujo Couette ($Re_H = ', ...
    num2str(Re_H, '%.0f'), '$)'], 'Interpreter', 'latex', 'FontSize', 16);
legend('Location', 'southeast', 'Interpreter', 'latex', 'FontSize', 11);
grid on;
set(gca, 'FontSize', 12, 'TickLabelInterpreter', 'latex');
xlim([0 U_wall*1.05]);
ylim([0 H*1000]);

exportgraphics(fig1, fullfile(fig_path, 'Ej5_perfiles_velocidad.png'), 'Resolution', 300);
fprintf('\n  Guardada: Ej5_perfiles_velocidad.png\n');

%% ============= FIGURA 2: Ley de la Pared (u+ vs y+) ================
fig2 = figure('Position', [100, 100, 1000, 700], 'Color', 'w');

% Filtrar puntos validos - extender rango para High-Re que llega hasta ~5000
mask_low = y_plus_low > 0.1 & y_plus_low < 6000;
mask_high = y_plus_high > 0.1 & y_plus_high < 6000;

% Leyes teoricas
semilogx(y_plus_visc, u_plus_visc, 'k-', 'LineWidth', 2, ...
    'DisplayName', 'Subcapa viscosa: $u^+ = y^+$');
hold on;
semilogx(y_plus_log, u_plus_log, 'k--', 'LineWidth', 2, ...
    'DisplayName', 'Ley logaritmica: $u^+ = \frac{1}{\kappa}\ln(y^+) + B$');

% Datos CFD
semilogx(y_plus_low(mask_low), u_plus_low(mask_low), 'b.-', ...
    'LineWidth', 1.5, 'MarkerSize', 8, 'DisplayName', 'CFD: Low-Re $k$-$\varepsilon$');
semilogx(y_plus_high(mask_high), u_plus_high(mask_high), 'rs-', ...
    'LineWidth', 1.5, 'MarkerSize', 10, 'MarkerFaceColor', 'r', ...
    'DisplayName', 'CFD: High-Re $k$-$\varepsilon$ (WF)');

% Lineas de referencia para zonas
xline(5, ':', 'Color', [0.5 0.5 0.5], 'LineWidth', 1, 'HandleVisibility', 'off');
xline(30, ':', 'Color', [0.5 0.5 0.5], 'LineWidth', 1, 'HandleVisibility', 'off');

% Anotaciones de zonas
text(1.5, 2, 'Subcapa viscosa', 'FontSize', 10, 'Interpreter', 'latex');
text(10, 8, 'Buffer', 'FontSize', 10, 'Interpreter', 'latex');
text(200, 15, 'Capa logaritmica', 'FontSize', 10, 'Interpreter', 'latex');

hold off;

xlabel('$y^+$', 'Interpreter', 'latex', 'FontSize', 16);
ylabel('$u^+$', 'Interpreter', 'latex', 'FontSize', 16);
title('Ley de la Pared - Flujo Couette Turbulento', ...
    'Interpreter', 'latex', 'FontSize', 18);
legend('Location', 'northwest', 'Interpreter', 'latex', 'FontSize', 11);
grid on;
set(gca, 'FontSize', 13, 'TickLabelInterpreter', 'latex');
xlim([0.5 5000]);
ylim([0 30]);

exportgraphics(fig2, fullfile(fig_path, 'Ej5_ley_pared.png'), 'Resolution', 300);
fprintf('  Guardada: Ej5_ley_pared.png\n');

%% ============= FIGURA 3: Detalle subcapa viscosa ================
fig3 = figure('Position', [100, 100, 900, 650], 'Color', 'w');

% Ampliar el rango para mostrar mas puntos de High-Re
% High-Re empieza en y+ ~ 74, asi que extendemos hasta 500
mask_low_zoom = y_plus_low > 0.1 & y_plus_low < 500;
mask_high_zoom = y_plus_high > 0.1 & y_plus_high < 500;

plot(y_plus_visc(y_plus_visc < 12), u_plus_visc(y_plus_visc < 12), 'k-', ...
    'LineWidth', 2, 'DisplayName', '$u^+ = y^+$');
hold on;

% Ley logaritmica extendida
y_log_short = linspace(10, 500, 100);
u_log_short = (1/kappa)*log(y_log_short) + B;
plot(y_log_short, u_log_short, 'k--', 'LineWidth', 2, ...
    'DisplayName', 'Ley logaritmica');

plot(y_plus_low(mask_low_zoom), u_plus_low(mask_low_zoom), 'bo-', ...
    'LineWidth', 1.5, 'MarkerSize', 5, 'MarkerFaceColor', 'b', ...
    'DisplayName', 'Low-Re');
plot(y_plus_high(mask_high_zoom), u_plus_high(mask_high_zoom), 'rs-', ...
    'LineWidth', 1.5, 'MarkerSize', 8, 'MarkerFaceColor', 'r', ...
    'DisplayName', 'High-Re (WF)');

xline(5, ':', 'Color', [0.5 0.5 0.5], 'HandleVisibility', 'off');
xline(30, ':', 'Color', [0.5 0.5 0.5], 'HandleVisibility', 'off');

% Anotaciones
text(2, 3, 'Subcapa', 'FontSize', 9, 'Interpreter', 'latex');
text(12, 10, 'Buffer', 'FontSize', 9, 'Interpreter', 'latex');
text(100, 16, 'Log', 'FontSize', 9, 'Interpreter', 'latex');

hold off;

xlabel('$y^+$', 'Interpreter', 'latex', 'FontSize', 14);
ylabel('$u^+$', 'Interpreter', 'latex', 'FontSize', 14);
title('Detalle de la Capa Limite (escala lineal)', 'Interpreter', 'latex', 'FontSize', 16);
legend('Location', 'southeast', 'Interpreter', 'latex', 'FontSize', 11);
grid on;
set(gca, 'FontSize', 12, 'TickLabelInterpreter', 'latex');
xlim([0 500]);
ylim([0 22]);

exportgraphics(fig3, fullfile(fig_path, 'Ej5_detalle_capa_limite.png'), 'Resolution', 300);
fprintf('  Guardada: Ej5_detalle_capa_limite.png\n');

%% ============= GUARDAR RESULTADOS ================
results.Re_H = Re_H;
results.nu = nu;
results.U_wall = U_wall;
results.H = H;
results.kappa = kappa;
results.B = B;

results.lowRe.y = y_low;
results.lowRe.u = u_low;
results.lowRe.y_plus = y_plus_low;
results.lowRe.u_plus = u_plus_low;
results.lowRe.tau_w = tau_w_low;
results.lowRe.u_tau = u_tau_low;
results.lowRe.y_plus_first = yplus_low;

results.highRe.y = y_high;
results.highRe.u = u_high;
results.highRe.y_plus = y_plus_high;
results.highRe.u_plus = u_plus_high;
results.highRe.tau_w = tau_w_high;
results.highRe.u_tau = u_tau_high;
results.highRe.y_plus_first = yplus_high;

save(fullfile(fig_path, 'resultados_ejercicio5.mat'), 'results');
fprintf('\nResultados guardados en: resultados_ejercicio5.mat\n');

%% ============= RESUMEN ================
fprintf('\n============================================\n');
fprintf(' RESUMEN DEL EJERCICIO 5\n');
fprintf('============================================\n');
fprintf(' Modelo Low-Re (LaunderSharmaKE):\n');
fprintf('   - tau_w = %.4f Pa\n', tau_w_low);
fprintf('   - u_tau = %.4f m/s\n', u_tau_low);
fprintf('   - y+ primera celda = %.2f (objetivo: ~1)\n', yplus_low);
fprintf('\n Modelo High-Re (kEpsilon + WF):\n');
fprintf('   - tau_w = %.4f Pa\n', tau_w_high);
fprintf('   - u_tau = %.4f m/s\n', u_tau_high);
fprintf('   - y+ primera celda = %.2f (objetivo: 30-300)\n', yplus_high);
fprintf('============================================\n');

%% ============= FUNCIONES AUXILIARES ================

function [y, u] = read_profile(case_path, time_str)
    % Lee perfil de velocidad desde graphUniform
    filename = fullfile(case_path, 'postProcessing', 'graphUniform', time_str, 'line.xy');
    
    if ~exist(filename, 'file')
        error('Archivo no encontrado: %s', filename);
    end
    
    data = readmatrix(filename, 'FileType', 'text');
    y = data(:, 2);  % columna Y
    u = data(:, 4);  % columna Ux
end

function [y, u] = read_profile_cellcentre(case_path, time_str)
    % Lee perfil de velocidad desde centros de celda (Ccy y U)
    % Esto da los valores REALES en los centros de celda, no interpolados
    
    ccy_file = fullfile(case_path, time_str, 'Ccy');
    ccx_file = fullfile(case_path, time_str, 'Ccx');
    u_file = fullfile(case_path, time_str, 'U');
    
    if ~exist(ccy_file, 'file')
        warning('Ccy no encontrado, usando graphUniform');
        [y, u] = read_profile(case_path, time_str);
        return;
    end
    
    % Leer coordenadas de centros de celda
    ccy = read_OF_field(ccy_file);
    ccx = read_OF_field(ccx_file);
    
    % Leer campo U
    U = read_OF_vector(u_file);
    
    % Si no hay datos, devolver vacio
    if isempty(ccy) || isempty(ccx) || isempty(U)
        warning('No se pudieron leer los campos, usando graphUniform');
        [y, u] = read_profile(case_path, time_str);
        return;
    end
    
    % Filtrar para x ~ 0.05 (centro del dominio)
    % Tolerancia pequena para obtener solo una columna de celdas
    x_target = 0.049;  % valor exacto que existe en la malla
    tol = 0.0005;
    mask = abs(ccx - x_target) < tol;
    
    % Si no hay puntos, aumentar tolerancia
    if sum(mask) == 0
        tol = 0.003;
        mask = abs(ccx - x_target) < tol;
    end
    
    y_raw = ccy(mask);
    u_raw = U(mask, 1);  % componente x
    
    % Ordenar por y y eliminar duplicados
    [y, idx] = sort(y_raw);
    u = u_raw(idx);
    
    % Eliminar duplicados (mismo y)
    [y, unique_idx] = unique(y);
    u = u(unique_idx);
end

function data = read_OF_field(filename)
    % Lee un campo escalar de OpenFOAM (formato nonuniform List<scalar>)
    % Enfoque simple: leer linea por linea
    
    fid = fopen(filename, 'r');
    if fid < 0
        warning('No se pudo abrir %s', filename);
        data = [];
        return;
    end
    
    % Buscar la linea con "internalField"
    found = false;
    n = 0;
    while ~feof(fid)
        line = fgetl(fid);
        if contains(line, 'internalField') && contains(line, 'List<scalar>')
            % La siguiente linea tiene el numero de elementos
            n_line = fgetl(fid);
            n = str2double(strtrim(n_line));
            % La siguiente linea es "("
            fgetl(fid);  
            found = true;
            break;
        end
    end
    
    if ~found || n == 0
        fclose(fid);
        warning('No se encontro internalField en %s', filename);
        data = [];
        return;
    end
    
    % Leer n valores
    data = zeros(n, 1);
    for i = 1:n
        line = fgetl(fid);
        data(i) = str2double(strtrim(line));
    end
    
    fclose(fid);
end

function U = read_OF_vector(filename)
    % Lee un campo vectorial de OpenFOAM (formato nonuniform List<vector>)
    fid = fopen(filename, 'r');
    content = fread(fid, '*char')';
    fclose(fid);
    
    % Buscar "nonuniform List<vector>" seguido del numero de elementos
    match = regexp(content, 'nonuniform\s+List<vector>\s*\n(\d+)\s*\n\(', 'tokens');
    if isempty(match)
        match = regexp(content, 'List<vector>\s*\n(\d+)\s*\n\(', 'tokens');
    end
    if isempty(match)
        error('Formato no reconocido en %s', filename);
    end
    
    n = str2double(match{1}{1});
    
    % Extraer todos los vectores con formato (x y z)
    % El patron captura numeros en notacion cientifica
    pattern = '\(([0-9.eE+-]+)\s+([0-9.eE+-]+)\s+([0-9.eE+-]+)\)';
    tokens = regexp(content, pattern, 'tokens');
    
    % Tomar solo los primeros n (internalField)
    U = zeros(n, 3);
    for i = 1:min(n, length(tokens))
        U(i,1) = str2double(tokens{i}{1});
        U(i,2) = str2double(tokens{i}{2});
        U(i,3) = str2double(tokens{i}{3});
    end
end

function tau_rho = read_tau_wall(case_path, time_str, patch_name)
    % Lee wallShearStress y devuelve el promedio de |tau_x|/rho
    filename = fullfile(case_path, time_str, 'wallShearStress');
    
    if ~exist(filename, 'file')
        warning('wallShearStress no encontrado');
        tau_rho = 0.1;
        return;
    end
    
    fid = fopen(filename, 'r');
    content = fread(fid, '*char')';
    fclose(fid);
    
    % Buscar el patch
    pattern = [patch_name '\s*\{[^}]*List<vector>\s*(\d+)\s*\(([^)]+)\)'];
    tokens = regexp(content, pattern, 'tokens');
    
    if isempty(tokens)
        warning('Patch %s no encontrado', patch_name);
        tau_rho = 0.1;
        return;
    end
    
    % Extraer valores del vector (solo componente x)
    vec_str = tokens{1}{2};
    % Formato: (x y z) (x y z) ...
    pattern_x = '\(([0-9.e+-]+)';
    vals = regexp(vec_str, pattern_x, 'tokens');
    
    tau_x = zeros(length(vals), 1);
    for i = 1:length(vals)
        tau_x(i) = str2double(vals{i}{1});
    end
    
    tau_rho = mean(abs(tau_x));
end

function yplus = read_yplus(case_path, time_str, patch_name)
    % Lee yPlus promedio del patch especificado
    filename = fullfile(case_path, time_str, 'yPlus');
    
    if ~exist(filename, 'file')
        warning('yPlus no encontrado');
        yplus = 1;
        return;
    end
    
    fid = fopen(filename, 'r');
    content = fread(fid, '*char')';
    fclose(fid);
    
    % Buscar el patch
    pattern = [patch_name '\s*\{[^}]*List<scalar>\s*\d+\s*\(([^)]+)\)'];
    tokens = regexp(content, pattern, 'tokens');
    
    if isempty(tokens)
        % Intentar formato uniform
        pattern2 = [patch_name '\s*\{[^}]*value\s+uniform\s+([0-9.e+-]+)'];
        tokens = regexp(content, pattern2, 'tokens');
        if ~isempty(tokens)
            yplus = str2double(tokens{1}{1});
            return;
        end
        warning('Patch %s no encontrado en yPlus', patch_name);
        yplus = 1;
        return;
    end
    
    vals = str2num(tokens{1}{1});
    yplus = mean(vals);
end
