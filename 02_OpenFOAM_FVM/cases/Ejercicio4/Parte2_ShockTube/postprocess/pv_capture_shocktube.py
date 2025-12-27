#!/usr/bin/env pvpython
"""
pv_capture_shocktube.py - Captura de campos del tubo de choque con ParaView

Este script genera capturas de los campos de presion, densidad, velocidad y
temperatura para el problema del tubo de choque de Sod.

Uso:
    /Applications/ParaView-6.0.1.app/Contents/bin/pvpython pv_capture_shocktube.py

O ejecutar desde el directorio del caso.
"""

from paraview.simple import *
import os
import sys

# Desactivar GUI
paraview.simple._DisableFirstRenderCameraReset()

# =============================================================================
# CONFIGURACION
# =============================================================================

# Directorios
script_dir = os.path.dirname(os.path.abspath(__file__))
case_base = os.path.dirname(script_dir)
fig_dir = os.path.join(case_base, '..', '..', '..', 'figures', 'Ejercicio4')

# Crear directorio de salida si no existe
if not os.path.exists(fig_dir):
    os.makedirs(fig_dir)

# Casos a procesar
cases = {
    'highorder': os.path.join(case_base, 'shockTube_highorder'),
    'loworder': os.path.join(case_base, 'shockTube_loworder')
}

# Tiempos de captura (0 a 0.007 s en pasos de 0.0005 s)
# Tiempo adimensional: t* = t * a_L / L = t * 374.17 / 10
capture_times = [0.0, 0.0005, 0.001, 0.0015, 0.002, 0.0025, 0.003,
                 0.0035, 0.004, 0.0045, 0.005, 0.0055, 0.006, 0.0065, 0.007]

# Configuracion de visualizacion
view_size = [1920, 400]  # Ancho x alto para tubo 1D
colorbar_position = [0.85, 0.25]

# Rangos de colores para cada campo
color_ranges = {
    'p': [10000, 100000],     # Pa
    'T': [200, 400],          # K
    'U': [0, 350],            # m/s (magnitud)
    'rho': [0.125, 1.0]       # kg/m^3
}

# Colormaps
colormaps = {
    'p': 'Cool to Warm',
    'T': 'Inferno (matplotlib)',
    'U': 'Viridis (matplotlib)',
    'rho': 'Plasma (matplotlib)'
}

# =============================================================================
# FUNCIONES
# =============================================================================

def create_foam_reader(case_path):
    """Crea un lector OpenFOAM para el caso dado."""
    foam_file = os.path.join(case_path, 'shockTube.foam')

    # Crear archivo .foam si no existe
    if not os.path.exists(foam_file):
        # Intentar con nombre generico
        foam_file = os.path.join(case_path, 'case.foam')
        if not os.path.exists(foam_file):
            open(foam_file, 'w').close()

    reader = OpenFOAMReader(FileName=foam_file)
    reader.CaseType = 'Reconstructed Case'
    reader.MeshRegions = ['internalMesh']
    reader.CellArrays = ['p', 'T', 'U', 'rho']

    return reader


def setup_view():
    """Configura la vista para visualizacion 1D (tubo horizontal)."""
    view = GetActiveViewOrCreate('RenderView')
    view.ViewSize = view_size
    view.Background = [1, 1, 1]  # Fondo blanco

    # Camara para ver el tubo desde arriba
    view.CameraPosition = [0, 0, 15]
    view.CameraFocalPoint = [0, 0, 0]
    view.CameraViewUp = [0, 1, 0]
    view.CameraParallelScale = 5.5
    view.CameraParallelProjection = 1

    return view


def apply_color_map(display, field, component=None):
    """Aplica el mapa de colores apropiado al campo."""
    if field == 'U':
        ColorBy(display, ('CELLS', 'U', 'Magnitude'))
    else:
        ColorBy(display, ('CELLS', field))

    # Obtener la barra de transferencia de colores
    lut = GetColorTransferFunction(field)

    # Configurar rango
    if field in color_ranges:
        lut.RescaleTransferFunction(color_ranges[field][0], color_ranges[field][1])

    # Aplicar colormap
    if field in colormaps:
        lut.ApplyPreset(colormaps[field], True)

    return lut


def add_colorbar(display, field, view):
    """Anade barra de colores a la visualizacion."""
    lut = GetColorTransferFunction(field)

    colorbar = GetScalarBar(lut, view)
    colorbar.Title = get_field_label(field)
    colorbar.ComponentTitle = ''
    colorbar.TitleFontSize = 16
    colorbar.LabelFontSize = 14
    colorbar.Position = colorbar_position
    colorbar.ScalarBarLength = 0.5
    colorbar.TitleColor = [0, 0, 0]
    colorbar.LabelColor = [0, 0, 0]
    colorbar.Visibility = 1

    return colorbar


def get_field_label(field):
    """Devuelve la etiqueta formateada para cada campo."""
    labels = {
        'p': 'Presion [Pa]',
        'T': 'Temperatura [K]',
        'U': 'Velocidad [m/s]',
        'rho': 'Densidad [kg/m^3]'
    }
    return labels.get(field, field)


def capture_field(reader, field, time, case_name, view, time_index):
    """Captura un campo especifico a un tiempo dado."""
    # Actualizar tiempo
    reader.UpdatePipeline(time)

    # Mostrar datos
    display = Show(reader, view)
    display.Representation = '3D Glyphs' if field == 'U' else 'Surface'

    # Aplicar colormap
    apply_color_map(display, field)
    add_colorbar(display, field, view)

    # Renderizar
    Render()

    # Nombre del archivo (usar indice para evitar problemas con decimales)
    filename = os.path.join(fig_dir, f'shocktube_{case_name}_{field}_{time_index:02d}.png')

    # Guardar imagen
    SaveScreenshot(filename, view, ImageResolution=view_size,
                   TransparentBackground=0)

    # Calcular tiempo adimensional para log
    t_star = time * 374.17 / 10.0
    print(f'  Guardado: {os.path.basename(filename)} (t={time:.4f}s, t*={t_star:.3f})')

    # Limpiar
    Hide(reader, view)


def capture_all_times(case_name, case_path, field='p'):
    """Captura un campo para todos los tiempos de un caso."""
    print(f'\nProcesando caso: {case_name}')
    print(f'  Campo: {field}')

    # Crear lector
    reader = create_foam_reader(case_path)

    # Configurar vista
    view = setup_view()

    # Obtener tiempos disponibles
    animationScene = GetAnimationScene()
    animationScene.UpdateAnimationUsingDataTimeSteps()

    # Capturar cada tiempo
    for i, t in enumerate(capture_times):
        try:
            capture_field(reader, field, t, case_name, view, i)
        except Exception as e:
            print(f'  Error en t={t}: {e}')

    # Limpiar
    Delete(reader)
    del reader


# =============================================================================
# EJECUCION PRINCIPAL
# =============================================================================

if __name__ == '__main__':
    print('='*60)
    print('Captura de campos del tubo de choque de Sod')
    print('='*60)

    # Procesar solo el caso de alto orden para la presion (usado en el GIF)
    field = 'p'  # Campo principal para el GIF

    for case_name, case_path in cases.items():
        if os.path.exists(case_path):
            capture_all_times(case_name, case_path, field)
        else:
            print(f'Caso no encontrado: {case_path}')

    print('\n' + '='*60)
    print('Capturas completadas')
    print(f'Directorio de salida: {fig_dir}')
    print('='*60)
