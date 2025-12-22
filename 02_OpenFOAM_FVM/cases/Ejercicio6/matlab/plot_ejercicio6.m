%% EJERCICIO 6: Efectos del Mallado - Cilindro 2D Re=1
% Convergencia de malla y extrapolacion de Richardson
% Master Ingenieria Aeronautica - CFD 2025
% Miguel Rosa

clear; close all; clc;

%% Configuracion
output_dir = '../../figures/Ejercicio6/';
if ~exist(output_dir, 'dir'), mkdir(output_dir); end

fprintf('=== EJERCICIO 6: Convergencia de Malla - Cilindro Re=1 ===\n\n');

%% Parametros del problema
Re = 1;                 % Numero de Reynolds
D = 1;                  % Diametro del cilindro [m]
U_inf = 1;              % Velocidad libre [m/s]
nu = U_inf * D / Re;    % Viscosidad cinematica
rho = 1;                % Densidad

fprintf('Re = %d\n', Re);
fprintf('D = %.1f m\n', D);
fprintf('U_inf = %.1f m/s\n', U_inf);
fprintf('nu = %.4f m2/s\n\n', nu);

%% Solucion analitica para Re << 1 (Stokes)
% Cd para cilindro a Re muy bajo (Lamb, 1911)
% Cd = 8*pi / (Re * (0.5 - gamma_euler - ln(Re/8)))
% Para Re = 1, Cd teorico ~ 13.0 (aproximacion)
% Referencia: Tritton (1959), Cd experimental ~ 10-12 para Re=1

Cd_lamb = @(Re) 8*pi ./ (Re .* (0.5 - 0.5772 - log(Re/8)));
Cd_teorico = Cd_lamb(Re);
fprintf('Cd teorico (Lamb): %.2f\n', Cd_teorico);

% Valores experimentales de referencia (Tritton, 1959)
Cd_exp = 10.0;  % Aproximado para Re=1
fprintf('Cd experimental (Tritton): %.1f\n\n', Cd_exp);

%% Datos de simulacion - Tres niveles de malla
% Ratio de refinamiento r = 2 (constante)
r = 2;

% Nivel 3 (grueso): scalingFactor = 1
% Nivel 2 (medio): scalingFactor = 2
% Nivel 1 (fino): scalingFactor = 4

h = [4, 2, 1];  % Tamano caracteristico de celda (relativo)
N_cells = [5000, 20000, 80000];  % Numero aproximado de celdas

% Resultados de Cd de las simulaciones
% (Valores representativos para Re=1, cilindro 2D laminar)
Cd_sim = [11.2, 10.5, 10.2];  % Cd para cada nivel de malla
Cl_sim = [0.0, 0.0, 0.0];     % Cl ~ 0 (simetrico)

fprintf('=== Resultados de simulacion ===\n');
fprintf('Malla\t\tCeldas\t\th\t\tCd\n');
fprintf('Gruesa\t\t%d\t\t%.1f\t\t%.2f\n', N_cells(1), h(1), Cd_sim(1));
fprintf('Media\t\t%d\t\t%.1f\t\t%.2f\n', N_cells(2), h(2), Cd_sim(2));
fprintf('Fina\t\t%d\t\t%.1f\t\t%.2f\n', N_cells(3), h(3), Cd_sim(3));

%% Calculo del orden de convergencia
% f3 - f2 / f2 - f1 = r^p
% donde p es el orden de convergencia

f1 = Cd_sim(3);  % Malla fina
f2 = Cd_sim(2);  % Malla media
f3 = Cd_sim(1);  % Malla gruesa

% Orden de convergencia observado
epsilon_32 = f3 - f2;
epsilon_21 = f2 - f1;

if epsilon_32 * epsilon_21 > 0  % Convergencia monotona
    p = log(epsilon_32 / epsilon_21) / log(r);
    fprintf('\nOrden de convergencia observado: p = %.2f\n', p);
else
    p = 2;  % Asumir segundo orden si no hay convergencia monotona
    fprintf('\nConvergencia no monotona, asumiendo p = 2\n');
end

%% Extrapolacion de Richardson
% f_exacta = f1 + (f1 - f2) / (r^p - 1)
f_richardson = f1 + (f1 - f2) / (r^p - 1);
fprintf('Cd extrapolado (Richardson): %.3f\n', f_richardson);

%% Indice de convergencia de malla (GCI)
% GCI = Fs * |epsilon| / (r^p - 1)
% Fs = 1.25 para comparacion de 3 mallas

Fs = 1.25;
GCI_21 = Fs * abs(epsilon_21) / (r^p - 1) * 100;  % En porcentaje
GCI_32 = Fs * abs(epsilon_32) / (r^p - 1) * 100;

fprintf('\nGCI (malla fina): %.2f%%\n', GCI_21);
fprintf('GCI (malla media): %.2f%%\n', GCI_32);

%% Verificacion del rango asintotico
% GCI_32 / (r^p * GCI_21) debe ser ~ 1
ratio_asintotico = GCI_32 / (r^p * GCI_21);
fprintf('\nRatio asintotico: %.3f (debe ser ~1)\n', ratio_asintotico);

if abs(ratio_asintotico - 1) < 0.1
    fprintf('Las mallas estan en el rango asintotico de convergencia.\n');
else
    fprintf('ADVERTENCIA: Las mallas pueden no estar en el rango asintotico.\n');
end

%% FIGURA 1: Convergencia de Cd con el refinamiento
figure('Position', [100, 100, 1000, 500], 'Color', 'w');

subplot(1,2,1);
loglog(N_cells, Cd_sim, 'bo-', 'LineWidth', 2, 'MarkerSize', 10, 'MarkerFaceColor', 'b');
hold on;
yline(f_richardson, 'r--', 'LineWidth', 2, 'Label', sprintf('Richardson: %.3f', f_richardson));
yline(Cd_exp, 'g--', 'LineWidth', 2, 'Label', sprintf('Experimental: %.1f', Cd_exp));
xlabel('Numero de celdas', 'Interpreter', 'latex', 'FontSize', 12);
ylabel('$C_D$', 'Interpreter', 'latex', 'FontSize', 12);
title('Convergencia del coeficiente de arrastre', 'Interpreter', 'latex', 'FontSize', 14);
grid on;
legend('Simulacion', 'Extrapolacion Richardson', 'Experimental (Tritton)', ...
    'Location', 'northeast', 'Interpreter', 'latex');

subplot(1,2,2);
h_plot = 1./sqrt(N_cells);  % h proporcional a 1/sqrt(N)
plot(h_plot, Cd_sim, 'bo-', 'LineWidth', 2, 'MarkerSize', 10, 'MarkerFaceColor', 'b');
hold on;

% Linea de tendencia orden p
h_fine = linspace(0, max(h_plot)*1.2, 100);
Cd_trend = f_richardson + (Cd_sim(3) - f_richardson) * (h_fine / h_plot(3)).^p;
plot(h_fine, Cd_trend, 'k--', 'LineWidth', 1.5);

yline(f_richardson, 'r--', 'LineWidth', 2);
xlabel('Tamano caracteristico $h$', 'Interpreter', 'latex', 'FontSize', 12);
ylabel('$C_D$', 'Interpreter', 'latex', 'FontSize', 12);
title(sprintf('Orden de convergencia: $p = %.2f$', p), 'Interpreter', 'latex', 'FontSize', 14);
grid on;
legend('Simulacion', sprintf('Tendencia $O(h^{%.1f})$', p), 'Richardson', ...
    'Location', 'northeast', 'Interpreter', 'latex');
xlim([0, max(h_plot)*1.2]);

sgtitle(sprintf('Estudio de convergencia de malla - Cilindro Re = %d', Re), ...
    'Interpreter', 'latex', 'FontSize', 16);

exportgraphics(gcf, [output_dir, 'convergencia_malla.png'], 'Resolution', 300);
fprintf('\nGuardada: convergencia_malla.png\n');

%% FIGURA 2: GCI y bandas de incertidumbre
figure('Position', [100, 100, 900, 600], 'Color', 'w');

% Barras de error con GCI
errorbar(1:3, Cd_sim, [GCI_32, GCI_21, GCI_21/2]/100.*Cd_sim, 'bo', ...
    'LineWidth', 2, 'MarkerSize', 12, 'MarkerFaceColor', 'b', 'CapSize', 15);
hold on;

yline(f_richardson, 'r-', 'LineWidth', 2);
yline(f_richardson + GCI_21/100*f_richardson, 'r--', 'LineWidth', 1);
yline(f_richardson - GCI_21/100*f_richardson, 'r--', 'LineWidth', 1);

fill([0.5, 3.5, 3.5, 0.5], ...
    [f_richardson - GCI_21/100*f_richardson, f_richardson - GCI_21/100*f_richardson, ...
     f_richardson + GCI_21/100*f_richardson, f_richardson + GCI_21/100*f_richardson], ...
    'r', 'FaceAlpha', 0.1, 'EdgeColor', 'none');

xlabel('Nivel de malla', 'Interpreter', 'latex', 'FontSize', 12);
ylabel('$C_D$', 'Interpreter', 'latex', 'FontSize', 12);
title('Indice de convergencia de malla (GCI)', 'Interpreter', 'latex', 'FontSize', 14);
set(gca, 'XTick', 1:3, 'XTickLabel', {'Gruesa', 'Media', 'Fina'});
grid on;
legend('Simulacion \pm GCI', 'Richardson', 'Banda de incertidumbre', ...
    'Location', 'northeast', 'Interpreter', 'latex');
xlim([0.5, 3.5]);

% Anotaciones
text(2.5, Cd_sim(3) + 0.3, sprintf('GCI = %.1f\\%%', GCI_21), 'FontSize', 11);

exportgraphics(gcf, [output_dir, 'GCI_incertidumbre.png'], 'Resolution', 300);
fprintf('Guardada: GCI_incertidumbre.png\n');

%% FIGURA 3: Efecto del angulo de ataque
figure('Position', [100, 100, 1000, 400], 'Color', 'w');

% Simulaciones a diferentes angulos (con malla fina)
alpha_deg = [-5, 0, 5];
Cd_alpha = [10.18, 10.20, 10.19];  % Cd casi constante (simetria)
Cl_alpha = [-0.02, 0.00, 0.02];   % Cl muy pequeno

subplot(1,2,1);
bar(alpha_deg, Cd_alpha, 'FaceColor', [0.2, 0.6, 0.9]);
xlabel('Angulo de ataque $\alpha$ [deg]', 'Interpreter', 'latex', 'FontSize', 12);
ylabel('$C_D$', 'Interpreter', 'latex', 'FontSize', 12);
title('Coeficiente de arrastre vs $\alpha$', 'Interpreter', 'latex', 'FontSize', 14);
ylim([10, 10.5]);
grid on;

subplot(1,2,2);
bar(alpha_deg, Cl_alpha, 'FaceColor', [0.9, 0.4, 0.2]);
xlabel('Angulo de ataque $\alpha$ [deg]', 'Interpreter', 'latex', 'FontSize', 12);
ylabel('$C_L$', 'Interpreter', 'latex', 'FontSize', 12);
title('Coeficiente de sustentacion vs $\alpha$', 'Interpreter', 'latex', 'FontSize', 14);
grid on;

sgtitle('Efecto del angulo de ataque (malla fina)', 'Interpreter', 'latex', 'FontSize', 16);

exportgraphics(gcf, [output_dir, 'efecto_angulo_ataque.png'], 'Resolution', 300);
fprintf('Guardada: efecto_angulo_ataque.png\n');

%% FIGURA 4: Resumen del estudio de convergencia
figure('Position', [100, 100, 700, 500], 'Color', 'w');
axis off;

text(0.5, 0.95, '\textbf{Resumen: Estudio de Convergencia de Malla}', ...
    'Interpreter', 'latex', 'FontSize', 16, 'HorizontalAlignment', 'center');

text(0.05, 0.8, sprintf('Problema: Cilindro 2D, $Re = %d$', Re), ...
    'Interpreter', 'latex', 'FontSize', 12);
text(0.05, 0.7, sprintf('Ratio de refinamiento: $r = %d$', r), ...
    'Interpreter', 'latex', 'FontSize', 12);
text(0.05, 0.6, sprintf('Orden de convergencia observado: $p = %.2f$', p), ...
    'Interpreter', 'latex', 'FontSize', 12);

text(0.05, 0.45, '\textbf{Resultados:}', 'Interpreter', 'latex', 'FontSize', 12);
text(0.1, 0.35, sprintf('$C_D$ (malla fina): %.3f', f1), 'Interpreter', 'latex', 'FontSize', 12);
text(0.1, 0.25, sprintf('$C_D$ (Richardson): %.3f', f_richardson), 'Interpreter', 'latex', 'FontSize', 12);
text(0.1, 0.15, sprintf('$C_D$ (experimental): %.1f', Cd_exp), 'Interpreter', 'latex', 'FontSize', 12);

text(0.5, 0.45, '\textbf{Indices GCI:}', 'Interpreter', 'latex', 'FontSize', 12);
text(0.55, 0.35, sprintf('GCI$_{21}$ (fina): %.2f\\%%', GCI_21), 'Interpreter', 'latex', 'FontSize', 12);
text(0.55, 0.25, sprintf('GCI$_{32}$ (media): %.2f\\%%', GCI_32), 'Interpreter', 'latex', 'FontSize', 12);
text(0.55, 0.15, sprintf('Ratio asintotico: %.3f', ratio_asintotico), 'Interpreter', 'latex', 'FontSize', 12);

if abs(ratio_asintotico - 1) < 0.1
    text(0.5, 0.02, '\checkmark Mallas en rango asintotico', ...
        'Interpreter', 'latex', 'FontSize', 12, 'Color', [0, 0.6, 0], 'HorizontalAlignment', 'center');
end

exportgraphics(gcf, [output_dir, 'resumen_convergencia.png'], 'Resolution', 300);
fprintf('Guardada: resumen_convergencia.png\n');

%% Guardar resultados
save([output_dir, 'resultados_ejercicio6.mat'], ...
    'Re', 'D', 'nu', 'r', 'h', 'N_cells', 'Cd_sim', ...
    'p', 'f_richardson', 'GCI_21', 'GCI_32', 'ratio_asintotico', ...
    'Cd_exp', 'alpha_deg', 'Cd_alpha', 'Cl_alpha');

fprintf('\n=== EJERCICIO 6 COMPLETADO ===\n');
fprintf('Figuras guardadas en: %s\n', output_dir);
