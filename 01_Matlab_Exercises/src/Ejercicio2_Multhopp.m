%% EJERCICIO 2: METODO DE MULTHOPP PARA ALAS RECTAS
% Master en Ingenieria Aeronautica - Universidad de Leon

clearvars; close all; clc;

%% Configurar directorio de figuras
script_dir = fileparts(mfilename('fullpath'));
if isempty(script_dir)
    script_dir = pwd;
end
fig_dir = fullfile(script_dir, '..', 'figures', 'Ejercicio2');
if ~exist(fig_dir, 'dir')
    mkdir(fig_dir);
end

% Configuracion para fondo blanco
set(0, 'DefaultFigureColor', 'w');

% Configurar interprete LaTeX para todas las figuras
set(groot,'defaulttextinterpreter','latex');
set(groot,'defaultLegendInterpreter','latex');
set(groot,'defaultAxesTickLabelInterpreter','latex');

%% DATOS DEL PROBLEMA
% Geometria del ala
b = 15;                 % Envergadura [m]
c_raiz = 2.1;          % Cuerda en la raiz [m]
c_punta = 1.0;         % Cuerda en la punta [m]
epsilon_raiz = 5;      % Torsion en la raiz [grados]
epsilon_punta = 1;     % Torsion en la punta [grados]

% Alerones
aileron_span = 0.10;   % Extension de alerones (10% de semi-envergadura)
delta_aileron = 6;     % Deflexion de alerones [grados]

% Aerodinamica
a0 = 5.5;              % Pendiente de la curva de sustentacion [1/rad]
alpha0 = 0;            % Angulo de sustentacion nula [grados]

% Discretizacion
N = 71;                % Numero de estaciones (minimo 45)
theta = linspace(pi/(2*N), pi*(1-1/(2*N)), N);  % Angulos para distribucion coseno
y = (b/2) * cos(theta);                          % Posiciones en la envergadura

% Rango de angulos de ataque a evaluar
alpha_range = 0:1:20;  % [grados]

fprintf('=========================================================\n');
fprintf('  EJERCICIO 2: METODO DE MULTHOPP\n');
fprintf('  Analisis de Ala Recta con Alerones\n');
fprintf('=========================================================\n\n');

%% CALCULO DE LA LEY DE CUERDAS
% Distribucion lineal: c(y) = c_raiz + (c_punta - c_raiz) * |2y/b|
c = c_raiz + (c_punta - c_raiz) * abs(2*y/b);

%% CALCULO DE LA LEY DE TORSION
% Distribucion lineal: epsilon(y) = epsilon_raiz + (epsilon_punta - epsilon_raiz) * |2y/b|
epsilon = epsilon_raiz + (epsilon_punta - epsilon_raiz) * abs(2*y/b);
epsilon_rad = epsilon * pi/180;  % Conversion a radianes

%% CONSTRUCCION DE LA MATRIZ DE INFLUENCIA (Metodo de Multhopp)
% Matriz A segun el metodo de Multhopp
A = zeros(N, N);

for i = 1:N
    for j = 1:N
        if i == j
            % Diagonal: termino singular
            A(i,j) = (a0/(8*b)) * c(i) + sin(theta(i))/(4*sin(theta(i)));
        else
            % Fuera de la diagonal
            A(i,j) = sin(theta(j)) / (4*sin(theta(i)) * (cos(theta(j)) - cos(theta(i))));
        end
    end
end

%% CASOS A ANALIZAR
% 1. Sin alerones
% 2. Alerones extendidos (positivos)
% 3. Alerones retraidos (negativos)

casos = {'Sin alerones', 'Alerones extendidos (+6 deg)', 'Alerones retraidos (-6 deg)'};
delta_cases = [0, delta_aileron, -delta_aileron];  % [grados]

% Preasignacion de resultados
resultados = struct();

% Calcular superficie alar (constante para todos los casos)
S = 0;
for i = 1:N-1
    S = S + 0.5 * (c(i) + c(i+1)) * abs(y(i+1) - y(i));
end
S = 2 * S;  % Ambas semialas

fprintf('Numero de estaciones: %d\n', N);
fprintf('Envergadura: %.1f m\n', b);
fprintf('Superficie alar: %.2f m^2\n\n', S);

for caso = 1:length(casos)
    fprintf('=== %s ===\n', casos{caso});
    
    % Deflexion de alerones segun el caso
    delta = zeros(1, N);
    delta_deg = delta_cases(caso);
    
    % Aplicar deflexion en el 10% exterior de cada semiala
    if delta_deg ~= 0
        % Identificar estaciones donde aplican los alerones
        aileron_limit = (b/2) * (1 - aileron_span);
        for i = 1:N
            if abs(y(i)) >= aileron_limit
                delta(i) = delta_deg * sign(y(i));  % Signo segun el lado del ala
            end
        end
    end
    
    delta_rad = delta * pi/180;  % Conversion a radianes
    
    % Inicializacion de vectores de resultados
    CL = zeros(length(alpha_range), 1);
    CDi = zeros(length(alpha_range), 1);
    CMx = zeros(length(alpha_range), 1);
    CMz = zeros(length(alpha_range), 1);
    
    for idx = 1:length(alpha_range)
        alpha = alpha_range(idx);
        alpha_rad = alpha * pi/180;
        
        % Vector del lado derecho: alpha + delta + epsilon
        b_vec = alpha_rad + delta_rad' + epsilon_rad';
        
        % Resolucion del sistema: A * Gamma = b
        Gamma = A \ b_vec;
        
        % Coeficiente de sustentacion: CL = (2/S) * integral(Gamma dy)
        CL_temp = 0;
        for i = 1:N-1
            CL_temp = CL_temp + 0.5 * (Gamma(i) + Gamma(i+1)) * abs(y(i+1) - y(i));
        end
        CL(idx) = (2 * CL_temp * 2) / S;  % Factor 2 por ambas semialas
        
        % Coeficiente de resistencia inducida: CDi = (2/S) * integral(Gamma * w dy)
        CDi_temp = 0;
        for i = 1:N-1
            % Calculo del downwash
            w = 0;
            for j = 1:N-1
                dGamma = Gamma(j+1) - Gamma(j);
                w = w - (dGamma / (4*pi)) * (1 / (y(i) - (y(j) + y(j+1))/2 + 1e-10));
            end
            
            CDi_temp = CDi_temp + Gamma(i) * w * abs(y(i+1) - y(i));
        end
        CDi(idx) = (2 * CDi_temp * 2) / S;
        
        % Momento de alabeo: CMx = (2/(S*b)) * integral(Gamma * y dy)
        CMx_temp = 0;
        for i = 1:N-1
            CMx_temp = CMx_temp + 0.5 * (Gamma(i) * y(i) + Gamma(i+1) * y(i+1)) * abs(y(i+1) - y(i));
        end
        CMx(idx) = (2 * CMx_temp * 2) / (S * b);
        
        % Momento de guinada: CMz = -(2/(S*b)) * integral(Gamma * c * y dy)
        CMz_temp = 0;
        for i = 1:N-1
            CMz_temp = CMz_temp + 0.5 * (Gamma(i) * c(i) * y(i) + Gamma(i+1) * c(i+1) * y(i+1)) * abs(y(i+1) - y(i));
        end
        CMz(idx) = -(2 * CMz_temp * 2) / (S * b);
    end
    
    % Almacenar resultados
    resultados.(sprintf('caso%d', caso)).nombre = casos{caso};
    resultados.(sprintf('caso%d', caso)).CL = CL;
    resultados.(sprintf('caso%d', caso)).CDi = CDi;
    resultados.(sprintf('caso%d', caso)).CMx = CMx;
    resultados.(sprintf('caso%d', caso)).CMz = CMz;
    
    % Mostrar algunos resultados
    fprintf('alpha = 10 deg: CL = %.4f, CDi = %.5f, CMx = %.6f, CMz = %.6f\n\n', ...
        CL(11), CDi(11), CMx(11), CMz(11));
end

%% GENERACION DE GRAFICAS

% Figura resumen
fig1 = figure('Position', [100, 100, 1200, 400]);

subplot(1,3,1)
hold on; grid on;
for caso = 1:length(casos)
    plot(alpha_range, resultados.(sprintf('caso%d', caso)).CL, 'LineWidth', 2);
end
xlabel('$\alpha$ [deg]', 'Interpreter', 'latex', 'FontSize', 12);
ylabel('$C_L$', 'Interpreter', 'latex', 'FontSize', 12);
title('Coeficiente de Sustentacion', 'Interpreter', 'latex','FontSize', 13, 'FontWeight', 'bold');
legend(casos, 'Location', 'best', 'Interpreter', 'latex', 'FontSize', 9);
xlim([0 20]);

subplot(1,3,2)
hold on; grid on;
for caso = 1:length(casos)
    plot(alpha_range, resultados.(sprintf('caso%d', caso)).CDi, 'LineWidth', 2);
end
xlabel('$\alpha$ [deg]', 'Interpreter', 'latex', 'FontSize', 12);
ylabel('$C_{Di}$', 'Interpreter', 'latex', 'FontSize', 12);
title('Resistencia Inducida', 'Interpreter', 'latex', 'FontSize', 13, 'FontWeight', 'bold');
legend(casos, 'Location', 'best', 'Interpreter', 'latex', 'FontSize', 9);
xlim([0 20]);

subplot(1,3,3)
hold on; grid on;
for caso = 1:length(casos)
    plot(alpha_range, resultados.(sprintf('caso%d', caso)).CMx, '-', 'LineWidth', 2);
end
xlabel('$\alpha$ [deg]', 'Interpreter', 'latex', 'FontSize', 12);
ylabel('$C_{Mx}$', 'Interpreter', 'latex', 'FontSize', 12);
title('Momento de Alabeo', 'Interpreter', 'latex', 'FontSize', 13, 'FontWeight', 'bold');
legend(casos, 'Location', 'best', 'Interpreter', 'latex', 'FontSize', 9);
xlim([0 20]);

sgtitle('Metodo de Multhopp - Coeficientes Aerodinamicos', 'Interpreter', 'latex', 'FontSize', 16, 'FontWeight', 'bold');
exportgraphics(fig1, fullfile(fig_dir, 'resumen_multhopp.png'), 'Resolution', 300);
fprintf('Guardada: %s\n', fullfile(fig_dir, 'resumen_multhopp.png'));

% Figuras individuales para el documento
% CL vs alpha (todas las configuraciones)
fig2 = figure('Position', [100, 100, 800, 500]);
hold on; grid on;
markers = {'-o', '-s', '-d'};
for caso = 1:length(casos)
    plot(alpha_range, resultados.(sprintf('caso%d', caso)).CL, markers{caso}, ...
         'LineWidth', 2, 'MarkerSize', 5);
end
xlabel('$\alpha$ [deg]', 'Interpreter', 'latex', 'FontSize', 12);
ylabel('$C_L$', 'Interpreter', 'latex', 'FontSize', 12);
title('$C_L$ vs $\alpha$ - Comparacion de Configuraciones', 'Interpreter', 'latex', ...
      'FontSize', 14, 'FontWeight', 'bold');
legend(casos, 'Location', 'best', 'Interpreter', 'latex', 'FontSize', 10);
xlim([0 20]);
exportgraphics(fig2, fullfile(fig_dir, 'CL_vs_alpha.png'), 'Resolution', 300);
fprintf('Guardada: %s\n', fullfile(fig_dir, 'CL_vs_alpha.png'));

% CDi vs alpha (todas las configuraciones)
fig3 = figure('Position', [100, 100, 800, 500]);
hold on; grid on;
for caso = 1:length(casos)
    plot(alpha_range, resultados.(sprintf('caso%d', caso)).CDi, markers{caso}, ...
         'LineWidth', 2, 'MarkerSize', 5);
end
xlabel('$\alpha$ [deg]', 'Interpreter', 'latex', 'FontSize', 12);
ylabel('$C_{Di}$', 'Interpreter', 'latex', 'FontSize', 12);
title('$C_{Di}$ vs $\alpha$ - Comparacion de Configuraciones', 'Interpreter', 'latex', ...
      'FontSize', 14, 'FontWeight', 'bold');
legend(casos, 'Location', 'best', 'Interpreter', 'latex', 'FontSize', 10);
xlim([0 20]);
exportgraphics(fig3, fullfile(fig_dir, 'CDi_vs_alpha.png'), 'Resolution', 300);
fprintf('Guardada: %s\n', fullfile(fig_dir, 'CDi_vs_alpha.png'));

% CMx vs alpha (momento de alabeo)
fig4 = figure('Position', [100, 100, 800, 500]);
hold on; grid on;
for caso = 1:length(casos)
    plot(alpha_range, resultados.(sprintf('caso%d', caso)).CMx, markers{caso}, ...
         'LineWidth', 2, 'MarkerSize', 5);
end
xlabel('$\alpha$ [deg]', 'Interpreter', 'latex', 'FontSize', 12);
ylabel('$C_{Mx}$', 'Interpreter', 'latex', 'FontSize', 12);
title('$C_{Mx}$ vs $\alpha$ - Momento de Alabeo', 'Interpreter', 'latex', ...
      'FontSize', 14, 'FontWeight', 'bold');
legend(casos, 'Location', 'best', 'Interpreter', 'latex', 'FontSize', 10);
xlim([0 20]);
exportgraphics(fig4, fullfile(fig_dir, 'CMx_vs_alpha.png'), 'Resolution', 300);
fprintf('Guardada: %s\n', fullfile(fig_dir, 'CMx_vs_alpha.png'));

% CMz vs alpha (momento de guinada)
fig5 = figure('Position', [100, 100, 800, 500]);
hold on; grid on;
for caso = 1:length(casos)
    plot(alpha_range, resultados.(sprintf('caso%d', caso)).CMz, markers{caso}, ...
         'LineWidth', 2, 'MarkerSize', 5);
end
xlabel('$\alpha$ [deg]', 'Interpreter', 'latex', 'FontSize', 12);
ylabel('$C_{Mz}$', 'Interpreter', 'latex', 'FontSize', 12);
title('$C_{Mz}$ vs $\alpha$ - Momento de Guinada (Efecto Adverso)', 'Interpreter', 'latex', ...
      'FontSize', 14, 'FontWeight', 'bold');
legend(casos, 'Location', 'best', 'Interpreter', 'latex', 'FontSize', 10);
xlim([0 20]);
exportgraphics(fig5, fullfile(fig_dir, 'CMz_vs_alpha.png'), 'Resolution', 300);
fprintf('Guardada: %s\n', fullfile(fig_dir, 'CMz_vs_alpha.png'));

%% GRAFICAS INDIVIDUALES PARA CADA CASO
for caso = 1:length(casos)
    fig_caso = figure('Position', [100 + 50*caso, 100 + 50*caso, 1000, 800]);
    
    % CL vs alpha
    subplot(2,2,1)
    plot(alpha_range, resultados.(sprintf('caso%d', caso)).CL, 'b-o', 'LineWidth', 2, 'MarkerSize', 5);
    grid on;
    xlabel('$\alpha$ [deg]', 'Interpreter', 'latex', 'FontSize', 11);
    ylabel('$C_L$', 'Interpreter', 'latex', 'FontSize', 11);
    title(sprintf('$C_L$ vs $\\alpha$ - %s', casos{caso}), 'Interpreter', 'latex', ...
          'FontSize', 12, 'FontWeight', 'bold');
    xlim([0 20]);
    
    % CDi vs alpha
    subplot(2,2,2)
    plot(alpha_range, resultados.(sprintf('caso%d', caso)).CDi, 'r-s', 'LineWidth', 2, 'MarkerSize', 5);
    grid on;
    xlabel('$\alpha$ [deg]', 'Interpreter', 'latex', 'FontSize', 11);
    ylabel('$C_{Di}$', 'Interpreter', 'latex', 'FontSize', 11);
    title(sprintf('$C_{Di}$ vs $\\alpha$ - %s', casos{caso}), 'Interpreter', 'latex', ...
          'FontSize', 12, 'FontWeight', 'bold');
    xlim([0 20]);
    
    % CMx vs alpha
    subplot(2,2,3)
    plot(alpha_range, resultados.(sprintf('caso%d', caso)).CMx, 'g-d', 'LineWidth', 2, 'MarkerSize', 5);
    grid on;
    xlabel('$\alpha$ [deg]', 'Interpreter', 'latex', 'FontSize', 11);
    ylabel('$C_{Mx}$', 'Interpreter', 'latex', 'FontSize', 11);
    title(sprintf('$C_{Mx}$ vs $\\alpha$ - %s', casos{caso}), 'Interpreter', 'latex', ...
          'FontSize', 12, 'FontWeight', 'bold');
    xlim([0 20]);
    
    % CMz vs alpha
    subplot(2,2,4)
    plot(alpha_range, resultados.(sprintf('caso%d', caso)).CMz, 'm-^', 'LineWidth', 2, 'MarkerSize', 5);
    grid on;
    xlabel('$\alpha$ [deg]', 'Interpreter', 'latex', 'FontSize', 11);
    ylabel('$C_{Mz}$', 'Interpreter', 'latex', 'FontSize', 11);
    title(sprintf('$C_{Mz}$ vs $\\alpha$ - %s', casos{caso}), 'Interpreter', 'latex', ...
          'FontSize', 12, 'FontWeight', 'bold');
    xlim([0 20]);
    
    sgtitle(sprintf('Resultados - %s', casos{caso}), 'FontSize', 14, 'FontWeight', 'bold');
    
    % Guardar figura de cada caso
    filename = sprintf('caso%d_%s.png', caso, strrep(lower(casos{caso}), ' ', '_'));
    filename = strrep(filename, '(', '');
    filename = strrep(filename, ')', '');
    filename = strrep(filename, '+', 'pos');
    filename = strrep(filename, '-', 'neg');
    exportgraphics(fig_caso, fullfile(fig_dir, filename), 'Resolution', 300);
    fprintf('Guardada: %s\n', fullfile(fig_dir, filename));
end

%% EXPORTAR RESULTADOS A ARCHIVOS
fprintf('\n=== EXPORTANDO RESULTADOS ===\n');

% Crear directorio de datos si no existe
data_dir = fullfile(script_dir, '..', 'data');
if ~exist(data_dir, 'dir')
    mkdir(data_dir);
end

% Tabla general
T = table(alpha_range', ...
    resultados.caso1.CL, resultados.caso1.CDi, resultados.caso1.CMx, resultados.caso1.CMz, ...
    resultados.caso2.CL, resultados.caso2.CDi, resultados.caso2.CMx, resultados.caso2.CMz, ...
    resultados.caso3.CL, resultados.caso3.CDi, resultados.caso3.CMx, resultados.caso3.CMz, ...
    'VariableNames', {'Alpha_deg', ...
    'CL_sin_ailerones', 'CDi_sin_ailerones', 'CMx_sin_ailerones', 'CMz_sin_ailerones', ...
    'CL_ailerones_pos', 'CDi_ailerones_pos', 'CMx_ailerones_pos', 'CMz_ailerones_pos', ...
    'CL_ailerones_neg', 'CDi_ailerones_neg', 'CMx_ailerones_neg', 'CMz_ailerones_neg'});

writetable(T, fullfile(data_dir, 'Resultados_Multhopp.csv'));
fprintf('Resultados guardados en: %s\n', fullfile(data_dir, 'Resultados_Multhopp.csv'));

% Guardar en .mat
save(fullfile(fig_dir, 'resultados_ejercicio2.mat'), 'resultados', 'alpha_range', ...
     'b', 'c_raiz', 'c_punta', 'N', 'S', 'casos');
fprintf('Datos guardados en: %s\n', fullfile(fig_dir, 'resultados_ejercicio2.mat'));

fprintf('\n=== CALCULO COMPLETADO ===\n');
fprintf('Numero de estaciones: %d\n', N);
fprintf('Envergadura: %.1f m\n', b);
fprintf('Superficie alar: %.2f m^2\n', S);
