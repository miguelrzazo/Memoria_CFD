%% EJERCICIO 1: METODO DE PANELES HESS-SMITH
% Dinamica de Fluidos Computacional
% Master en Ingenieria Aeronautica
% 
% Calculo del perfil de presiones, coeficiente de sustentacion y momento
% de cabeceo respecto al punto 1/4 de la cuerda usando el metodo de
% Hess-Smith con al menos 40 paneles sobre el perfil.
%

clc; clearvars; close all;

%% Configurar directorio de figuras
script_dir = fileparts(mfilename('fullpath'));
if isempty(script_dir)
    script_dir = pwd;
end
% Ruta a la carpeta de figuras del proyecto
fig_dir = fullfile(script_dir, '..', 'figures', 'Ejercicio1');
if ~exist(fig_dir, 'dir')
    mkdir(fig_dir);
end

% Configurar interprete LaTeX para todas las figuras
set(groot,'defaulttextinterpreter','latex');
set(groot,'defaultLegendInterpreter','latex');
set(groot,'defaultAxesTickLabelInterpreter','latex');

%% 1. DEFINICION DEL PERFIL
% Coordenadas del perfil proporcionadas en el enunciado (originales)

% Extrados (original)
x_ext_orig = [0.00000, 0.01250, 0.02500, 0.05000, 0.07500, 0.10000, ...
              0.15000, 0.20000, 0.30000, 0.40000, 0.50000, 0.60000, ...
              0.70000, 0.80000, 0.90000, 0.95000, 1.00000];

z_ext_orig = [0.00000, 0.02046, 0.03042, 0.04564, 0.05767, 0.06709, ...
              0.08224, 0.09218, 0.10187, 0.09936, 0.08975, 0.07434, ...
              0.05673, 0.03782, 0.01971, 0.01166, 0.00440];

% Intrados (original)
x_int_orig = [0.000000, 0.012500, 0.025000, 0.050000, 0.075000, 0.100000, ...
              0.150000, 0.200000, 0.300000, 0.400000, 0.500000, 0.600000, ...
              0.700000, 0.800000, 0.900000, 0.950000, 1.000000];

z_int_orig = [0.000000, -0.016440, -0.019580, -0.021850, -0.022230, -0.022010, ...
              -0.020760, -0.019520, -0.018330, -0.019140, -0.021650, -0.023560, ...
              -0.023670, -0.020480, -0.013090, -0.007440, 0.000000];

%% =========================================================================
% INTERPOLACION PARA OBTENER AL MENOS 40 PANELES
% Usamos distribucion coseno para mayor densidad en borde de ataque
%% =========================================================================
N_pts_lado = 41;  % 41 puntos por lado -> 80 paneles totales (>40)

% Distribucion coseno (de 0 a 1)
beta = linspace(0, pi, N_pts_lado);
x_coseno = 0.5 * (1 - cos(beta));  % Mayor densidad en LE y TE

% Interpolar extrados
x_extrados = x_coseno;
z_extrados = interp1(x_ext_orig, z_ext_orig, x_coseno, 'pchip');

% Interpolar intrados
x_intrados = x_coseno;
z_intrados = interp1(x_int_orig, z_int_orig, x_coseno, 'pchip');

% Organizar coordenadas del perfil (extrados de TE a LE, intrados de LE a TE)
x_perfil = [fliplr(x_extrados(2:end)), x_intrados];
z_perfil = [fliplr(z_extrados(2:end)), z_intrados];

N_paneles = length(x_perfil) - 1;  % Numero de paneles
N_extrados = length(x_extrados) - 1;  % Paneles en el extrados
N_intrados = length(x_intrados) - 1;  % Paneles en el intrados
fprintf('Numero de paneles: %d (Extrados: %d, Intrados: %d)\n', N_paneles, N_extrados, N_intrados);
fprintf('NOTA: Se cumple el requisito de al menos 40 paneles.\n\n');

%% 2. CALCULO DE GEOMETRIA DE LOS PANELES

% Puntos extremos de los paneles
x_i = x_perfil(1:end-1);
z_i = z_perfil(1:end-1);
x_ip1 = x_perfil(2:end);
z_ip1 = z_perfil(2:end);

% Puntos medios (puntos de control o nodos)
x_medio = 0.5 * (x_i + x_ip1);
z_medio = 0.5 * (z_i + z_ip1);

% Longitud de los paneles
longitud_panel = sqrt((x_ip1 - x_i).^2 + (z_ip1 - z_i).^2);

% Angulo de los paneles (theta) respecto al eje X
theta = atan2((z_ip1 - z_i), (x_ip1 - x_i));

%% 3. RANGO DE ANGULOS DE ATAQUE
alpha_deg = -10:1:25;  % Angulos de ataque de -10 a 25 grados
alpha_rad = deg2rad(alpha_deg);
n_alpha = length(alpha_deg);

% Velocidad de la corriente libre (asumida)
U_inf = 20;  % m/s

% Inicializar variables de resultados
CL_array = zeros(1, n_alpha);
CM_array = zeros(1, n_alpha);
CM_c4_array = zeros(1, n_alpha);
Cp_matrix = zeros(N_paneles, n_alpha);

%% 4. BUCLE PRINCIPAL PARA CADA ANGULO DE ATAQUE

for idx_alpha = 1:n_alpha
    alpha = alpha_rad(idx_alpha);
    
    %% 4.1. CONSTRUCCION DE LA MATRIZ DE INFLUENCIA
    % Sistema de ecuaciones: [A]{q, gamma} = {b}
    % donde q son las intensidades de los manantiales y gamma la circulacion
    
    A = zeros(N_paneles + 1, N_paneles + 1);
    b = zeros(N_paneles + 1, 1);
    
    % Componentes de la velocidad de la corriente libre
    U_x = U_inf * cos(alpha);
    U_z = U_inf * sin(alpha);
    
    % Recorrer puntos de control (ecuacion de condicion de contorno)
    for i = 1:N_paneles
        % Punto de control del panel i
        x_ctrl = x_medio(i);
        z_ctrl = z_medio(i);
        
        % Normal al panel i
        n_x = -sin(theta(i));
        n_z = cos(theta(i));
        
        % Recorrer paneles j (fuentes de influencia)
        for j = 1:N_paneles
            % Calcular coeficientes de influencia del panel j sobre el punto i
            [u_q, w_q] = influencia_manantial(x_ctrl, z_ctrl, ...
                         x_i(j), z_i(j), x_ip1(j), z_ip1(j));
            [u_gamma, w_gamma] = influencia_torbellino(x_ctrl, z_ctrl, ...
                         x_i(j), z_i(j), x_ip1(j), z_ip1(j));
            
            % Contribucion de manantiales a la ecuacion de contorno
            A(i, j) = u_q * n_x + w_q * n_z;
            
            % Contribucion de torbellinos a la ecuacion de contorno
            A(i, N_paneles + 1) = A(i, N_paneles + 1) + ...
                                   u_gamma * n_x + w_gamma * n_z;
        end
        
        % Lado derecho: condicion de no penetracion
        b(i) = -(U_x * n_x + U_z * n_z);
    end
    
    %% 4.2. CONDICION DE KUTTA
    % La condicion de Kutta se impone en el borde de salida
    % Velocidades tangenciales en el extrados e intrados deben ser iguales
    
    % Panel del borde de salida superior (primer panel)
    i_sup = 1;
    % Panel del borde de salida inferior (ultimo panel)
    i_inf = N_paneles;
    
    % Tangentes a los paneles
    t_x_sup = cos(theta(i_sup));
    t_z_sup = sin(theta(i_sup));
    t_x_inf = cos(theta(i_inf));
    t_z_inf = sin(theta(i_inf));
    
    % Construir ecuacion de Kutta
    for j = 1:N_paneles
        % Influencia en el panel superior
        [u_q_sup, w_q_sup] = influencia_manantial(x_medio(i_sup), z_medio(i_sup), ...
                             x_i(j), z_i(j), x_ip1(j), z_ip1(j));
        [u_gamma_sup, w_gamma_sup] = influencia_torbellino(x_medio(i_sup), z_medio(i_sup), ...
                             x_i(j), z_i(j), x_ip1(j), z_ip1(j));
        
        % Influencia en el panel inferior
        [u_q_inf, w_q_inf] = influencia_manantial(x_medio(i_inf), z_medio(i_inf), ...
                             x_i(j), z_i(j), x_ip1(j), z_ip1(j));
        [u_gamma_inf, w_gamma_inf] = influencia_torbellino(x_medio(i_inf), z_medio(i_inf), ...
                             x_i(j), z_i(j), x_ip1(j), z_ip1(j));
        
        % Suma de velocidades tangenciales
        A(N_paneles + 1, j) = (u_q_sup * t_x_sup + w_q_sup * t_z_sup) + ...
                              (u_q_inf * t_x_inf + w_q_inf * t_z_inf);
        
        A(N_paneles + 1, N_paneles + 1) = A(N_paneles + 1, N_paneles + 1) + ...
                                          (u_gamma_sup * t_x_sup + w_gamma_sup * t_z_sup) + ...
                                          (u_gamma_inf * t_x_inf + w_gamma_inf * t_z_inf);
    end
    
    % Lado derecho de la condicion de Kutta
    b(N_paneles + 1) = -(U_x * (t_x_sup + t_x_inf) + U_z * (t_z_sup + t_z_inf));
    
    %% 4.3. RESOLUCION DEL SISTEMA
    solucion = A \ b;
    q = solucion(1:N_paneles);       % Intensidades de manantiales
    gamma = solucion(N_paneles + 1); % Circulacion total
    
    %% 4.4. CALCULO DE VELOCIDADES Y COEFICIENTES DE PRESION
    V_tang = zeros(N_paneles, 1);
    
    for i = 1:N_paneles
        % Tangente al panel i
        t_x = cos(theta(i));
        t_z = sin(theta(i));
        
        % Velocidad inducida por todos los paneles
        u_ind = 0;
        w_ind = 0;
        
        for j = 1:N_paneles
            [u_q, w_q] = influencia_manantial(x_medio(i), z_medio(i), ...
                         x_i(j), z_i(j), x_ip1(j), z_ip1(j));
            [u_gamma, w_gamma] = influencia_torbellino(x_medio(i), z_medio(i), ...
                         x_i(j), z_i(j), x_ip1(j), z_ip1(j));
            
            u_ind = u_ind + u_q * q(j) + u_gamma * gamma;
            w_ind = w_ind + w_q * q(j) + w_gamma * gamma;
        end
        
        % Velocidad total
        u_total = U_x + u_ind;
        w_total = U_z + w_ind;
        
        % Componente tangencial de la velocidad
        V_tang(i) = u_total * t_x + w_total * t_z;
    end
    
    % Coeficiente de presion: Cp = 1 - (V/U_inf)^2
    Cp = 1 - (V_tang / U_inf).^2;
    Cp_matrix(:, idx_alpha) = Cp;
    
    %% 4.5. CALCULO DEL COEFICIENTE DE SUSTENTACION
    % Usando el teorema de Kutta-Joukowski: L = rho * U_inf * Gamma
    % CL = L / (0.5 * rho * U_inf^2 * c) = 2 * Gamma / (U_inf * c)
    c = 1.0;  % Cuerda unitaria (normalizada)
    CL = 2 * gamma / (U_inf * c);
    CL_array(idx_alpha) = CL;
    
    %% 4.6. CALCULO DEL COEFICIENTE DE MOMENTO
    % Momento respecto al origen (borde de ataque)
    M_O = 0;
    for i = 1:N_paneles
        % Fuerza normal al panel
        dL = -Cp(i) * longitud_panel(i);
        
        % Momento respecto al origen
        M_O = M_O + dL * x_medio(i);
    end
    
    CM = M_O / c;
    CM_array(idx_alpha) = CM;
    
    % Momento respecto al cuarto de cuerda (c/4 = 0.25)
    x_c4 = 0.25 * c;
    CM_c4 = CM - CL * x_c4;
    CM_c4_array(idx_alpha) = CM_c4;
end

%% 5. VISUALIZACION DE RESULTADOS

% Configuracion para fondo blanco (mejor para LaTeX)
set(0, 'DefaultFigureColor', 'w');

% 5.1. Perfil aerodinamico
fig1 = figure('Position', [100, 100, 800, 400]);
plot(x_perfil, z_perfil, 'b-', 'LineWidth', 2);
hold on;
plot(x_medio, z_medio, 'ro', 'MarkerSize', 4, 'MarkerFaceColor', 'r');
axis equal;
grid on;
xlabel('$x/c$', 'Interpreter', 'latex', 'FontSize', 12);
ylabel('$z/c$', 'Interpreter', 'latex', 'FontSize', 12);
title('Perfil Aerodinamico y Paneles', 'Interpreter', 'latex','FontSize', 14);
legend('Perfil', 'Puntos de control', 'Location', 'best');
exportgraphics(fig1, fullfile(fig_dir, 'perfil_paneles.png'), 'Resolution', 300);
fprintf('Guardada: %s\n', fullfile(fig_dir, 'perfil_paneles.png'));

% 5.2. CL vs alpha
fig2 = figure('Position', [100, 100, 800, 500]);
plot(alpha_deg, CL_array, 'b-o', 'LineWidth', 2, 'MarkerSize', 6);
grid on;
xlabel('$\alpha$ [deg]', 'Interpreter', 'latex', 'FontSize', 12);
ylabel('$C_L$', 'Interpreter', 'latex', 'FontSize', 12);
title('Coeficiente de Sustentacion vs Angulo de Ataque', 'Interpreter', 'latex', 'FontSize', 14);
exportgraphics(fig2, fullfile(fig_dir, 'CL_vs_alpha.png'), 'Resolution', 300);
fprintf('Guardada: %s\n', fullfile(fig_dir, 'CL_vs_alpha.png'));

% 5.3. CM respecto al origen vs alpha
fig3 = figure('Position', [100, 100, 800, 500]);
plot(alpha_deg, CM_array, 'r-o', 'LineWidth', 2, 'MarkerSize', 6);
grid on;
xlabel('$\alpha$ [deg]', 'Interpreter', 'latex', 'FontSize', 12);
ylabel('$C_{M,O}$', 'Interpreter', 'latex', 'FontSize', 12);
title('Coeficiente de Momento respecto al Origen', 'Interpreter', 'latex', 'FontSize', 14);
exportgraphics(fig3, fullfile(fig_dir, 'CM0_vs_alpha.png'), 'Resolution', 300);
fprintf('Guardada: %s\n', fullfile(fig_dir, 'CM0_vs_alpha.png'));

% 5.4. CM respecto al c/4 vs alpha
fig4 = figure('Position', [100, 100, 800, 500]);
plot(alpha_deg, CM_c4_array, 'g-o', 'LineWidth', 2, 'MarkerSize', 6);
grid on;
xlabel('$\alpha$ [deg]', 'Interpreter', 'latex', 'FontSize', 12);
ylabel('$C_{M,c/4}$', 'Interpreter', 'latex', 'FontSize', 12);
title('Coeficiente de Momento respecto al Cuarto de Cuerda', 'Interpreter', 'latex', 'FontSize', 14);
exportgraphics(fig4, fullfile(fig_dir, 'CMc4_vs_alpha.png'), 'Resolution', 300);
fprintf('Guardada: %s\n', fullfile(fig_dir, 'CMc4_vs_alpha.png'));

% 5.5. Distribucion de Cp para algunos angulos de ataque
alpha_plot = [0, 5, 10, 15];  % Angulos a graficar
colors = lines(length(alpha_plot));  % Colores distintos para cada alpha

fig5 = figure('Position', [100, 100, 900, 600]);
hold on;

% Indices para separar extrados e intrados
idx_extrados = 1:N_extrados;
idx_intrados = (N_extrados+1):N_paneles;

for i = 1:length(alpha_plot)
    idx = find(alpha_deg == alpha_plot(i), 1);
    if ~isempty(idx)
        % Extrados: linea solida con marcador circular
        plot(x_medio(idx_extrados), Cp_matrix(idx_extrados, idx), '-o', ...
             'LineWidth', 1.8, 'MarkerSize', 5, 'Color', colors(i,:), ...
             'MarkerFaceColor', colors(i,:), ...
             'DisplayName', sprintf('$\\alpha = %d^\\circ$ (Extrados)', alpha_plot(i)));
        
        % Intrados: linea discontinua con marcador cuadrado
        plot(x_medio(idx_intrados), Cp_matrix(idx_intrados, idx), '--s', ...
             'LineWidth', 1.8, 'MarkerSize', 5, 'Color', colors(i,:), ...
             'MarkerFaceColor', 'none', ...
             'DisplayName', sprintf('$\\alpha = %d^\\circ$ (Intrados)', alpha_plot(i)));
    end
end

grid on;
xlabel('$x/c$', 'Interpreter', 'latex', 'FontSize', 12);
ylabel('$C_p$', 'Interpreter', 'latex', 'FontSize', 12);
title('Distribucion de $C_p$ sobre el perfil', 'Interpreter', 'latex', 'FontSize', 14);
legend('Location', 'eastoutside', 'Interpreter', 'latex', 'FontSize', 9);
set(gca, 'YDir', 'reverse');  % Invertir eje Y (convencion aeronautica)

exportgraphics(fig5, fullfile(fig_dir, 'Cp_distribucion.png'), 'Resolution', 300);
fprintf('Guardada: %s\n', fullfile(fig_dir, 'Cp_distribucion.png'));

%% 6. EXPORTAR RESULTADOS
fprintf('\n========================================\n');
fprintf('RESULTADOS DEL METODO DE HESS-SMITH\n');
fprintf('========================================\n');
fprintf('Numero de paneles: %d\n', N_paneles);
fprintf('Velocidad de corriente libre: %.2f m/s\n', U_inf);
fprintf('Rango de angulos de ataque: %.1f deg a %.1f deg\n\n', alpha_deg(1), alpha_deg(end));

fprintf('Algunos valores representativos:\n');
fprintf('alpha [deg]\t\tC_L\t\tC_{M,O}\t\tC_{M,c/4}\n');
fprintf('------------------------------------------------\n');
for i = 1:5:length(alpha_deg)
    fprintf('%.1f\t\t%.4f\t\t%.4f\t\t%.4f\n', ...
            alpha_deg(i), CL_array(i), CM_array(i), CM_c4_array(i));
end

% Exportar a CSV
data_dir = fullfile(script_dir, '..', 'data');
if ~exist(data_dir, 'dir')
    mkdir(data_dir);
end

T = table(alpha_deg', CL_array', CM_array', CM_c4_array', ...
    'VariableNames', {'Alpha_deg', 'CL', 'CM_O', 'CM_c4'});
writetable(T, fullfile(data_dir, 'Resultados_HessSmith.csv'));
fprintf('\nResultados exportados a: %s\n', fullfile(data_dir, 'Resultados_HessSmith.csv'));

% Guardar datos en .mat para uso posterior
save(fullfile(fig_dir, 'resultados_ejercicio1.mat'), ...
    'alpha_deg', 'CL_array', 'CM_array', 'CM_c4_array', 'Cp_matrix', ...
    'x_medio', 'z_medio', 'x_perfil', 'z_perfil', 'N_paneles');
fprintf('Datos guardados en: %s\n', fullfile(fig_dir, 'resultados_ejercicio1.mat'));

fprintf('\n=== CALCULO COMPLETADO ===\n');

%% FUNCIONES AUXILIARES

function [u, w] = influencia_manantial(x, z, x1, z1, x2, z2)
    % Calcula la influencia de un manantial de intensidad unitaria
    % distribuido sobre un panel lineal desde (x1,z1) hasta (x2,z2)
    % sobre el punto (x,z)
    
    % Transformacion al sistema local del panel
    dx = x2 - x1;
    dz = z2 - z1;
    L = sqrt(dx^2 + dz^2);
    
    % Cosenos directores
    cos_theta = dx / L;
    sin_theta = dz / L;
    
    % Coordenadas en el sistema local del panel
    x_local = (x - x1) * cos_theta + (z - z1) * sin_theta;
    z_local = -(x - x1) * sin_theta + (z - z1) * cos_theta;
    
    % Evitar singularidades
    if abs(z_local) < 1e-10
        z_local = 1e-10;
    end
    
    % Coeficientes de influencia en el sistema local
    r1 = sqrt(x_local^2 + z_local^2);
    r2 = sqrt((x_local - L)^2 + z_local^2);
    
    theta1 = atan2(z_local, x_local);
    theta2 = atan2(z_local, x_local - L);
    
    u_local = (log(r2 / r1)) / (2 * pi);
    w_local = (theta2 - theta1) / (2 * pi);
    
    % Transformacion al sistema global
    u = u_local * cos_theta - w_local * sin_theta;
    w = u_local * sin_theta + w_local * cos_theta;
end

function [u, w] = influencia_torbellino(x, z, x1, z1, x2, z2)
    % Calcula la influencia de un torbellino de intensidad unitaria
    % distribuido sobre un panel lineal desde (x1,z1) hasta (x2,z2)
    % sobre el punto (x,z)
    
    % Transformacion al sistema local del panel
    dx = x2 - x1;
    dz = z2 - z1;
    L = sqrt(dx^2 + dz^2);
    
    % Cosenos directores
    cos_theta = dx / L;
    sin_theta = dz / L;
    
    % Coordenadas en el sistema local del panel
    x_local = (x - x1) * cos_theta + (z - z1) * sin_theta;
    z_local = -(x - x1) * sin_theta + (z - z1) * cos_theta;
    
    % Evitar singularidades
    if abs(z_local) < 1e-10
        z_local = 1e-10;
    end
    
    % Coeficientes de influencia en el sistema local
    r1 = sqrt(x_local^2 + z_local^2);
    r2 = sqrt((x_local - L)^2 + z_local^2);
    
    theta1 = atan2(z_local, x_local);
    theta2 = atan2(z_local, x_local - L);
    
    u_local = -(theta2 - theta1) / (2 * pi);
    w_local = (log(r2 / r1)) / (2 * pi);
    
    % Transformacion al sistema global
    u = u_local * cos_theta - w_local * sin_theta;
    w = u_local * sin_theta + w_local * cos_theta;
end
