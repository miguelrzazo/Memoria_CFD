#!/usr/bin/env pvpython
# -*- coding: utf-8 -*-
"""
Script ParaView para capturas con zoom apropiado - Ejercicio 7
Cilindro transitorio Re=550
"""

from paraview.simple import *

# Configuracion
case_path = '/Users/miguelrosa/Desktop/Master/Asignaturas/CFD/Practica/Memoria_CFD/02_OpenFOAM_FVM/cases/Ejercicio7/cylinder/cylinder.foam'
output_dir = '/Users/miguelrosa/Desktop/Master/Asignaturas/CFD/Practica/Memoria_CFD/02_OpenFOAM_FVM/figures/Ejercicio7/'

# Cargar caso OpenFOAM
print("Cargando caso OpenFOAM...")
foam = OpenFOAMReader(FileName=case_path)
foam.MeshRegions = ['internalMesh']
foam.CellArrays = ['U', 'p']

# Obtener tiempos disponibles
animationScene = GetAnimationScene()
animationScene.UpdateAnimationUsingDataTimeSteps()
times = foam.TimestepValues
print(f"Tiempos disponibles: {len(times)} pasos")
print(f"Rango: {times[0]:.2f} - {times[-1]:.2f} s")

# Ir al ultimo tiempo
animationScene.AnimationTime = times[-1]
print(f"Tiempo seleccionado: {times[-1]:.2f} s")

# Crear vista
renderView = GetActiveViewOrCreate('RenderView')
renderView.ViewSize = [1920, 1080]
renderView.Background = [1, 1, 1]  # Fondo blanco

# Mostrar datos
display = Show(foam, renderView)

# Colorear por magnitud de velocidad
ColorBy(display, ('CELLS', 'U', 'Magnitude'))
uLUT = GetColorTransferFunction('U')
uLUT.RescaleTransferFunction(0.0, 1.5)
uLUT.ApplyPreset('Rainbow Uniform', True)

# Mostrar barra de color
colorBar = GetScalarBar(uLUT, renderView)
colorBar.Title = 'U Magnitude'
colorBar.ComponentTitle = '[m/s]'
colorBar.Visibility = 1
colorBar.TitleFontSize = 16
colorBar.LabelFontSize = 14

# ============================================================
# CONFIGURACION DE CAMARA CON ZOOM APROPIADO
# ============================================================
# El cilindro esta en (0,0) con D=1m
# Queremos ver desde x=-2 hasta x=15 aprox (para ver la estela)
# y desde y=-5 hasta y=5

# Vista 2D (plano XY)
renderView.InteractionMode = '2D'
renderView.CameraPosition = [5.0, 0.0, 30.0]  # Centro en x=5, elevado en Z
renderView.CameraFocalPoint = [5.0, 0.0, 0.0]  # Mirando al plano XY
renderView.CameraViewUp = [0.0, 1.0, 0.0]  # Y hacia arriba
renderView.CameraParallelScale = 8.0  # Controla el zoom (menor = mas zoom)
renderView.CameraParallelProjection = 1  # Proyeccion ortografica

# Actualizar vista
Render()

# ============================================================
# CAPTURA 1: Campo de velocidad completo con buen zoom
# ============================================================
print("Generando captura de velocidad con zoom corregido...")
SaveScreenshot(output_dir + 'velocity_magnitude_t50_v2.png', renderView,
               ImageResolution=[1920, 1080],
               TransparentBackground=0)
print(f"Guardada: velocity_magnitude_t50_v2.png")

# ============================================================
# CAPTURA 2: Zoom en el cilindro y estela cercana
# ============================================================
print("Generando zoom en cilindro y estela...")
renderView.CameraPosition = [2.0, 0.0, 30.0]
renderView.CameraFocalPoint = [2.0, 0.0, 0.0]
renderView.CameraParallelScale = 3.0  # Mas zoom

Render()
SaveScreenshot(output_dir + 'velocity_zoom_estela_t50.png', renderView,
               ImageResolution=[1920, 1080],
               TransparentBackground=0)
print(f"Guardada: velocity_zoom_estela_t50.png")

# ============================================================
# CAPTURA 3: Campo de presion con buen zoom
# ============================================================
print("Generando campo de presion...")
renderView.CameraPosition = [5.0, 0.0, 30.0]
renderView.CameraFocalPoint = [5.0, 0.0, 0.0]
renderView.CameraParallelScale = 8.0

ColorBy(display, ('CELLS', 'p'))
pLUT = GetColorTransferFunction('p')
pLUT.RescaleTransferFunction(-0.5, 0.5)
pLUT.ApplyPreset('Cool to Warm', True)

colorBar = GetScalarBar(pLUT, renderView)
colorBar.Title = 'Pressure'
colorBar.ComponentTitle = '[Pa]'
colorBar.Visibility = 1

Render()
SaveScreenshot(output_dir + 'pressure_t50_v2.png', renderView,
               ImageResolution=[1920, 1080],
               TransparentBackground=0)
print(f"Guardada: pressure_t50_v2.png")

# ============================================================
# CAPTURA 4: Secuencia temporal de vortice de Von Karman
# ============================================================
print("Generando secuencia temporal de estela...")

# Volver a velocidad
ColorBy(display, ('CELLS', 'U', 'Magnitude'))
uLUT.RescaleTransferFunction(0.0, 1.5)
colorBar = GetScalarBar(uLUT, renderView)
colorBar.Title = 'U Magnitude'
colorBar.ComponentTitle = '[m/s]'
colorBar.Visibility = 1

# Zoom en la estela
renderView.CameraPosition = [5.0, 0.0, 30.0]
renderView.CameraFocalPoint = [5.0, 0.0, 0.0]
renderView.CameraParallelScale = 6.0

# Capturar varios instantes para ver evolucion del vortice
for t_target in [45.0, 46.0, 47.0, 48.0, 49.0, 50.0]:
    # Buscar tiempo mas cercano
    t_idx = min(range(len(times)), key=lambda i: abs(times[i] - t_target))
    t_actual = times[t_idx]
    animationScene.AnimationTime = t_actual
    
    Render()
    filename = f'velocity_estela_t{int(t_target)}.png'
    SaveScreenshot(output_dir + filename, renderView,
                   ImageResolution=[1920, 1080],
                   TransparentBackground=0)
    print(f"Guardada: {filename}")

# ============================================================
# CAPTURA 5: Detalle muy cercano al cilindro
# ============================================================
print("Generando detalle cercano al cilindro...")
animationScene.AnimationTime = times[-1]

renderView.CameraPosition = [0.5, 0.0, 30.0]
renderView.CameraFocalPoint = [0.5, 0.0, 0.0]
renderView.CameraParallelScale = 1.5  # Zoom muy cercano

Render()
SaveScreenshot(output_dir + 'velocity_detalle_cilindro.png', renderView,
               ImageResolution=[1920, 1080],
               TransparentBackground=0)
print(f"Guardada: velocity_detalle_cilindro.png")

print("\n=== Capturas completadas ===")
print(f"Archivos guardados en: {output_dir}")
