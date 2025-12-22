#!/usr/bin/env pvpython
"""
Script pvpython para visualizar la ley de pared
Ejercicio 5: Wall Functions - Couette Flow
Master Ingenieria Aeronautica - CFD 2025
"""

from paraview.simple import *
import os
import numpy as np

# Configuracion de directorios
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
OUTPUT_DIR = os.path.join(SCRIPT_DIR, '..', '..', 'figures', 'Ejercicio5')
os.makedirs(OUTPUT_DIR, exist_ok=True)

# Configuracion de visualizacion
VIEW_SIZE = [1000, 700]
FONT_SIZE = 14

def load_case(case_path, case_name):
    """Carga un caso de OpenFOAM"""
    foam_file = os.path.join(case_path, f'{case_name}.foam')
    if not os.path.exists(foam_file):
        open(foam_file, 'w').close()

    reader = OpenFOAMReader(registrationName=case_name, FileName=foam_file)
    reader.MeshRegions = ['internalMesh']
    reader.CellArrays = ['U', 'k', 'nut', 'epsilon', 'yPlus']
    return reader

def create_velocity_profile(data_low, data_high, output_name):
    """Crea grafica del perfil de velocidad"""

    # Plot Over Line para Low-Re (perfil vertical en x=0.05m)
    plotLine_low = PlotOverLine(registrationName='LineLow', Input=data_low)
    plotLine_low.Point1 = [0.005, 0.0, 0.005]
    plotLine_low.Point2 = [0.005, 0.1, 0.005]
    plotLine_low.Resolution = 500

    # Plot Over Line para High-Re
    plotLine_high = PlotOverLine(registrationName='LineHigh', Input=data_high)
    plotLine_high.Point1 = [0.005, 0.0, 0.005]
    plotLine_high.Point2 = [0.005, 0.1, 0.005]
    plotLine_high.Resolution = 100

    # Crear vista de grafica
    chartView = CreateView('XYChartView')
    chartView.ViewSize = VIEW_SIZE
    chartView.ChartTitle = 'Perfil de Velocidad - Couette Flow'
    chartView.BottomAxisTitle = 'y [m]'
    chartView.LeftAxisTitle = 'U [m/s]'

    # Mostrar Low-Re
    display_low = Show(plotLine_low, chartView)
    display_low.XArrayName = 'arc_length'
    display_low.SeriesVisibility = ['U_Magnitude']
    display_low.SeriesLabel = ['U_Magnitude', 'Low-Re (LaunderSharma)']
    display_low.SeriesColor = ['U_Magnitude', '0', '0', '1']
    display_low.SeriesLineThickness = ['U_Magnitude', '2']

    # Mostrar High-Re
    display_high = Show(plotLine_high, chartView)
    display_high.XArrayName = 'arc_length'
    display_high.SeriesVisibility = ['U_Magnitude']
    display_high.SeriesLabel = ['U_Magnitude', 'High-Re (Wall Functions)']
    display_high.SeriesColor = ['U_Magnitude', '1', '0', '0']
    display_high.SeriesLineThickness = ['U_Magnitude', '2']
    display_high.SeriesLineStyle = ['U_Magnitude', '2']

    # Guardar imagen
    output_file = os.path.join(OUTPUT_DIR, output_name)
    SaveScreenshot(output_file, chartView, ImageResolution=VIEW_SIZE)
    print(f'Guardada: {output_file}')

    Delete(plotLine_low)
    Delete(plotLine_high)
    Delete(chartView)

def create_mesh_visualization(data, case_name, output_name):
    """Visualiza la malla cerca de la pared"""
    view = GetActiveViewOrCreate('RenderView')
    view.ViewSize = VIEW_SIZE
    view.Background = [1, 1, 1]

    # Mostrar malla
    display = Show(data, view)
    display.Representation = 'Surface With Edges'
    display.EdgeColor = [0, 0, 0]

    # Vista 2D
    view.CameraPosition = [0.005, 0.05, 0.5]
    view.CameraFocalPoint = [0.005, 0.05, 0.005]
    view.CameraViewUp = [0, 1, 0]
    view.CameraParallelScale = 0.06

    # Texto
    text = Text(registrationName='MeshText')
    text.Text = f'Malla: {case_name}'
    textDisplay = Show(text, view)
    textDisplay.FontSize = FONT_SIZE
    textDisplay.Color = [0, 0, 0]

    output_file = os.path.join(OUTPUT_DIR, output_name)
    SaveScreenshot(output_file, view, ImageResolution=VIEW_SIZE)
    print(f'Guardada: {output_file}')

    Delete(text)
    Hide(data, view)

def create_field_visualization(data, field_name, case_name, output_name):
    """Visualiza un campo escalar"""
    view = GetActiveViewOrCreate('RenderView')
    view.ViewSize = VIEW_SIZE
    view.Background = [1, 1, 1]

    display = Show(data, view)
    ColorBy(display, ('CELLS', field_name))

    lut = GetColorTransferFunction(field_name)
    lut.ApplyPreset('Rainbow Uniform', True)

    colorBar = GetScalarBar(lut, view)
    colorBar.Title = field_name
    colorBar.Visibility = 1

    view.CameraPosition = [0.005, 0.05, 0.5]
    view.CameraFocalPoint = [0.005, 0.05, 0.005]
    view.CameraViewUp = [0, 1, 0]
    view.CameraParallelScale = 0.06

    text = Text(registrationName='FieldText')
    text.Text = f'{field_name} - {case_name}'
    textDisplay = Show(text, view)
    textDisplay.FontSize = FONT_SIZE
    textDisplay.Color = [0, 0, 0]

    output_file = os.path.join(OUTPUT_DIR, output_name)
    SaveScreenshot(output_file, view, ImageResolution=VIEW_SIZE)
    print(f'Guardada: {output_file}')

    Delete(text)
    Hide(data, view)

def main():
    print("="*50)
    print("  Procesando Ejercicio 5 - Wall Functions")
    print("="*50)

    case_low = os.path.join(SCRIPT_DIR, 'planarCouette_LowRe')
    case_high = os.path.join(SCRIPT_DIR, 'planarCouette_HighRe')

    if not os.path.exists(case_low) or not os.path.exists(case_high):
        print("Error: No se encontraron los casos")
        print("Ejecute primero run_couette.sh")
        return

    print("\nCargando casos...")
    data_low = load_case(case_low, 'planarCouette_LowRe')
    data_high = load_case(case_high, 'planarCouette_HighRe')

    data_low.UpdatePipeline()
    data_high.UpdatePipeline()

    times_low = data_low.TimestepValues
    times_high = data_high.TimestepValues

    if len(times_low) > 0:
        latest_time_low = times_low[-1]
        data_low.UpdatePipeline(time=latest_time_low)
        print(f"Low-Re: tiempo = {latest_time_low}")

    if len(times_high) > 0:
        latest_time_high = times_high[-1]
        data_high.UpdatePipeline(time=latest_time_high)
        print(f"High-Re: tiempo = {latest_time_high}")

    # Crear visualizaciones
    print("\nGenerando visualizaciones...")

    # Perfil de velocidad
    create_velocity_profile(data_low, data_high, 'perfil_velocidad_comparacion.png')

    # Malla
    create_mesh_visualization(data_low, 'Low-Reynolds', 'malla_lowRe.png')
    create_mesh_visualization(data_high, 'High-Reynolds', 'malla_highRe.png')

    # Campos turbulentos
    for field in ['U', 'k', 'nut']:
        create_field_visualization(data_low, field, 'Low-Re',
                                  f'{field}_lowRe.png')
        create_field_visualization(data_high, field, 'High-Re',
                                  f'{field}_highRe.png')

    print("\n" + "="*50)
    print("  Visualizacion completada")
    print("="*50)

if __name__ == '__main__':
    main()
