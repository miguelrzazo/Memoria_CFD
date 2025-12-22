#!/usr/bin/env pvpython
# -*- coding: utf-8 -*-
"""
Script ParaView - Ejercicio 5: Planar Couette Flow
Wall Functions Analysis - Low Reynolds vs High Reynolds
Re = 535000 (ultima cifra DNI = 7)

Ejecutar con: pvpython pv_capture_ejercicio5.py
"""

from paraview.simple import *
import os

# ============================================================
# CONFIGURACION
# ============================================================
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
OUTPUT_DIR = os.path.join(SCRIPT_DIR, '..', '..', 'figures', 'Ejercicio5')

# Casos
CASE_LOWRE = os.path.join(SCRIPT_DIR, 'planarCouette_LowRe')
CASE_HIGHRE = os.path.join(SCRIPT_DIR, 'planarCouette_HighRe')

# Crear directorio de salida
os.makedirs(OUTPUT_DIR, exist_ok=True)

# Configuracion de vista
VIEW_SIZE = [1600, 900]

print("=" * 60)
print("EJERCICIO 5: Planar Couette Flow - Wall Functions")
print("=" * 60)

def create_foam_file(case_path, case_name):
    """Crea archivo .foam si no existe"""
    foam_file = os.path.join(case_path, f'{case_name}.foam')
    if not os.path.exists(foam_file):
        open(foam_file, 'w').close()
    return foam_file

def load_case(case_path, case_name):
    """Carga un caso de OpenFOAM"""
    foam_file = create_foam_file(case_path, case_name)
    print(f"\nCargando: {foam_file}")

    reader = OpenFOAMReader(registrationName=case_name, FileName=foam_file)
    reader.MeshRegions = ['internalMesh']
    reader.CellArrays = ['U', 'k', 'nut', 'epsilon', 'p']

    # Actualizar y obtener ultimo tiempo
    reader.UpdatePipeline()
    times = reader.TimestepValues
    if len(times) > 0:
        latest_time = times[-1]
        reader.UpdatePipeline(time=latest_time)
        print(f"  Tiempo final: {latest_time}")

    return reader

def capture_field(reader, field_name, case_name, colormap='Rainbow Uniform'):
    """Captura un campo escalar o vectorial"""

    view = GetActiveViewOrCreate('RenderView')
    view.ViewSize = VIEW_SIZE
    view.Background = [1, 1, 1]

    display = Show(reader, view)
    display.Representation = 'Surface'

    if field_name == 'U':
        ColorBy(display, ('CELLS', 'U', 'Magnitude'))
        lut = GetColorTransferFunction('U')
        lut.RescaleTransferFunction(0.0, 10.0)
    else:
        ColorBy(display, ('CELLS', field_name))
        lut = GetColorTransferFunction(field_name)

    lut.ApplyPreset(colormap, True)

    # Barra de color
    colorBar = GetScalarBar(lut, view)
    colorBar.Title = field_name if field_name != 'U' else '|U| [m/s]'
    colorBar.ComponentTitle = ''
    colorBar.Visibility = 1
    colorBar.TitleFontSize = 16
    colorBar.LabelFontSize = 14

    # Vista 2D del canal
    view.InteractionMode = '2D'
    view.CameraPosition = [0.05, 0.05, 1.0]
    view.CameraFocalPoint = [0.05, 0.05, 0.0]
    view.CameraViewUp = [0.0, 1.0, 0.0]
    view.CameraParallelScale = 0.055
    view.CameraParallelProjection = 1

    Render()

    # Guardar
    output_file = os.path.join(OUTPUT_DIR, f'{field_name}_{case_name}.png')
    SaveScreenshot(output_file, view, ImageResolution=VIEW_SIZE, TransparentBackground=0)
    print(f"  Guardada: {os.path.basename(output_file)}")

    Hide(reader, view)
    return output_file

def capture_mesh(reader, case_name, zoom_wall=False):
    """Captura la malla"""

    view = GetActiveViewOrCreate('RenderView')
    view.ViewSize = VIEW_SIZE
    view.Background = [1, 1, 1]

    display = Show(reader, view)
    display.Representation = 'Wireframe'
    display.AmbientColor = [0, 0, 0]
    display.DiffuseColor = [0, 0, 0]
    display.LineWidth = 1.0

    view.InteractionMode = '2D'
    view.CameraParallelProjection = 1

    if zoom_wall:
        # Zoom cerca de la pared inferior
        view.CameraPosition = [0.05, 0.01, 0.5]
        view.CameraFocalPoint = [0.05, 0.01, 0.0]
        view.CameraParallelScale = 0.015
        suffix = 'detalle'
    else:
        # Vista completa
        view.CameraPosition = [0.05, 0.05, 1.0]
        view.CameraFocalPoint = [0.05, 0.05, 0.0]
        view.CameraParallelScale = 0.055
        suffix = 'completa'

    view.CameraViewUp = [0.0, 1.0, 0.0]

    Render()

    output_file = os.path.join(OUTPUT_DIR, f'malla_{suffix}_{case_name}.png')
    SaveScreenshot(output_file, view, ImageResolution=VIEW_SIZE, TransparentBackground=0)
    print(f"  Guardada: {os.path.basename(output_file)}")

    Hide(reader, view)
    return output_file

# ============================================================
# MAIN
# ============================================================

# Verificar casos
if not os.path.exists(CASE_LOWRE):
    print(f"ERROR: No se encuentra {CASE_LOWRE}")
    exit(1)
if not os.path.exists(CASE_HIGHRE):
    print(f"ERROR: No se encuentra {CASE_HIGHRE}")
    exit(1)

# Cargar casos
print("\n[1/4] Cargando casos...")
data_lowRe = load_case(CASE_LOWRE, 'planarCouette_LowRe')
data_highRe = load_case(CASE_HIGHRE, 'planarCouette_HighRe')

# Capturar campos - Low-Re
print("\n[2/4] Capturando campos Low-Re...")
for field, cmap in [('U', 'Rainbow Uniform'), ('k', 'Cool to Warm'), ('nut', 'Viridis (matplotlib)')]:
    capture_field(data_lowRe, field, 'lowRe', cmap)

# Capturar campos - High-Re
print("\n[3/4] Capturando campos High-Re...")
for field, cmap in [('U', 'Rainbow Uniform'), ('k', 'Cool to Warm'), ('nut', 'Viridis (matplotlib)')]:
    capture_field(data_highRe, field, 'highRe', cmap)

# Capturar mallas
print("\n[4/4] Capturando mallas...")
capture_mesh(data_lowRe, 'lowRe', zoom_wall=False)
capture_mesh(data_lowRe, 'lowRe', zoom_wall=True)
capture_mesh(data_highRe, 'highRe', zoom_wall=False)
capture_mesh(data_highRe, 'highRe', zoom_wall=True)

# Resumen
print("\n" + "=" * 60)
print("CAPTURAS COMPLETADAS")
print("=" * 60)
print(f"\nDirectorio: {OUTPUT_DIR}")
print("\nArchivos generados:")
for f in sorted(os.listdir(OUTPUT_DIR)):
    if f.endswith('.png'):
        print(f"  - {f}")
