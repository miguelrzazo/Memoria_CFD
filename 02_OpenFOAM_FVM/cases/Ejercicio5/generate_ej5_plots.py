#!/usr/bin/env python3
"""Genera figuras faltantes del Ejercicio 5 a partir de los archivos exportados por pvpython.
 - law_of_wall.png (ley de pared U+ vs y+)
 - perfil_velocidad_ej5.png (perfil de velocidad a partir de perfil_velocidad_data.csv)
 - campos_turbulentos.png (montaje k + nut)
"""
import os
import math
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.image as mpimg


def read_csv_auto(path):
    with open(path, 'r', encoding='utf-8') as f:
        header = f.readline().strip().replace('"','').split(',')
    data = np.loadtxt(path, delimiter=',', skiprows=1)
    return header, data


def compute_u_magnitude(header, data):
    # Find indices for U:0,U:1,U:2 and Points:1 (y)
    try:
        i_u0 = header.index('U:0')
        i_u1 = header.index('U:1')
        i_u2 = header.index('U:2')
        i_py = header.index('Points:1')
    except ValueError:
        raise RuntimeError('Column headers not found in CSV')
    U = np.sqrt(data[:, i_u0]**2 + data[:, i_u1]**2 + data[:, i_u2]**2)
    y = data[:, i_py]
    return y, U


def spalding_um(y_plus, kappa=0.41, B=5.2):
    # Solve Spalding implicit relation for U+ given y+
    U_plus = np.zeros_like(y_plus)
    for i, yp in enumerate(y_plus):
        if yp <= 0:
            U_plus[i] = 0.0
            continue
        Up = yp if yp < 1 else np.log(yp) / kappa + B
        for _ in range(60):
            exp_term = math.exp(kappa * Up)
            f = Up + math.exp(-kappa * B) * (exp_term - 1 - kappa * Up - (kappa * Up)**2 / 2 - (kappa * Up)**3 / 6) - yp
            df = 1 + math.exp(-kappa * B) * (kappa * exp_term - kappa - kappa**2 * Up - 0.5 * kappa**3 * Up**2)
            Up_new = Up - f / df if df != 0 else Up
            if abs(Up_new - Up) < 1e-8:
                Up = Up_new
                break
            Up = Up_new
        U_plus[i] = Up
    return U_plus


def main():
    out_dir = os.path.join(os.path.dirname(__file__), '..', 'figures', 'Ejercicio5')
    out_dir = os.path.abspath(out_dir)
    csv_path = os.path.join(out_dir, 'perfil_velocidad_data.csv')
    if not os.path.exists(out_dir):
        os.makedirs(out_dir, exist_ok=True)

    # Parameters (same as MATLAB script)
    Re = 535000
    H = 0.1
    U_wall = 10.0
    nu = U_wall * H / Re
    rho = 1.0

    # 1) Read CSV and plot perfil_velocidad_ej5.png
    if os.path.exists(csv_path):
        header, data = read_csv_auto(csv_path)
        y, U = compute_u_magnitude(header, data)
        # Save perfil velocidad (dimensional)
        plt.figure(figsize=(6,8), dpi=150)
        plt.plot(U, y*1000, 'b-', linewidth=2.5, label='Perfil (sim)')
        plt.plot([0, U_wall], [0, H*1000], 'r--', linewidth=2, label='Couette laminar')
        plt.xlabel('U [m/s]')
        plt.ylabel('y [mm]')
        plt.title(f'Perfil de velocidad - Couette (Re={Re})')
        plt.legend()
        plt.grid(True)
        perfil_out = os.path.join(out_dir, 'perfil_velocidad_ej5.png')
        plt.savefig(perfil_out, bbox_inches='tight')
        plt.close()
        print('Guardada:', perfil_out)

        # 2) Generate law_of_wall.png using Spalding law and estimated u_tau
        Cf = 0.074 * Re**(-0.2)
        tau_w = 0.5 * rho * U_wall**2 * Cf
        u_tau = math.sqrt(tau_w / rho)
        y_plus = y * u_tau / nu
        U_plus_spalding = spalding_um(y_plus)

        plt.figure(figsize=(8,6), dpi=150)
        yp_sorted_idx = np.argsort(y_plus)
        yp_plot = y_plus[yp_sorted_idx]
        Uplus_plot = U_plus_spalding[yp_sorted_idx]
        # viscous and log lines
        U_plus_viscous = yp_plot
        kappa = 0.41; B = 5.2
        U_plus_log = (1/kappa) * np.log(yp_plot) + B
        plt.semilogx(yp_plot, U_plus_viscous, 'b--', linewidth=2, label='$U^+ = y^+$')
        mask = yp_plot > 5
        plt.semilogx(yp_plot[mask], U_plus_log[mask], 'r--', linewidth=2, label='Ley log')
        plt.semilogx(yp_plot, Uplus_plot, 'k-', linewidth=2.5, label="Spalding compuesta")
        plt.xlabel('$y^+$')
        plt.ylabel('$U^+$')
        plt.title('Ley de pared - Couette turbulento')
        plt.legend()
        plt.grid(True)
        law_out = os.path.join(out_dir, 'law_of_wall.png')
        plt.savefig(law_out, bbox_inches='tight')
        plt.close()
        print('Guardada:', law_out)
    else:
        print('CSV de perfil no encontrado:', csv_path)

    # 3) Combine k and nut images into campos_turbulentos.png
    k_img = os.path.join(out_dir, 'k_field_t4000.png')
    nut_img = os.path.join(out_dir, 'nut_field_t4000.png')
    combined_out = os.path.join(out_dir, 'campos_turbulentos.png')
    if os.path.exists(k_img) and os.path.exists(nut_img):
        ka = mpimg.imread(k_img)
        na = mpimg.imread(nut_img)
        h = max(ka.shape[0], na.shape[0])
        w1 = ka.shape[1]
        w2 = na.shape[1]
        # Create figure with two subplots and save
        fig, ax = plt.subplots(1,2, figsize=(12,6), dpi=150)
        ax[0].imshow(ka)
        ax[0].axis('off')
        ax[0].set_title('k field')
        ax[1].imshow(na)
        ax[1].axis('off')
        ax[1].set_title('nut field')
        fig.tight_layout()
        fig.savefig(combined_out, bbox_inches='tight')
        plt.close(fig)
        print('Guardada:', combined_out)
    else:
        print('No se encontraron k/nut images en', out_dir)


if __name__ == '__main__':
    main()
