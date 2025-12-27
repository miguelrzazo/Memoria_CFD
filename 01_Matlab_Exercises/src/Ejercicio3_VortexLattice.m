%% ========================================================================
%  EJERCICIO 3: METODO VORTEX LATTICE - CONFIGURACION TANDEM
%  Master en Ingenieria Aeronautica - Universidad de Leon

% =========================================================================

clear; clc; close all;

%% ========================================================================
%  CONFIGURACION DE DIRECTORIOS Y SALIDA
% =========================================================================
script_dir = fileparts(mfilename('fullpath'));
fig_dir = fullfile(script_dir, '..', 'figures', 'Ejercicio3');
if ~exist(fig_dir, 'dir')
    mkdir(fig_dir);
end

%% ========================================================================
%  PARAMETROS GEOMETRICOS
% =========================================================================
% Velocidad de referencia
V_inf = 1.0;  % m/s (normalizada)
rho = 1.225;  % kg/m^3

% --- ALA PRINCIPAL ---
ala1.b = 14.0;              % Envergadura [m]
ala1.sweep = 20;            % Flecha [deg]
ala1.c_root = 1.7;          % Cuerda en la raiz [m]
ala1.c_tip = 0.9;           % Cuerda en la punta [m]
ala1.twist_root = 0;        % Torsion en la raiz [deg]
ala1.twist_tip = 4;         % Torsion en la punta [deg] (washin)
ala1.alpha_0 = -2;          % Angulo de sustentacion nula NACA2414 [deg]
ala1.x_le = 0;              % Posicion x del borde de ataque en la raiz
ala1.z = 0;                 % Posicion vertical
ala1.ny = 30;               % Paneles en envergadura (por semiala)
ala1.nx = 10;               % Paneles en cuerda

% --- ALA TRASERA ---
ala2.b = 9.0;               % Envergadura [m]
ala2.sweep = 13;            % Flecha [deg]
ala2.c_root = 1.3;          % Cuerda en la raiz [m]
ala2.c_tip = 0.65;          % Cuerda en la punta [m]
ala2.twist_root = 0;        % Torsion en la raiz [deg]
ala2.twist_tip = 0;         % Torsion en la punta [deg] (sin torsion)
ala2.alpha_0 = 0;           % Angulo de sustentacion nula NACA0016 [deg]
ala2.x_le = 9.0;            % Posicion x del borde de ataque (distancia P-P')
ala2.z = 0;                 % Posicion vertical
ala2.ny = 20;               % Paneles en envergadura (por semiala)
ala2.nx = 8;                % Paneles en cuerda

% Punto de referencia para momentos (punto P del ala principal)
x_ref = ala1.c_root / 4;    % Cuarto de cuerda en la raiz del ala principal

%% ========================================================================
%  ANGULOS DE ATAQUE A ANALIZAR
% =========================================================================
alphas = [-5, -2.5, -1, 0, 1, 2.5, 5, 10];  % [deg]
n_alpha = length(alphas);

% Colores para las graficas (distintos para cada angulo)
colors = [
    0.1216, 0.4667, 0.7059;   % Azul
    1.0000, 0.4980, 0.0549;   % Naranja
    0.1725, 0.6275, 0.1725;   % Verde
    0.8392, 0.1529, 0.1569;   % Rojo
    0.5804, 0.4039, 0.7412;   % Purpura
    0.5490, 0.3373, 0.2941;   % Marron
    0.8902, 0.4667, 0.7608;   % Rosa
    0.4980, 0.4980, 0.4980    % Gris
];

%% ========================================================================
%  GENERACION DE LA MALLA
% =========================================================================
fprintf('Generando mallas para ambas alas...\n');

% Generar paneles para ambas alas
[ctrl1, bv1, norm1, chord1, dy1, twist1, alpha0_1, corners1] = generar_malla(ala1);
[ctrl2, bv2, norm2, chord2, dy2, twist2, alpha0_2, corners2] = generar_malla(ala2);

n_panels1 = size(ctrl1, 1);
n_panels2 = size(ctrl2, 1);
n_total = n_panels1 + n_panels2;

fprintf('  Ala principal: %d paneles\n', n_panels1);
fprintf('  Ala trasera: %d paneles\n', n_panels2);
fprintf('  Total: %d paneles\n', n_total);

% Combinar datos de ambas alas
ctrl = [ctrl1; ctrl2];           % Puntos de control
bv = [bv1; bv2];                 % Posiciones del vortice ligado
norm_vec = [norm1; norm2];       % Vectores normales
chord = [chord1; chord2];        % Cuerdas locales
dy = [dy1; dy2];                 % Anchuras de panel
twist = [twist1; twist2];        % Torsion local
alpha0 = [alpha0_1; alpha0_2];   % Angulo de sustentacion nula
corners = [corners1; corners2];  % Esquinas de paneles

%% ========================================================================
%  CONSTRUCCION DE LA MATRIZ DE INFLUENCIA (AIC)
% =========================================================================
fprintf('Construyendo matriz de influencia AIC...\n');

AIC = zeros(n_total, n_total);

for i = 1:n_total
    xc = ctrl(i, :);
    nc = norm_vec(i, :);

    for j = 1:n_total
        % Velocidad inducida por el horseshoe vortex del panel j
        [u, v, w] = horseshoe_velocity(xc, bv(j,:), corners(j,:,:));

        % Proyeccion sobre la normal del panel i
        AIC(i,j) = u*nc(1) + v*nc(2) + w*nc(3);
    end
end

fprintf('  Matriz AIC construida (%dx%d)\n', n_total, n_total);

%% ========================================================================
%  RESOLUCION PARA CADA ANGULO DE ATAQUE
% =========================================================================
% Preallocacion de resultados
results.alpha = alphas;
results.CL_main = zeros(1, n_alpha);
results.CL_rear = zeros(1, n_alpha);
results.CL_total = zeros(1, n_alpha);
results.CDi_main = zeros(1, n_alpha);
results.CDi_rear = zeros(1, n_alpha);
results.CDi_total = zeros(1, n_alpha);
results.CM_main = zeros(1, n_alpha);
results.CM_rear = zeros(1, n_alpha);
results.CM_total = zeros(1, n_alpha);

% Almacenar distribuciones de Gamma
Gamma_all = zeros(n_total, n_alpha);

fprintf('\nResolviendo para cada angulo de ataque...\n');

for k = 1:n_alpha
    alpha = alphas(k);
    fprintf('  alpha = %+6.2f deg... ', alpha);

    % Vector de terminos independientes (condicion de contorno)
    % La condicion es: V_n = V_inf * sin(alpha_eff) donde
    % alpha_eff = alpha_geom + twist - alpha_0
    RHS = zeros(n_total, 1);
    for i = 1:n_total
        % Angulo efectivo local = alpha_geometrico + twist - alpha_0
        alpha_eff = alpha + twist(i) - alpha0(i);
        alpha_eff_rad = alpha_eff * pi/180;

        % RHS = -V_inf * sin(alpha_eff) para condicion de velocidad normal nula
        RHS(i) = -V_inf * sin(alpha_eff_rad);
    end

    % Resolver el sistema lineal
    Gamma = AIC \ RHS;
    Gamma_all(:,k) = Gamma;

    % Calcular fuerzas y momentos
    L_main = 0; L_rear = 0;
    Di_main = 0; Di_rear = 0;
    M_main = 0; M_rear = 0;

    for i = 1:n_total
        % Calcular downwash inducido en el punto de control
        w_ind = 0;
        for j = 1:n_total
            [~, ~, wj] = horseshoe_velocity(ctrl(i,:), bv(j,:), corners(j,:,:));
            w_ind = w_ind + wj * Gamma(j);
        end

        % Sustentacion local (teorema de Kutta-Joukowski)
        dL = rho * V_inf * Gamma(i) * dy(i);

        % Resistencia inducida local
        dDi = -rho * w_ind * Gamma(i) * dy(i);

        % Momento de cabeceo respecto al punto de referencia
        x_panel = bv(i, 1);
        brazo_M = x_panel - x_ref;
        dM = -dL * brazo_M;  % Momento positivo = picado (nose-up)

        % Acumular por ala
        if i <= n_panels1
            L_main = L_main + dL;
            Di_main = Di_main + dDi;
            M_main = M_main + dM;
        else
            L_rear = L_rear + dL;
            Di_rear = Di_rear + dDi;
            M_rear = M_rear + dM;
        end
    end

    % Superficie de referencia (ala principal)
    S_ref = ala1.b * (ala1.c_root + ala1.c_tip) / 2;
    c_ref = (ala1.c_root + ala1.c_tip) / 2;  % Cuerda media
    q_inf = 0.5 * rho * V_inf^2;

    % Coeficientes adimensionales
    results.CL_main(k) = L_main / (q_inf * S_ref);
    results.CL_rear(k) = L_rear / (q_inf * S_ref);
    results.CL_total(k) = (L_main + L_rear) / (q_inf * S_ref);

    results.CDi_main(k) = Di_main / (q_inf * S_ref);
    results.CDi_rear(k) = Di_rear / (q_inf * S_ref);
    results.CDi_total(k) = (Di_main + Di_rear) / (q_inf * S_ref);

    results.CM_main(k) = M_main / (q_inf * S_ref * c_ref);
    results.CM_rear(k) = M_rear / (q_inf * S_ref * c_ref);
    results.CM_total(k) = (M_main + M_rear) / (q_inf * S_ref * c_ref);

    fprintf('CL = %+.4f, CDi = %.4f, CM = %+.4f\n', ...
        results.CL_total(k), results.CDi_total(k), results.CM_total(k));
end

%% ========================================================================
%  EXTRAER POSICIONES Y PARA GRAFICAS
% =========================================================================
y_main = ctrl(1:n_panels1, 2);
y_rear = ctrl(n_panels1+1:end, 2);

% Calcular Cp local basado en la circulacion
Cp_main = zeros(n_panels1, n_alpha);
Cp_rear = zeros(n_panels2, n_alpha);

for k = 1:n_alpha
    for i = 1:n_panels1
        gamma_local = Gamma_all(i, k);
        c_local = chord(i);
        V_local = V_inf + gamma_local / c_local;
        Cp_main(i, k) = 1 - (V_local/V_inf)^2;
    end
    for i = 1:n_panels2
        gamma_local = Gamma_all(n_panels1 + i, k);
        c_local = chord(n_panels1 + i);
        V_local = V_inf + gamma_local / c_local;
        Cp_rear(i, k) = 1 - (V_local/V_inf)^2;
    end
end

%% ========================================================================
%  GENERACION DE GRAFICAS
% =========================================================================
fprintf('\nGenerando graficas...\n');

% Configuracion general de graficas
set(0, 'DefaultAxesFontSize', 12);
set(0, 'DefaultLineLineWidth', 1.5);
set(0, 'DefaultAxesTickLabelInterpreter', 'latex');
set(0, 'DefaultLegendInterpreter', 'latex');
set(0, 'DefaultTextInterpreter', 'latex');

% Crear leyenda
legend_str = cell(n_alpha, 1);
for k = 1:n_alpha
    legend_str{k} = sprintf('$\\alpha = %+.1f^\\circ$', alphas(k));
end

%% --- FIGURA 1: CL vs alpha ---
fig1 = figure('Position', [100, 100, 800, 600], 'Color', 'w');
hold on; grid on; box on;

plot(alphas, results.CL_main, '-o', 'Color', [0.2 0.4 0.8], ...
    'MarkerFaceColor', [0.2 0.4 0.8], 'MarkerSize', 8, 'LineWidth', 2);
plot(alphas, results.CL_rear, '-s', 'Color', [0.8 0.2 0.2], ...
    'MarkerFaceColor', [0.8 0.2 0.2], 'MarkerSize', 8, 'LineWidth', 2);
plot(alphas, results.CL_total, '-d', 'Color', [0.2 0.6 0.2], ...
    'MarkerFaceColor', [0.2 0.6 0.2], 'MarkerSize', 8, 'LineWidth', 2);

xlabel('$\alpha$ [$^\circ$]', 'FontSize', 14);
ylabel('$C_L$ [-]', 'FontSize', 14);
title('Coeficiente de Sustentaci\''on vs \''Angulo de Ataque', 'FontSize', 14);
legend({'Ala principal', 'Ala trasera', 'Conjunto'}, ...
    'Location', 'northwest', 'FontSize', 12);
xlim([min(alphas)-1, max(alphas)+1]);

saveas(fig1, fullfile(fig_dir, 'CL_vs_alpha.png'));
fprintf('  Guardado: CL_vs_alpha.png\n');

%% --- FIGURA 2: CDi vs alpha ---
fig2 = figure('Position', [100, 100, 800, 600], 'Color', 'w');
hold on; grid on; box on;

plot(alphas, results.CDi_main, '-o', 'Color', [0.2 0.4 0.8], ...
    'MarkerFaceColor', [0.2 0.4 0.8], 'MarkerSize', 8, 'LineWidth', 2);
plot(alphas, results.CDi_rear, '-s', 'Color', [0.8 0.2 0.2], ...
    'MarkerFaceColor', [0.8 0.2 0.2], 'MarkerSize', 8, 'LineWidth', 2);
plot(alphas, results.CDi_total, '-d', 'Color', [0.2 0.6 0.2], ...
    'MarkerFaceColor', [0.2 0.6 0.2], 'MarkerSize', 8, 'LineWidth', 2);

xlabel('$\alpha$ [$^\circ$]', 'FontSize', 14);
ylabel('$C_{Di}$ [-]', 'FontSize', 14);
title('Coeficiente de Resistencia Inducida vs \''Angulo de Ataque', 'FontSize', 14);
legend({'Ala principal', 'Ala trasera', 'Conjunto'}, ...
    'Location', 'northwest', 'FontSize', 12);
xlim([min(alphas)-1, max(alphas)+1]);

saveas(fig2, fullfile(fig_dir, 'CDi_vs_alpha.png'));
fprintf('  Guardado: CDi_vs_alpha.png\n');

%% --- FIGURA 3: CM vs alpha ---
fig3 = figure('Position', [100, 100, 800, 600], 'Color', 'w');
hold on; grid on; box on;

plot(alphas, results.CM_main, '-o', 'Color', [0.2 0.4 0.8], ...
    'MarkerFaceColor', [0.2 0.4 0.8], 'MarkerSize', 8, 'LineWidth', 2);
plot(alphas, results.CM_rear, '-s', 'Color', [0.8 0.2 0.2], ...
    'MarkerFaceColor', [0.8 0.2 0.2], 'MarkerSize', 8, 'LineWidth', 2);
plot(alphas, results.CM_total, '-d', 'Color', [0.2 0.6 0.2], ...
    'MarkerFaceColor', [0.2 0.6 0.2], 'MarkerSize', 8, 'LineWidth', 2);

xlabel('$\alpha$ [$^\circ$]', 'FontSize', 14);
ylabel('$C_M$ [-]', 'FontSize', 14);
title('Coeficiente de Momento de Cabeceo vs \''Angulo de Ataque', 'FontSize', 14);
legend({'Ala principal', 'Ala trasera', 'Conjunto'}, ...
    'Location', 'northeast', 'FontSize', 12);
xlim([min(alphas)-1, max(alphas)+1]);

saveas(fig3, fullfile(fig_dir, 'CM_vs_alpha.png'));
fprintf('  Guardado: CM_vs_alpha.png\n');

%% --- FIGURA 4: Polar de resistencia inducida (CL vs CDi) ---
fig4 = figure('Position', [100, 100, 800, 600], 'Color', 'w');
hold on; grid on; box on;

plot(results.CDi_main, results.CL_main, '-o', 'Color', [0.2 0.4 0.8], ...
    'MarkerFaceColor', [0.2 0.4 0.8], 'MarkerSize', 8, 'LineWidth', 2);
plot(results.CDi_rear, results.CL_rear, '-s', 'Color', [0.8 0.2 0.2], ...
    'MarkerFaceColor', [0.8 0.2 0.2], 'MarkerSize', 8, 'LineWidth', 2);
plot(results.CDi_total, results.CL_total, '-d', 'Color', [0.2 0.6 0.2], ...
    'MarkerFaceColor', [0.2 0.6 0.2], 'MarkerSize', 8, 'LineWidth', 2);

xlabel('$C_{Di}$ [-]', 'FontSize', 14);
ylabel('$C_L$ [-]', 'FontSize', 14);
title('Polar de Resistencia Inducida', 'FontSize', 14);
legend({'Ala principal', 'Ala trasera', 'Conjunto'}, ...
    'Location', 'southeast', 'FontSize', 12);

saveas(fig4, fullfile(fig_dir, 'polar_drag.png'));
fprintf('  Guardado: polar_drag.png\n');

%% --- FIGURA 5: Máximos de circulación (Gamma) para cada angulo ---
fig5 = figure('Position', [100, 100, 900, 600], 'Color', 'w');
hold on; grid on; box on;

% Calcular valores maximos de Gamma para cada angulo
Gamma_max_main = zeros(1, n_alpha);
Gamma_max_rear = zeros(1, n_alpha);

for k = 1:n_alpha
    Gamma_main = Gamma_all(1:n_panels1, k);
    Gamma_rear = Gamma_all(n_panels1+1:end, k);
    Gamma_max_main(k) = max(abs(Gamma_main));
    Gamma_max_rear(k) = max(abs(Gamma_rear));
end

% Plotear solo los maximos con markers
plot(alphas, Gamma_max_main, '-o', 'Color', [0.2 0.4 0.8], ...
    'MarkerFaceColor', [0.2 0.4 0.8], 'MarkerSize', 10, 'LineWidth', 2);
plot(alphas, Gamma_max_rear, '-s', 'Color', [0.8 0.2 0.2], ...
    'MarkerFaceColor', [0.8 0.2 0.2], 'MarkerSize', 10, 'LineWidth', 2);

xlabel('$\alpha$ [$^\circ$]', 'FontSize', 14);
ylabel('$|\Gamma|_{max}$ [m$^2$/s]', 'FontSize', 14);
title('Valores M\''aximos de Circulaci\''on', 'FontSize', 14);
legend('Ala principal', 'Ala trasera', 'Location', 'northwest', 'FontSize', 12);
xlim([min(alphas)-1, max(alphas)+1]);

saveas(fig5, fullfile(fig_dir, 'Gamma_distribucion.png'));
fprintf('  Guardado: Gamma_distribucion.png\n');

%% --- FIGURA 6: Maximos de Cp para cada angulo ---
fig6 = figure('Position', [100, 100, 900, 600], 'Color', 'w');
hold on; grid on; box on;

% Calcular valores minimos (maxima succion) de Cp para cada angulo
Cp_min_main = zeros(1, n_alpha);
Cp_min_rear = zeros(1, n_alpha);

for k = 1:n_alpha
    Cp_min_main(k) = min(Cp_main(:, k));
    Cp_min_rear(k) = min(Cp_rear(:, k));
end

% Plotear solo los minimos (maxima succion) con markers
plot(alphas, Cp_min_main, '-o', 'Color', [0.2 0.4 0.8], ...
    'MarkerFaceColor', [0.2 0.4 0.8], 'MarkerSize', 10, 'LineWidth', 2);
plot(alphas, Cp_min_rear, '-s', 'Color', [0.8 0.2 0.2], ...
    'MarkerFaceColor', [0.8 0.2 0.2], 'MarkerSize', 10, 'LineWidth', 2);

xlabel('$\alpha$ [$^\circ$]', 'FontSize', 14);
ylabel('$C_{p,min}$ [-]', 'FontSize', 14);
title('M\''axima Succi\''on ($C_p$ m\''inimo)', 'FontSize', 14);
legend('Ala principal', 'Ala trasera', 'Location', 'southwest', 'FontSize', 12);
xlim([min(alphas)-1, max(alphas)+1]);
set(gca, 'YDir', 'reverse');  % Convencion aeronautica: Cp negativo arriba

saveas(fig6, fullfile(fig_dir, 'Cp_distribucion.png'));
fprintf('  Guardado: Cp_distribucion.png\n');

%% --- FIGURA 7: Resumen de coeficientes aerodinamicos (subplots) ---
fig7 = figure('Position', [100, 100, 1200, 400], 'Color', 'w');

subplot(1,3,1);
hold on; grid on; box on;
plot(alphas, results.CL_main, '-o', 'Color', [0.2 0.4 0.8], ...
    'MarkerFaceColor', [0.2 0.4 0.8], 'MarkerSize', 6, 'LineWidth', 1.5);
plot(alphas, results.CL_rear, '-s', 'Color', [0.8 0.2 0.2], ...
    'MarkerFaceColor', [0.8 0.2 0.2], 'MarkerSize', 6, 'LineWidth', 1.5);
plot(alphas, results.CL_total, '-d', 'Color', [0.2 0.6 0.2], ...
    'MarkerFaceColor', [0.2 0.6 0.2], 'MarkerSize', 6, 'LineWidth', 1.5);
xlabel('$\alpha$ [$^\circ$]', 'FontSize', 12);
ylabel('$C_L$ [-]', 'FontSize', 12);
title('Sustentaci\''on', 'FontSize', 12);
legend({'Principal', 'Trasera', 'Total'}, 'Location', 'northwest', 'FontSize', 9);

subplot(1,3,2);
hold on; grid on; box on;
plot(alphas, results.CDi_main, '-o', 'Color', [0.2 0.4 0.8], ...
    'MarkerFaceColor', [0.2 0.4 0.8], 'MarkerSize', 6, 'LineWidth', 1.5);
plot(alphas, results.CDi_rear, '-s', 'Color', [0.8 0.2 0.2], ...
    'MarkerFaceColor', [0.8 0.2 0.2], 'MarkerSize', 6, 'LineWidth', 1.5);
plot(alphas, results.CDi_total, '-d', 'Color', [0.2 0.6 0.2], ...
    'MarkerFaceColor', [0.2 0.6 0.2], 'MarkerSize', 6, 'LineWidth', 1.5);
xlabel('$\alpha$ [$^\circ$]', 'FontSize', 12);
ylabel('$C_{Di}$ [-]', 'FontSize', 12);
title('Resistencia Inducida', 'FontSize', 12);
legend({'Principal', 'Trasera', 'Total'}, 'Location', 'northwest', 'FontSize', 9);

subplot(1,3,3);
hold on; grid on; box on;
plot(alphas, results.CM_main, '-o', 'Color', [0.2 0.4 0.8], ...
    'MarkerFaceColor', [0.2 0.4 0.8], 'MarkerSize', 6, 'LineWidth', 1.5);
plot(alphas, results.CM_rear, '-s', 'Color', [0.8 0.2 0.2], ...
    'MarkerFaceColor', [0.8 0.2 0.2], 'MarkerSize', 6, 'LineWidth', 1.5);
plot(alphas, results.CM_total, '-d', 'Color', [0.2 0.6 0.2], ...
    'MarkerFaceColor', [0.2 0.6 0.2], 'MarkerSize', 6, 'LineWidth', 1.5);
xlabel('$\alpha$ [$^\circ$]', 'FontSize', 12);
ylabel('$C_M$ [-]', 'FontSize', 12);
title('Momento de Cabeceo', 'FontSize', 12);
legend({'Principal', 'Trasera', 'Total'}, 'Location', 'northeast', 'FontSize', 9);

sgtitle('Resumen de Coeficientes Aerodin\''amicos - M\''etodo Vortex Lattice', ...
    'FontSize', 14, 'Interpreter', 'latex');

saveas(fig7, fullfile(fig_dir, 'resumen_VLM.png'));
fprintf('  Guardado: resumen_VLM.png\n');

%% --- FIGURA 8: Visualizacion 3D de la geometria ---
fig8 = figure('Position', [100, 100, 900, 700], 'Color', 'w');
hold on; grid on; box on;
view(45, 25);
axis equal;

% Dibujar paneles del ala principal
for i = 1:n_panels1
    crn = squeeze(corners(i, :, :));
    fill3(crn(:,1), crn(:,2), crn(:,3), [0.2 0.4 0.8], ...
        'FaceAlpha', 0.6, 'EdgeColor', 'k', 'LineWidth', 0.5);
end

% Dibujar paneles del ala trasera
for i = 1:n_panels2
    crn = squeeze(corners(n_panels1 + i, :, :));
    fill3(crn(:,1), crn(:,2), crn(:,3), [0.8 0.2 0.2], ...
        'FaceAlpha', 0.6, 'EdgeColor', 'k', 'LineWidth', 0.5);
end

xlabel('$x$ [m]', 'FontSize', 14);
ylabel('$y$ [m]', 'FontSize', 14);
zlabel('$z$ [m]', 'FontSize', 14);
title('Geometr\''ia de la Configuraci\''on T\''andem', 'FontSize', 14);

% Leyenda manual
h1 = fill3(nan, nan, nan, [0.2 0.4 0.8], 'FaceAlpha', 0.6);
h2 = fill3(nan, nan, nan, [0.8 0.2 0.2], 'FaceAlpha', 0.6);
legend([h1, h2], {'Ala Principal', 'Ala Trasera'}, 'Location', 'northeast', 'FontSize', 12);

saveas(fig8, fullfile(fig_dir, 'geometria_3D.png'));
fprintf('  Guardado: geometria_3D.png\n');

%% --- FIGURA 9: Distribucion de Cp vs posicion en envergadura (3x1 grid) ---
fig9 = figure('Position', [100, 100, 1200, 900], 'Color', 'w');

% Configurar colores para angulos de ataque
colors = [
    0.1216, 0.4667, 0.7059;   % Azul
    1.0000, 0.4980, 0.0549;   % Naranja
    0.1725, 0.6275, 0.1725;   % Verde
    0.8392, 0.1529, 0.1569;   % Rojo
    0.5804, 0.4039, 0.7412;   % Purpura
    0.5490, 0.3373, 0.2941;   % Marron
    0.8902, 0.4667, 0.7608;   % Rosa
    0.4980, 0.4980, 0.4980    % Gris
];

% Tipos de linea para diferentes alas
line_styles = {'-', '--', ':'};

% Subplot 1: Ala principal
subplot(3,1,1);
hold on; grid on; box on;

for k = 1:n_alpha
    % Usar puntos en lugar de lineas, con colores para diferenciar AoA
    plot(y_main, Cp_main(:,k), 'o', 'Color', colors(k,:), ...
        'MarkerFaceColor', colors(k,:), 'MarkerSize', 4, 'LineStyle', 'none', ...
        'DisplayName', sprintf('$\\alpha = %+.1f^\\circ$', alphas(k)));
end

xlabel('$y$ [m]', 'FontSize', 12);
ylabel('$C_p$ [-]', 'FontSize', 12);
title('Ala Principal - Distribuci\''on de $C_p$', 'FontSize', 14);
legend('Location', 'northeast', 'FontSize', 10, 'NumColumns', 2);
set(gca, 'YDir', 'reverse');  % Convencion aeronautica
xlim([min(y_main), max(y_main)]);

% Subplot 2: Ala trasera
subplot(3,1,2);
hold on; grid on; box on;

for k = 1:n_alpha
    % Usar puntos en lugar de lineas, con colores para diferenciar AoA
    plot(y_rear, Cp_rear(:,k), 's', 'Color', colors(k,:), ...
        'MarkerFaceColor', colors(k,:), 'MarkerSize', 4, 'LineStyle', 'none', ...
        'DisplayName', sprintf('$\\alpha = %+.1f^\\circ$', alphas(k)));
end

xlabel('$y$ [m]', 'FontSize', 12);
ylabel('$C_p$ [-]', 'FontSize', 12);
title('Ala Trasera - Distribuci\''on de $C_p$', 'FontSize', 14);
legend('Location', 'northeast', 'FontSize', 10, 'NumColumns', 2);
set(gca, 'YDir', 'reverse');  % Convencion aeronautica
xlim([min(y_rear), max(y_rear)]);

% Subplot 3: Conjunto (ambas alas)
subplot(3,1,3);
hold on; grid on; box on;

legend_entries = [];
h_plots = [];

for k = 1:n_alpha
    % Ala principal (puntos circulares)
    h1 = plot(y_main, Cp_main(:,k), 'o', 'Color', colors(k,:), ...
        'MarkerFaceColor', colors(k,:), 'MarkerSize', 4, 'LineStyle', 'none');
    
    % Ala trasera (puntos cuadrados)
    h2 = plot(y_rear, Cp_rear(:,k), 's', 'Color', colors(k,:), ...
        'MarkerFaceColor', colors(k,:), 'MarkerSize', 4, 'LineStyle', 'none');
    
    if k == 1
        legend_entries = [legend_entries, h1, h2];
    end
end

% Crear leyenda personalizada
legend(legend_entries, {'Ala Principal', 'Ala Trasera'}, ...
    'Location', 'northeast', 'FontSize', 10);

xlabel('$y$ [m]', 'FontSize', 12);
ylabel('$C_p$ [-]', 'FontSize', 12);
title('Conjunto - Distribuci\''on de $C_p$ (diferentes \''angulos)', 'FontSize', 14);
set(gca, 'YDir', 'reverse');  % Convencion aeronautica

% Ajustar limites del eje x para mostrar ambas alas
xlim([min([y_main; y_rear]), max([y_main; y_rear])]);

% Titulo general
sgtitle('Distribuci\''on de Coeficiente de Presi\''on $C_p$ - M\''etodo Vortex Lattice', ...
    'FontSize', 16, 'Interpreter', 'latex');

saveas(fig9, fullfile(fig_dir, 'Cp_distribucion_completa.png'));
fprintf('  Guardado: Cp_distribucion_completa.png\n');

%% --- FIGURA 10: Distribucion de carga sustentadora (puntos maximos) ---
% Seleccionar angulo de ataque para visualizacion
alpha_plot = 5;  % [deg]
idx_alpha = find(alphas == alpha_plot);

if isempty(idx_alpha)
    % Si no existe exactamente 5°, usar el mas cercano
    [~, idx_alpha] = min(abs(alphas - alpha_plot));
    alpha_plot = alphas(idx_alpha);
end

fig10 = figure('Position', [100, 100, 1000, 600], 'Color', 'w');

% Calcular carga sustentadora local dL/dy = rho * V_inf * Gamma
L_prime_main = rho * V_inf * Gamma_all(1:n_panels1, idx_alpha);
L_prime_rear = rho * V_inf * Gamma_all(n_panels1+1:end, idx_alpha);

% Subplot 1: Ala principal
subplot(1,2,1);
hold on; grid on; box on;

% Mostrar solo puntos (sin lineas) para evitar efecto sawtooth
plot(y_main, L_prime_main, 'o', 'Color', [0.2 0.4 0.8], ...
    'MarkerFaceColor', [0.2 0.4 0.8], 'MarkerSize', 6, 'LineStyle', 'none');

xlabel('$y$ [m]', 'FontSize', 12);
ylabel('$dL/dy$ [N/m]', 'FontSize', 12);
title(sprintf('Ala Principal - Distribuci\''on de Carga ($\\alpha = %.1f^\\circ$)', alpha_plot), 'FontSize', 14);
xlim([min(y_main), max(y_main)]);

% Subplot 2: Ala trasera
subplot(1,2,2);
hold on; grid on; box on;

% Mostrar solo puntos (sin lineas) para evitar efecto sawtooth
plot(y_rear, L_prime_rear, 's', 'Color', [0.8 0.2 0.2], ...
    'MarkerFaceColor', [0.8 0.2 0.2], 'MarkerSize', 6, 'LineStyle', 'none');

xlabel('$y$ [m]', 'FontSize', 12);
ylabel('$dL/dy$ [N/m]', 'FontSize', 12);
title(sprintf('Ala Trasera - Distribuci\''on de Carga ($\\alpha = %.1f^\\circ$)', alpha_plot), 'FontSize', 14);
xlim([min(y_rear), max(y_rear)]);

% Titulo general
sgtitle('Distribuci\''on de Carga Sustentadora - Puntos M\''aximos', ...
    'FontSize', 16, 'Interpreter', 'latex');

saveas(fig10, fullfile(fig_dir, 'carga_distribucion.png'));
fprintf('  Guardado: carga_distribucion.png\n');

%% --- FIGURA 11: Contornos de Cp en la superficie del ala (grid de angulos) ---
% Seleccionar angulos de ataque para visualizacion
alphas_plot = [-5, 0, 5, 10];  % [deg]
n_plot = length(alphas_plot);

fig11 = figure('Position', [100, 100, 1400, 1000], 'Color', 'w');

% Crear grid 2x4 para mostrar contornos de ambas alas en diferentes angulos
for i = 1:n_plot
    alpha_plot = alphas_plot(i);
    idx_alpha = find(alphas == alpha_plot);
    
    if isempty(idx_alpha)
        [~, idx_alpha] = min(abs(alphas - alpha_plot));
        alpha_plot = alphas(idx_alpha);
    end
    
    % Subplot para ala principal
    subplot(2, n_plot, i);
    hold on; grid on; box on;
    
    % Crear malla para contornos en el ala principal
    n_contour = 40;  % Reducido para mejor rendimiento
    y_contour_main = linspace(min(y_main), max(y_main), n_contour);
    x_contour_main = linspace(0, max(chord(1:n_panels1)), n_contour);
    
    [X_main, Y_main] = meshgrid(x_contour_main, y_contour_main);
    Cp_contour_main = zeros(size(X_main));
    
    % Interpolar Cp en la malla
    for ii = 1:n_contour
        for jj = 1:n_contour
            [~, idx_panel] = min(sqrt((y_main - Y_main(ii,jj)).^2 + (bv(1:n_panels1,1) + chord(1:n_panels1).*X_main(ii,jj) - bv(1:n_panels1,1)).^2));
            Cp_contour_main(ii,jj) = Cp_main(idx_panel, idx_alpha);
        end
    end
    
    % Graficar contornos
    contourf(X_main, Y_main, Cp_contour_main, 15, 'LineStyle', 'none');
    colormap('jet');
    colorbar;
    clim([-3, 1]);
    
    % Dibujar silueta del ala
    for ii = 1:length(y_main)
        x_start = 0;
        x_end = chord(ii);
        y_pos = y_main(ii);
        plot([x_start, x_end], [y_pos, y_pos], 'k-', 'LineWidth', 1);
    end
    
    xlabel('$x/c$ [-]', 'FontSize', 10);
    ylabel('$y$ [m]', 'FontSize', 10);
    title(sprintf('Ala Principal - $\\alpha = %.1f^\\circ$', alpha_plot), 'FontSize', 12);
    set(gca, 'YDir', 'reverse');
    
    % Subplot para ala trasera
    subplot(2, n_plot, i + n_plot);
    hold on; grid on; box on;
    
    % Crear malla para contornos en el ala trasera
    y_contour_rear = linspace(min(y_rear), max(y_rear), n_contour);
    x_contour_rear = linspace(0, max(chord(n_panels1+1:end)), n_contour);
    
    [X_rear, Y_rear] = meshgrid(x_contour_rear, y_contour_rear);
    Cp_contour_rear = zeros(size(X_rear));
    
    % Interpolar Cp en la malla
    for ii = 1:n_contour
        for jj = 1:n_contour
            [~, idx_panel] = min(sqrt((y_rear - Y_rear(ii,jj)).^2 + (bv(n_panels1+1:end,1) + chord(n_panels1+1:end).*X_rear(ii,jj) - bv(n_panels1+1:end,1)).^2));
            Cp_contour_rear(ii,jj) = Cp_rear(idx_panel, idx_alpha);
        end
    end
    
    % Graficar contornos
    contourf(X_rear, Y_rear, Cp_contour_rear, 15, 'LineStyle', 'none');
    colormap('jet');
    colorbar;
    clim([-3, 1]);
    
    % Dibujar silueta del ala
    for ii = 1:length(y_rear)
        x_start = 0;
        x_end = chord(n_panels1 + ii);
        y_pos = y_rear(ii);
        plot([x_start, x_end], [y_pos, y_pos], 'k-', 'LineWidth', 1);
    end
    
    xlabel('$x/c$ [-]', 'FontSize', 10);
    ylabel('$y$ [m]', 'FontSize', 10);
    title(sprintf('Ala Trasera - $\\alpha = %.1f^\\circ$', alpha_plot), 'FontSize', 12);
    set(gca, 'YDir', 'reverse');
end

% Titulo general
sgtitle('Contornos de $C_p$ en Superficie - ', ...
    'FontSize', 16, 'Interpreter', 'latex');

saveas(fig11, fullfile(fig_dir, 'Cp_contornos.png'));
fprintf('  Guardado: Cp_contornos.png\n');


%% ========================================================================
%  GUARDAR RESULTADOS
% =========================================================================
save(fullfile(fig_dir, 'resultados_ejercicio3.mat'), 'results', ...
    'Gamma_all', 'alphas', 'ala1', 'ala2', 'ctrl', 'bv', 'chord', 'dy');
fprintf('\nResultados guardados en: resultados_ejercicio3.mat\n');

%% ========================================================================
%  TABLA DE RESULTADOS
% =========================================================================
fprintf('\n');
fprintf('=================================================================\n');
fprintf('        TABLA DE RESULTADOS - METODO VORTEX LATTICE\n');
fprintf('=================================================================\n');
fprintf('  alpha    CL_main   CL_rear   CL_total   CDi_total   CM_total\n');
fprintf('-----------------------------------------------------------------\n');
for k = 1:n_alpha
    fprintf('  %+5.1f    %+7.4f   %+7.4f   %+7.4f    %7.5f    %+7.4f\n', ...
        alphas(k), results.CL_main(k), results.CL_rear(k), ...
        results.CL_total(k), results.CDi_total(k), results.CM_total(k));
end
fprintf('=================================================================\n');

fprintf('\nEjercicio 3 completado.\n');

%% ========================================================================
%  FUNCIONES AUXILIARES
% ========================================================================

function [ctrl, bv, norm_vec, chord, dy, twist, alpha0, corners] = generar_malla(ala)
%GENERAR_MALLA Genera la malla de paneles para un ala
%   Usa distribucion coseno en la envergadura para mejor resolucion
%   en las puntas. Genera paneles para ambas semialas.

    ny = ala.ny;  % Paneles por semiala
    nx = ala.nx;  % Paneles en cuerda

    % Distribucion coseno en y (para una semiala)
    theta_y = linspace(0, pi/2, ny+1);
    y_semi = (ala.b/2) * sin(theta_y);

    % Crear posiciones y para ambas semialas
    y_full = [-fliplr(y_semi(2:end)), y_semi];
    ny_full = length(y_full) - 1;  % Numero total de divisiones en y

    % Total de paneles
    n_panels = ny_full * nx;

    % Preallocacion
    ctrl = zeros(n_panels, 3);
    bv = zeros(n_panels, 3);
    norm_vec = zeros(n_panels, 3);
    chord = zeros(n_panels, 1);
    dy = zeros(n_panels, 1);
    twist = zeros(n_panels, 1);
    alpha0 = zeros(n_panels, 1);
    corners = zeros(n_panels, 4, 3);

    sweep_rad = ala.sweep * pi/180;

    idx = 1;
    for j = 1:ny_full
        y1 = y_full(j);
        y2 = y_full(j+1);
        y_mid = (y1 + y2) / 2;

        % Interpolacion de propiedades
        eta = abs(y_mid) / (ala.b/2);  % Posicion adimensional
        c_local = ala.c_root + (ala.c_tip - ala.c_root) * eta;
        twist_local = ala.twist_root + (ala.twist_tip - ala.twist_root) * eta;
        x_le_local = ala.x_le + abs(y_mid) * tan(sweep_rad);

        % Cuerdas y posiciones x del borde de ataque en y1 e y2
        eta1 = abs(y1) / (ala.b/2);
        eta2 = abs(y2) / (ala.b/2);
        c1 = ala.c_root + (ala.c_tip - ala.c_root) * eta1;
        c2 = ala.c_root + (ala.c_tip - ala.c_root) * eta2;
        x_le_1 = ala.x_le + abs(y1) * tan(sweep_rad);
        x_le_2 = ala.x_le + abs(y2) * tan(sweep_rad);

        % Distribucion uniforme en cuerda
        x_panel = linspace(0, 1, nx+1);

        for i = 1:nx
            x1_frac = x_panel(i);
            x2_frac = x_panel(i+1);

            % Vertices del panel (4 esquinas)
            crn = zeros(4, 3);
            crn(1,:) = [x_le_1 + x1_frac*c1, y1, ala.z];  % LE, y1
            crn(2,:) = [x_le_1 + x2_frac*c1, y1, ala.z];  % TE, y1
            crn(3,:) = [x_le_2 + x2_frac*c2, y2, ala.z];  % TE, y2
            crn(4,:) = [x_le_2 + x1_frac*c2, y2, ala.z];  % LE, y2

            corners(idx, :, :) = crn;

            % Punto de control (3/4 de cuerda, centro del panel)
            x_ctrl = x_le_local + (x1_frac + 0.75*(x2_frac - x1_frac)) * c_local;
            ctrl(idx, :) = [x_ctrl, y_mid, ala.z];

            % Posicion del vortice ligado (1/4 de cuerda)
            x_bound = x_le_local + (x1_frac + 0.25*(x2_frac - x1_frac)) * c_local;
            bv(idx, :) = [x_bound, y_mid, ala.z];

            % Normal al panel
            v1 = crn(2,:) - crn(1,:);
            v2 = crn(4,:) - crn(1,:);
            n = cross(v1, v2);
            norm_vec(idx, :) = n / norm(n);

            % Cuerda del panel
            chord(idx) = c_local * (x2_frac - x1_frac);

            % Anchura del panel
            dy(idx) = abs(y2 - y1);

            % Torsion y alpha_0
            twist(idx) = twist_local;
            alpha0(idx) = ala.alpha_0;

            idx = idx + 1;
        end
    end
end

function [u, v, w] = horseshoe_velocity(P, bv_pos, crn)
%HORSESHOE_VELOCITY Calcula la velocidad inducida por un vortice en herradura
%   P: punto donde se calcula la velocidad [x, y, z]
%   bv_pos: posicion del vortice ligado [x, y, z]
%   crn: esquinas del panel [4x3]
%
%   El vortice en herradura consiste en:
%   - Vortice ligado (bound vortex) en el 1/4 de cuerda
%   - Dos vortices de estela hacia infinito aguas abajo

    crn = squeeze(crn);

    % Posiciones y del vortice ligado
    y1 = crn(1, 2);  % y del lado 1
    y2 = crn(4, 2);  % y del lado 2
    x_bound = bv_pos(1);
    z_bound = bv_pos(3);

    % Puntos A y B del vortice ligado
    A = [x_bound, y1, z_bound];
    B = [x_bound, y2, z_bound];

    % Velocidad inducida total (circulacion unitaria)
    u = 0; v = 0; w = 0;

    % 1. Vortice ligado (de A a B)
    [du, dv, dw] = vortex_segment(A, B, P);
    u = u + du; v = v + dv; w = w + dw;

    % 2. Vortice de estela desde infinito hasta A
    A_inf = [A(1) + 1000, A(2), A(3)];
    [du, dv, dw] = vortex_segment(A_inf, A, P);
    u = u + du; v = v + dv; w = w + dw;

    % 3. Vortice de estela desde B hasta infinito
    B_inf = [B(1) + 1000, B(2), B(3)];
    [du, dv, dw] = vortex_segment(B, B_inf, P);
    u = u + du; v = v + dv; w = w + dw;
end

function [u, v, w] = vortex_segment(A, B, P)
%VORTEX_SEGMENT Velocidad inducida por un segmento de vortice recto
%   Ley de Biot-Savart para un filamento de vortice finito
%   A, B: extremos del segmento
%   P: punto donde se calcula la velocidad
%   Circulacion unitaria (Gamma = 1)

    % Vectores
    r0 = B - A;           % Direccion del segmento
    r1 = P - A;           % Vector de A al punto P
    r2 = P - B;           % Vector de B al punto P

    % Distancias
    r1_mag = norm(r1);
    r2_mag = norm(r2);

    % Core radius para evitar singularidades
    core = 1e-8;

    % Producto cruz r1 x r2
    r1_cross_r2 = cross(r1, r2);
    r1_cross_r2_mag = norm(r1_cross_r2);

    % Verificar si el punto esta muy cerca del segmento
    if r1_cross_r2_mag < core || r1_mag < core || r2_mag < core
        u = 0; v = 0; w = 0;
        return;
    end

    % Ley de Biot-Savart (Gamma = 1)
    K = (1 / (4 * pi)) * r1_cross_r2 / (r1_cross_r2_mag^2);
    factor = dot(r0, r1/r1_mag - r2/r2_mag);

    vel = K * factor;

    u = vel(1);
    v = vel(2);
    w = vel(3);
end
