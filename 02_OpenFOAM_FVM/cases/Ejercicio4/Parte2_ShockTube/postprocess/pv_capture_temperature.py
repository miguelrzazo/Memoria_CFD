#!/usr/bin/env pvpython
"""
pv_capture_temperature.py - Captura campos de temperatura del tubo de choque

Genera frames del campo de temperatura para crear GIF animado.

Uso:
    /Applications/ParaView-6.0.1.app/Contents/bin/pvpython pv_capture_temperature.py
"""

from paraview.simple import *
import os
import sys

# Configuracion de rutas
script_dir = os.path.dirname(os.path.abspath(__file__))
case_base = os.path.dirname(script_dir)
fig_dir = os.path.join(case_base, '..', '..', '..', 'figures', 'Ejercicio4')
frames_dir = os.path.join(fig_dir, 'pv_frames_T')

# Crear directorios si no existen
for d in [fig_dir, frames_dir]:
    if not os.path.exists(d):
        os.makedirs(d)

# Ruta al caso OpenFOAM
case_highorder = os.path.join(case_base, 'shockTube_highorder')
foam_file = os.path.join(case_highorder, 'case.foam')

# Crear archivo .foam si no existe
if not os.path.exists(foam_file):
    open(foam_file, 'w').close()

print("="*60)
print("Captura de campos de temperatura - Tubo de choque")
print("="*60)
print(f"Caso: {case_highorder}")
print(f"Frames: {frames_dir}")

# Parametros de tiempo adimensional
a_L = 374.17  # m/s
L = 10.0  # m

# Cargar caso OpenFOAM
print("\nCargando caso OpenFOAM...")
foam_case = OpenFOAMReader(FileName=foam_file)
foam_case.CaseType = 'Reconstructed Case'
foam_case.MeshRegions = ['internalMesh']
foam_case.CellArrays = ['T', 'p', 'U']

# Obtener tiempos disponibles
foam_case.UpdatePipeline()
animationScene = GetAnimationScene()
animationScene.UpdateAnimationUsingDataTimeSteps()
timesteps = foam_case.TimestepValues
print(f"Tiempos disponibles: {len(timesteps)}")

# Configurar vista
renderView = GetActiveViewOrCreate('RenderView')
renderView.ViewSize = [1600, 300]
renderView.Background = [1.0, 1.0, 1.0]  # Fondo blanco

# Configurar camara para vista del tubo (1D horizontal)
renderView.CameraPosition = [0, 0, 20]
renderView.CameraFocalPoint = [0, 0, 0]
renderView.CameraViewUp = [0, 1, 0]
renderView.CameraParallelScale = 6
renderView.CameraParallelProjection = 1

# Mostrar el caso
display = Show(foam_case, renderView)
display.Representation = 'Surface'

# Configurar visualizacion del campo de temperatura
ColorBy(display, ('CELLS', 'T'))
display.RescaleTransferFunctionToDataRange(True)
display.SetScalarBarVisibility(renderView, True)

# Obtener lookup table de temperatura
TLUT = GetColorTransferFunction('T')
TLUT.RescaleTransferFunction(200, 400)  # Rango de temperatura [200 K, 400 K]
TLUT.ApplyPreset('Cool to Warm', True)

# Configurar barra de colores
TColorBar = GetScalarBar(TLUT, renderView)
TColorBar.Title = 'Temperatura [K]'
TColorBar.ComponentTitle = ''
TColorBar.TitleFontSize = 18
TColorBar.LabelFontSize = 14
TColorBar.Position = [0.85, 0.2]
TColorBar.ScalarBarLength = 0.6
TColorBar.TitleColor = [0, 0, 0]
TColorBar.LabelColor = [0, 0, 0]

# Capturar frames para cada tiempo
print("\nCapturando frames...")
for i, t in enumerate(timesteps):
    # Calcular tiempo adimensional
    t_star = t * a_L / L

    # Actualizar tiempo
    animationScene.AnimationTime = t
    foam_case.UpdatePipeline(t)

    # Agregar anotacion de tiempo
    text = Text()
    text.Text = f't* = {t_star:.3f}'
    textDisplay = Show(text, renderView)
    textDisplay.FontSize = 24
    textDisplay.Color = [0, 0, 0]
    textDisplay.WindowLocation = 'Upper Center'

    # Renderizar
    Render()

    # Guardar frame
    frame_name = f"T_frame_{i:03d}.png"
    frame_path = os.path.join(frames_dir, frame_name)
    SaveScreenshot(frame_path, renderView, ImageResolution=[1600, 300])
    print(f"  Frame {i}: t = {t:.4f} s (t* = {t_star:.3f}) -> {frame_name}")

    # Limpiar anotacion
    Hide(text, renderView)
    Delete(text)

print(f"\n{len(timesteps)} frames guardados en: {frames_dir}")
print("\nPara crear el GIF, ejecute:")
print(f"  python3 create_shocktube_gif.py")
print("="*60)
