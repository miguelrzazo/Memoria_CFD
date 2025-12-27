#!/usr/bin/env python3
"""
create_shocktube_gif.py - Genera GIF animado de la evolucion del tubo de choque

Este script crea un GIF animado mostrando la evolucion temporal del campo de
presion en el problema del tubo de choque de Sod.

Uso:
    python3 create_shocktube_gif.py

Requiere:
    - matplotlib
    - numpy
    - imageio (o PIL)
"""

import os
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.animation as animation
from matplotlib.colors import Normalize
import glob

# =============================================================================
# CONFIGURACION
# =============================================================================

script_dir = os.path.dirname(os.path.abspath(__file__))
case_base = os.path.dirname(script_dir)
fig_dir = os.path.join(case_base, '..', '..', '..', 'figures', 'Ejercicio4')

# Crear directorio si no existe
if not os.path.exists(fig_dir):
    os.makedirs(fig_dir)

# Rutas de los casos
highorder_path = os.path.join(case_base, 'shockTube_highorder', 'postProcessing', 'graph')
loworder_path = os.path.join(case_base, 'shockTube_loworder', 'postProcessing', 'graph')

# Tiempos a incluir en el GIF (tiempo adimensional: t* = t * 374.17 / 10)
times = ['0', '0.0005', '0.001', '0.0015', '0.002', '0.0025', '0.003',
         '0.0035', '0.004', '0.0045', '0.005', '0.0055', '0.006', '0.0065', '0.007']
# Tiempos adimensionales correspondientes: 0, 0.019, 0.037, ..., 0.262

# Configuracion del GIF
fps = 3  # Frames por segundo
dpi = 150


# =============================================================================
# FUNCIONES
# =============================================================================

def read_line_data(filepath):
    """Lee datos de linea de OpenFOAM postProcessing."""
    if not os.path.exists(filepath):
        return None, None, None, None

    # Formato: x  T  mag(U)  p
    data = np.loadtxt(filepath, skiprows=1)
    x = data[:, 0]
    T = data[:, 1]
    U = data[:, 2]
    p = data[:, 3]

    return x, T, U, p


def load_all_data(case_path, times):
    """Carga datos para todos los tiempos."""
    data = {}
    for t in times:
        filepath = os.path.join(case_path, t, 'line.xy')
        x, T, U, p = read_line_data(filepath)
        if x is not None:
            data[t] = {'x': x, 'T': T, 'U': U, 'p': p}
    return data


def create_pressure_gif():
    """Crea GIF animado del campo de presion."""
    print('Cargando datos...')

    # Cargar datos de ambos casos
    data_high = load_all_data(highorder_path, times)
    data_low = load_all_data(loworder_path, times)

    if not data_high:
        print('Error: No se encontraron datos del caso highorder')
        return

    available_times = sorted(data_high.keys(), key=lambda x: float(x))
    print(f'Tiempos disponibles: {len(available_times)}')

    # Crear figura
    fig, ax = plt.subplots(figsize=(12, 5), dpi=dpi)
    fig.patch.set_facecolor('white')

    # Configuracion de ejes
    ax.set_xlim(-5, 5)
    ax.set_ylim(0, 110)
    ax.set_xlabel(r'$x$ [m]', fontsize=12)
    ax.set_ylabel(r'$p$ [kPa]', fontsize=12)
    ax.grid(True, alpha=0.3)

    # Lineas iniciales
    line_high, = ax.plot([], [], 'b-', lw=2, label='Alto orden (linearUpwind)')
    line_low, = ax.plot([], [], 'r--', lw=2, label='Bajo orden (upwind)')

    ax.legend(loc='lower left', fontsize=10)

    # Titulo con tiempo
    title = ax.set_title('', fontsize=14)

    def init():
        line_high.set_data([], [])
        line_low.set_data([], [])
        title.set_text('')
        return line_high, line_low, title

    def animate(i):
        t = available_times[i]
        t_float = float(t)

        # Datos alto orden
        if t in data_high:
            x = data_high[t]['x']
            p = data_high[t]['p'] / 1000  # Pa a kPa
            line_high.set_data(x, p)

        # Datos bajo orden
        if t in data_low:
            x = data_low[t]['x']
            p = data_low[t]['p'] / 1000
            line_low.set_data(x, p)

        title.set_text(f'Tubo de choque de Sod - $t = {t_float:.2f}$ s')

        return line_high, line_low, title

    # Crear animacion
    print('Creando animacion...')
    anim = animation.FuncAnimation(fig, animate, init_func=init,
                                   frames=len(available_times),
                                   interval=1000/fps, blit=True)

    # Guardar GIF
    gif_path = os.path.join(fig_dir, 'shocktube_presion_evolucion.gif')
    print(f'Guardando GIF: {gif_path}')

    # Usar Pillow como writer
    try:
        writer = animation.PillowWriter(fps=fps)
        anim.save(gif_path, writer=writer, dpi=dpi)
        print(f'GIF guardado exitosamente: {gif_path}')
    except Exception as e:
        print(f'Error con PillowWriter: {e}')
        # Intentar con imagemagick
        try:
            anim.save(gif_path, writer='imagemagick', fps=fps, dpi=dpi)
            print(f'GIF guardado con ImageMagick: {gif_path}')
        except Exception as e2:
            print(f'Error con ImageMagick: {e2}')
            # Guardar frames individuales
            print('Guardando frames individuales...')
            for i, t in enumerate(available_times):
                animate(i)
                frame_path = os.path.join(fig_dir, f'shocktube_presion_frame_{i:03d}.png')
                fig.savefig(frame_path, dpi=dpi, bbox_inches='tight',
                           facecolor='white', edgecolor='none')
            print(f'Frames guardados en: {fig_dir}')

    plt.close(fig)


def create_multifield_gif():
    """Crea GIF con multiples campos (p, rho, T, U)."""
    print('Cargando datos para GIF multifield...')

    data_high = load_all_data(highorder_path, times)

    if not data_high:
        print('Error: No se encontraron datos')
        return

    available_times = sorted(data_high.keys(), key=lambda x: float(x))

    # Calcular densidad desde ecuacion de estado: p = rho * R * T
    R = 287  # J/(kg*K)

    # Crear figura con 4 subplots
    fig, axes = plt.subplots(2, 2, figsize=(14, 10), dpi=dpi)
    fig.patch.set_facecolor('white')

    # Configurar cada subplot
    ax_p = axes[0, 0]
    ax_rho = axes[0, 1]
    ax_T = axes[1, 0]
    ax_U = axes[1, 1]

    # Limites
    ax_p.set_xlim(-5, 5); ax_p.set_ylim(0, 110)
    ax_rho.set_xlim(-5, 5); ax_rho.set_ylim(0, 1.1)
    ax_T.set_xlim(-5, 5); ax_T.set_ylim(100, 400)
    ax_U.set_xlim(-5, 5); ax_U.set_ylim(-20, 350)

    # Etiquetas
    ax_p.set_xlabel(r'$x$ [m]'); ax_p.set_ylabel(r'$p$ [kPa]')
    ax_rho.set_xlabel(r'$x$ [m]'); ax_rho.set_ylabel(r'$\rho$ [kg/m$^3$]')
    ax_T.set_xlabel(r'$x$ [m]'); ax_T.set_ylabel(r'$T$ [K]')
    ax_U.set_xlabel(r'$x$ [m]'); ax_U.set_ylabel(r'$u$ [m/s]')

    ax_p.set_title('Presion')
    ax_rho.set_title('Densidad')
    ax_T.set_title('Temperatura')
    ax_U.set_title('Velocidad')

    for ax in axes.flat:
        ax.grid(True, alpha=0.3)

    # Lineas
    line_p, = ax_p.plot([], [], 'b-', lw=2)
    line_rho, = ax_rho.plot([], [], 'r-', lw=2)
    line_T, = ax_T.plot([], [], 'orange', lw=2)
    line_U, = ax_U.plot([], [], 'g-', lw=2)

    # Titulo principal
    suptitle = fig.suptitle('', fontsize=14, y=0.98)

    plt.tight_layout(rect=[0, 0, 1, 0.96])

    def init():
        for line in [line_p, line_rho, line_T, line_U]:
            line.set_data([], [])
        suptitle.set_text('')
        return line_p, line_rho, line_T, line_U, suptitle

    def animate(i):
        t = available_times[i]
        t_float = float(t)

        if t in data_high:
            x = data_high[t]['x']
            p = data_high[t]['p']
            T = data_high[t]['T']
            U = data_high[t]['U']
            rho = p / (R * T)

            line_p.set_data(x, p/1000)
            line_rho.set_data(x, rho)
            line_T.set_data(x, T)
            line_U.set_data(x, U)

        suptitle.set_text(f'Tubo de choque de Sod - Esquema linearUpwind - $t = {t_float:.2f}$ s')

        return line_p, line_rho, line_T, line_U, suptitle

    # Crear animacion
    print('Creando animacion multifield...')
    anim = animation.FuncAnimation(fig, animate, init_func=init,
                                   frames=len(available_times),
                                   interval=1000/fps, blit=True)

    # Guardar
    gif_path = os.path.join(fig_dir, 'shocktube_campos_evolucion.gif')
    print(f'Guardando: {gif_path}')

    try:
        writer = animation.PillowWriter(fps=fps)
        anim.save(gif_path, writer=writer, dpi=dpi)
        print(f'GIF multifield guardado: {gif_path}')
    except Exception as e:
        print(f'Error: {e}')

    plt.close(fig)


def create_paraview_temperature_gif():
    """Crea GIF a partir de frames de ParaView del campo de temperatura."""
    from PIL import Image

    frames_dir = os.path.join(fig_dir, 'pv_frames_T')
    gif_path = os.path.join(fig_dir, 'shocktube_temperatura_paraview.gif')

    print('Buscando frames de ParaView...')

    # Buscar frames
    frame_files = sorted(glob.glob(os.path.join(frames_dir, 'T_frame_*.png')))

    if not frame_files:
        print(f'No se encontraron frames en: {frames_dir}')
        print('Ejecute primero: pvpython pv_capture_temperature.py')
        return False

    print(f'Encontrados {len(frame_files)} frames')

    # Cargar frames
    frames = []
    for f in frame_files:
        img = Image.open(f)
        frames.append(img)

    # Crear GIF
    print(f'Creando GIF: {gif_path}')
    frames[0].save(
        gif_path,
        save_all=True,
        append_images=frames[1:],
        duration=int(1000/fps),
        loop=0
    )

    print(f'GIF de temperatura guardado: {gif_path}')
    return True


# =============================================================================
# EJECUCION PRINCIPAL
# =============================================================================

if __name__ == '__main__':
    print('='*60)
    print('Generacion de GIFs del tubo de choque')
    print('='*60)

    # GIF principal: evolucion de presion comparando esquemas
    create_pressure_gif()

    # GIF secundario: evolucion de todos los campos
    create_multifield_gif()

    # GIF de temperatura desde ParaView (si hay frames disponibles)
    print('\n' + '-'*60)
    create_paraview_temperature_gif()

    print('\n' + '='*60)
    print('Proceso completado')
    print(f'Directorio de salida: {fig_dir}')
    print('='*60)
