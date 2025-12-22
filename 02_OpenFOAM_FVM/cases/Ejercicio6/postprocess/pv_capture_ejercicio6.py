#!/usr/bin/env pvpython
# -*- coding: utf-8 -*-
"""
Script ParaView - Ejercicio 6: Convergencia de Malla
Captura de mallas y campos de flujo para Re=1, cilindro 2D

Ejecutar con: pvpython pv_capture_ejercicio6.py
"""

from paraview.simple import *
import os

# ============================================================
# CONFIGURACION
# ============================================================
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
OUTPUT_DIR = os.path.join(SCRIPT_DIR, '../../figures/Ejercicio6')

# Casos a visualizar
CASES = {
    'coarse': os.path.join(SCRIPT_DIR, 'cylinder_coarse'),
    'medium': os.path.join(SCRIPT_DIR, 'cylinder_medium'),
    'fine': os.path.join(SCRIPT_DIR, 'cylinder_fine'),
}

# Crear directorio de salida
os.makedirs(OUTPUT_DIR, exist_ok=True)

# Configuracion de vista
VIEW_SIZE = [1400, 900]

print("=" * 70)
print("EJERCICIO 6: Convergencia de Malla - Cilindro Re=1")
print("=" * 70)

def create_foam_file(case_path, case_name):
    """Crea archivo .foam si no existe"""
    foam_file = os.path.join(case_path, f'{case_name}.foam')
    if not os.path.exists(foam_file):
        open(foam_file, 'w').close()
    return foam_file

def load_case(case_path, case_name):
    """Carga un caso de OpenFOAM"""
    foam_file = create_foam_file(case_path, case_name)
    print(f"\nCargando: {case_name}")
    print(f"  Ruta: {foam_file}")

    reader = OpenFOAMReader(registrationName=case_name, FileName=foam_file)
    reader.MeshRegions = ['internalMesh']
    reader.CellArrays = ['U', 'p']

    # Actualizar y obtener ultimo tiempo
    reader.UpdatePipeline()
    times = reader.TimestepValues
    if len(times) > 0:
        latest_time = times[-1]
        reader.UpdatePipeline(time=latest_time)
        print(f"  Tiempo final: {latest_time}")
    else:
        print(f"  Advertencia: No se encontraron timesteps")

    return reader

def capture_mesh(reader, case_name):
    """Captura la malla en modo wireframe"""
    view = GetActiveViewOrCreate('RenderView')
    view.ViewSize = VIEW_SIZE
    view.Background = [1, 1, 1]

    display = Show(reader, view)
    display.Representation = 'Wireframe'
    display.AmbientColor = [0.2, 0.2, 0.2]
    display.DiffuseColor = [0.2, 0.2, 0.2]
    display.LineWidth = 1.0

    # Vista general del dominio (zoom out)
    view.ResetCamera()
    view.CameraPosition = [0, 0, 150]
    view.CameraFocalPoint = [0, 0, 0]
    view.CameraViewUp = [0, 1, 0]

    Render()

    output_file = os.path.join(OUTPUT_DIR, f'malla_{case_name}_vista_general.png')
    SaveScreenshot(output_file, view, ImageResolution=VIEW_SIZE, TransparentBackground=0)
    print(f"  Guardada: malla_{case_name}_vista_general.png")

    # Vista detalle cerca del cilindro
    view.CameraPosition = [0, 0, 2.5]
    view.CameraFocalPoint = [0, 0, 0]
    view.CameraViewUp = [0, 1, 0]

    Render()

    output_file = os.path.join(OUTPUT_DIR, f'malla_{case_name}_detalle.png')
    SaveScreenshot(output_file, view, ImageResolution=VIEW_SIZE, TransparentBackground=0)
    print(f"  Guardada: malla_{case_name}_detalle.png")

    Hide(reader, view)

def capture_velocity_field(reader, case_name):
    """Captura el campo de velocidad (magnitud)"""
    view = GetActiveViewOrCreate('RenderView')
    view.ViewSize = VIEW_SIZE
    view.Background = [1, 1, 1]

    display = Show(reader, view)
    display.Representation = 'Surface'

    # Colorear por magnitud de velocidad
    ColorBy(display, ('CELLS', 'U', 'Magnitude'))
    lut = GetColorTransferFunction('U')
    lut.RescaleTransferFunction(0.0, 1.5)
    lut.ApplyPreset('Rainbow Uniform', True)

    # Barra de color
    colorBar = GetScalarBar(lut, view)
    colorBar.Title = '|U| [m/s]'
    colorBar.ComponentTitle = ''
    colorBar.Visibility = 1
    colorBar.TitleFontSize = 14
    colorBar.LabelFontSize = 12

    # Vista del dominio - AJUSTADA para mejor visualización
    # Zoom intermedio para mostrar cilindro y estela completa
    view.ResetCamera()
    view.CameraPosition = [0, 0, 250]
    view.CameraFocalPoint = [0, 0, 0]
    view.CameraViewUp = [0, 1, 0]

    Render()

    output_file = os.path.join(OUTPUT_DIR, f'velocidad_{case_name}.png')
    SaveScreenshot(output_file, view, ImageResolution=VIEW_SIZE, TransparentBackground=0)
    print(f"  Guardada: velocidad_{case_name}.png")

    Hide(reader, view)

def capture_pressure_field(reader, case_name):
    """Captura el campo de presión"""
    view = GetActiveViewOrCreate('RenderView')
    view.ViewSize = VIEW_SIZE
    view.Background = [1, 1, 1]

    display = Show(reader, view)
    display.Representation = 'Surface'

    # Colorear por presión
    ColorBy(display, ('CELLS', 'p'))
    lut = GetColorTransferFunction('p')
    lut.ApplyPreset('Cool to Warm', True)

    # Barra de color
    colorBar = GetScalarBar(lut, view)
    colorBar.Title = 'p [Pa]'
    colorBar.ComponentTitle = ''
    colorBar.Visibility = 1
    colorBar.TitleFontSize = 14
    colorBar.LabelFontSize = 12

    # Vista del dominio - AJUSTADA para mejor visualización
    # Zoom in para mostrar el cilindro y gradientes de presión
    view.ResetCamera()
    view.CameraPosition = [0, 0, 130]
    view.CameraFocalPoint = [0, 0, 0]
    view.CameraViewUp = [0, 1, 0]

    Render()

    output_file = os.path.join(OUTPUT_DIR, f'presion_{case_name}.png')
    SaveScreenshot(output_file, view, ImageResolution=VIEW_SIZE, TransparentBackground=0)
    print(f"  Guardada: presion_{case_name}.png")

    Hide(reader, view)

# ============================================================
# MAIN
# ============================================================

print("\n[1/3] Capturando mallas...")
for case_key, case_path in CASES.items():
    if os.path.exists(case_path):
        data = load_case(case_path, case_key)
        capture_mesh(data, case_key)
    else:
        print(f"  ADVERTENCIA: No se encuentra {case_path}")

print("\n[2/3] Capturando campo de velocidad (malla fina)...")
case_path = CASES['fine']
if os.path.exists(case_path):
    data = load_case(case_path, 'fine')
    capture_velocity_field(data, 'fine')
else:
    print(f"  ADVERTENCIA: No se encuentra {case_path}")

print("\n[3/3] Capturando campo de presión (malla fina)...")
case_path = CASES['fine']
if os.path.exists(case_path):
    data = load_case(case_path, 'fine')
    capture_pressure_field(data, 'fine')
else:
    print(f"  ADVERTENCIA: No se encuentra {case_path}")

# Resumen
print("\n" + "=" * 70)
print("CAPTURAS COMPLETADAS")
print("=" * 70)
print(f"\nDirectorio: {OUTPUT_DIR}")
print("\nArchivos generados:")
for f in sorted(os.listdir(OUTPUT_DIR)):
    if f.endswith('.png'):
        print(f"  - {f}")

print("\n")
