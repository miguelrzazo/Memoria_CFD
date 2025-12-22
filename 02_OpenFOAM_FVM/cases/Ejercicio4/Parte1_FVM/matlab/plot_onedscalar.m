%% Parte I: OneDScalar - Solucion 1D Conveccion-Difusion
% Genera solucion analitica y discretizaciones numericas (Upwind, Central)
% Guarda figuras en ../../figures/Ejercicio4/

clear; close all; clc;
output_dir = '../../figures/Ejercicio4/';
if ~exist(output_dir, 'dir'), mkdir(output_dir); end

% Parametros fisicos
L = 1.0;           % longitud
U = 1.0;           % velocidad convectiva (m/s)
alpha = 1e-3;      % difusividad (m2/s)
Pe = U*L/alpha;    % numero de Peclet

% Malla
N = [20, 50, 200];
x_fine = linspace(0, L, 1000)';

% Solucion analitica (steady 1D adveccion-difusion, Dirichlet T(0)=1, T(L)=0)
if abs(U) < 1e-12
    T_anal = @(x) 1 - x/L;
else
    r = U/(2*alpha);
    % closed form for steady 1D with constant coeffs: T = (exp(Pe*x/L)-1)/(exp(Pe)-1) reversed sign
    T_anal = @(x) (1 - exp(Pe * x / L)) ./ (1 - exp(Pe));
end
Tref = T_anal(x_fine);

results = struct();
for k=1:length(N)
    n = N(k);
    x = linspace(0, L, n+1)';
    dx = L/n;
    % build matrix for steady: -alpha T'' + U T' = 0
    A = zeros(n+1);
    b = zeros(n+1,1);
    % Dirichlet BCs
    A(1,1)=1; b(1)=1;
    A(end,end)=1; b(end)=0;
    for i=2:n
        % coefficients for central differencing
        aW = alpha/dx^2 + max(U,0)/(2*dx);
        aE = alpha/dx^2 + max(-U,0)/(2*dx);
        aP = aW + aE;
        % for stability with upwind, compute separately later
        A(i,i-1) = -aW;
        A(i,i)   = aP;
        A(i,i+1) = -aE;
    end
    Tcen = A\b; % central-like
    % upwind scheme (first-order)
    Aup = zeros(n+1);
    bup = b;
    Aup(1,1)=1; Aup(end,end)=1;
    for i=2:n
        aW = alpha/dx^2 + U/dx;   % upwind for positive U
        aE = alpha/dx^2;
        aP = aW + aE;
        Aup(i,i-1) = -aW;
        Aup(i,i) = aP;
        Aup(i,i+1) = -aE;
    end
    Tup = Aup\bup;

    results(k).n = n;
    results(k).x = x;
    results(k).Tcen = Tcen;
    results(k).Tup = Tup;
    results(k).Tref = T_anal(x);
end

% Figura: comparacion soluciones (finest numeric vs analitica)
figure('Color','w','Position',[100 100 1000 400]);
plot(x_fine, Tref, 'k-', 'LineWidth', 2, 'DisplayName','Analitica'); hold on;
for k=1:length(N)
    plot(results(k).x, results(k).Tup, '--', 'LineWidth', 1.2, 'DisplayName', sprintf('Upwind N=%d', results(k).n));
    plot(results(k).x, results(k).Tcen, ':', 'LineWidth', 1, 'DisplayName', sprintf('Central N=%d', results(k).n));
end
xlabel('x [m]','Interpreter','latex'); ylabel('T','Interpreter','latex');
title(sprintf('Solucion estacionaria 1D (Pe = %.1e)', Pe),'Interpreter','latex');
legend('Location','best'); grid on;
exportgraphics(gcf, [output_dir,'onedscalar_solution.png'],'Resolution',300);
fprintf('Guardada: onedscalar_solution.png\n');

% Figura: Error (L2) vs N
Ns = [results.n];
L2_up = zeros(size(Ns)); L2_cen = zeros(size(Ns));
for k=1:length(Ns)
    % interpolate analytic to node positions
    x = results(k).x;
    Tref_n = T_anal(x);
    L2_up(k) = sqrt(mean((results(k).Tup - Tref_n).^2));
    L2_cen(k) = sqrt(mean((results(k).Tcen - Tref_n).^2));
end
figure('Color','w','Position',[200 200 700 400]);
loglog(Ns, L2_up, 'ro-','LineWidth',1.5,'DisplayName','Upwind (1st order)'); hold on;
loglog(Ns, L2_cen, 'bs-','LineWidth',1.5,'DisplayName','Central-like');
xlabel('N (number of cells)','Interpreter','latex'); ylabel('$L_2$ error','Interpreter','latex');
title('Convergencia numerica - OneDScalar','Interpreter','latex');
legend('Location','best'); grid on;
exportgraphics(gcf, [output_dir,'onedscalar_error.png'],'Resolution',300);
fprintf('Guardada: onedscalar_error.png\n');

% Guardar resultados matlab
save([output_dir,'resultados_onedscalar.mat'],'results','x_fine','Tref','Ns','L2_up','L2_cen');
fprintf('Guardados datos en resultados_onedscalar.mat\n');
