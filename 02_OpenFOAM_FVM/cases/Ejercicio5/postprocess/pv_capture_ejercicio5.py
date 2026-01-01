#!/usr/bin/env pvpython
# -*- coding: utf-8 -*-
"""
Script ParaView - Ejercicio 5: Flujo Couette Turbulento
Captura de campos de velocidad para Low-Re y High-Re

Ejecutar con: pvpython pv_capture_ejercicio5.py
"""

from paraview.simple import *
import os
import sys

# ============================================================
# CONFIGURACION
# ============================================================
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
CASES_DIR = os.path.dirname(SCRIPT_DIR)
OUTPUT_DIR = os.path.join(os.path.dirname(os.path.dirname(CASES_DIR)), 'figures', 'Ejercicio5')

CASES = {
    'Low_Re': os.path.join(CASES_DIR, 'couetteLowRe'),
    'High_Re': os.path.join(CASES_DIR, 'couetteHighRe'),
}

os.makedirs(OUTPUT_DIR, exist_ok=True)

VIEW_SIZE = [1400, 600]

print("=" * 70)
print("EJERCICIO 5: Flujo Couette Turbulento")
print("Capturas de campos de velocidad")
print("=" * 70)

def create_foam_file(case_path):
    """Crea archivo .foam si no existe"""
    foam_file = os.path.join(case_path, f'{os.path.basename(case_path)}.foam')
    if not os.path.exists(foam_file):
        open(foam_file, 'w').close()
    return foam_file

def load_case(case_path):
    """Carga un caso de OpenFOAM"""
    case_name = os.path.basename(case_path)
    foam_file = create_foam_file(case_path)
    print(f"  Cargando: {case_name}")

    reader = OpenFOAMReader(registrationName=case_name, FileName=foam_file)
    reader.MeshRegions = ['internalMesh']
    reader.CellArrays = ['U', 'p', 'k', 'epsilon', 'nut']

    reader.UpdatePipeline()
    times = reader.TimestepValues
    if len(times) > 0:
        latest_time = times[-1]
        reader.UpdatePipeline(time=latest_time)
        print(f"    Tiempo: {latest_time}")

    return reader

def setup_view(renderView, zoom_factor=1.0):
    """Configura la vista para el canal Couette"""
    # El canal es de 1m x 0.1m. Centrado en (0.5, 0.05)
    renderView.CameraPosition = [0.05, 0.05, 0.5]
    renderView.CameraFocalPoint = [0.05, 0.05, 0.0]
    renderView.CameraViewUp = [0, 1, 0]
    renderView.CameraParallelProjection = 1
    renderView.CameraParallelScale = 0.06 / zoom_factor
    Render(renderView)

def capture_velocity_field(case_name, case_path):
    """Captura el campo de velocidad"""
    print(f"\n  Capturando campo de velocidad: {case_name}")
    
    reader = load_case(case_path)
    
    # Crear vista
    renderView = CreateView('RenderView')
    renderView.ViewSize = VIEW_SIZE
    renderView.InteractionMode = '2D'
    renderView.OrientationAxesVisibility = 0
    renderView.Background = [1, 1, 1] # Blanco
    
    # Mostrar datos directamente (U magnitud)
    display = Show(reader, renderView)
    display.Representation = 'Surface'
    
    # Verificar rango de datos
    info = reader.GetDataInformation().DataInformation
    bounds = info.GetBounds()
    print(f"    Bounds: {bounds}")
    
    # Configurar colores usando la magnitud de U directamente del reader
    ColorBy(display, ('CELLS', 'U'))
    uLUT = GetColorTransferFunction('U')
    uLUT.ApplyPreset('Rainbow Desaturated', True)
    uLUT.RescaleTransferFunction(0.0, 10.0)
    
    # Colorbar
    colorbar = GetScalarBar(uLUT, renderView)
    colorbar.Title = 'U (m/s)'
    colorbar.ComponentTitle = 'Magnitude'
    colorbar.TitleColor = [0, 0, 0]
    colorbar.LabelColor = [0, 0, 0]
    colorbar.ScalarBarLength = 0.6
    display.SetScalarBarVisibility(renderView, True)
    
    # Configurar vista
    setup_view(renderView, zoom_factor=1.0)
    
    # Guardar
    output_file = os.path.join(OUTPUT_DIR, f'Ej5_velocity_{case_name}.png')
    SaveScreenshot(output_file, renderView, ImageResolution=VIEW_SIZE)
    print(f"    Guardado: {output_file}")
    
    Delete(renderView)
    Delete(reader)

def capture_turbulence_field(case_name, case_path, field='k'):
    """Captura campos de turbulencia (k, epsilon, nut)"""
    print(f"\n  Capturando campo {field}: {case_name}")
    
    reader = load_case(case_path)
    
    # Crear vista
    renderView = CreateView('RenderView')
    renderView.ViewSize = VIEW_SIZE
    renderView.InteractionMode = '2D'
    renderView.OrientationAxesVisibility = 0
    renderView.Background = [1, 1, 1]
    
    # Mostrar datos
    display = Show(reader, renderView)
    display.Representation = 'Surface'
    
    # Verificar rango de datos
    info = reader.GetDataInformation().DataInformation
    bounds = info.GetBounds()
    print(f"    Bounds: {bounds}")
    
    # Configurar colores
    ColorBy(display, ('CELLS', field))
    fieldLUT = GetColorTransferFunction(field)
    fieldLUT.ApplyPreset('Viridis (matplotlib)', True)
    
    # Obtener rango de datos y asegurar que no es cero/invalido
    import math
    rng = info.GetCellDataInformation().GetArrayInformation(field).GetComponentRange(0)
    print(f"    Rango {field}: {rng}")
    
    if rng[1] > rng[0]:
        fieldLUT.RescaleTransferFunction(rng[0], rng[1])
    else:
        fieldLUT.RescaleTransferFunction(0, 1e-6) # Fallback
    
    # Colorbar
    colorbar = GetScalarBar(fieldLUT, renderView)
    colorbar.TitleColor = [0, 0, 0]
    colorbar.LabelColor = [0, 0, 0]
    
    if field == 'k':
        colorbar.Title = 'k (m2/s2)'
    elif field == 'epsilon':
        colorbar.Title = 'eps (m2/s3)'
    elif field == 'nut':
        colorbar.Title = 'nut (m2/s)'
    
    display.SetScalarBarVisibility(renderView, True)
    
    # Configurar vista
    setup_view(renderView, zoom_factor=1.0)
    
    # Guardar
    output_file = os.path.join(OUTPUT_DIR, f'Ej5_{field}_{case_name}.png')
    SaveScreenshot(output_file, renderView, ImageResolution=VIEW_SIZE)
    print(f"    Guardado: {output_file}")
    
    Delete(renderView)
    Delete(reader)

# ============================================================
# EJECUCION PRINCIPAL
# ============================================================
if __name__ == "__main__":
    print("\n[1/6] Capturando campos de velocidad...")
    for case_name, case_path in CASES.items():
        capture_velocity_field(case_name, case_path)
    
    print("\n[2/6] Capturando campos de energía cinética turbulenta (k)...")
    for case_name, case_path in CASES.items():
        capture_turbulence_field(case_name, case_path, field='k')
    
    print("\n[3/6] Capturando campos de viscosidad turbulenta (nut)...")
    for case_name, case_path in CASES.items():
        capture_turbulence_field(case_name, case_path, field='nut')
    
    print("\n" + "=" * 70)
    print("COMPLETADO - Todas las capturas generadas")
    print(f"Directorio de salida: {OUTPUT_DIR}")
    print("=" * 70)
