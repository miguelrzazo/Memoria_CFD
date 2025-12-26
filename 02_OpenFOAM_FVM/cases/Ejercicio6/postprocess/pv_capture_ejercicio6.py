#!/usr/bin/env pvpython
# -*- coding: utf-8 -*-
"""
Script ParaView - Ejercicio 6: Convergencia de Malla
Captura de mallas y campos de flujo para Re=1, cilindro 2D

Este script unificado genera:
1. Capturas de mallas (coarse, medium, fine) - vista general y detalle
2. Campos de velocidad y presion para malla fina
3. Campos de velocidad y presion para diferentes angulos de ataque

Ejecutar con: pvpython pv_capture_ejercicio6.py
"""

from paraview.simple import *
import os

# ============================================================
# CONFIGURACION
# ============================================================
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
CASES_DIR = os.path.dirname(SCRIPT_DIR)  # Directorio padre donde estan los casos
OUTPUT_DIR = os.path.join(os.path.dirname(os.path.dirname(CASES_DIR)), 'figures', 'Ejercicio6')

# Casos de convergencia de malla
MESH_CASES = {
    'coarse': os.path.join(CASES_DIR, 'cylinder_coarse'),
    'medium': os.path.join(CASES_DIR, 'cylinder_medium'),
    'fine': os.path.join(CASES_DIR, 'cylinder_fine'),
}

# Casos de diferentes angulos de ataque
ANGLE_CASES = {
    'alpha_0': os.path.join(CASES_DIR, 'cylinder_fine'),
    'alpha_neg5': os.path.join(CASES_DIR, 'cylinder_fine_alpha_neg5'),
    'alpha_pos5': os.path.join(CASES_DIR, 'cylinder_fine_alpha_pos5'),
}

# Crear directorio de salida
os.makedirs(OUTPUT_DIR, exist_ok=True)

# Configuracion de vista
VIEW_SIZE = [1400, 900]

# Distancias de camara para diferentes vistas
ZOOM_DOMAIN_FULL = 30   # Vista completa del dominio (200D x 200D)
ZOOM_CYLINDER_REGION = 190   # Vista del cilindro con algo de entorno (para velocity/pressure)
ZOOM_VELOCITY = 60     # Vista específica para campos de velocidad
ZOOM_DETAIL = 5         # Vista detalle del cilindro (para malla)

print("=" * 70)
print("EJERCICIO 6: Convergencia de Malla - Cilindro Re=1")
print("Script unificado de capturas ParaView")
print("=" * 70)

def create_foam_file(case_path, case_name):
    """Crea archivo .foam si no existe"""
    foam_file = os.path.join(case_path, f'{os.path.basename(case_path)}.foam')
    if not os.path.exists(foam_file):
        open(foam_file, 'w').close()
    return foam_file

def load_case(case_path):
    """Carga un caso de OpenFOAM"""
    case_name = os.path.basename(case_path)
    foam_file = create_foam_file(case_path, case_name)
    print(f"  Cargando: {case_name}")

    reader = OpenFOAMReader(registrationName=case_name, FileName=foam_file)
    reader.MeshRegions = ['internalMesh']
    reader.CellArrays = ['U', 'p']

    reader.UpdatePipeline()
    times = reader.TimestepValues
    if len(times) > 0:
        latest_time = times[-1]
        reader.UpdatePipeline(time=latest_time)
        print(f"    Tiempo: {latest_time}")

    return reader

def setup_view():
    """Configura la vista de renderizado"""
    view = GetActiveViewOrCreate('RenderView')
    view.ViewSize = VIEW_SIZE
    view.Background = [1, 1, 1]
    return view

def set_camera(view, zoom_level):
    """Configura la camara para una vista determinada"""
    view.CameraPosition = [0, 0, zoom_level]
    view.CameraFocalPoint = [0, 0, 0]
    view.CameraViewUp = [0, 1, 0]
    Render()

def capture_mesh(reader, case_name):
    """Captura la malla en modo wireframe - vista general y detalle"""
    view = setup_view()

    display = Show(reader, view)
    display.Representation = 'Wireframe'
    display.AmbientColor = [0.2, 0.2, 0.2]
    display.DiffuseColor = [0.2, 0.2, 0.2]
    display.LineWidth = 1.0

    # Vista general del dominio completo
    view.ResetCamera()
    set_camera(view, ZOOM_DOMAIN_FULL)

    output_file = os.path.join(OUTPUT_DIR, f'malla_{case_name}_vista_general.png')
    SaveScreenshot(output_file, view, ImageResolution=VIEW_SIZE, TransparentBackground=0)
    print(f"    Guardada: malla_{case_name}_vista_general.png")

    # Vista detalle cerca del cilindro
    set_camera(view, ZOOM_DETAIL)

    output_file = os.path.join(OUTPUT_DIR, f'malla_{case_name}_detalle.png')
    SaveScreenshot(output_file, view, ImageResolution=VIEW_SIZE, TransparentBackground=0)
    print(f"    Guardada: malla_{case_name}_detalle.png")

    Hide(reader, view)
    Delete(reader)

def capture_velocity_field(reader, output_name, zoom_level=ZOOM_VELOCITY):
    """Captura el campo de velocidad (magnitud)"""
    view = setup_view()

    display = Show(reader, view)
    display.Representation = 'Surface'

    ColorBy(display, ('CELLS', 'U', 'Magnitude'))
    lut = GetColorTransferFunction('U')
    lut.RescaleTransferFunction(0.0, 1.5)
    lut.ApplyPreset('Rainbow Uniform', True)

    colorBar = GetScalarBar(lut, view)
    colorBar.Title = '|U| [m/s]'
    colorBar.ComponentTitle = ''
    colorBar.Visibility = 1
    colorBar.TitleFontSize = 14
    colorBar.LabelFontSize = 12

    view.ResetCamera()
    set_camera(view, zoom_level)

    output_file = os.path.join(OUTPUT_DIR, f'velocidad_{output_name}.png')
    SaveScreenshot(output_file, view, ImageResolution=VIEW_SIZE, TransparentBackground=0)
    print(f"    Guardada: velocidad_{output_name}.png")

    Hide(reader, view)

def capture_pressure_field(reader, output_name, zoom_level=ZOOM_CYLINDER_REGION):
    """Captura el campo de presion"""
    view = setup_view()

    display = Show(reader, view)
    display.Representation = 'Surface'

    ColorBy(display, ('CELLS', 'p'))
    lut = GetColorTransferFunction('p')
    lut.ApplyPreset('Cool to Warm', True)

    colorBar = GetScalarBar(lut, view)
    colorBar.Title = 'p [Pa]'
    colorBar.ComponentTitle = ''
    colorBar.Visibility = 1
    colorBar.TitleFontSize = 14
    colorBar.LabelFontSize = 12

    view.ResetCamera()
    set_camera(view, zoom_level)

    output_file = os.path.join(OUTPUT_DIR, f'presion_{output_name}.png')
    SaveScreenshot(output_file, view, ImageResolution=VIEW_SIZE, TransparentBackground=0)
    print(f"    Guardada: presion_{output_name}.png")

    Hide(reader, view)

# ============================================================
# MAIN - EJECUCION SECUENCIAL
# ============================================================

# PARTE 1: Capturas de mallas para estudio de convergencia
print("\n[1/3] Capturando mallas de convergencia...")
for case_key, case_path in MESH_CASES.items():
    if os.path.exists(case_path):
        print(f"\n  Caso: {case_key}")
        data = load_case(case_path)
        capture_mesh(data, case_key)
    else:
        print(f"  ADVERTENCIA: No se encuentra {case_path}")

# PARTE 2: Campos de velocidad y presion para malla fina
print("\n[2/3] Capturando campos de flujo (malla fina)...")
fine_path = MESH_CASES['fine']
if os.path.exists(fine_path):
    data = load_case(fine_path)
    capture_velocity_field(data, 'fine')  # Usa ZOOM_VELOCITY por defecto
    capture_pressure_field(data, 'fine', ZOOM_DETAIL)  # Más zoom para presión
    Delete(data)

# PARTE 3: Campos para diferentes angulos de ataque
print("\n[3/3] Capturando campos para diferentes angulos de ataque...")
for angle_name, case_path in ANGLE_CASES.items():
    if os.path.exists(case_path):
        print(f"\n  Caso: {angle_name}")
        data = load_case(case_path)
        capture_velocity_field(data, angle_name)  # Usa ZOOM_VELOCITY por defecto
        capture_pressure_field(data, angle_name, ZOOM_DETAIL)  # Más zoom para presión
        Delete(data)
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
