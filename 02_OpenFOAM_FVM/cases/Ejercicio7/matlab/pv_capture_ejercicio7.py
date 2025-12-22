#!/usr/bin/env pvpython
# -*- coding: utf-8 -*-
"""
EJERCICIO 7: Capturas de ParaView para simulacion transitoria de cilindro
Genera capturas de campos de velocidad, presion y vorticidad
"""

from paraview.simple import *
import os

# Configuracion de rutas
script_dir = os.path.dirname(os.path.abspath(__file__))
case_dir = os.path.join(script_dir, '..', 'cylinder')
fig_dir = os.path.join(script_dir, '..', '..', 'figures', 'Ejercicio7')

# Crear directorio de figuras si no existe
os.makedirs(fig_dir, exist_ok=True)

print("=" * 60)
print("  EJERCICIO 7: Capturas de ParaView")
print("=" * 60)
print(f"\nCase dir: {case_dir}")
print(f"Output dir: {fig_dir}")

# Crear archivo .foam si no existe
foam_file = os.path.join(case_dir, 'cylinder.foam')
if not os.path.exists(foam_file):
    open(foam_file, 'a').close()
    print(f"Creado: {foam_file}")

# Cargar caso OpenFOAM
print("\nCargando caso OpenFOAM...")
reader = OpenFOAMReader(registrationName='cylinder', FileName=foam_file)
reader.MeshRegions = ['internalMesh']
reader.CellArrays = ['U', 'p', 'k', 'omega', 'nut']

# Obtener tiempos disponibles
animationScene = GetAnimationScene()
animationScene.UpdateAnimationUsingDataTimeSteps()
times = reader.TimestepValues
print(f"Tiempos disponibles: {len(times)} pasos")
print(f"  Rango: {min(times):.2f} - {max(times):.2f} s")

# Seleccionar tiempos para capturas
# t = 50s (ultimo), t = 45s, t = 40s (instantes durante vortex shedding)
capture_times = [50.0, 45.0, 40.0, 30.0]
capture_times = [t for t in capture_times if any(abs(tt - t) < 0.1 for tt in times)]

# Configurar vista
view = GetActiveViewOrCreate('RenderView')
view.ViewSize = [1920, 1080]
view.Background = [1.0, 1.0, 1.0]  # Fondo blanco

# Configurar camara para vista del cilindro (zoom apropiado)
view.CameraPosition = [5, 0, 30]
view.CameraFocalPoint = [5, 0, 0]
view.CameraViewUp = [0, 1, 0]
view.CameraParallelScale = 8

# Funcion para encontrar el tiempo mas cercano
def find_nearest_time(target, times):
    return min(times, key=lambda x: abs(x - target))

# Funcion para generar capturas
def capture_field(field_name, color_map, title, filename, t_capture):
    # Ir al tiempo especificado
    nearest_t = find_nearest_time(t_capture, times)
    animationScene.AnimationTime = nearest_t
    
    # Mostrar campo
    display = Show(reader, view)
    ColorBy(display, ('CELLS', field_name))
    
    # Configurar colormap
    if field_name == 'U':
        display.SetScalarBarVisibility(view, True)
        lut = GetColorTransferFunction(field_name)
        lut.ApplyPreset('Rainbow Uniform', True)
        lut.RescaleTransferFunction(0, 1.5)
        display.LookupTable = lut
    elif field_name == 'p':
        display.SetScalarBarVisibility(view, True)
        lut = GetColorTransferFunction(field_name)
        lut.ApplyPreset('Cool to Warm', True)
        lut.RescaleTransferFunction(-0.5, 0.5)
        display.LookupTable = lut
    
    # Renderizar y guardar
    Render()
    output_path = os.path.join(fig_dir, filename)
    SaveScreenshot(output_path, view, ImageResolution=[1920, 1080])
    print(f"  Guardada: {filename}")
    
    Hide(reader, view)

# Generar capturas para el ultimo tiempo (t ~ 50s)
print("\n" + "-" * 40)
print("Generando capturas de campos...")
print("-" * 40)

t_final = find_nearest_time(50.0, times)
animationScene.AnimationTime = t_final

# 1. Campo de velocidad (magnitud)
print(f"\n[t = {t_final:.2f}s] Campo de velocidad...")
display = Show(reader, view)
ColorBy(display, ('CELLS', 'U', 'Magnitude'))
display.SetScalarBarVisibility(view, True)
lut = GetColorTransferFunction('U')
lut.ApplyPreset('Rainbow Uniform', True)
lut.RescaleTransferFunction(0, 1.5)
display.LookupTable = lut
Render()
SaveScreenshot(os.path.join(fig_dir, 'velocity_magnitude_t50.png'), view, ImageResolution=[1920, 1080])
print("  Guardada: velocity_magnitude_t50.png")

# 2. Campo de presion
print(f"\n[t = {t_final:.2f}s] Campo de presion...")
ColorBy(display, ('CELLS', 'p'))
lut_p = GetColorTransferFunction('p')
lut_p.ApplyPreset('Cool to Warm', True)
lut_p.RescaleTransferFunction(-0.5, 0.5)
display.LookupTable = lut_p
Render()
SaveScreenshot(os.path.join(fig_dir, 'pressure_t50.png'), view, ImageResolution=[1920, 1080])
print("  Guardada: pressure_t50.png")

# 3. Vista ampliada del cilindro
print(f"\n[t = {t_final:.2f}s] Vista ampliada cilindro...")
view.CameraParallelScale = 3
view.CameraFocalPoint = [1, 0, 0]
view.CameraPosition = [1, 0, 30]
ColorBy(display, ('CELLS', 'U', 'Magnitude'))
display.LookupTable = lut
Render()
SaveScreenshot(os.path.join(fig_dir, 'velocity_zoom_cylinder_t50.png'), view, ImageResolution=[1920, 1080])
print("  Guardada: velocity_zoom_cylinder_t50.png")

# Restaurar vista
view.CameraParallelScale = 8
view.CameraFocalPoint = [5, 0, 0]
view.CameraPosition = [5, 0, 30]

# 4. Comparar dos instantes diferentes (para mostrar vortex shedding)
Hide(reader, view)

for idx, t_cap in enumerate([45.0, 47.5]):
    t_actual = find_nearest_time(t_cap, times)
    animationScene.AnimationTime = t_actual
    
    display = Show(reader, view)
    ColorBy(display, ('CELLS', 'U', 'Magnitude'))
    display.SetScalarBarVisibility(view, True)
    display.LookupTable = lut
    Render()
    
    fname = f'velocity_t{int(t_actual)}.png'
    SaveScreenshot(os.path.join(fig_dir, fname), view, ImageResolution=[1920, 1080])
    print(f"  Guardada: {fname}")
    Hide(reader, view)

# 5. Vista de la malla
print("\nGenerando vista de malla...")
animationScene.AnimationTime = 0
display = Show(reader, view)
display.Representation = 'Surface With Edges'
display.AmbientColor = [0, 0, 0]
display.DiffuseColor = [0.8, 0.8, 0.8]
display.EdgeColor = [0, 0, 0]
display.SetScalarBarVisibility(view, False)

# Zoom a la zona del cilindro
view.CameraParallelScale = 2
view.CameraFocalPoint = [0, 0, 0]
view.CameraPosition = [0, 0, 30]
Render()
SaveScreenshot(os.path.join(fig_dir, 'malla_cilindro.png'), view, ImageResolution=[1920, 1080])
print("  Guardada: malla_cilindro.png")

# Vista de la malla completa
view.CameraParallelScale = 15
view.CameraFocalPoint = [10, 0, 0]
view.CameraPosition = [10, 0, 50]
Render()
SaveScreenshot(os.path.join(fig_dir, 'malla_completa.png'), view, ImageResolution=[1920, 1080])
print("  Guardada: malla_completa.png")

# 6. Streamlines para visualizar estela
print("\nGenerando streamlines...")
Hide(reader, view)

# Volver al tiempo final
animationScene.AnimationTime = t_final

# Mostrar campo
display = Show(reader, view)
ColorBy(display, ('CELLS', 'U', 'Magnitude'))
display.LookupTable = lut
display.Opacity = 0.5

# Crear streamlines
try:
    streamTracer = StreamTracerWithCustomSource(registrationName='Streamlines', 
                                                 Input=reader,
                                                 SeedType='Line')
    streamTracer.Vectors = ['CELLS', 'U']
    streamTracer.MaximumStreamlineLength = 30.0
    streamTracer.SeedType.Point1 = [-3, -3, 0]
    streamTracer.SeedType.Point2 = [-3, 3, 0]
    streamTracer.SeedType.Resolution = 30
    
    streamDisplay = Show(streamTracer, view)
    streamDisplay.Representation = 'Surface'
    ColorBy(streamDisplay, ('POINTS', 'U', 'Magnitude'))
    streamDisplay.LookupTable = lut
    streamDisplay.LineWidth = 2.0
    
    view.CameraParallelScale = 10
    view.CameraFocalPoint = [8, 0, 0]
    view.CameraPosition = [8, 0, 40]
    
    Render()
    SaveScreenshot(os.path.join(fig_dir, 'streamlines_t50.png'), view, ImageResolution=[1920, 1080])
    print("  Guardada: streamlines_t50.png")
    
    Hide(streamTracer, view)
except Exception as e:
    print(f"  Error creando streamlines: {e}")

Hide(reader, view)

print("\n" + "=" * 60)
print("  Capturas completadas")
print("=" * 60)
print(f"\nFiguras guardadas en: {fig_dir}")
