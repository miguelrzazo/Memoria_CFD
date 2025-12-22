%% EJERCICIO 6: Analisis de Convergencia de Malla
% Extrapolacion de Richardson y calculo del GCI
% Master Ingenieria Aeronautica - CFD 2025
% Universidad de Leon

clear; close all; clc;

%% Configuracion
output_dir = '../../figures/Ejercicio6/';
if ~exist(output_dir, 'dir'), mkdir(output_dir); end

fprintf('===========================================\n');
fprintf('  EJERCICIO 6: Convergencia de Malla\n');
fprintf('===========================================\n\n');

%% Datos de las simulaciones (a completar con resultados reales)
% Estos valores deben actualizarse con los resultados de OpenFOAM

% Numero de celdas en cada malla (aproximado basado en scalingFactor)
% scalingFactor: coarse=1, medium=2, fine=4
% El numero de celdas escala aproximadamente como scalingFactor^2 en 2D
N_coarse = 1000;   % Ejemplo: actualizar con checkMesh
N_medium = 4000;
N_fine = 16000;

% Tamano caracteristico de celda (h = sqrt(Area/N_celdas))
% Para un dominio similar, h es proporcional a 1/sqrt(N)
Area_dominio = 200 * 200;  % Dominio de 200x200 (diametro 1, dominio 100D)
h = [sqrt(Area_dominio/N_coarse), sqrt(Area_dominio/N_medium), sqrt(Area_dominio/N_fine)];

% Parametro de interes: Coeficiente de arrastre Cd
% Valores ejemplo (reemplazar con resultados reales de postProcessing/forceCoeffs)
% Para Re=1 laminar, Cd teorico ~ 20-30 (Stokes drag)
Cd_coarse = 22.5;
Cd_medium = 21.8;
Cd_fine = 21.5;

% Almacenar en vectores
Cd = [Cd_coarse, Cd_medium, Cd_fine];
labels = {'Gruesa', 'Media', 'Fina'};

%% Calculo del orden de convergencia
fprintf('=== ESTUDIO DE CONVERGENCIA ===\n\n');

% Ratio de refinamiento
r = h(1) / h(2);  % Debe ser aproximadamente 2
r_verificacion = h(2) / h(3);
fprintf('Ratio de refinamiento r12 = %.4f\n', r);
fprintf('Ratio de refinamiento r23 = %.4f\n', r_verificacion);

% Diferencias entre soluciones
epsilon_21 = Cd(2) - Cd(1);  % f2 - f1
epsilon_32 = Cd(3) - Cd(2);  % f3 - f2

fprintf('\nDiferencias:\n');
fprintf('  epsilon_21 (medium - coarse) = %.6f\n', epsilon_21);
fprintf('  epsilon_32 (fine - medium) = %.6f\n', epsilon_32);

% Orden de convergencia observado (metodo iterativo)
% p = ln(epsilon_21/epsilon_32) / ln(r)
if abs(epsilon_32) > 1e-10 && sign(epsilon_21) == sign(epsilon_32)
    p_observed = log(abs(epsilon_21/epsilon_32)) / log(r);
else
    p_observed = 2.0;  % Asumir segundo orden si no converge monotonicamente
    fprintf('\nAdvertencia: Convergencia no monotonica. Usando p=2.\n');
end

fprintf('\nOrden de convergencia observado: p = %.4f\n', p_observed);

%% Extrapolacion de Richardson
% Valor extrapolado a malla infinitamente fina
if abs(epsilon_32) > 1e-10
    Cd_extrapolated = Cd(3) + epsilon_32 / (r^p_observed - 1);
else
    Cd_extrapolated = Cd(3);
end

fprintf('\n=== EXTRAPOLACION DE RICHARDSON ===\n');
fprintf('Cd extrapolado (h->0) = %.6f\n', Cd_extrapolated);

% Comparacion con solucion analitica
% Para cilindro 2D a Re=1, Cd teorico (Lamb):
% Cd = 8*pi / (Re * (0.5 - gamma - ln(Re/8)))
% donde gamma = 0.5772 (Euler-Mascheroni)
Re = 1;
gamma_euler = 0.5772;
Cd_teorico = 8*pi / (Re * (0.5 - gamma_euler - log(Re/8)));
fprintf('Cd teorico (Lamb) = %.6f\n', Cd_teorico);
fprintf('Error respecto a teorico = %.2f%%\n', ...
    abs(Cd_extrapolated - Cd_teorico)/Cd_teorico * 100);

%% Calculo del GCI (Grid Convergence Index)
fprintf('\n=== INDICE DE CONVERGENCIA DE MALLA (GCI) ===\n');

% Factor de seguridad
Fs = 1.25;  % Factor para 3 mallas

% Error relativo entre mallas
e_32 = abs((Cd(3) - Cd(2)) / Cd(3));
e_21 = abs((Cd(2) - Cd(1)) / Cd(2));

% GCI para malla fina
GCI_fine = Fs * e_32 / (r^p_observed - 1);

% GCI para malla media
GCI_medium = Fs * e_21 / (r^p_observed - 1);

fprintf('GCI (malla fina) = %.4f (%.2f%%)\n', GCI_fine, GCI_fine*100);
fprintf('GCI (malla media) = %.4f (%.2f%%)\n', GCI_medium, GCI_medium*100);

%% Verificacion de rango asintotico
% Condicion: GCI_medium / (r^p * GCI_fine) debe ser aproximadamente 1
ratio_asintotico = GCI_medium / (r^p_observed * GCI_fine);
fprintf('\nVerificacion rango asintotico:\n');
fprintf('GCI_medium / (r^p * GCI_fine) = %.4f\n', ratio_asintotico);
if abs(ratio_asintotico - 1) < 0.1
    fprintf('-> Las mallas ESTAN en el rango asintotico de convergencia.\n');
else
    fprintf('-> ADVERTENCIA: Las mallas pueden NO estar en el rango asintotico.\n');
end

%% FIGURA 1: Convergencia de Cd vs tamano de malla
figure('Position', [100, 100, 900, 600], 'Color', 'w');

% Grafica log-log
loglog(h, Cd, 'bo-', 'LineWidth', 2, 'MarkerSize', 12, 'MarkerFaceColor', 'b');
hold on;

% Linea de tendencia (orden p)
h_fit = linspace(min(h)*0.5, max(h)*1.5, 100);
Cd_fit = Cd_extrapolated + (Cd(3) - Cd_extrapolated) * (h_fit/h(3)).^p_observed;
loglog(h_fit, Cd_fit, 'r--', 'LineWidth', 1.5);

% Valor extrapolado
yline(Cd_extrapolated, 'g--', 'LineWidth', 1.5);

% Valor teorico
yline(Cd_teorico, 'k:', 'LineWidth', 1.5);

xlabel('Tamano caracteristico de celda $h$ [m]', 'Interpreter', 'latex', 'FontSize', 12);
ylabel('$C_d$', 'Interpreter', 'latex', 'FontSize', 12);
title(sprintf('Convergencia de malla (orden $p = %.2f$)', p_observed), ...
    'Interpreter', 'latex', 'FontSize', 14);
legend({'Simulaciones', sprintf('Ajuste orden %.2f', p_observed), ...
    'Richardson extrapolado', 'Solucion teorica (Lamb)'}, ...
    'Location', 'northeast', 'Interpreter', 'latex');
grid on;

% Anotaciones
for i = 1:3
    text(h(i)*1.1, Cd(i), labels{i}, 'FontSize', 10);
end

exportgraphics(gcf, [output_dir, 'convergencia_malla.png'], 'Resolution', 300);
fprintf('\nGuardada: convergencia_malla.png\n');

%% FIGURA 2: Barras de incertidumbre GCI
figure('Position', [100, 100, 700, 500], 'Color', 'w');

bar_data = [Cd(2), Cd(3)];
bar_errors = [GCI_medium * Cd(2), GCI_fine * Cd(3)];

b = bar(bar_data);
hold on;
errorbar([1, 2], bar_data, bar_errors, 'k.', 'LineWidth', 2);

% Linea de Richardson extrapolado
yline(Cd_extrapolated, 'r--', 'LineWidth', 1.5, 'Label', 'Richardson');
yline(Cd_teorico, 'g:', 'LineWidth', 1.5, 'Label', 'Teorico');

set(gca, 'XTickLabel', {'Media', 'Fina'});
xlabel('Nivel de malla', 'Interpreter', 'latex', 'FontSize', 12);
ylabel('$C_d$', 'Interpreter', 'latex', 'FontSize', 12);
title('Incertidumbre de discretizacion (GCI)', 'Interpreter', 'latex', 'FontSize', 14);
legend({'$C_d$ simulado', 'GCI', 'Richardson', 'Teorico'}, ...
    'Location', 'northeast', 'Interpreter', 'latex');
grid on;

exportgraphics(gcf, [output_dir, 'GCI_incertidumbre.png'], 'Resolution', 300);
fprintf('Guardada: GCI_incertidumbre.png\n');

%% FIGURA 3: Tabla resumen
figure('Position', [100, 100, 800, 500], 'Color', 'w');
axis off;

text(0.5, 0.95, '\textbf{Resumen de Convergencia de Malla}', ...
    'Interpreter', 'latex', 'FontSize', 16, 'HorizontalAlignment', 'center');

% Crear tabla
col_titles = {'Malla', 'N celdas', 'h [m]', 'Cd', 'Error [\%]'};
row_data = {
    'Gruesa', N_coarse, h(1), Cd(1), abs(Cd(1)-Cd_teorico)/Cd_teorico*100;
    'Media', N_medium, h(2), Cd(2), abs(Cd(2)-Cd_teorico)/Cd_teorico*100;
    'Fina', N_fine, h(3), Cd(3), abs(Cd(3)-Cd_teorico)/Cd_teorico*100;
    'Richardson', '-', '0', Cd_extrapolated, abs(Cd_extrapolated-Cd_teorico)/Cd_teorico*100;
    'Teorico', '-', '-', Cd_teorico, 0;
};

y_pos = 0.75;
for j = 1:5
    text(0.1 + (j-1)*0.18, y_pos+0.08, col_titles{j}, 'FontSize', 11, 'FontWeight', 'bold');
end

for i = 1:5
    y_pos = 0.75 - i*0.12;
    for j = 1:5
        if isnumeric(row_data{i,j})
            if j == 2 && row_data{i,j} ~= 0
                txt = sprintf('%d', row_data{i,j});
            else
                txt = sprintf('%.4f', row_data{i,j});
            end
        else
            txt = row_data{i,j};
        end
        text(0.1 + (j-1)*0.18, y_pos, txt, 'FontSize', 10);
    end
end

text(0.5, 0.15, sprintf('Orden de convergencia: $p = %.2f$', p_observed), ...
    'Interpreter', 'latex', 'FontSize', 12, 'HorizontalAlignment', 'center');
text(0.5, 0.08, sprintf('GCI (malla fina): %.2f\\%%', GCI_fine*100), ...
    'Interpreter', 'latex', 'FontSize', 12, 'HorizontalAlignment', 'center');

exportgraphics(gcf, [output_dir, 'tabla_convergencia.png'], 'Resolution', 300);
fprintf('Guardada: tabla_convergencia.png\n');

%% Guardar resultados
save([output_dir, 'resultados_convergencia.mat'], ...
    'h', 'Cd', 'p_observed', 'Cd_extrapolated', 'Cd_teorico', ...
    'GCI_fine', 'GCI_medium', 'ratio_asintotico');

fprintf('\n===========================================\n');
fprintf('  EJERCICIO 6 ANALISIS COMPLETADO\n');
fprintf('===========================================\n');
