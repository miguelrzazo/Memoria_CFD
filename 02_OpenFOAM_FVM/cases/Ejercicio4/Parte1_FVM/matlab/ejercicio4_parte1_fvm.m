%% EJERCICIO 4 - PARTE 1: Metodo de Volumenes Finitos
% Ecuacion de transporte: d(rho*u*phi)/dx = d/dx(Gamma * dphi/dx)
% Master Ingenieria Aeronautica - CFD 2025
% Universidad de Leon

clear; close all; clc;

%% Configuracion de salida
output_dir = '../figures/';
if ~exist(output_dir, 'dir'), mkdir(output_dir); end

fprintf('===========================================\n');
fprintf('  EJERCICIO 4 - PARTE 1: FVM en MATLAB\n');
fprintf('===========================================\n\n');

%% Parametros del problema (enunciado)
L = 1.0;          % Longitud del dominio [m]
rho = 1.0;        % Densidad [kg/m^3]
Gamma = 0.1;      % Coeficiente de difusion [kg/(m*s)]

% Condiciones de contorno
phi_A = 1.0;      % phi en x=0
phi_B = 0.0;      % phi en x=L

%% CASO 1: u = 0.1 m/s, N = 5 celdas
fprintf('--- CASO 1: u = 0.1 m/s, N = 5 celdas ---\n');
u = 0.1;
N = 5;

phi_1 = resolver_fvm(N, L, u, rho, Gamma, phi_A, phi_B);
x_1 = linspace(L/(2*N), L - L/(2*N), N)';

% Solucion analitica
x_anal = linspace(0, L, 1000)';
phi_anal_1 = solucion_analitica(x_anal, L, u, rho, Gamma, phi_A, phi_B);

% Valores esperados del enunciado
phi_esperado = [0.9421; 0.8006; 0.6276; 0.4163; 0.1579];

fprintf('Resultados numericos vs esperados:\n');
fprintf('  Celda   x [m]     phi_num    phi_esp    Error [%%]\n');
for i = 1:N
    error_pct = abs(phi_1(i) - phi_esperado(i))/phi_esperado(i) * 100;
    fprintf('    %d     %.2f      %.4f     %.4f     %.2f%%\n', ...
        i, x_1(i), phi_1(i), phi_esperado(i), error_pct);
end

Pe_1 = rho * u * L / Gamma;
fprintf('\nNumero de Peclet: Pe = %.2f\n', Pe_1);

%% CASO 2: u = 2.5 m/s, N = 5 celdas
fprintf('\n--- CASO 2: u = 2.5 m/s, N = 5 celdas ---\n');
u = 2.5;
N = 5;

phi_2 = resolver_fvm(N, L, u, rho, Gamma, phi_A, phi_B);
x_2 = linspace(L/(2*N), L - L/(2*N), N)';

phi_anal_2 = solucion_analitica(x_anal, L, u, rho, Gamma, phi_A, phi_B);

Pe_2 = rho * u * L / Gamma;
fprintf('Numero de Peclet: Pe = %.2f\n', Pe_2);
fprintf('Resultados: phi = [%.4f, %.4f, %.4f, %.4f, %.4f]\n', phi_2);

%% CASO 3: u = 2.5 m/s, N = 20 celdas
fprintf('\n--- CASO 3: u = 2.5 m/s, N = 20 celdas ---\n');
u = 2.5;
N = 20;

phi_3 = resolver_fvm(N, L, u, rho, Gamma, phi_A, phi_B);
x_3 = linspace(L/(2*N), L - L/(2*N), N)';

fprintf('Numero de Peclet: Pe = %.2f\n', Pe_2);
fprintf('Primeros 5 valores: phi = [%.4f, %.4f, %.4f, %.4f, %.4f, ...]\n', phi_3(1:5));

%% FIGURA 1: Caso 1 - Verificacion con valores del enunciado
figure('Position', [100, 100, 800, 500], 'Color', 'w');

u = 0.1;
phi_anal_plot = solucion_analitica(x_anal, L, u, rho, Gamma, phi_A, phi_B);

plot(x_anal, phi_anal_plot, 'k-', 'LineWidth', 2, 'DisplayName', 'Solucion analitica');
hold on;
plot(x_1, phi_1, 'bo-', 'LineWidth', 1.5, 'MarkerSize', 10, 'MarkerFaceColor', 'b', ...
    'DisplayName', 'FVM (N=5)');
plot(x_1, phi_esperado, 'rs', 'MarkerSize', 12, 'LineWidth', 2, ...
    'DisplayName', 'Valores esperados');

xlabel('$x$ [m]', 'Interpreter', 'latex', 'FontSize', 12);
ylabel('$\phi$', 'Interpreter', 'latex', 'FontSize', 12);
title(sprintf('Caso 1: $u = 0.1$ m/s, $N = 5$ celdas (Pe = %.2f)', Pe_1), ...
    'Interpreter', 'latex', 'FontSize', 14);
legend('Location', 'northeast', 'Interpreter', 'latex');
grid on;
xlim([0, L]);
ylim([0, 1.1]);

exportgraphics(gcf, [output_dir, 'fvm_caso1_verificacion.png'], 'Resolution', 300);
fprintf('\nGuardada: fvm_caso1_verificacion.png\n');

%% FIGURA 2: Comparacion de los 3 casos
figure('Position', [100, 100, 1200, 400], 'Color', 'w');

% Caso 1
subplot(1,3,1);
u = 0.1;
phi_anal_1 = solucion_analitica(x_anal, L, u, rho, Gamma, phi_A, phi_B);
plot(x_anal, phi_anal_1, 'k-', 'LineWidth', 2);
hold on;
plot(x_1, phi_1, 'bo-', 'LineWidth', 1.5, 'MarkerSize', 8, 'MarkerFaceColor', 'b');
xlabel('$x$ [m]', 'Interpreter', 'latex');
ylabel('$\phi$', 'Interpreter', 'latex');
title(sprintf('$u = 0.1$ m/s, $N = 5$ (Pe = %.1f)', Pe_1), 'Interpreter', 'latex');
legend({'Analitica', 'FVM'}, 'Location', 'northeast', 'Interpreter', 'latex');
grid on; xlim([0,1]); ylim([0, 1.1]);

% Caso 2
subplot(1,3,2);
u = 2.5;
phi_anal_2 = solucion_analitica(x_anal, L, u, rho, Gamma, phi_A, phi_B);
plot(x_anal, phi_anal_2, 'k-', 'LineWidth', 2);
hold on;
plot(x_2, phi_2, 'ro-', 'LineWidth', 1.5, 'MarkerSize', 8, 'MarkerFaceColor', 'r');
xlabel('$x$ [m]', 'Interpreter', 'latex');
ylabel('$\phi$', 'Interpreter', 'latex');
title(sprintf('$u = 2.5$ m/s, $N = 5$ (Pe = %.1f)', Pe_2), 'Interpreter', 'latex');
legend({'Analitica', 'FVM'}, 'Location', 'northeast', 'Interpreter', 'latex');
grid on; xlim([0,1]); ylim([0, 1.1]);

% Caso 3
subplot(1,3,3);
plot(x_anal, phi_anal_2, 'k-', 'LineWidth', 2);
hold on;
plot(x_3, phi_3, 'go-', 'LineWidth', 1.5, 'MarkerSize', 6, 'MarkerFaceColor', 'g');
xlabel('$x$ [m]', 'Interpreter', 'latex');
ylabel('$\phi$', 'Interpreter', 'latex');
title(sprintf('$u = 2.5$ m/s, $N = 20$ (Pe = %.1f)', Pe_2), 'Interpreter', 'latex');
legend({'Analitica', 'FVM'}, 'Location', 'northeast', 'Interpreter', 'latex');
grid on; xlim([0,1]); ylim([0, 1.1]);

sgtitle('Efecto de la velocidad y numero de celdas en la solucion FVM', ...
    'Interpreter', 'latex', 'FontSize', 14);

exportgraphics(gcf, [output_dir, 'fvm_comparacion_casos.png'], 'Resolution', 300);
fprintf('Guardada: fvm_comparacion_casos.png\n');

%% FIGURA 3: Efecto de incrementar Peclet
figure('Position', [100, 100, 900, 600], 'Color', 'w');

velocidades = [0.1, 0.5, 1.0, 2.5];
colores = {'b', 'g', 'm', 'r'};
N = 5;

for i = 1:length(velocidades)
    u = velocidades(i);
    phi_num = resolver_fvm(N, L, u, rho, Gamma, phi_A, phi_B);
    x_num = linspace(L/(2*N), L - L/(2*N), N)';
    phi_anal = solucion_analitica(x_anal, L, u, rho, Gamma, phi_A, phi_B);
    Pe = rho * u * L / Gamma;

    plot(x_anal, phi_anal, [colores{i}, '-'], 'LineWidth', 1.5, ...
        'DisplayName', sprintf('Anal. Pe=%.1f', Pe));
    hold on;
    plot(x_num, phi_num, [colores{i}, 'o'], 'MarkerSize', 8, 'MarkerFaceColor', colores{i}, ...
        'HandleVisibility', 'off');
end

xlabel('$x$ [m]', 'Interpreter', 'latex', 'FontSize', 12);
ylabel('$\phi$', 'Interpreter', 'latex', 'FontSize', 12);
title('Efecto del numero de Peclet en la solucion (N=5 celdas)', 'Interpreter', 'latex', 'FontSize', 14);
legend('Location', 'northeast', 'Interpreter', 'latex');
grid on;
xlim([0, L]);
ylim([0, 1.1]);

% Agregar anotacion
text(0.6, 0.9, 'Marcadores: FVM', 'FontSize', 10, 'Interpreter', 'latex');
text(0.6, 0.85, 'Lineas: Analitica', 'FontSize', 10, 'Interpreter', 'latex');

exportgraphics(gcf, [output_dir, 'fvm_efecto_peclet.png'], 'Resolution', 300);
fprintf('Guardada: fvm_efecto_peclet.png\n');

%% FIGURA 4: Convergencia con refinamiento de malla
figure('Position', [100, 100, 800, 500], 'Color', 'w');

u = 2.5;
Pe = rho * u * L / Gamma;
Ns = [5, 10, 20, 50, 100];
errores = zeros(size(Ns));

for i = 1:length(Ns)
    N = Ns(i);
    phi_num = resolver_fvm(N, L, u, rho, Gamma, phi_A, phi_B);
    x_num = linspace(L/(2*N), L - L/(2*N), N)';
    phi_anal_interp = solucion_analitica(x_num, L, u, rho, Gamma, phi_A, phi_B);
    errores(i) = sqrt(mean((phi_num - phi_anal_interp).^2));
end

loglog(Ns, errores, 'bo-', 'LineWidth', 2, 'MarkerSize', 10, 'MarkerFaceColor', 'b');
hold on;
% Linea de referencia orden 1
loglog(Ns, errores(1) * (Ns(1)./Ns), 'r--', 'LineWidth', 1.5, 'DisplayName', 'Orden 1');
% Linea de referencia orden 2
loglog(Ns, errores(1) * (Ns(1)./Ns).^2, 'g--', 'LineWidth', 1.5, 'DisplayName', 'Orden 2');

xlabel('Numero de celdas $N$', 'Interpreter', 'latex', 'FontSize', 12);
ylabel('Error RMS', 'Interpreter', 'latex', 'FontSize', 12);
title(sprintf('Convergencia de malla ($u = 2.5$ m/s, Pe = %.1f)', Pe), ...
    'Interpreter', 'latex', 'FontSize', 14);
legend({'FVM Upwind', 'Orden 1', 'Orden 2'}, 'Location', 'southwest', 'Interpreter', 'latex');
grid on;

exportgraphics(gcf, [output_dir, 'fvm_convergencia_malla.png'], 'Resolution', 300);
fprintf('Guardada: fvm_convergencia_malla.png\n');

%% Guardar resultados
save([output_dir, 'resultados_fvm_parte1.mat'], ...
    'phi_1', 'x_1', 'phi_2', 'x_2', 'phi_3', 'x_3', ...
    'phi_esperado', 'Pe_1', 'Pe_2', 'Ns', 'errores');

fprintf('\n===========================================\n');
fprintf('  EJERCICIO 4 PARTE 1 COMPLETADO\n');
fprintf('===========================================\n');

%% ========== FUNCIONES AUXILIARES ==========

function phi = resolver_fvm(N, L, u, rho, Gamma, phi_A, phi_B)
    % Resuelve la ecuacion de conveccion-difusion 1D usando FVM
    % Esquema: Upwind para conveccion, diferencias centrales para difusion

    dx = L / N;

    % Flujo convectivo y coeficiente difusivo en las caras
    F = rho * u;          % Flujo masico convectivo
    D = Gamma / dx;       % Coeficiente difusivo

    % Numero de Peclet de celda
    Pe_cell = F * dx / Gamma;

    % Inicializar matriz y vector
    A = zeros(N, N);
    b = zeros(N, 1);

    % Coeficientes para celdas interiores (esquema upwind)
    aW = D + max(F, 0);
    aE = D + max(-F, 0);

    for i = 1:N
        if i == 1
            % Celda adyacente a frontera izquierda (x=0)
            Sp = -(2*D + F);  % Coeficiente de phi_A en la ecuacion
            Su = (2*D + F) * phi_A;  % Termino fuente
            aP = aE - Sp;
            A(i, i) = aP;
            A(i, i+1) = -aE;
            b(i) = Su;
        elseif i == N
            % Celda adyacente a frontera derecha (x=L)
            Sp = -(2*D);  % Para condicion de salida
            Su = 2*D * phi_B;
            aP = aW - Sp;
            A(i, i) = aP;
            A(i, i-1) = -aW;
            b(i) = Su;
        else
            % Celdas interiores
            aP = aW + aE;
            A(i, i) = aP;
            A(i, i-1) = -aW;
            A(i, i+1) = -aE;
            b(i) = 0;
        end
    end

    % Resolver sistema lineal
    phi = A \ b;
end

function phi = solucion_analitica(x, L, u, rho, Gamma, phi_A, phi_B)
    % Solucion analitica de la ecuacion de conveccion-difusion 1D
    % d(rho*u*phi)/dx = d/dx(Gamma * dphi/dx)
    % con phi(0) = phi_A, phi(L) = phi_B

    Pe = rho * u * L / Gamma;

    if abs(Pe) < 1e-10
        % Caso puramente difusivo
        phi = phi_A + (phi_B - phi_A) * x / L;
    else
        % Caso general conveccion-difusion
        phi = phi_A + (phi_B - phi_A) * (exp(Pe * x / L) - 1) / (exp(Pe) - 1);
    end
end
