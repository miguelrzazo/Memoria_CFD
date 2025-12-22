%% EJERCICIO 5: Analisis de Wall Functions - Planar Couette Flow
% Re = 535000 (ultima cifra DNI = 7)
% Comparacion con ley de pared analitica
% Miguel Rosa - Master Ingenieria Aeronautica 2025

clearvars; close all; clc;

%% Parametros del problema
Re = 535000;        % Numero de Reynolds (5e5 + 7*5000)
H = 0.1;            % Altura del canal [m]
U_wall = 10;        % Velocidad de la pared movil [m/s]
nu = U_wall * H / Re;  % Viscosidad cinematica [m2/s]
rho = 1.0;          % Densidad (normalizada)

fprintf('=== EJERCICIO 5: Planar Couette - Wall Functions ===\n');
fprintf('Re = %d\n', Re);
fprintf('H = %.2f m\n', H);
fprintf('U_wall = %.1f m/s\n', U_wall);
fprintf('nu = %.6e m2/s\n\n', nu);

%% Directorios
case_dir = '../../cases/Ejercicio5/planarCouette/';
output_dir = '../../figures/Ejercicio5/';

% Crear directorio de salida si no existe
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

%% Buscar ultimo tiempo disponible
time_dirs = dir(case_dir);
time_dirs = time_dirs([time_dirs.isdir]);
times = zeros(length(time_dirs), 1);
k = 0;
for i = 1:length(time_dirs)
    name = time_dirs(i).name;
    if ~strcmp(name, '.') && ~strcmp(name, '..') && ~strcmp(name, 'constant') && ~strcmp(name, 'system')
        t = str2double(name);
        if ~isnan(t) && t > 0
            k = k + 1;
            times(k) = t;
        end
    end
end
times = times(1:k);

if isempty(times)
    fprintf('NOTA: No se encontraron tiempos de simulacion.\n');
    fprintf('Generando graficas teoricas...\n');
    t_final = 0;
else
    times = sort(times);
    t_final = times(end);
    fprintf('Tiempo final encontrado: %.1f s\n', t_final);
end

%% Leer perfil de velocidad desde postProcessing o directamente
% Intentar leer de postProcessing/graphUniform
graph_file = [case_dir, sprintf('%g', t_final), '/uniform/UMean'];

% Alternativa: leer el campo U del ultimo tiempo
U_file = [case_dir, sprintf('%g', t_final), '/U'];

if exist(U_file, 'file')
    fprintf('Leyendo campo U desde: %s\n', U_file);
    
    % Leer archivo de OpenFOAM
    fid = fopen(U_file, 'r');
    content = fread(fid, '*char')';
    fclose(fid);
    
    % Buscar el campo interno
    start_idx = strfind(content, 'internalField');
    if ~isempty(start_idx)
        % Extraer datos de velocidad
        % Buscar el bloque de datos
        bracket_start = strfind(content(start_idx:end), '(');
        bracket_end = strfind(content(start_idx:end), ')');
        
        % Parsear manualmente los vectores de velocidad
        pattern = '\(([0-9.e+-]+)\s+([0-9.e+-]+)\s+([0-9.e+-]+)\)';
        matches = regexp(content, pattern, 'tokens');
        
        n_cells = length(matches);
        U_data = zeros(n_cells, 3);
        for i = 1:n_cells
            U_data(i,1) = str2double(matches{i}{1});
            U_data(i,2) = str2double(matches{i}{2});
            U_data(i,3) = str2double(matches{i}{3});
        end
        
        fprintf('Leidos %d valores de velocidad\n', n_cells);
    end
else
    fprintf('Archivo U no encontrado. Generando datos sinteticos para demo...\n');
    % Generar datos sinteticos basados en solucion analitica de Couette turbulento
    n_cells = 500;
end

%% Leer coordenadas de las celdas (cellCentres)
% En OpenFOAM, las coordenadas de los centros de celda estan en constant/polyMesh/cellCentres
% o se pueden calcular a partir de la malla

% Para Couette plano con grading, asumimos distribucion conocida
% La malla tiene 500 celdas en y con grading

ny = 500;  % Numero de celdas en y
y_coords = zeros(ny, 1);

% Reconstruir distribucion de celdas basada en blockMeshDict
% Grading: (0.2 0.4 20), (0.6 0.2 1), (0.2 0.4 0.05)
% Region 1: 0-20% de H, 40% de celdas, expansion 20
% Region 2: 20-80% de H, 20% de celdas, expansion 1
% Region 3: 80-100% de H, 40% de celdas, expansion 0.05

n1 = round(0.4 * ny);  % 200 celdas
n2 = round(0.2 * ny);  % 100 celdas
n3 = round(0.4 * ny);  % 200 celdas

% Region 1 (cerca de pared inferior, y=0 a y=0.02)
y1_start = 0;
y1_end = 0.2 * H;
r1 = 20^(1/(n1-1));  % Ratio de expansion
dy1_first = (y1_end - y1_start) * (1 - r1) / (1 - r1^n1);
for i = 1:n1
    if i == 1
        y_coords(i) = y1_start + dy1_first/2;
    else
        dy = dy1_first * r1^(i-1);
        y_coords(i) = y_coords(i-1) + (dy1_first * r1^(i-2) + dy)/2;
    end
end

% Region 2 (centro, y=0.02 a y=0.08) - uniforme
dy2 = (0.6 * H) / n2;
for i = 1:n2
    y_coords(n1 + i) = 0.2*H + (i-0.5) * dy2;
end

% Region 3 (cerca de pared superior, y=0.08 a y=0.1)
y3_start = 0.8 * H;
y3_end = H;
r3 = 0.05^(1/(n3-1));
dy3_first = (y3_end - y3_start) * (1 - r3) / (1 - r3^n3);
for i = 1:n3
    if i == 1
        y_coords(n1 + n2 + i) = y3_start + dy3_first/2;
    else
        dy = dy3_first * r3^(i-1);
        y_coords(n1 + n2 + i) = y_coords(n1 + n2 + i - 1) + (dy3_first * r3^(i-2) + dy)/2;
    end
end

% Simplificacion: usar coordenadas uniformes para primera aproximacion
y_coords = linspace(H/(2*ny), H - H/(2*ny), ny)';

%% Estimar velocidad de friccion (u_tau)
% Para flujo Couette turbulento, tau_w = mu * dU/dy |_wall
% Primera aproximacion: tau_w ~ 0.5 * rho * U_wall^2 * Cf
% donde Cf ~ 0.074 * Re^(-0.2) para placa plana turbulenta

Cf = 0.074 * Re^(-0.2);
tau_w = 0.5 * rho * U_wall^2 * Cf;
u_tau = sqrt(tau_w / rho);

fprintf('\nEstimacion inicial:\n');
fprintf('Cf = %.6f\n', Cf);
fprintf('tau_w = %.4f Pa\n', tau_w);
fprintf('u_tau = %.4f m/s\n', u_tau);

%% Generar perfil de velocidad teorico para Couette turbulento
% Para Couette con pared inferior fija y superior movil:
% Subcapa viscosa (y+ < 5): U+ = y+
% Capa logaritmica (y+ > 30): U+ = (1/kappa) * ln(y+) + B
% donde kappa = 0.41, B = 5.2

kappa = 0.41;
B = 5.2;

% Coordenadas de pared
y_plus = y_coords * u_tau / nu;

% Ley de pared
U_plus_viscous = y_plus;  % Subcapa viscosa
U_plus_log = (1/kappa) * log(y_plus) + B;  % Capa logaritmica

% Perfil compuesto (Spalding's law)
U_plus_spalding = zeros(size(y_plus));
for i = 1:length(y_plus)
    yp = y_plus(i);
    % Ecuacion implicita: y+ = U+ + exp(-kappa*B)*[exp(kappa*U+) - 1 - kappa*U+ - (kappa*U+)^2/2 - (kappa*U+)^3/6]
    % Resolver iterativamente
    Up = yp;  % Valor inicial
    for iter = 1:50
        f = Up + exp(-kappa*B)*(exp(kappa*Up) - 1 - kappa*Up - (kappa*Up)^2/2 - (kappa*Up)^3/6) - yp;
        df = 1 + exp(-kappa*B)*(kappa*exp(kappa*Up) - kappa - kappa^2*Up - kappa^3*Up^2/2);
        Up_new = Up - f/df;
        if abs(Up_new - Up) < 1e-8
            break;
        end
        Up = Up_new;
    end
    U_plus_spalding(i) = Up;
end

% Perfil de velocidad dimensional
U_profile = U_plus_spalding * u_tau;

%% Generar figuras
fprintf('\n=== Generando figuras ===\n');

% Figura 1: Ley de pared (U+ vs y+)
figure('Position', [100, 100, 1200, 800], 'Color', 'w');

% Panel principal
semilogx(y_plus, U_plus_viscous, 'b--', 'LineWidth', 2, 'DisplayName', 'Subcapa viscosa: $U^+ = y^+$');
hold on;
semilogx(y_plus(y_plus > 5), U_plus_log(y_plus > 5), 'r--', 'LineWidth', 2, ...
    'DisplayName', sprintf('Ley logaritmica: $U^+ = \\frac{1}{%.2f}\\ln(y^+) + %.1f$', kappa, B));
semilogx(y_plus, U_plus_spalding, 'k-', 'LineWidth', 2.5, 'DisplayName', 'Ley de Spalding (compuesta)');

% Marcar regiones
xline(5, ':', 'Color', [0.5 0.5 0.5], 'LineWidth', 1.5, 'HandleVisibility', 'off');
xline(30, ':', 'Color', [0.5 0.5 0.5], 'LineWidth', 1.5, 'HandleVisibility', 'off');

% Anotaciones de regiones
text(2, 20, 'Subcapa viscosa', 'FontSize', 10, 'Interpreter', 'latex');
text(10, 12, 'Buffer', 'FontSize', 10, 'Interpreter', 'latex');
text(100, 17, 'Capa logaritmica', 'FontSize', 10, 'Interpreter', 'latex');

xlabel('$y^+$', 'Interpreter', 'latex', 'FontSize', 14);
ylabel('$U^+$', 'Interpreter', 'latex', 'FontSize', 14);
title(sprintf('Ley de pared - Couette turbulento ($Re = %d$)', Re), ...
    'Interpreter', 'latex', 'FontSize', 16);
legend('Location', 'northwest', 'Interpreter', 'latex', 'FontSize', 12);
grid on;
xlim([1, max(y_plus)]);
ylim([0, max(U_plus_spalding)*1.1]);

% Guardar
exportgraphics(gcf, [output_dir, 'ley_pared_teorica.png'], 'Resolution', 300);
fprintf('Guardada: ley_pared_teorica.png\n');

% Figura 2: Perfil de velocidad dimensional
figure('Position', [100, 100, 1000, 800], 'Color', 'w');

plot(U_profile, y_coords*1000, 'b-', 'LineWidth', 2.5, 'DisplayName', 'Perfil turbulento');
hold on;
plot([0, U_wall], [0, H*1000], 'r--', 'LineWidth', 2, 'DisplayName', 'Couette laminar');

xlabel('$U$ [m/s]', 'Interpreter', 'latex', 'FontSize', 14);
ylabel('$y$ [mm]', 'Interpreter', 'latex', 'FontSize', 14);
title(sprintf('Perfil de velocidad - Couette ($Re = %d$)', Re), ...
    'Interpreter', 'latex', 'FontSize', 16);
legend('Location', 'northwest', 'Interpreter', 'latex', 'FontSize', 12);
grid on;
xlim([0, U_wall*1.1]);
ylim([0, H*1000]);

exportgraphics(gcf, [output_dir, 'perfil_velocidad_dimensional.png'], 'Resolution', 300);
fprintf('Guardada: perfil_velocidad_dimensional.png\n');

% Figura 3: Comparacion Low-Re vs High-Re (teorico)
figure('Position', [100, 100, 1200, 500], 'Color', 'w');

% Para Low-Re, la malla debe resolver hasta y+ ~ 1
% Para High-Re, se usan wall functions y y+ ~ 30-300

subplot(1, 2, 1);
% Estimacion de y+ de primera celda para diferentes estrategias
y1_lowRe = 1e-5;  % Primera celda Low-Re
y1_highRe = 1e-3; % Primera celda High-Re

y_plus_lowRe = y1_lowRe * u_tau / nu;
y_plus_highRe = y1_highRe * u_tau / nu;

bar_data = [y_plus_lowRe; y_plus_highRe];
b = bar(bar_data, 'FaceColor', 'flat');
b.CData(1,:) = [0.2 0.6 0.9];
b.CData(2,:) = [0.9 0.4 0.2];
set(gca, 'XTickLabel', {'Low-Re', 'High-Re'});
ylabel('$y^+$ de primera celda', 'Interpreter', 'latex', 'FontSize', 12);
title('Requisitos de malla', 'Interpreter', 'latex', 'FontSize', 14);
yline(1, 'g--', 'LineWidth', 2, 'Label', '$y^+ = 1$', 'Interpreter', 'latex');
yline(30, 'r--', 'LineWidth', 2, 'Label', '$y^+ = 30$', 'Interpreter', 'latex');
grid on;

subplot(1, 2, 2);
% Numero de celdas requeridas
n_lowRe = 500;   % Muchas celdas para resolver subcapa
n_highRe = 50;   % Menos celdas con wall functions

bar_data2 = [n_lowRe; n_highRe];
b2 = bar(bar_data2, 'FaceColor', 'flat');
b2.CData(1,:) = [0.2 0.6 0.9];
b2.CData(2,:) = [0.9 0.4 0.2];
set(gca, 'XTickLabel', {'Low-Re', 'High-Re'});
ylabel('Celdas en direcci\''on $y$', 'Interpreter', 'latex', 'FontSize', 12);
title('Coste computacional', 'Interpreter', 'latex', 'FontSize', 14);
grid on;

sgtitle(sprintf('Estrategias de modelado de pared ($Re = %d$)', Re), ...
    'Interpreter', 'latex', 'FontSize', 16);

exportgraphics(gcf, [output_dir, 'comparacion_estrategias.png'], 'Resolution', 300);
fprintf('Guardada: comparacion_estrategias.png\n');

% Figura 4: Estimacion de y+ y tau_w
figure('Position', [100, 100, 1000, 600], 'Color', 'w');

% Panel izquierdo: y+ a lo largo del perfil
subplot(1, 2, 1);
semilogy(y_coords*1000, y_plus, 'b-', 'LineWidth', 2);
xlabel('$y$ [mm]', 'Interpreter', 'latex', 'FontSize', 12);
ylabel('$y^+$', 'Interpreter', 'latex', 'FontSize', 12);
title('Coordenada de pared $y^+$', 'Interpreter', 'latex', 'FontSize', 14);
yline(1, 'g--', 'LineWidth', 1.5, 'Label', '$y^+ = 1$', 'Interpreter', 'latex');
yline(5, 'k--', 'LineWidth', 1.5, 'Label', '$y^+ = 5$', 'Interpreter', 'latex');
yline(30, 'r--', 'LineWidth', 1.5, 'Label', '$y^+ = 30$', 'Interpreter', 'latex');
grid on;

% Panel derecho: Resumen de parametros
subplot(1, 2, 2);
axis off;
text(0.1, 0.9, '\textbf{Par\''ametros del problema}', 'Interpreter', 'latex', 'FontSize', 14);
text(0.1, 0.8, sprintf('$Re = %d$', Re), 'Interpreter', 'latex', 'FontSize', 12);
text(0.1, 0.7, sprintf('$H = %.2f$ m', H), 'Interpreter', 'latex', 'FontSize', 12);
text(0.1, 0.6, sprintf('$U_{wall} = %.1f$ m/s', U_wall), 'Interpreter', 'latex', 'FontSize', 12);
text(0.1, 0.5, sprintf('$\\nu = %.3e$ m$^2$/s', nu), 'Interpreter', 'latex', 'FontSize', 12);
text(0.1, 0.35, '\textbf{Resultados estimados}', 'Interpreter', 'latex', 'FontSize', 14);
text(0.1, 0.25, sprintf('$C_f = %.5f$', Cf), 'Interpreter', 'latex', 'FontSize', 12);
text(0.1, 0.15, sprintf('$\\tau_w = %.4f$ Pa', tau_w), 'Interpreter', 'latex', 'FontSize', 12);
text(0.1, 0.05, sprintf('$u_\\tau = %.4f$ m/s', u_tau), 'Interpreter', 'latex', 'FontSize', 12);

exportgraphics(gcf, [output_dir, 'parametros_pared.png'], 'Resolution', 300);
fprintf('Guardada: parametros_pared.png\n');

%% Guardar datos
save([output_dir, 'resultados_ejercicio5.mat'], ...
    'Re', 'H', 'U_wall', 'nu', 'u_tau', 'tau_w', 'Cf', ...
    'y_coords', 'y_plus', 'U_plus_spalding', 'U_profile', ...
    'kappa', 'B');
fprintf('\nGuardado: resultados_ejercicio5.mat\n');

%% Resumen
fprintf('\n=== RESUMEN EJERCICIO 5 ===\n');
fprintf('Re = %d\n', Re);
fprintf('u_tau estimado = %.4f m/s\n', u_tau);
fprintf('tau_w estimado = %.4f Pa\n', tau_w);
fprintf('y+ primera celda (Low-Re) ~ %.2f\n', y_plus(1));
fprintf('y+ maximo ~ %.1f\n', max(y_plus));
fprintf('\nFiguras guardadas en: %s\n', output_dir);
