%% ==========================================================================
%  EJERCICIO 4 - PARTE 2: TUBO DE CHOQUE DE SOD
%  Comparacion de esquemas numericos: alto orden (vanAlbada) vs bajo orden (upwind)
%  ==========================================================================
%  Autor: Miguel Rosa
%  Fecha: Diciembre 2025
%  ==========================================================================

clear; clc; close all;

%% Configuracion de graficos LaTeX
set(groot,'defaultTextInterpreter','latex');
set(groot,'defaultLegendInterpreter','latex');
set(groot,'defaultAxesTickLabelInterpreter','latex');
set(groot,'defaultAxesFontSize',12);
set(groot,'defaultLineLineWidth',1.5);

%% Rutas
baseDir = fileparts(mfilename('fullpath'));
highOrderDir = fullfile(baseDir, '..', 'shockTube_highOrder');
lowOrderDir = fullfile(baseDir, '..', 'shockTube_lowOrder');
figDir = fullfile(baseDir, '..', '..', '..', 'figures', 'Ejercicio4');
analyticFile = fullfile(baseDir, '..', 'ResultadosAnalaticos.csv');

% Crear directorio de figuras si no existe
if ~exist(figDir, 'dir')
    mkdir(figDir);
end

%% Parametros del problema de Sod
% Condiciones iniciales
rho_L = 1.0;      % kg/m^3 (izquierda)
p_L = 100000;     % Pa (izquierda)
T_L = 348.432;    % K (izquierda)

rho_R = 0.125;    % kg/m^3 (derecha)
p_R = 10000;      % Pa (derecha)
T_R = 278.746;    % K (derecha)

% Dominio
x_min = -5;
x_max = 5;
L_domain = x_max - x_min;

%% Leer solucion analitica
fprintf('Leyendo solucion analitica...\n');
analytic = readtable(analyticFile);
x_an = analytic.X * L_domain + x_min;  % Convertir de [0,1] a [-5,5]
rho_an = analytic.Rho * rho_L;         % Desnormalizar densidad
p_an = analytic.P * p_L;               % Desnormalizar presion
vel_an = analytic.Vel * sqrt(p_L/rho_L); % Desnormalizar velocidad (usar a = sqrt(p/rho))

fprintf('  Solucion analitica cargada: %d puntos\n', length(x_an));

%% Funcion para leer perfiles de OpenFOAM (graphCell output)
function [x, T, U, p] = readOpenFOAMProfile(caseDir, time)
    % Buscar el directorio de postProcessing
    graphDir = fullfile(caseDir, 'postProcessing', 'graph', sprintf('%.2f', time));
    if ~exist(graphDir, 'dir')
        graphDir = fullfile(caseDir, 'postProcessing', 'graph', sprintf('%.1f', time));
    end
    if ~exist(graphDir, 'dir')
        graphDir = fullfile(caseDir, 'postProcessing', 'graph', num2str(time));
    end

    % Intentar leer el archivo de perfil
    profileFile = fullfile(graphDir, 'line_T_mag(U)_p.csv');
    if ~exist(profileFile, 'file')
        profileFile = fullfile(graphDir, 'line.csv');
    end

    if exist(profileFile, 'file')
        data = readtable(profileFile);
        x = data{:,1};
        T = data{:,2};
        U = data{:,3};
        p = data{:,4};
    else
        % Leer desde archivos separados si existen
        warning('No se encontro archivo de perfil consolidado en %s', graphDir);
        x = []; T = []; U = []; p = [];
    end
end

%% Funcion alternativa para leer campos de OpenFOAM directamente
function [x, rho, p, U, T] = readFieldsFromTimeDir(caseDir, time)
    timeDir = fullfile(caseDir, sprintf('%.2f', time));
    if ~exist(timeDir, 'dir')
        timeDir = fullfile(caseDir, sprintf('%.1f', time));
    end
    if ~exist(timeDir, 'dir')
        timeDir = fullfile(caseDir, num2str(time));
    end

    % Leer coordenadas x desde polyMesh/points
    meshDir = fullfile(caseDir, 'constant', 'polyMesh');

    % Leer campos
    pFile = fullfile(timeDir, 'p');
    TFile = fullfile(timeDir, 'T');
    UFile = fullfile(timeDir, 'U');
    rhoFile = fullfile(timeDir, 'rho');

    if exist(pFile, 'file')
        p = readOpenFOAMField(pFile);
        T = readOpenFOAMField(TFile);
        U = readOpenFOAMVectorField(UFile);
        if exist(rhoFile, 'file')
            rho = readOpenFOAMField(rhoFile);
        else
            % Calcular densidad desde p y T usando ecuacion de estado
            R = 287.05;  % Constante del gas ideal para aire
            rho = p ./ (R * T);
        end

        % Generar coordenadas x uniformes
        n = length(p);
        x = linspace(-5, 5, n)';
    else
        x = []; rho = []; p = []; U = []; T = [];
    end
end

function field = readOpenFOAMField(filename)
    fid = fopen(filename, 'r');
    content = fread(fid, '*char')';
    fclose(fid);

    % Buscar el inicio de los datos (despues de internalField)
    pattern = 'internalField\s+nonuniform\s+List<scalar>\s+(\d+)';
    tokens = regexp(content, pattern, 'tokens');
    if isempty(tokens)
        % Probar con uniform
        pattern = 'internalField\s+uniform\s+([\d.eE+-]+)';
        tokens = regexp(content, pattern, 'tokens');
        if ~isempty(tokens)
            field = str2double(tokens{1}{1}) * ones(1000, 1);
            return;
        end
        field = [];
        return;
    end

    n = str2double(tokens{1}{1});

    % Extraer valores
    pattern = '\(\s*([\d.eE\s+-]+)\s*\)';
    dataMatch = regexp(content, pattern, 'tokens');
    if ~isempty(dataMatch)
        values = str2num(dataMatch{1}{1});
        field = values(:);
    else
        field = [];
    end
end

function U = readOpenFOAMVectorField(filename)
    fid = fopen(filename, 'r');
    content = fread(fid, '*char')';
    fclose(fid);

    % Buscar vectores (x y z)
    pattern = '\(([\d.eE+-]+)\s+([\d.eE+-]+)\s+([\d.eE+-]+)\)';
    matches = regexp(content, pattern, 'tokens');

    if ~isempty(matches)
        n = length(matches);
        Ux = zeros(n, 1);
        for i = 1:n
            Ux(i) = str2double(matches{i}{1});
        end
        U = abs(Ux);  % Magnitud de velocidad (solo componente x)
    else
        U = [];
    end
end

%% Leer resultados de OpenFOAM
fprintf('\nLeyendo resultados de OpenFOAM...\n');

% Tiempos de interes
t_validation = 0.1;  % Para validacion con analitica
t_comparison = 0.15; % Para comparacion entre esquemas

% Intentar leer perfiles de graphCell primero
% Si no funcionan, leer directamente de los campos

% High Order - t=0.1
[x_high_01, rho_high_01, p_high_01, U_high_01, T_high_01] = ...
    readFieldsFromTimeDir(highOrderDir, t_validation);

% High Order - t=0.15
[x_high_015, rho_high_015, p_high_015, U_high_015, T_high_015] = ...
    readFieldsFromTimeDir(highOrderDir, t_comparison);

% Low Order - t=0.1
[x_low_01, rho_low_01, p_low_01, U_low_01, T_low_01] = ...
    readFieldsFromTimeDir(lowOrderDir, t_validation);

% Low Order - t=0.15
[x_low_015, rho_low_015, p_low_015, U_low_015, T_low_015] = ...
    readFieldsFromTimeDir(lowOrderDir, t_comparison);

%% Verificar que los datos se cargaron
if isempty(x_high_01)
    fprintf('ADVERTENCIA: No se pudieron leer datos de highOrder. Verificar que la simulacion ha terminado.\n');
    return;
end

fprintf('  High Order t=0.1: %d puntos\n', length(x_high_01));
fprintf('  High Order t=0.15: %d puntos\n', length(x_high_015));
fprintf('  Low Order t=0.1: %d puntos\n', length(x_low_01));
fprintf('  Low Order t=0.15: %d puntos\n', length(x_low_015));

%% =========================================================================
%  FIGURA 1: VALIDACION CON SOLUCION ANALITICA (t = 0.1 s)
%  =========================================================================
fprintf('\nGenerando figura de validacion (t = 0.1 s)...\n');

fig1 = figure('Color','w','Position',[100 100 1400 500]);

% Subplot 1: Densidad
subplot(1,3,1);
hold on; grid on; box on;
plot(x_an, rho_an, 'k-', 'LineWidth', 2, 'DisplayName', 'Anal\''{i}tica');
plot(x_high_01, rho_high_01, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Alto orden (vanAlbada)');
plot(x_low_01, rho_low_01, 'r--', 'LineWidth', 1.5, 'DisplayName', 'Bajo orden (upwind)');
xlabel('$x$ [m]');
ylabel('$\rho$ [kg/m$^3$]');
title('Densidad');
legend('Location', 'southwest');
xlim([-5 5]);

% Subplot 2: Presion
subplot(1,3,2);
hold on; grid on; box on;
plot(x_an, p_an/1000, 'k-', 'LineWidth', 2, 'DisplayName', 'Anal\''{i}tica');
plot(x_high_01, p_high_01/1000, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Alto orden');
plot(x_low_01, p_low_01/1000, 'r--', 'LineWidth', 1.5, 'DisplayName', 'Bajo orden');
xlabel('$x$ [m]');
ylabel('$p$ [kPa]');
title('Presi\''on');
legend('Location', 'southwest');
xlim([-5 5]);

% Subplot 3: Velocidad
subplot(1,3,3);
hold on; grid on; box on;
plot(x_an, vel_an, 'k-', 'LineWidth', 2, 'DisplayName', 'Anal\''{i}tica');
plot(x_high_01, U_high_01, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Alto orden');
plot(x_low_01, U_low_01, 'r--', 'LineWidth', 1.5, 'DisplayName', 'Bajo orden');
xlabel('$x$ [m]');
ylabel('$|U|$ [m/s]');
title('Velocidad');
legend('Location', 'northwest');
xlim([-5 5]);

sgtitle(sprintf('Validaci\\''on del tubo de choque de Sod en $t = %.2f$ s', t_validation), ...
    'FontSize', 14);

print(fig1, fullfile(figDir, 'shocktube_validacion_t01.png'), '-dpng', '-r300');
fprintf('  Guardada: shocktube_validacion_t01.png\n');

%% =========================================================================
%  FIGURA 2: COMPARACION DE ESQUEMAS (t = 0.15 s)
%  =========================================================================
fprintf('\nGenerando figura de comparacion (t = 0.15 s)...\n');

fig2 = figure('Color','w','Position',[100 100 1400 500]);

% Subplot 1: Densidad
subplot(1,3,1);
hold on; grid on; box on;
plot(x_high_015, rho_high_015, 'b-', 'LineWidth', 1.8, 'DisplayName', 'Alto orden (vanAlbada)');
plot(x_low_015, rho_low_015, 'r--', 'LineWidth', 1.8, 'DisplayName', 'Bajo orden (upwind)');
xlabel('$x$ [m]');
ylabel('$\rho$ [kg/m$^3$]');
title('Densidad');
legend('Location', 'southwest');
xlim([-5 5]);

% Subplot 2: Presion
subplot(1,3,2);
hold on; grid on; box on;
plot(x_high_015, p_high_015/1000, 'b-', 'LineWidth', 1.8, 'DisplayName', 'Alto orden');
plot(x_low_015, p_low_015/1000, 'r--', 'LineWidth', 1.8, 'DisplayName', 'Bajo orden');
xlabel('$x$ [m]');
ylabel('$p$ [kPa]');
title('Presi\''on');
legend('Location', 'southwest');
xlim([-5 5]);

% Subplot 3: Velocidad
subplot(1,3,3);
hold on; grid on; box on;
plot(x_high_015, U_high_015, 'b-', 'LineWidth', 1.8, 'DisplayName', 'Alto orden');
plot(x_low_015, U_low_015, 'r--', 'LineWidth', 1.8, 'DisplayName', 'Bajo orden');
xlabel('$x$ [m]');
ylabel('$|U|$ [m/s]');
title('Velocidad');
legend('Location', 'northwest');
xlim([-5 5]);

sgtitle(sprintf('Comparaci\\''on de esquemas num\\''ericos en $t = %.2f$ s', t_comparison), ...
    'FontSize', 14);

print(fig2, fullfile(figDir, 'shocktube_comparacion_t015.png'), '-dpng', '-r300');
fprintf('  Guardada: shocktube_comparacion_t015.png\n');

%% =========================================================================
%  FIGURA 3: DETALLE DE DISCONTINUIDADES (t = 0.1 s)
%  =========================================================================
fprintf('\nGenerando figura de detalle de discontinuidades...\n');

fig3 = figure('Color','w','Position',[100 100 1400 400]);

% Subplot 1: Onda de rarefaccion (zona izquierda)
subplot(1,3,1);
hold on; grid on; box on;
plot(x_an, rho_an, 'k-', 'LineWidth', 2, 'DisplayName', 'Anal\''{i}tica');
plot(x_high_01, rho_high_01, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Alto orden');
plot(x_low_01, rho_low_01, 'r--', 'LineWidth', 1.5, 'DisplayName', 'Bajo orden');
xlabel('$x$ [m]');
ylabel('$\rho$ [kg/m$^3$]');
title('Onda de rarefacci\\''on');
legend('Location', 'northeast');
xlim([-4 -1]);
ylim([0.3 1.1]);

% Subplot 2: Discontinuidad de contacto (zona central)
subplot(1,3,2);
hold on; grid on; box on;
plot(x_an, rho_an, 'k-', 'LineWidth', 2, 'DisplayName', 'Anal\''{i}tica');
plot(x_high_01, rho_high_01, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Alto orden');
plot(x_low_01, rho_low_01, 'r--', 'LineWidth', 1.5, 'DisplayName', 'Bajo orden');
xlabel('$x$ [m]');
ylabel('$\rho$ [kg/m$^3$]');
title('Discontinuidad de contacto');
legend('Location', 'northeast');
xlim([0 2.5]);
ylim([0.2 0.5]);

% Subplot 3: Onda de choque (zona derecha)
subplot(1,3,3);
hold on; grid on; box on;
plot(x_an, p_an/1000, 'k-', 'LineWidth', 2, 'DisplayName', 'Anal\''{i}tica');
plot(x_high_01, p_high_01/1000, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Alto orden');
plot(x_low_01, p_low_01/1000, 'r--', 'LineWidth', 1.5, 'DisplayName', 'Bajo orden');
xlabel('$x$ [m]');
ylabel('$p$ [kPa]');
title('Onda de choque');
legend('Location', 'northeast');
xlim([2 5]);
ylim([5 35]);

sgtitle('Detalle de las tres discontinuidades en $t = 0.1$ s', 'FontSize', 14);

print(fig3, fullfile(figDir, 'shocktube_detalle_discontinuidades_validacion.png'), '-dpng', '-r300');
fprintf('  Guardada: shocktube_detalle_discontinuidades_validacion.png\n');

%% =========================================================================
%  FIGURA 4: ERRORES DE VALIDACION
%  =========================================================================
fprintf('\nCalculando errores de validacion...\n');

% Interpolar soluciones numericas a la malla analitica
rho_high_interp = interp1(x_high_01, rho_high_01, x_an, 'linear', 'extrap');
rho_low_interp = interp1(x_low_01, rho_low_01, x_an, 'linear', 'extrap');
p_high_interp = interp1(x_high_01, p_high_01, x_an, 'linear', 'extrap');
p_low_interp = interp1(x_low_01, p_low_01, x_an, 'linear', 'extrap');
U_high_interp = interp1(x_high_01, U_high_01, x_an, 'linear', 'extrap');
U_low_interp = interp1(x_low_01, U_low_01, x_an, 'linear', 'extrap');

% Calcular errores L2 relativos
err_rho_high = norm(rho_high_interp - rho_an) / norm(rho_an) * 100;
err_rho_low = norm(rho_low_interp - rho_an) / norm(rho_an) * 100;
err_p_high = norm(p_high_interp - p_an) / norm(p_an) * 100;
err_p_low = norm(p_low_interp - p_an) / norm(p_an) * 100;

% Para velocidad, evitar division por cero
vel_an_norm = vel_an;
vel_an_norm(vel_an_norm < 1e-10) = 1e-10;
err_U_high = norm(U_high_interp - vel_an) / norm(vel_an + 1) * 100;
err_U_low = norm(U_low_interp - vel_an) / norm(vel_an + 1) * 100;

fprintf('  Errores L2 relativos:\n');
fprintf('    Densidad:  High=%.2f%%, Low=%.2f%%\n', err_rho_high, err_rho_low);
fprintf('    Presion:   High=%.2f%%, Low=%.2f%%\n', err_p_high, err_p_low);
fprintf('    Velocidad: High=%.2f%%, Low=%.2f%%\n', err_U_high, err_U_low);

% Crear figura de barras
fig4 = figure('Color','w','Position',[100 100 800 500]);

categories = {'Densidad $\rho$', 'Presi\''on $p$', 'Velocidad $|U|$'};
errors_high = [err_rho_high, err_p_high, err_U_high];
errors_low = [err_rho_low, err_p_low, err_U_low];

X = categorical(categories);
X = reordercats(X, categories);

bar_data = [errors_high; errors_low]';
b = bar(X, bar_data);
b(1).FaceColor = [0.2 0.4 0.8];
b(2).FaceColor = [0.8 0.2 0.2];

ylabel('Error L2 relativo [\%]');
title('Errores de validaci\''on respecto a la soluci\''on anal\''{\i}tica ($t = 0.1$ s)');
legend({'Alto orden (vanAlbada)', 'Bajo orden (upwind)'}, 'Location', 'northeast');
grid on; box on;

print(fig4, fullfile(figDir, 'shocktube_errores_validacion.png'), '-dpng', '-r300');
fprintf('  Guardada: shocktube_errores_validacion.png\n');

%% =========================================================================
%  FIGURA 5: DIAGRAMA x-t CONCEPTUAL
%  =========================================================================
fprintf('\nGenerando diagrama x-t conceptual...\n');

fig5 = figure('Color','w','Position',[100 100 700 600]);
hold on; grid on; box on;

% Parametros de las ondas (aproximados para Sod)
% Velocidad del sonido izquierda
gamma = 1.4;
a_L = sqrt(gamma * p_L / rho_L);
a_R = sqrt(gamma * p_R / rho_R);

% Velocidades caracteristicas aproximadas
v_raref_head = -a_L;           % Cabeza de rarefaccion
v_raref_tail = -0.5 * a_L;     % Cola de rarefaccion (aproximado)
v_contact = 92.7;              % Velocidad de contacto (de datos analiticos)
v_shock = 200;                 % Velocidad de choque (aproximada)

t_max = 0.15;

% Dibujar lineas caracteristicas
% Onda de rarefaccion (abanico)
t_vals = linspace(0, t_max, 100);
for frac = linspace(0, 1, 10)
    v = v_raref_head + frac * (v_raref_tail - v_raref_head);
    x_raref = v * t_vals;
    plot(x_raref, t_vals, 'b-', 'LineWidth', 0.8);
end

% Discontinuidad de contacto
x_contact = v_contact * t_vals;
plot(x_contact, t_vals, 'g-', 'LineWidth', 2.5, 'DisplayName', 'Contacto');

% Onda de choque
x_shock = v_shock * t_vals;
plot(x_shock, t_vals, 'r-', 'LineWidth', 2.5, 'DisplayName', 'Choque');

% Etiquetas de regiones
text(-4, 0.08, '(1)', 'FontSize', 14, 'FontWeight', 'bold');
text(-1, 0.08, '(2)', 'FontSize', 14, 'FontWeight', 'bold');
text(0.5, 0.08, '(3)', 'FontSize', 14, 'FontWeight', 'bold');
text(3.5, 0.08, '(4)', 'FontSize', 14, 'FontWeight', 'bold');

% Linea del diafragma inicial
plot([0 0], [0 t_max], 'k--', 'LineWidth', 1);

xlabel('$x$ [m]');
ylabel('$t$ [s]');
title('Diagrama $x$-$t$ del tubo de choque de Sod');
xlim([-5 5]);
ylim([0 t_max]);

% Leyenda manual
plot(NaN, NaN, 'b-', 'LineWidth', 2, 'DisplayName', 'Rarefacci\''on');
plot(NaN, NaN, 'g-', 'LineWidth', 2.5, 'DisplayName', 'Contacto');
plot(NaN, NaN, 'r-', 'LineWidth', 2.5, 'DisplayName', 'Choque');
legend('Location', 'northwest');

print(fig5, fullfile(figDir, 'shocktube_diagrama_xt.png'), '-dpng', '-r300');
fprintf('  Guardada: shocktube_diagrama_xt.png\n');

%% =========================================================================
%  GUARDAR DATOS PARA REFERENCIA
%  =========================================================================
fprintf('\nGuardando resultados...\n');

save(fullfile(figDir, 'resultados_shocktube.mat'), ...
    'x_an', 'rho_an', 'p_an', 'vel_an', ...
    'x_high_01', 'rho_high_01', 'p_high_01', 'U_high_01', ...
    'x_low_01', 'rho_low_01', 'p_low_01', 'U_low_01', ...
    'x_high_015', 'rho_high_015', 'p_high_015', 'U_high_015', ...
    'x_low_015', 'rho_low_015', 'p_low_015', 'U_low_015', ...
    'err_rho_high', 'err_rho_low', 'err_p_high', 'err_p_low');

fprintf('\n=== COMPLETADO ===\n');
fprintf('Figuras guardadas en: %s\n', figDir);
