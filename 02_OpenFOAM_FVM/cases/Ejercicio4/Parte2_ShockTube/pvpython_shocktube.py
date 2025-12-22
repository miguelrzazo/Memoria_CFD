#!/usr/bin/env pvpython
"""
Script pvpython para visualizar resultados del Shock Tube de Sod
Ejercicio 4 - Parte 2: Esquemas Numericos
Master Ingenieria Aeronautica - CFD 2025
"""

from paraview.simple import *
import os
import sys

# Configuracion de directorios
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
OUTPUT_DIR = os.path.join(SCRIPT_DIR, 'figures')
os.makedirs(OUTPUT_DIR, exist_ok=True)

# Configuracion de visualizacion
VIEW_SIZE = [1200, 400]
FONT_SIZE = 14

def setup_view():
    """Configura la vista de renderizado"""
    view = GetActiveViewOrCreate('RenderView')
    view.ViewSize = VIEW_SIZE
    view.Background = [1, 1, 1]  # Fondo blanco
    return view

def load_case(case_path, case_name):
    """Carga un caso de OpenFOAM"""
    foam_file = os.path.join(case_path, f'{case_name}.foam')
    # Crear archivo .foam si no existe
    if not os.path.exists(foam_file):
        open(foam_file, 'w').close()

    reader = OpenFOAMReader(registrationName=case_name, FileName=foam_file)
    reader.MeshRegions = ['internalMesh']
    reader.CellArrays = ['p', 'T', 'U', 'rho']
    return reader

def create_line_plot(data_high, data_low, variable, time, output_name):
    """Crea grafica de linea comparando alto y bajo orden"""

    # Crear Plot Over Line para alto orden
    plotLine_high = PlotOverLine(registrationName='LineHigh', Input=data_high)
    plotLine_high.Point1 = [-5.0, 0.0, 0.0]
    plotLine_high.Point2 = [5.0, 0.0, 0.0]
    plotLine_high.Resolution = 1000

    # Crear Plot Over Line para bajo orden
    plotLine_low = PlotOverLine(registrationName='LineLow', Input=data_low)
    plotLine_low.Point1 = [-5.0, 0.0, 0.0]
    plotLine_low.Point2 = [5.0, 0.0, 0.0]
    plotLine_low.Resolution = 1000

    # Configurar vista de grafica
    lineChartView = CreateView('XYChartView')
    lineChartView.ViewSize = VIEW_SIZE
    lineChartView.ChartTitle = f'{variable} a t = {time} s'
    lineChartView.BottomAxisTitle = 'x [m]'
    lineChartView.LeftAxisTitle = variable

    # Mostrar datos de alto orden
    display_high = Show(plotLine_high, lineChartView)
    display_high.SeriesVisibility = [variable]
    display_high.SeriesLabel = [variable, 'Alto orden (vanAlbada)']
    display_high.SeriesColor = [variable, '0', '0', '1']  # Azul
    display_high.SeriesLineStyle = [variable, '1']
    display_high.SeriesLineThickness = [variable, '2']

    # Mostrar datos de bajo orden
    display_low = Show(plotLine_low, lineChartView)
    display_low.SeriesVisibility = [variable]
    display_low.SeriesLabel = [variable, 'Bajo orden (upwind)']
    display_low.SeriesColor = [variable, '1', '0', '0']  # Rojo
    display_low.SeriesLineStyle = [variable, '2']
    display_low.SeriesLineThickness = [variable, '2']

    # Guardar imagen
    output_file = os.path.join(OUTPUT_DIR, output_name)
    SaveScreenshot(output_file, lineChartView, ImageResolution=VIEW_SIZE)
    print(f'Guardada: {output_file}')

    Delete(plotLine_high)
    Delete(plotLine_low)
    Delete(lineChartView)

def create_contour_plot(data, variable, time, case_name, output_name):
    """Crea visualizacion de contornos 2D"""
    view = setup_view()

    # Mostrar datos
    display = Show(data, view)
    ColorBy(display, ('CELLS', variable))

    # Configurar barra de colores
    lut = GetColorTransferFunction(variable)
    lut.ApplyPreset('Rainbow Uniform', True)

    colorBar = GetScalarBar(lut, view)
    colorBar.Title = variable
    colorBar.ComponentTitle = ''
    colorBar.Visibility = 1

    # Ajustar camara para vista 2D (XY)
    view.CameraPosition = [0, 0, 20]
    view.CameraFocalPoint = [0, 0, 0]
    view.CameraViewUp = [0, 1, 0]
    view.CameraParallelScale = 6

    # Agregar texto con tiempo
    text = Text(registrationName='TimeText')
    text.Text = f't = {time} s\n{case_name}'
    textDisplay = Show(text, view)
    textDisplay.FontSize = FONT_SIZE
    textDisplay.Color = [0, 0, 0]

    # Guardar imagen
    output_file = os.path.join(OUTPUT_DIR, output_name)
    SaveScreenshot(output_file, view, ImageResolution=VIEW_SIZE)
    print(f'Guardada: {output_file}')

    Delete(text)
    Hide(data, view)

def main():
    """Funcion principal"""
    print("="*50)
    print("  Procesando Shock Tube con ParaView")
    print("="*50)

    # Rutas de casos
    case_high = os.path.join(SCRIPT_DIR, 'shockTube_highOrder')
    case_low = os.path.join(SCRIPT_DIR, 'shockTube_lowOrder')

    # Verificar que existen los casos
    if not os.path.exists(case_high) or not os.path.exists(case_low):
        print("Error: No se encontraron los casos de OpenFOAM")
        print("Ejecute primero run_shocktube.sh")
        sys.exit(1)

    # Cargar casos
    print("\nCargando casos...")
    data_high = load_case(case_high, 'shockTube_highOrder')
    data_low = load_case(case_low, 'shockTube_lowOrder')

    # Obtener tiempos disponibles
    data_high.UpdatePipeline()
    times = data_high.TimestepValues

    if len(times) == 0:
        print("Error: No hay tiempos disponibles. Ejecute la simulacion primero.")
        sys.exit(1)

    print(f"Tiempos disponibles: {times}")

    # Procesar tiempo t=0.1s (o el mas cercano)
    target_time = 0.1
    closest_time = min(times, key=lambda x: abs(x - target_time))
    print(f"\nProcesando tiempo t = {closest_time} s")

    # Actualizar a tiempo especifico
    data_high.UpdatePipeline(time=closest_time)
    data_low.UpdatePipeline(time=closest_time)

    # Crear visualizaciones de contorno
    for var in ['p', 'rho', 'T']:
        create_contour_plot(data_high, var, closest_time, 'Alto Orden',
                           f'shocktube_{var}_highOrder_t{closest_time:.2f}.png')
        create_contour_plot(data_low, var, closest_time, 'Bajo Orden',
                           f'shocktube_{var}_lowOrder_t{closest_time:.2f}.png')

    print("\n" + "="*50)
    print("  Visualizacion completada")
    print("="*50)

if __name__ == '__main__':
    main()
