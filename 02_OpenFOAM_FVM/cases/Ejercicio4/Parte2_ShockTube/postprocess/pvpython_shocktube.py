#!/usr/bin/env pvpython
"""
EJERCICIO 4 - PARTE 2: Capturas de ParaView para tubo de choque de Sod
Genera capturas de campos de presion, temperatura y velocidad para
los casos de alto orden (vanAlbada) y bajo orden (upwind).

Autor: Miguel Rosa
Fecha: Diciembre 2025

Uso:
    pvpython pvpython_shocktube.py
"""

from paraview.simple import *
import os
import sys

# Configuracion de rutas
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
BASE_DIR = os.path.dirname(SCRIPT_DIR)
HIGH_ORDER_DIR = os.path.join(BASE_DIR, 'shockTube_highOrder')
LOW_ORDER_DIR = os.path.join(BASE_DIR, 'shockTube_lowOrder')
OUTPUT_DIR = os.path.join(os.path.dirname(BASE_DIR), '..', 'figures', 'Ejercicio4')

# Crear directorio de salida si no existe
os.makedirs(OUTPUT_DIR, exist_ok=True)

# Tiempos de interes
TIMES = [0.01, 0.05, 0.10, 0.15]

def create_foam_file(case_dir):
    """Crear archivo .foam para ParaView"""
    foam_file = os.path.join(case_dir, 'case.foam')
    if not os.path.exists(foam_file):
        open(foam_file, 'w').close()
    return foam_file

def capture_field_slice(reader, field_name, time, output_path, title=""):
    """Captura un campo como slice 2D"""
    # Actualizar tiempo
    animationScene = GetAnimationScene()
    animationScene.UpdateAnimationUsingDataTimeSteps()

    # Encontrar el tiempo mas cercano
    times = reader.TimestepValues
    closest_time = min(times, key=lambda t: abs(t - time))
    animationScene.AnimationTime = closest_time

    # Crear slice en el plano z=0
    slice1 = Slice(Input=reader)
    slice1.SliceType = 'Plane'
    slice1.SliceType.Origin = [0.0, 0.0, 0.0]
    slice1.SliceType.Normal = [0.0, 0.0, 1.0]

    # Crear vista
    renderView = CreateView('RenderView')
    renderView.ViewSize = [1600, 400]
    renderView.OrientationAxesVisibility = 0
    renderView.Background = [1.0, 1.0, 1.0]

    # Mostrar slice
    display = Show(slice1, renderView)

    # Configurar colores
    if field_name == 'p':
        ColorBy(display, ('CELLS', 'p'))
        lut = GetColorTransferFunction('p')
        lut.ApplyPreset('Cool to Warm', True)
    elif field_name == 'T':
        ColorBy(display, ('CELLS', 'T'))
        lut = GetColorTransferFunction('T')
        lut.ApplyPreset('Cool to Warm (Extended)', True)
    elif field_name == 'U':
        ColorBy(display, ('CELLS', 'mag(U)'))
        lut = GetColorTransferFunction('magU')
        lut.ApplyPreset('Viridis (matplotlib)', True)
    elif field_name == 'rho':
        ColorBy(display, ('CELLS', 'rho'))
        lut = GetColorTransferFunction('rho')
        lut.ApplyPreset('Rainbow Uniform', True)

    # Escalar colores automaticamente
    display.RescaleTransferFunctionToDataRange(True, False)

    # Agregar barra de colores
    colorBar = GetScalarBar(lut, renderView)
    colorBar.Title = field_name
    colorBar.Visibility = 1
    colorBar.TitleColor = [0.0, 0.0, 0.0]
    colorBar.LabelColor = [0.0, 0.0, 0.0]

    # Configurar camara (vista 2D)
    renderView.InteractionMode = '2D'
    renderView.CameraPosition = [0.0, 0.0, 20.0]
    renderView.CameraFocalPoint = [0.0, 0.0, 0.0]
    renderView.CameraViewUp = [0.0, 1.0, 0.0]
    ResetCamera()

    # Guardar screenshot
    SaveScreenshot(output_path, renderView, ImageResolution=[1600, 400])
    print(f"  Guardado: {os.path.basename(output_path)}")

    # Limpiar
    Delete(slice1)
    Delete(renderView)

def capture_plot_over_line(reader, time, output_path):
    """Captura perfil como grafica XY"""
    # Actualizar tiempo
    animationScene = GetAnimationScene()
    animationScene.UpdateAnimationUsingDataTimeSteps()
    times = reader.TimestepValues
    closest_time = min(times, key=lambda t: abs(t - time))
    animationScene.AnimationTime = closest_time

    # Crear PlotOverLine
    plotLine = PlotOverLine(Input=reader)
    plotLine.Point1 = [-5.0, 0.0, 0.0]
    plotLine.Point2 = [5.0, 0.0, 0.0]
    plotLine.Resolution = 500

    # Crear vista XY
    chartView = CreateView('XYChartView')
    chartView.ViewSize = [1200, 400]
    chartView.LeftAxisTitle = 'Valor'
    chartView.BottomAxisTitle = 'x [m]'
    chartView.ChartTitle = f't = {closest_time:.2f} s'

    # Mostrar linea
    display = Show(plotLine, chartView)
    display.SeriesVisibility = ['p', 'T', 'mag(U)']

    # Guardar
    SaveScreenshot(output_path, chartView, ImageResolution=[1200, 400])
    print(f"  Guardado: {os.path.basename(output_path)}")

    # Limpiar
    Delete(plotLine)
    Delete(chartView)

def process_case(case_dir, case_name):
    """Procesar un caso de OpenFOAM"""
    print(f"\nProcesando caso: {case_name}")

    # Crear archivo .foam
    foam_file = create_foam_file(case_dir)

    if not os.path.exists(foam_file):
        print(f"  ERROR: No se encontro {foam_file}")
        return

    # Abrir caso
    reader = OpenFOAMReader(FileName=foam_file)
    reader.MeshRegions = ['internalMesh']
    reader.CellArrays = ['p', 'T', 'U', 'rho']

    # Verificar tiempos disponibles
    reader.UpdatePipeline()
    available_times = list(reader.TimestepValues)
    print(f"  Tiempos disponibles: {available_times}")

    # Generar capturas para cada tiempo
    for t in TIMES:
        if not any(abs(at - t) < 0.001 for at in available_times):
            print(f"  Saltando t={t} (no disponible)")
            continue

        # Capturas de campos
        for field in ['p', 'T', 'rho']:
            output_file = os.path.join(OUTPUT_DIR,
                f'shocktube_{case_name}_{field}_t{t:.2f}.png')
            try:
                capture_field_slice(reader, field, t, output_file)
            except Exception as e:
                print(f"  Error capturando {field}: {e}")

    # Limpiar
    Delete(reader)
    print(f"  Caso {case_name} completado")

def main():
    print("=" * 60)
    print("EJERCICIO 4 - PARTE 2: Capturas de ParaView")
    print("=" * 60)

    # Procesar ambos casos
    if os.path.exists(HIGH_ORDER_DIR):
        process_case(HIGH_ORDER_DIR, 'highOrder')
    else:
        print(f"Advertencia: No existe {HIGH_ORDER_DIR}")

    if os.path.exists(LOW_ORDER_DIR):
        process_case(LOW_ORDER_DIR, 'lowOrder')
    else:
        print(f"Advertencia: No existe {LOW_ORDER_DIR}")

    print("\n" + "=" * 60)
    print("COMPLETADO")
    print(f"Figuras guardadas en: {OUTPUT_DIR}")
    print("=" * 60)

if __name__ == '__main__':
    main()
