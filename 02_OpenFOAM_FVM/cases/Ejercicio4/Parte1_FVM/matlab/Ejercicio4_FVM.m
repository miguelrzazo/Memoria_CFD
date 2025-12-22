%% ========================================================================
%  EJERCICIO 4: M?TODOS DE VOL?MENES FINITOS (FVM)
%  Parte 1: Soluciones Anal?ticas para Validaci?n
%  ========================================================================
%  Este script implementa las soluciones anal?ticas de:
%  1. Ecuaci?n de advecci?n-difusi?n 1D (estado estacionario)
%  2. Problema del tubo de choque de Sod (Riemann problem)
%  
%  Los resultados se utilizan para validar las simulaciones OpenFOAM
%  ========================================================================

clear; clc; close all;

%% ========================================================================
%  CONFIGURACI?N GLOBAL
%  ========================================================================
fprintf('=========================================================\n');
fprintf('  EJERCICIO 4: M?TODOS DE VOL?MENES FINITOS (FVM)\n');
fprintf('  Soluciones Anal?ticas para Validaci?n\n');
fprintf('=========================================================\n\n');

% Crear directorio para figuras si no existe
figDir = 'figures';
if ~exist(figDir, 'dir')
    mkdir(figDir);
end

%% ========================================================================
%  PARTE 1: ADVECCI?N-DIFUSI?N 1D (ESTADO ESTACIONARIO)
%  ========================================================================
fprintf('PARTE 1: Advecci?n-Difusi?n 1D\n');
fprintf('---------------------------------------------------------\n');

% La ecuaci?n de advecci?n-difusi?n estacionaria 1D es:
%   u * dT/dx = D * d?T/dx?
% Con condiciones de contorno:
%   T(0) = T_in = 1
%   T(L) = T_out = 0
%
% La soluci?n anal?tica es:
%   T(x) = T_in + (T_out - T_in) * (exp(Pe*x/L) - 1) / (exp(Pe) - 1)
% donde Pe = u*L/D es el n?mero de P?clet

% Par?metros del problema
L = 1.0;            % Longitud del dominio [m]
u = 0.1;            % Velocidad de advecci?n [m/s]
D = 0.01;           % Coeficiente de difusi?n [m?/s]
T_in = 1.0;         % Temperatura en la entrada
T_out = 0.0;        % Temperatura en la salida

% N?mero de P?clet
Pe = u * L / D;
fprintf('  Longitud del dominio: L = %.2f m\n', L);
fprintf('  Velocidad de advecci?n: u = %.2f m/s\n', u);
fprintf('  Coeficiente de difusi?n: D = %.4f m?/s\n', D);
fprintf('  N?mero de P?clet: Pe = %.2f\n', Pe);

% Discretizaci?n espacial
N_points = 1000;
x = linspace(0, L, N_points);

% Soluci?n anal?tica
T_analitica = T_in + (T_out - T_in) * (exp(Pe * x / L) - 1) / (exp(Pe) - 1);

% An?lisis del n?mero de P?clet
fprintf('\n  An?lisis del r?gimen de transporte:\n');
if Pe < 1
    fprintf('    Pe < 1: Difusi?n dominante\n');
elseif Pe > 10
    fprintf('    Pe > 10: Advecci?n dominante\n');
else
    fprintf('    1 < Pe < 10: R?gimen mixto\n');
end

% Diferentes n?meros de P?clet para comparaci?n
Pe_valores = [0.1, 1, 5, 10, 50];
T_Pe = zeros(length(Pe_valores), N_points);

for i = 1:length(Pe_valores)
    Pe_i = Pe_valores(i);
    if abs(Pe_i) < 1e-10
        % Caso puramente difusivo (lineal)
        T_Pe(i, :) = T_in + (T_out - T_in) * x / L;
    else
        T_Pe(i, :) = T_in + (T_out - T_in) * (exp(Pe_i * x / L) - 1) / (exp(Pe_i) - 1);
    end
end

% Gr?fica: Perfiles de temperatura para diferentes n?meros de P?clet
figure('Position', [100, 100, 800, 500]);
colors = lines(length(Pe_valores));
for i = 1:length(Pe_valores)
    plot(x, T_Pe(i, :), 'LineWidth', 2, 'Color', colors(i, :), ...
         'DisplayName', sprintf('Pe = %.1f', Pe_valores(i)));
    hold on;
end
xlabel('Posici?n x/L [-]', 'FontSize', 12);
ylabel('Temperatura T [-]', 'FontSize', 12);
title('Soluci?n Anal?tica: Advecci?n-Difusi?n 1D', 'FontSize', 14);
legend('Location', 'northeast', 'FontSize', 10);
grid on;
xlim([0 1]);
ylim([0 1]);
saveas(gcf, fullfile(figDir, 'adveccion_difusion_peclet.png'));
saveas(gcf, fullfile(figDir, 'adveccion_difusion_peclet.eps'), 'epsc');

% Gr?fica: Soluci?n para el caso espec?fico del problema
figure('Position', [100, 100, 800, 500]);
plot(x, T_analitica, 'b-', 'LineWidth', 2);
hold on;
% Marcar puntos de referencia
plot([0, L], [T_in, T_out], 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
xlabel('Posici?n x [m]', 'FontSize', 12);
ylabel('Temperatura T [-]', 'FontSize', 12);
title(sprintf('Advecci?n-Difusi?n 1D (Pe = %.2f)', Pe), 'FontSize', 14);
legend({'Soluci?n anal?tica', 'Condiciones de contorno'}, 'Location', 'northeast');
grid on;
xlim([0 L]);
saveas(gcf, fullfile(figDir, 'adveccion_difusion_caso.png'));
saveas(gcf, fullfile(figDir, 'adveccion_difusion_caso.eps'), 'epsc');

% Exportar datos para comparaci?n con OpenFOAM
T_export = [x', T_analitica'];
writematrix(T_export, 'T_analitica_advdiff.csv');
fprintf('\n  Datos exportados a: T_analitica_advdiff.csv\n');

%% ========================================================================
%  PARTE 2: TUBO DE CHOQUE DE SOD (PROBLEMA DE RIEMANN)
%  ========================================================================
fprintf('\n=========================================================\n');
fprintf('PARTE 2: Tubo de Choque de Sod\n');
fprintf('---------------------------------------------------------\n');

% El problema del tubo de choque de Sod es un problema de Riemann cl?sico
% para las ecuaciones de Euler compresibles 1D.
%
% Condiciones iniciales (t = 0):
%   Lado izquierdo (x < 0):  rho_L = 1.0,    p_L = 1.0,    u_L = 0
%   Lado derecho (x > 0):    rho_R = 0.125,  p_R = 0.1,    u_R = 0
%
% Par?metros del gas ideal:
%   gamma = 1.4 (aire)

% Par?metros del problema
gamma = 1.4;        % Relaci?n de calores espec?ficos
R_gas = 287.0;      % Constante del gas [J/(kg*K)]

% Condiciones iniciales (lado izquierdo - alta presi?n)
rho_L = 1.0;        % Densidad [kg/m?]
p_L = 100000;       % Presi?n [Pa] (1 bar)
u_L = 0.0;          % Velocidad [m/s]

% Condiciones iniciales (lado derecho - baja presi?n)
rho_R = 0.125;      % Densidad [kg/m?]
p_R = 10000;        % Presi?n [Pa] (0.1 bar)
u_R = 0.0;          % Velocidad [m/s]

% Tiempo de simulaci?n
t_final = 0.007;    % Tiempo final [s] (7 ms para ver bien las estructuras)

% Dominio espacial
x_min = -5;
x_max = 5;
N_cells = 1000;
x_sod = linspace(x_min, x_max, N_cells);

fprintf('  Condiciones iniciales:\n');
fprintf('    Lado izquierdo: rho = %.3f kg/m?, p = %.0f Pa, u = %.1f m/s\n', rho_L, p_L, u_L);
fprintf('    Lado derecho:   rho = %.3f kg/m?, p = %.0f Pa, u = %.1f m/s\n', rho_R, p_R, u_R);
fprintf('  Tiempo de simulaci?n: t = %.4f s\n', t_final);
fprintf('  Gamma = %.2f\n', gamma);

% Calcular velocidades del sonido iniciales
a_L = sqrt(gamma * p_L / rho_L);
a_R = sqrt(gamma * p_R / rho_R);
fprintf('\n  Velocidades del sonido:\n');
fprintf('    a_L = %.2f m/s\n', a_L);
fprintf('    a_R = %.2f m/s\n', a_R);

% =========================================================================
% Soluci?n exacta del problema de Riemann
% =========================================================================
% La soluci?n consiste en 5 regiones separadas por:
% 1. Onda de rarefacci?n (cabeza) - se propaga a la izquierda
% 2. Onda de rarefacci?n (cola)
% 3. Discontinuidad de contacto - se propaga a la derecha
% 4. Onda de choque - se propaga a la derecha

% Funci?n para calcular la presi?n en la regi?n intermedia (m?todo iterativo)
% Usando la relaci?n de Rankine-Hugoniot y relaciones de ondas isentr?picas

% Par?metros derivados
g1 = (gamma - 1) / (2 * gamma);
g2 = (gamma + 1) / (2 * gamma);
g3 = 2 * gamma / (gamma - 1);
g4 = 2 / (gamma - 1);
g5 = 2 / (gamma + 1);
g6 = (gamma - 1) / (gamma + 1);
g7 = (gamma - 1) / 2;
g8 = gamma - 1;

% Funci?n para resolver la presi?n en la zona de contacto
% p_star se obtiene iterativamente

% Estimaci?n inicial
p_star_inicial = 0.5 * (p_L + p_R);

% Funci?n objetivo para Newton-Raphson
f_L = @(p) f_K(p, rho_L, p_L, a_L, gamma);
f_R = @(p) f_K(p, rho_R, p_R, a_R, gamma);
fp_L = @(p) fp_K(p, rho_L, p_L, a_L, gamma);
fp_R = @(p) fp_K(p, rho_R, p_R, a_R, gamma);

% Resolver para p_star
p_star = p_star_inicial;
tol = 1e-10;
max_iter = 100;

for iter = 1:max_iter
    f = f_L(p_star) + f_R(p_star) + (u_R - u_L);
    fp = fp_L(p_star) + fp_R(p_star);
    dp = -f / fp;
    p_star = p_star + dp;
    if abs(dp / p_star) < tol
        break;
    end
end

% Velocidad en la zona de contacto
u_star = 0.5 * (u_L + u_R + f_R(p_star) - f_L(p_star));

fprintf('\n  Soluci?n del problema de Riemann:\n');
fprintf('    p* = %.2f Pa (presi?n en zona de contacto)\n', p_star);
fprintf('    u* = %.2f m/s (velocidad en zona de contacto)\n', u_star);

% Densidades en las regiones intermedias
% Lado izquierdo (onda de rarefacci?n)
rho_star_L = rho_L * (p_star / p_L)^(1/gamma);
a_star_L = a_L * (p_star / p_L)^g1;

% Lado derecho (onda de choque)
rho_star_R = rho_R * ((p_star/p_R + g6) / (g6*p_star/p_R + 1));

% Velocidad del choque
S_shock = u_R + a_R * sqrt(g2 * p_star/p_R + g1);

% Velocidades de la onda de rarefacci?n
S_HL = u_L - a_L;           % Cabeza de la rarefacci?n
S_TL = u_star - a_star_L;    % Cola de la rarefacci?n

fprintf('    rho*_L = %.4f kg/m?\n', rho_star_L);
fprintf('    rho*_R = %.4f kg/m?\n', rho_star_R);
fprintf('\n  Velocidades de las ondas:\n');
fprintf('    Cabeza rarefacci?n: S_HL = %.2f m/s\n', S_HL);
fprintf('    Cola rarefacci?n: S_TL = %.2f m/s\n', S_TL);
fprintf('    Discontinuidad contacto: u* = %.2f m/s\n', u_star);
fprintf('    Onda de choque: S_shock = %.2f m/s\n', S_shock);

% Calcular la soluci?n en cada punto del dominio
rho_exact = zeros(1, N_cells);
u_exact = zeros(1, N_cells);
p_exact = zeros(1, N_cells);

for i = 1:N_cells
    xi = x_sod(i);
    S = xi / t_final;  % Velocidad caracter?stica local
    
    if S < S_HL
        % Regi?n 1: Estado inicial izquierdo (sin perturbar)
        rho_exact(i) = rho_L;
        u_exact(i) = u_L;
        p_exact(i) = p_L;
    elseif S < S_TL
        % Regi?n 2: Dentro de la onda de rarefacci?n
        u_exact(i) = g5 * (a_L + g7*u_L + S);
        a_local = g5 * (a_L + g7*(u_L - S));
        rho_exact(i) = rho_L * (a_local / a_L)^g4;
        p_exact(i) = p_L * (a_local / a_L)^g3;
    elseif S < u_star
        % Regi?n 3: Entre cola de rarefacci?n y discontinuidad de contacto
        rho_exact(i) = rho_star_L;
        u_exact(i) = u_star;
        p_exact(i) = p_star;
    elseif S < S_shock
        % Regi?n 4: Entre discontinuidad de contacto y choque
        rho_exact(i) = rho_star_R;
        u_exact(i) = u_star;
        p_exact(i) = p_star;
    else
        % Regi?n 5: Estado inicial derecho (sin perturbar)
        rho_exact(i) = rho_R;
        u_exact(i) = u_R;
        p_exact(i) = p_R;
    end
end

% Normalizar para comparaci?n (como en el archivo CSV de referencia)
rho_norm = rho_exact / rho_L;
p_norm = p_exact / p_L;
% La velocidad en el CSV parece estar normalizada, usamos la velocidad dimensional
u_norm = u_exact / sqrt(gamma * p_L / rho_L);  % Normalizada por velocidad del sonido

% Gr?ficas del tubo de choque
figure('Position', [100, 100, 1200, 800]);

% Densidad
subplot(2, 2, 1);
plot(x_sod, rho_exact, 'b-', 'LineWidth', 2);
xlabel('Posici?n x [m]', 'FontSize', 11);
ylabel('Densidad \rho [kg/m?]', 'FontSize', 11);
title('Densidad', 'FontSize', 12);
grid on;
xlim([x_min, x_max]);

% Velocidad
subplot(2, 2, 2);
plot(x_sod, u_exact, 'r-', 'LineWidth', 2);
xlabel('Posici?n x [m]', 'FontSize', 11);
ylabel('Velocidad u [m/s]', 'FontSize', 11);
title('Velocidad', 'FontSize', 12);
grid on;
xlim([x_min, x_max]);

% Presi?n
subplot(2, 2, 3);
plot(x_sod, p_exact/1000, 'g-', 'LineWidth', 2);
xlabel('Posici?n x [m]', 'FontSize', 11);
ylabel('Presi?n p [kPa]', 'FontSize', 11);
title('Presi?n', 'FontSize', 12);
grid on;
xlim([x_min, x_max]);

% Energ?a interna espec?fica
e_exact = p_exact ./ (rho_exact * g8);
subplot(2, 2, 4);
plot(x_sod, e_exact/1000, 'm-', 'LineWidth', 2);
xlabel('Posici?n x [m]', 'FontSize', 11);
ylabel('Energ?a interna e [kJ/kg]', 'FontSize', 11);
title('Energ?a Interna Espec?fica', 'FontSize', 12);
grid on;
xlim([x_min, x_max]);

sgtitle(sprintf('Tubo de Choque de Sod - Soluci?n Exacta (t = %.4f s)', t_final), 'FontSize', 14);
saveas(gcf, fullfile(figDir, 'shocktube_solucion_exacta.png'));
saveas(gcf, fullfile(figDir, 'shocktube_solucion_exacta.eps'), 'epsc');

% Gr?fica combinada normalizada
figure('Position', [100, 100, 900, 600]);
x_norm = (x_sod - x_min) / (x_max - x_min);  % Normalizar posici?n [0,1]
plot(x_norm, rho_norm, 'b-', 'LineWidth', 2, 'DisplayName', 'Densidad \rho/\rho_L');
hold on;
plot(x_norm, p_norm, 'r-', 'LineWidth', 2, 'DisplayName', 'Presi?n p/p_L');
plot(x_norm, u_exact/max(abs(u_exact)), 'g-', 'LineWidth', 2, 'DisplayName', 'Velocidad u (norm)');
xlabel('Posici?n x/L [-]', 'FontSize', 12);
ylabel('Variables normalizadas [-]', 'FontSize', 12);
title('Tubo de Choque de Sod - Variables Normalizadas', 'FontSize', 14);
legend('Location', 'best', 'FontSize', 10);
grid on;
xlim([0 1]);
saveas(gcf, fullfile(figDir, 'shocktube_normalizado.png'));
saveas(gcf, fullfile(figDir, 'shocktube_normalizado.eps'), 'epsc');

% Exportar datos para comparaci?n con OpenFOAM
sod_export = [(x_sod' - x_min) / (x_max - x_min), rho_norm', p_norm', u_exact'];
writematrix(sod_export, 'sod_analitico.csv');
fprintf('\n  Datos exportados a: sod_analitico.csv\n');

%% ========================================================================
%  PARTE 3: AN?LISIS DE ESQUEMAS NUM?RICOS
%  ========================================================================
fprintf('\n=========================================================\n');
fprintf('PARTE 3: An?lisis de Esquemas Num?ricos\n');
fprintf('---------------------------------------------------------\n');

% Comparaci?n de esquemas de discretizaci?n para advecci?n-difusi?n

% Par?metros
N_celdas_lista = [20, 50, 100, 500, 1000];
dx_list = L ./ N_celdas_lista;

% N?mero de P?clet de celda para diferentes discretizaciones
Pe_celda = u * dx_list / D;

fprintf('\n  N?mero de P?clet de celda para diferentes mallas:\n');
fprintf('  %10s %15s %15s\n', 'N celdas', 'dx [m]', 'Pe_celda');
for i = 1:length(N_celdas_lista)
    fprintf('  %10d %15.4e %15.4f\n', N_celdas_lista(i), dx_list(i), Pe_celda(i));
end

% Criterio de estabilidad: Pe_celda < 2 para esquemas upwind
fprintf('\n  Criterio de estabilidad: Pe_celda < 2\n');
for i = 1:length(N_celdas_lista)
    if Pe_celda(i) < 2
        estable = 'ESTABLE';
    else
        estable = 'INESTABLE (puede requerir correcci?n)';
    end
    fprintf('    N = %d: %s\n', N_celdas_lista(i), estable);
end

% Comparaci?n esquema Central vs Upwind para advecci?n-difusi?n
figure('Position', [100, 100, 1000, 400]);

N_test = 50;
dx = L / N_test;
x_test = linspace(dx/2, L - dx/2, N_test);

% Soluci?n anal?tica en los centros de celda
T_ref = T_in + (T_out - T_in) * (exp(Pe * x_test / L) - 1) / (exp(Pe) - 1);

% Esquema Central Differencing (CD)
% El esquema CD puede producir oscilaciones si Pe_celda > 2
Pe_test = u * dx / D;

subplot(1, 2, 1);
plot(x_test, T_ref, 'k-', 'LineWidth', 2, 'DisplayName', 'Exacta');
hold on;

% Simulaci?n simple de esquema FVM con diferentes esquemas
% (esto es una aproximaci?n para ilustraci?n)
if Pe_test > 2
    title_str = sprintf('N = %d celdas, Pe_{celda} = %.2f (>2)', N_test, Pe_test);
    text(0.5, 0.5, 'Esquema CD puede oscilar', 'FontSize', 10, 'HorizontalAlignment', 'center');
else
    title_str = sprintf('N = %d celdas, Pe_{celda} = %.2f (<2)', N_test, Pe_test);
end

xlabel('Posici?n x [m]', 'FontSize', 11);
ylabel('Temperatura T [-]', 'FontSize', 11);
title(title_str, 'FontSize', 12);
legend('Location', 'northeast');
grid on;
xlim([0 L]);

% Error de truncamiento vs refinamiento de malla
subplot(1, 2, 2);
loglog(N_celdas_lista, 1./N_celdas_lista.^2, 'b-o', 'LineWidth', 2, 'DisplayName', 'O(h?)');
hold on;
loglog(N_celdas_lista, 1./N_celdas_lista, 'r--s', 'LineWidth', 2, 'DisplayName', 'O(h)');
xlabel('N?mero de celdas N', 'FontSize', 11);
ylabel('Error esperado', 'FontSize', 11);
title('Orden de Convergencia Te?rico', 'FontSize', 12);
legend('Location', 'northeast');
grid on;

saveas(gcf, fullfile(figDir, 'esquemas_numericos.png'));
saveas(gcf, fullfile(figDir, 'esquemas_numericos.eps'), 'epsc');

%% ========================================================================
%  RESUMEN DE RESULTADOS
%  ========================================================================
fprintf('\n=========================================================\n');
fprintf('  RESUMEN DE RESULTADOS\n');
fprintf('=========================================================\n');
fprintf('  Figuras generadas en: %s/\n', figDir);
fprintf('    - adveccion_difusion_peclet.png/eps\n');
fprintf('    - adveccion_difusion_caso.png/eps\n');
fprintf('    - shocktube_solucion_exacta.png/eps\n');
fprintf('    - shocktube_normalizado.png/eps\n');
fprintf('    - esquemas_numericos.png/eps\n');
fprintf('\n  Datos CSV exportados:\n');
fprintf('    - T_analitica_advdiff.csv\n');
fprintf('    - sod_analitico.csv\n');
fprintf('=========================================================\n');

%% ========================================================================
%  FUNCIONES AUXILIARES
%  ========================================================================

function f = f_K(p, rho_K, p_K, a_K, gamma)
    % Funci?n para el solver de Riemann
    A_K = 2 / ((gamma + 1) * rho_K);
    B_K = (gamma - 1) / (gamma + 1) * p_K;
    
    if p > p_K
        % Onda de choque
        f = (p - p_K) * sqrt(A_K / (p + B_K));
    else
        % Onda de rarefacci?n
        f = 2 * a_K / (gamma - 1) * ((p / p_K)^((gamma - 1) / (2 * gamma)) - 1);
    end
end

function fp = fp_K(p, rho_K, p_K, a_K, gamma)
    % Derivada de la funci?n f_K para Newton-Raphson
    A_K = 2 / ((gamma + 1) * rho_K);
    B_K = (gamma - 1) / (gamma + 1) * p_K;
    
    if p > p_K
        % Onda de choque
        fp = sqrt(A_K / (p + B_K)) * (1 - (p - p_K) / (2 * (p + B_K)));
    else
        % Onda de rarefacci?n
        fp = 1 / (rho_K * a_K) * (p / p_K)^(-(gamma + 1) / (2 * gamma));
    end
end
