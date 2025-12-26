#!/usr/bin/env python3
"""
EJERCICIO 4 - PARTE 2: Crear GIF de evolucion temporal del tubo de choque
Genera un GIF animado mostrando la propagacion de las ondas de choque,
rarefaccion y discontinuidad de contacto.

Autor: Miguel Rosa
Fecha: Diciembre 2025

Uso:
    python create_shocktube_gif.py

Requisitos:
    - matplotlib
    - numpy
    - imageio (o pillow)
"""

import os
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.animation as animation
from matplotlib.gridspec import GridSpec
import glob
import re

# Configuracion de rutas
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
BASE_DIR = os.path.dirname(SCRIPT_DIR)
HIGH_ORDER_DIR = os.path.join(BASE_DIR, 'shockTube_highOrder')
LOW_ORDER_DIR = os.path.join(BASE_DIR, 'shockTube_lowOrder')
OUTPUT_DIR = os.path.join(os.path.dirname(BASE_DIR), '..', 'figures', 'Ejercicio4')

# Crear directorio de salida
os.makedirs(OUTPUT_DIR, exist_ok=True)

def parse_openfoam_field(filepath):
    """Parse un archivo de campo escalar de OpenFOAM"""
    with open(filepath, 'r') as f:
        content = f.read()

    # Buscar valores entre parentesis
    pattern = r'internalField\s+nonuniform\s+List<scalar>\s+\d+\s*\(\s*([\d.eE\s+-]+)\s*\)'
    match = re.search(pattern, content, re.DOTALL)

    if match:
        values_str = match.group(1)
        values = [float(v) for v in values_str.split()]
        return np.array(values)

    # Intentar con uniform
    pattern = r'internalField\s+uniform\s+([\d.eE+-]+)'
    match = re.search(pattern, content)
    if match:
        return np.full(1000, float(match.group(1)))

    return None

def parse_openfoam_vector_field(filepath):
    """Parse un archivo de campo vectorial de OpenFOAM"""
    with open(filepath, 'r') as f:
        content = f.read()

    # Buscar vectores (x y z)
    pattern = r'\(([\d.eE+-]+)\s+([\d.eE+-]+)\s+([\d.eE+-]+)\)'
    matches = re.findall(pattern, content)

    if matches:
        # Saltar los primeros matches (pueden ser metadata)
        # Buscar donde empiezan los datos reales
        data_start = content.find('internalField')
        if data_start > 0:
            content_data = content[data_start:]
            matches = re.findall(pattern, content_data)

        if len(matches) > 10:  # Suficientes datos
            Ux = np.array([float(m[0]) for m in matches[:1000]])
            return np.abs(Ux)  # Magnitud de velocidad

    return None

def get_available_times(case_dir):
    """Obtener lista de tiempos disponibles en un caso"""
    times = []
    for item in os.listdir(case_dir):
        try:
            t = float(item)
            if t > 0:
                times.append(t)
        except ValueError:
            continue
    return sorted(times)

def read_fields_at_time(case_dir, time):
    """Leer campos p, T, rho, U en un tiempo dado"""
    time_dir = os.path.join(case_dir, f'{time:.2f}'.rstrip('0').rstrip('.'))
    if not os.path.exists(time_dir):
        time_dir = os.path.join(case_dir, f'{time}')
    if not os.path.exists(time_dir):
        time_dir = os.path.join(case_dir, f'{time:.1f}')

    if not os.path.exists(time_dir):
        return None

    data = {}

    # Leer presion
    p_file = os.path.join(time_dir, 'p')
    if os.path.exists(p_file):
        data['p'] = parse_openfoam_field(p_file)

    # Leer temperatura
    T_file = os.path.join(time_dir, 'T')
    if os.path.exists(T_file):
        data['T'] = parse_openfoam_field(T_file)

    # Leer densidad
    rho_file = os.path.join(time_dir, 'rho')
    if os.path.exists(rho_file):
        data['rho'] = parse_openfoam_field(rho_file)
    elif 'p' in data and 'T' in data:
        # Calcular desde ecuacion de estado
        R = 287.05
        data['rho'] = data['p'] / (R * data['T'])

    # Leer velocidad
    U_file = os.path.join(time_dir, 'U')
    if os.path.exists(U_file):
        data['U'] = parse_openfoam_vector_field(U_file)

    return data

def create_animation(case_dir, case_name, output_file):
    """Crear GIF animado de la evolucion temporal"""
    print(f"\nCreando animacion para {case_name}...")

    # Obtener tiempos disponibles
    times = get_available_times(case_dir)
    if not times:
        print(f"  No se encontraron tiempos en {case_dir}")
        return

    print(f"  Tiempos disponibles: {times}")

    # Coordenadas x
    n_cells = 1000
    x = np.linspace(-5, 5, n_cells)

    # Leer todos los datos
    all_data = []
    valid_times = []
    for t in times:
        data = read_fields_at_time(case_dir, t)
        if data and 'p' in data:
            all_data.append(data)
            valid_times.append(t)

    if not all_data:
        print(f"  No se pudieron leer datos")
        return

    print(f"  Tiempos validos: {valid_times}")

    # Configurar figura
    fig = plt.figure(figsize=(14, 8), facecolor='white')
    gs = GridSpec(2, 2, figure=fig, hspace=0.3, wspace=0.25)

    ax1 = fig.add_subplot(gs[0, 0])
    ax2 = fig.add_subplot(gs[0, 1])
    ax3 = fig.add_subplot(gs[1, 0])
    ax4 = fig.add_subplot(gs[1, 1])

    axes = [ax1, ax2, ax3, ax4]
    fields = ['rho', 'p', 'T', 'U']
    labels = [r'Densidad $\rho$ [kg/m$^3$]', r'Presion $p$ [kPa]',
              r'Temperatura $T$ [K]', r'Velocidad $|U|$ [m/s]']
    colors = ['blue', 'red', 'green', 'purple']

    # Inicializar lineas
    lines = []
    for ax, label, color in zip(axes, labels, colors):
        ax.set_xlim(-5, 5)
        ax.set_xlabel('x [m]')
        ax.set_ylabel(label)
        ax.grid(True, alpha=0.3)
        line, = ax.plot([], [], color=color, linewidth=1.5)
        lines.append(line)

    # Titulo
    title = fig.suptitle('', fontsize=14, fontweight='bold')

    # Establecer limites de y
    ax1.set_ylim(0, 1.2)  # rho
    ax2.set_ylim(0, 110)  # p (kPa)
    ax3.set_ylim(250, 380)  # T
    ax4.set_ylim(-50, 400)  # U

    def init():
        for line in lines:
            line.set_data([], [])
        title.set_text('')
        return lines + [title]

    def animate(i):
        data = all_data[i]
        t = valid_times[i]

        # Actualizar cada linea
        if 'rho' in data and data['rho'] is not None:
            lines[0].set_data(x, data['rho'])
        if 'p' in data and data['p'] is not None:
            lines[1].set_data(x, data['p']/1000)  # kPa
        if 'T' in data and data['T'] is not None:
            lines[2].set_data(x, data['T'])
        if 'U' in data and data['U'] is not None:
            lines[3].set_data(x, data['U'])

        title.set_text(f'Tubo de choque de Sod - Esquema {case_name} - t = {t:.3f} s')
        return lines + [title]

    # Crear animacion
    anim = animation.FuncAnimation(fig, animate, init_func=init,
                                   frames=len(valid_times), interval=200,
                                   blit=True)

    # Guardar como GIF
    print(f"  Guardando GIF...")
    anim.save(output_file, writer='pillow', fps=5, dpi=100)
    print(f"  Guardado: {output_file}")

    plt.close(fig)

def create_comparison_animation(output_file):
    """Crear GIF comparando alto vs bajo orden"""
    print("\nCreando animacion comparativa...")

    # Obtener tiempos comunes
    times_high = get_available_times(HIGH_ORDER_DIR)
    times_low = get_available_times(LOW_ORDER_DIR)

    if not times_high or not times_low:
        print("  No hay suficientes datos para comparacion")
        return

    # Usar tiempos comunes
    common_times = sorted(set(times_high) & set(times_low))
    if not common_times:
        common_times = times_high  # Usar solo high order si no hay comunes

    print(f"  Tiempos comunes: {common_times}")

    # Coordenadas x
    n_cells = 1000
    x = np.linspace(-5, 5, n_cells)

    # Leer datos
    data_high = []
    data_low = []
    valid_times = []

    for t in common_times:
        dh = read_fields_at_time(HIGH_ORDER_DIR, t)
        dl = read_fields_at_time(LOW_ORDER_DIR, t)
        if dh and 'p' in dh:
            data_high.append(dh)
            data_low.append(dl if dl else dh)
            valid_times.append(t)

    if not data_high:
        print("  No se pudieron leer datos")
        return

    # Configurar figura
    fig, axes = plt.subplots(2, 2, figsize=(14, 10), facecolor='white')
    fig.subplots_adjust(hspace=0.3, wspace=0.25)

    fields = ['rho', 'p', 'T', 'U']
    labels = [r'Densidad $\rho$ [kg/m$^3$]', r'Presion $p$ [kPa]',
              r'Temperatura $T$ [K]', r'Velocidad $|U|$ [m/s]']

    lines_high = []
    lines_low = []

    for ax, label in zip(axes.flat, labels):
        ax.set_xlim(-5, 5)
        ax.set_xlabel('x [m]')
        ax.set_ylabel(label)
        ax.grid(True, alpha=0.3)
        lh, = ax.plot([], [], 'b-', linewidth=1.5, label='Alto orden (vanAlbada)')
        ll, = ax.plot([], [], 'r--', linewidth=1.5, label='Bajo orden (upwind)')
        ax.legend(loc='best', fontsize=9)
        lines_high.append(lh)
        lines_low.append(ll)

    # Limites
    axes[0,0].set_ylim(0, 1.2)
    axes[0,1].set_ylim(0, 110)
    axes[1,0].set_ylim(250, 380)
    axes[1,1].set_ylim(-50, 400)

    title = fig.suptitle('', fontsize=14, fontweight='bold')

    def init():
        for lh, ll in zip(lines_high, lines_low):
            lh.set_data([], [])
            ll.set_data([], [])
        return lines_high + lines_low + [title]

    def animate(i):
        dh = data_high[i]
        dl = data_low[i]
        t = valid_times[i]

        # Densidad
        if 'rho' in dh and dh['rho'] is not None:
            lines_high[0].set_data(x, dh['rho'])
        if dl and 'rho' in dl and dl['rho'] is not None:
            lines_low[0].set_data(x, dl['rho'])

        # Presion
        if 'p' in dh and dh['p'] is not None:
            lines_high[1].set_data(x, dh['p']/1000)
        if dl and 'p' in dl and dl['p'] is not None:
            lines_low[1].set_data(x, dl['p']/1000)

        # Temperatura
        if 'T' in dh and dh['T'] is not None:
            lines_high[2].set_data(x, dh['T'])
        if dl and 'T' in dl and dl['T'] is not None:
            lines_low[2].set_data(x, dl['T'])

        # Velocidad
        if 'U' in dh and dh['U'] is not None:
            lines_high[3].set_data(x, dh['U'])
        if dl and 'U' in dl and dl['U'] is not None:
            lines_low[3].set_data(x, dl['U'])

        title.set_text(f'Tubo de choque de Sod - Comparacion de esquemas - t = {t:.3f} s')
        return lines_high + lines_low + [title]

    anim = animation.FuncAnimation(fig, animate, init_func=init,
                                   frames=len(valid_times), interval=200,
                                   blit=True)

    print(f"  Guardando GIF...")
    anim.save(output_file, writer='pillow', fps=5, dpi=100)
    print(f"  Guardado: {output_file}")

    plt.close(fig)

def main():
    print("=" * 60)
    print("EJERCICIO 4 - PARTE 2: Generador de GIF")
    print("=" * 60)

    # Animacion para alto orden
    if os.path.exists(HIGH_ORDER_DIR):
        output_high = os.path.join(OUTPUT_DIR, 'shocktube_highOrder_evolution.gif')
        create_animation(HIGH_ORDER_DIR, 'Alto Orden (vanAlbada)', output_high)

    # Animacion para bajo orden
    if os.path.exists(LOW_ORDER_DIR):
        output_low = os.path.join(OUTPUT_DIR, 'shocktube_lowOrder_evolution.gif')
        create_animation(LOW_ORDER_DIR, 'Bajo Orden (upwind)', output_low)

    # Animacion comparativa
    if os.path.exists(HIGH_ORDER_DIR) and os.path.exists(LOW_ORDER_DIR):
        output_comp = os.path.join(OUTPUT_DIR, 'shocktube_comparacion_evolution.gif')
        create_comparison_animation(output_comp)

    print("\n" + "=" * 60)
    print("COMPLETADO")
    print(f"GIFs guardados en: {OUTPUT_DIR}")
    print("=" * 60)

if __name__ == '__main__':
    main()
