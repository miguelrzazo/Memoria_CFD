% run_ejercicio5.m
% Wrapper to run Ejercicio5 MATLAB processing (single entry point)
try
    basedir = fileparts(mfilename('fullpath'));
catch
    basedir = pwd;
end
orig = pwd; onCleanup(@() cd(orig)); cd(basedir);
addpath(basedir);
try
    if exist(fullfile(basedir,'../plot_ejercicio5.m'),'file')
        fprintf('Running plot_ejercicio5...\n');
        run(fullfile(basedir,'../plot_ejercicio5.m'));
    else
        warning('plot_ejercicio5.m not found. If plotting scripts are elsewhere, update this wrapper.');
    end
catch ME
    warning('plot_ejercicio5 failed: %s', ME.message);
end
fprintf('run_ejercicio5 completed. Figures should be in ../../figures/Ejercicio5/.\n');
