%% ========================================================================
%  EJERCICIO 4 - PARTE 1: METODO DE VOLUMENES FINITOS 1D
%  Ecuacion de Transporte: d(rho*u*phi)/dx = d/dx(Gamma*dphi/dx)
% =========================================================================
%  Autor: Miguel Rosa
%  Fecha: Diciembre 2025
%
%  Descripcion:
%  Implementacion del metodo de volumenes finitos para resolver la ecuacion
%  de conveccion-difusion 1D en regimen estacionario.
%  Se comparan diferentes casos: 5 celdas, 20 celdas, diferentes velocidades
% =========================================================================

clear; clc; close all;

%% Crear directorio de figuras
fig_dir = '../figures/Ejercicio4';
if ~exist(fig_dir, 'dir')
    mkdir(fig_dir);
end

%% Configuracion LaTeX
set(0, 'DefaultTextInterpreter', 'latex');
set(0, 'DefaultAxesTickLabelInterpreter', 'latex');
set(0, 'DefaultLegendInterpreter', 'latex');
set(0, 'DefaultAxesFontSize', 12);

%% ========================================================================
%  CASO 1: 5 celdas, u = 0.1 m/s (VALIDACION)
% =========================================================================
fprintf('=========================================================\n');
fprintf('CASO 1: 5 celdas, u = 0.1 m/s (validacion)\n');
fprintf('=========================================================\n');

% Parametros
L = 1.0;           % Longitud del dominio [m]
u = 0.1;           % Velocidad [m/s]
rho = 1.0;         % Densidad [kg/m³]
Gamma = 0.1;       % Coeficiente de difusion [kg/(m·s)]
N = 5;             % Numero de celdas

% Condiciones de contorno
phi_0 = 1.0;       % phi en x=0
phi_L = 0.0;       % phi en x=L

% Resolver
[phi1, x1, Pe1] = solve_FVM_1D(N, L, u, rho, Gamma, phi_0, phi_L);

fprintf('\nResultados con 5 celdas:\n');
fprintf('Numero de Peclet: Pe = %.4f\n', Pe1);
fprintf('Solucion phi:\n');
for i = 1:N
    fprintf('  phi_%d = %.4f\n', i, phi1(i));
end

% Valores esperados del enunciado
phi_esperado = [0.9421; 0.8006; 0.6276; 0.4163; 0.1579];
error = abs(phi1 - phi_esperado);
fprintf('\nComparacion con solucion esperada:\n');
fprintf('  Error maximo: %.6f\n', max(error));
fprintf('  Error RMS: %.6f\n', sqrt(mean(error.^2)));

%% ========================================================================
%  CASO 2: 5 celdas, u = 2.5 m/s (ALTA VELOCIDAD)
% =========================================================================
fprintf('\n=========================================================\n');
fprintf('CASO 2: 5 celdas, u = 2.5 m/s (alta velocidad)\n');
fprintf('=========================================================\n');

u2 = 2.5;
[phi2, x2, Pe2] = solve_FVM_1D(N, L, u2, rho, Gamma, phi_0, phi_L);

fprintf('\nResultados con 5 celdas, u = 2.5 m/s:\n');
fprintf('Numero de Peclet: Pe = %.4f\n', Pe2);
fprintf('Solucion phi:\n');
for i = 1:N
    fprintf('  phi_%d = %.4f\n', i, phi2(i));
end

%% ========================================================================
%  CASO 3: 20 celdas, u = 2.5 m/s (REFINAMIENTO)
% =========================================================================
fprintf('\n=========================================================\n');
fprintf('CASO 3: 20 celdas, u = 2.5 m/s (refinamiento)\n');
fprintf('=========================================================\n');

N3 = 20;
[phi3, x3, Pe3] = solve_FVM_1D(N3, L, u2, rho, Gamma, phi_0, phi_L);

fprintf('\nResultados con 20 celdas, u = 2.5 m/s:\n');
fprintf('Numero de Peclet: Pe = %.4f\n', Pe3);

%% ========================================================================
%  SOLUCION ANALITICA
% =========================================================================
% Para la ecuacion de conveccion-difusion estacionaria 1D:
% d/dx(rho*u*phi - Gamma*dphi/dx) = 0
% Con phi(0)=1, phi(L)=0, la solucion analitica es:
% phi(x) = (exp(Pe*x/L) - exp(Pe)) / (1 - exp(Pe))
% donde Pe = rho*u*L/Gamma es el numero de Peclet

x_analitica = linspace(0, L, 200);
phi_analitica_1 = solucion_analitica(x_analitica, L, Pe1, phi_0, phi_L);
phi_analitica_2 = solucion_analitica(x_analitica, L, Pe2, phi_0, phi_L);

%% ========================================================================
%  FIGURA 1: Comparacion Caso 1 vs Solucion Analitica
% =========================================================================
fig1 = figure('Position', [100, 100, 900, 600], 'Color', 'w');
hold on; grid on; box on;

plot(x_analitica, phi_analitica_1, 'k-', 'LineWidth', 2, 'DisplayName', 'Soluci\''on anal\''itica');
plot(x1, phi1, 'ro-', 'MarkerFaceColor', 'r', 'MarkerSize', 10, 'LineWidth', 2, ...
    'DisplayName', sprintf('FVM (%d celdas)', N));

xlabel('$x$ [m]', 'FontSize', 14);
ylabel('$\phi$ [-]', 'FontSize', 14);
title(sprintf('Caso 1: $u = %.1f$ m/s, $N = %d$, $Pe = %.2f$', u, N, Pe1), 'FontSize', 14);
legend('Location', 'northeast', 'FontSize', 12);
xlim([0, L]);
ylim([0, 1.1]);

saveas(fig1, fullfile(fig_dir, 'FVM_caso1_validacion.png'));
fprintf('\n  Guardado: FVM_caso1_validacion.png\n');

%% ========================================================================
%  FIGURA 2: Efecto de incrementar velocidad (Caso 1 vs Caso 2)
% =========================================================================
fig2 = figure('Position', [100, 100, 900, 600], 'Color', 'w');
hold on; grid on; box on;

plot(x_analitica, phi_analitica_1, 'k--', 'LineWidth', 1.5, ...
    'DisplayName', sprintf('Anal\''itica ($u = %.1f$ m/s, $Pe = %.1f$)', u, Pe1));
plot(x1, phi1, 'ro-', 'MarkerFaceColor', 'r', 'MarkerSize', 10, 'LineWidth', 2, ...
    'DisplayName', sprintf('FVM ($u = %.1f$ m/s)', u));

plot(x_analitica, phi_analitica_2, 'b--', 'LineWidth', 1.5, ...
    'DisplayName', sprintf('Anal\''itica ($u = %.1f$ m/s, $Pe = %.1f$)', u2, Pe2));
plot(x2, phi2, 'bs-', 'MarkerFaceColor', 'b', 'MarkerSize', 10, 'LineWidth', 2, ...
    'DisplayName', sprintf('FVM ($u = %.1f$ m/s)', u2));

xlabel('$x$ [m]', 'FontSize', 14);
ylabel('$\phi$ [-]', 'FontSize', 14);
title(sprintf('Efecto de incrementar velocidad ($N = %d$ celdas)', N), 'FontSize', 14);
legend('Location', 'northeast', 'FontSize', 11);
xlim([0, L]);
ylim([0, 1.1]);

saveas(fig2, fullfile(fig_dir, 'FVM_efecto_velocidad.png'));
fprintf('  Guardado: FVM_efecto_velocidad.png\n');

%% ========================================================================
%  FIGURA 3: Efecto de refinamiento (Caso 2 vs Caso 3)
% =========================================================================
fig3 = figure('Position', [100, 100, 900, 600], 'Color', 'w');
hold on; grid on; box on;

plot(x_analitica, phi_analitica_2, 'k-', 'LineWidth', 2, ...
    'DisplayName', sprintf('Soluci\''on anal\''itica ($Pe = %.1f$)', Pe2));
plot(x2, phi2, 'ro-', 'MarkerFaceColor', 'r', 'MarkerSize', 10, 'LineWidth', 2, ...
    'DisplayName', sprintf('FVM (%d celdas)', N));
plot(x3, phi3, 'bs-', 'MarkerFaceColor', 'b', 'MarkerSize', 8, 'LineWidth', 1.5, ...
    'DisplayName', sprintf('FVM (%d celdas)', N3));

xlabel('$x$ [m]', 'FontSize', 14);
ylabel('$\phi$ [-]', 'FontSize', 14);
title(sprintf('Efecto de refinamiento de malla ($u = %.1f$ m/s)', u2), 'FontSize', 14);
legend('Location', 'northeast', 'FontSize', 12);
xlim([0, L]);
ylim([0, 1.1]);

saveas(fig3, fullfile(fig_dir, 'FVM_efecto_refinamiento.png'));
fprintf('  Guardado: FVM_efecto_refinamiento.png\n');

%% ========================================================================
%  FIGURA 4: Resumen comparativo
% =========================================================================
fig4 = figure('Position', [100, 100, 1200, 400], 'Color', 'w');

subplot(1,3,1);
hold on; grid on; box on;
plot(x_analitica, phi_analitica_1, 'k-', 'LineWidth', 2);
plot(x1, phi1, 'ro-', 'MarkerFaceColor', 'r', 'MarkerSize', 8, 'LineWidth', 1.5);
xlabel('$x$ [m]', 'FontSize', 12);
ylabel('$\phi$ [-]', 'FontSize', 12);
title(sprintf('Caso 1\n$u = %.1f$ m/s, $N = %d$', u, N), 'FontSize', 12);
legend('Anal\''itica', 'FVM', 'Location', 'northeast', 'FontSize', 10);
xlim([0, L]); ylim([0, 1.1]);

subplot(1,3,2);
hold on; grid on; box on;
plot(x_analitica, phi_analitica_2, 'k-', 'LineWidth', 2);
plot(x2, phi2, 'ro-', 'MarkerFaceColor', 'r', 'MarkerSize', 8, 'LineWidth', 1.5);
xlabel('$x$ [m]', 'FontSize', 12);
ylabel('$\phi$ [-]', 'FontSize', 12);
title(sprintf('Caso 2\n$u = %.1f$ m/s, $N = %d$', u2, N), 'FontSize', 12);
legend('Anal\''itica', 'FVM', 'Location', 'northeast', 'FontSize', 10);
xlim([0, L]); ylim([0, 1.1]);

subplot(1,3,3);
hold on; grid on; box on;
plot(x_analitica, phi_analitica_2, 'k-', 'LineWidth', 2);
plot(x3, phi3, 'ro-', 'MarkerFaceColor', 'r', 'MarkerSize', 6, 'LineWidth', 1.5);
xlabel('$x$ [m]', 'FontSize', 12);
ylabel('$\phi$ [-]', 'FontSize', 12);
title(sprintf('Caso 3\n$u = %.1f$ m/s, $N = %d$', u2, N3), 'FontSize', 12);
legend('Anal\''itica', 'FVM', 'Location', 'northeast', 'FontSize', 10);
xlim([0, L]); ylim([0, 1.1]);

sgtitle('M\''etodo de Vol\''umenes Finitos -- Ecuaci\''on de Transporte 1D', ...
    'FontSize', 14, 'Interpreter', 'latex');

saveas(fig4, fullfile(fig_dir, 'FVM_resumen.png'));
fprintf('  Guardado: FVM_resumen.png\n');

fprintf('\n=========================================================\n');
fprintf('Ejercicio 4 - Parte 1 completado\n');
fprintf('=========================================================\n');

%% ========================================================================
%  FUNCIONES AUXILIARES
% =========================================================================

function [phi, x_centers, Pe] = solve_FVM_1D(N, L, u, rho, Gamma, phi_0, phi_L)
%SOLVE_FVM_1D Resuelve ecuacion de conveccion-difusion 1D por FVM
%   Ecuacion: d/dx(rho*u*phi - Gamma*dphi/dx) = 0
%   Esquema: Upwind para conveccion, diferencias centradas para difusion
%
%   Entradas:
%     N      - Numero de celdas
%     L      - Longitud del dominio
%     u      - Velocidad [m/s]
%     rho    - Densidad [kg/m³]
%     Gamma  - Coeficiente de difusion [kg/(m·s)]
%     phi_0  - Valor en x=0
%     phi_L  - Valor en x=L
%
%   Salidas:
%     phi       - Solucion en centros de celda
%     x_centers - Posiciones de centros de celda
%     Pe        - Numero de Peclet

    % Numero de Peclet
    Pe = rho * u * L / Gamma;

    % Discretizacion espacial
    dx = L / N;
    x_centers = (0.5:N-0.5) * dx;  % Centros de celda
    x_faces = (0:N) * dx;          % Caras de celda

    % Matriz del sistema [A]{phi} = {b}
    A = zeros(N, N);
    b = zeros(N, 1);

    % Flujos convectivos y difusivos en caras
    F = rho * u;        % Flujo convectivo (constante)
    D = Gamma / dx;     % Coeficiente difusivo

    % Ensamblaje del sistema
    for i = 1:N
        if i == 1
            % Primera celda: cara oeste tiene BC
            % Cara oeste (face w): phi_0 conocido
            % Conveccion: F * phi_w (upwind)
            % Difusion: D * (phi_w - phi_1)

            % Cara este (face e): entre celda 1 y 2
            % Conveccion: F * phi_1 (upwind, u>0)
            % Difusion: D * (phi_2 - phi_1)

            A(i,i) = F + 2*D;
            if i+1 <= N
                A(i,i+1) = -D;
            end
            b(i) = F * phi_0 + D * phi_0;

        elseif i == N
            % Ultima celda: cara este tiene BC
            % Cara oeste (face w): entre celda N-1 y N
            % Conveccion: F * phi_{N-1} (upwind, u>0)
            % Difusion: D * (phi_{N-1} - phi_N)

            % Cara este (face e): phi_L conocido
            % Conveccion: F * phi_N (upwind)
            % Difusion: D * (phi_L - phi_N)

            if i-1 >= 1
                A(i,i-1) = -F - D;
            end
            A(i,i) = F + 2*D;
            b(i) = D * phi_L;

        else
            % Celdas internas
            % Cara oeste (face w): entre celda i-1 e i
            % Conveccion: F * phi_{i-1} (upwind, u>0)
            % Difusion: D * (phi_{i-1} - phi_i)

            % Cara este (face e): entre celda i e i+1
            % Conveccion: F * phi_i (upwind, u>0)
            % Difusion: D * (phi_{i+1} - phi_i)

            if i-1 >= 1
                A(i,i-1) = -F - D;
            end
            A(i,i) = F + 2*D;
            if i+1 <= N
                A(i,i+1) = -D;
            end
            b(i) = 0;
        end
    end

    % Resolver sistema lineal
    phi = A \ b;
end

function phi = solucion_analitica(x, L, Pe, phi_0, phi_L)
%SOLUCION_ANALITICA Solucion exacta de la ecuacion de conveccion-difusion 1D
%   phi(x) = A + B*exp(Pe*x/L)
%   Con phi(0) = phi_0 y phi(L) = phi_L
%
%   Resolviendo:
%   phi_0 = A + B
%   phi_L = A + B*exp(Pe)
%
%   B = (phi_L - phi_0) / (exp(Pe) - 1)
%   A = phi_0 - B

    if abs(Pe) < 1e-6
        % Caso limite: Pe -> 0 (difusion pura)
        phi = phi_0 + (phi_L - phi_0) * (x / L);
    else
        B = (phi_L - phi_0) / (exp(Pe) - 1);
        A = phi_0 - B;
        phi = A + B * exp(Pe * x / L);
    end
end
