#!/usr/bin/env pvpython
# -*- coding: utf-8 -*-
"""
Script unificado ParaView - Ejercicios OpenFOAM (4-7)
Master Ingenieria Aeronautica - CFD 2025
Miguel Rosa

Este script genera todas las capturas necesarias para los ejercicios
de OpenFOAM de la memoria de CFD.

Uso:
    pvpython pv_capture_all.py [ejercicio]
    
    ejercicio: 4, 5, 6, 7 o 'all' (por defecto)
"""

from paraview.simple import *
import os
import sys

# ============================================================
# CONFIGURACION GLOBAL
# ============================================================
BASE_PATH = '/Users/miguelrosa/Desktop/Master/Asignaturas/CFD/Practica/Memoria_CFD'
CASES_PATH = os.path.join(BASE_PATH, '02_OpenFOAM_FVM/cases')
FIGURES_PATH = os.path.join(BASE_PATH, '02_OpenFOAM_FVM/figures')

# Resolucion de imagenes
IMAGE_RES = [1920, 1080]
BACKGROUND_COLOR = [1, 1, 1]  # Blanco

# ============================================================
# FUNCIONES AUXILIARES
# ============================================================

def setup_view():
    """Configurar vista de renderizado"""
    view = GetActiveViewOrCreate('RenderView')
    view.ViewSize = IMAGE_RES
    view.Background = BACKGROUND_COLOR
    return view

def create_foam_file(case_path, name):
    """Crear archivo .foam si no existe"""
    foam_file = os.path.join(case_path, f'{name}.foam')
    if not os.path.exists(foam_file):
        open(foam_file, 'w').close()
    return foam_file

def save_screenshot(view, output_path, filename):
    """Guardar captura con configuracion estandar"""
    os.makedirs(output_path, exist_ok=True)
    filepath = os.path.join(output_path, filename)
    SaveScreenshot(filepath, view, ImageResolution=IMAGE_RES, TransparentBackground=0)
    print(f"  Guardada: {filename}")
    return filepath

def set_2d_camera(view, center_x, center_y, scale, z_pos=30):
    """Configurar camara 2D"""
    view.InteractionMode = '2D'
    view.CameraPosition = [center_x, center_y, z_pos]
    view.CameraFocalPoint = [center_x, center_y, 0.0]
    view.CameraViewUp = [0.0, 1.0, 0.0]
    view.CameraParallelScale = scale
    view.CameraParallelProjection = 1

# ============================================================
# EJERCICIO 5: PLANAR COUETTE - WALL FUNCTIONS
# ============================================================

def capture_ejercicio5():
    """Generar capturas para Ejercicio 5: Planar Couette Flow"""
    print("\n" + "="*60)
    print("EJERCICIO 5: Planar Couette Flow - Wall Functions")
    print("="*60)
    
    case_path = os.path.join(CASES_PATH, 'Ejercicio5/planarCouette')
    output_path = os.path.join(FIGURES_PATH, 'Ejercicio5')
    
    # Crear archivo .foam
    foam_file = create_foam_file(case_path, 'planarCouette')
    
    # Cargar caso
    print(f"\nCargando: {foam_file}")
    foam = OpenFOAMReader(FileName=foam_file)
    foam.MeshRegions = ['internalMesh']
    foam.CellArrays = ['U', 'p', 'k', 'epsilon', 'nut']
    
    # Configurar tiempo
    animationScene = GetAnimationScene()
    animationScene.UpdateAnimationUsingDataTimeSteps()
    times = foam.TimestepValues
    
    if len(times) == 0:
        print("ERROR: No hay tiempos disponibles")
        return
    
    print(f"Tiempos: {len(times)} pasos ({times[0]:.0f} - {times[-1]:.0f} s)")
    animationScene.AnimationTime = times[-1]
    t_final = int(times[-1])
    
    # Configurar vista
    view = setup_view()
    display = Show(foam, view)
    
    # 1. Campo de velocidad
    print("\n[1/5] Campo de velocidad...")
    ColorBy(display, ('CELLS', 'U', 'Magnitude'))
    uLUT = GetColorTransferFunction('U')
    uLUT.RescaleTransferFunction(0.0, 10.0)
    uLUT.ApplyPreset('Rainbow Uniform', True)
    GetScalarBar(uLUT, view).Visibility = 1
    set_2d_camera(view, 0.05, 0.05, 0.06, 1.0)
    Render()
    save_screenshot(view, output_path, f'velocity_field_t{t_final}.png')
    
    # 2. Energia cinetica turbulenta
    print("\n[2/5] Campo de k...")
    ColorBy(display, ('CELLS', 'k'))
    kLUT = GetColorTransferFunction('k')
    kLUT.ApplyPreset('Cool to Warm', True)
    GetScalarBar(kLUT, view).Visibility = 1
    Render()
    save_screenshot(view, output_path, f'k_field_t{t_final}.png')
    
    # 3. Viscosidad turbulenta
    print("\n[3/5] Campo de nut...")
    ColorBy(display, ('CELLS', 'nut'))
    nutLUT = GetColorTransferFunction('nut')
    nutLUT.ApplyPreset('Viridis (matplotlib)', True)
    GetScalarBar(nutLUT, view).Visibility = 1
    Render()
    save_screenshot(view, output_path, f'nut_field_t{t_final}.png')
    
    # 4. Malla
    print("\n[4/5] Malla...")
    display.Representation = 'Wireframe'
    display.AmbientColor = [0, 0, 0]
    set_2d_camera(view, 0.05, 0.01, 0.015, 0.5)
    Render()
    save_screenshot(view, output_path, 'malla_detalle_pared.png')
    
    set_2d_camera(view, 0.05, 0.05, 0.06, 1.0)
    Render()
    save_screenshot(view, output_path, 'malla_completa.png')
    
    # 5. Perfil de velocidad
    print("\n[5/5] Perfil de velocidad...")
    display.Representation = 'Surface'
    ColorBy(display, ('CELLS', 'U', 'Magnitude'))
    
    plotLine = PlotOverLine(Input=foam)
    plotLine.Point1 = [0.05, 0.0, 0.005]
    plotLine.Point2 = [0.05, 0.1, 0.005]
    plotLine.Resolution = 500
    
    chartView = CreateView('XYChartView')
    chartView.ViewSize = IMAGE_RES
    plotDisplay = Show(plotLine, chartView)
    plotDisplay.SeriesVisibility = ['U_Magnitude']
    Render()
    save_screenshot(chartView, output_path, 'perfil_velocidad.png')
    
    # Exportar datos CSV
    csv_file = os.path.join(output_path, 'perfil_velocidad_data.csv')
    SaveData(csv_file, proxy=plotLine, WriteTimeSteps=0, FieldAssociation='Point Data')
    print(f"  Guardado: perfil_velocidad_data.csv")
    
    # Limpiar
    Delete(plotLine)
    Delete(foam)
    
    print(f"\n[OK] Ejercicio 5 completado: {output_path}")

# ============================================================
# EJERCICIO 7: CILINDRO TRANSITORIO
# ============================================================

def capture_ejercicio7():
    """Generar capturas para Ejercicio 7: Cilindro Transitorio"""
    print("\n" + "="*60)
    print("EJERCICIO 7: Cilindro Transitorio - Von Karman")
    print("="*60)
    
    case_path = os.path.join(CASES_PATH, 'Ejercicio7/cylinder')
    output_path = os.path.join(FIGURES_PATH, 'Ejercicio7')
    
    # Crear archivo .foam
    foam_file = create_foam_file(case_path, 'cylinder')
    
    # Cargar caso
    print(f"\nCargando: {foam_file}")
    foam = OpenFOAMReader(FileName=foam_file)
    foam.MeshRegions = ['internalMesh']
    foam.CellArrays = ['U', 'p']
    
    # Configurar tiempo
    animationScene = GetAnimationScene()
    animationScene.UpdateAnimationUsingDataTimeSteps()
    times = foam.TimestepValues
    
    if len(times) == 0:
        print("ERROR: No hay tiempos disponibles")
        return
    
    print(f"Tiempos: {len(times)} pasos ({times[0]:.2f} - {times[-1]:.2f} s)")
    animationScene.AnimationTime = times[-1]
    t_final = times[-1]
    
    # Configurar vista
    view = setup_view()
    display = Show(foam, view)
    
    # 1. Campo de velocidad - vista general
    print("\n[1/7] Velocidad vista general...")
    ColorBy(display, ('CELLS', 'U', 'Magnitude'))
    uLUT = GetColorTransferFunction('U')
    uLUT.RescaleTransferFunction(0.0, 1.5)
    uLUT.ApplyPreset('Rainbow Uniform', True)
    colorBar = GetScalarBar(uLUT, view)
    colorBar.Title = 'U Magnitude'
    colorBar.ComponentTitle = '[m/s]'
    colorBar.Visibility = 1
    set_2d_camera(view, 5.0, 0.0, 8.0)
    Render()
    save_screenshot(view, output_path, f'velocity_magnitude_t{int(t_final)}.png')
    
    # 2. Zoom en estela
    print("\n[2/7] Zoom en estela...")
    set_2d_camera(view, 2.0, 0.0, 3.0)
    Render()
    save_screenshot(view, output_path, 'velocity_zoom_estela.png')
    
    # 3. Campo de presion
    print("\n[3/7] Campo de presion...")
    set_2d_camera(view, 5.0, 0.0, 8.0)
    ColorBy(display, ('CELLS', 'p'))
    pLUT = GetColorTransferFunction('p')
    pLUT.RescaleTransferFunction(-0.5, 0.5)
    pLUT.ApplyPreset('Cool to Warm', True)
    colorBar = GetScalarBar(pLUT, view)
    colorBar.Title = 'Pressure'
    colorBar.ComponentTitle = '[Pa]'
    colorBar.Visibility = 1
    Render()
    save_screenshot(view, output_path, f'pressure_t{int(t_final)}.png')
    
    # 4. Detalle cilindro
    print("\n[4/7] Detalle cilindro...")
    ColorBy(display, ('CELLS', 'U', 'Magnitude'))
    set_2d_camera(view, 0.5, 0.0, 1.5)
    Render()
    save_screenshot(view, output_path, 'velocity_detalle_cilindro.png')
    
    # 5. Secuencia temporal
    print("\n[5/7] Secuencia temporal...")
    set_2d_camera(view, 5.0, 0.0, 6.0)
    
    for t_target in [45.0, 47.0, 50.0]:
        t_idx = min(range(len(times)), key=lambda i: abs(times[i] - t_target))
        animationScene.AnimationTime = times[t_idx]
        Render()
        save_screenshot(view, output_path, f'velocity_estela_t{int(t_target)}.png')
    
    # 6. Malla
    print("\n[6/7] Malla...")
    animationScene.AnimationTime = times[-1]
    display.Representation = 'Wireframe'
    display.AmbientColor = [0, 0, 0]
    set_2d_camera(view, 0.0, 0.0, 1.0)
    Render()
    save_screenshot(view, output_path, 'malla_cilindro.png')
    
    set_2d_camera(view, 5.0, 0.0, 10.0)
    Render()
    save_screenshot(view, output_path, 'malla_completa.png')
    
    # Limpiar
    Delete(foam)
    
    print(f"\n[OK] Ejercicio 7 completado: {output_path}")

# ============================================================
# MAIN
# ============================================================

def main():
    """Funcion principal"""
    # Determinar que ejercicios ejecutar
    if len(sys.argv) > 1:
        ejercicio = sys.argv[1].lower()
    else:
        ejercicio = 'all'
    
    print("="*60)
    print("GENERADOR DE CAPTURAS PARAVIEW - CFD 2025")
    print("="*60)
    
    if ejercicio == '5':
        capture_ejercicio5()
    elif ejercicio == '7':
        capture_ejercicio7()
    elif ejercicio == 'all':
        capture_ejercicio5()
        capture_ejercicio7()
    else:
        print(f"Ejercicio no reconocido: {ejercicio}")
        print("Uso: pvpython pv_capture_all.py [5|7|all]")
        return
    
    print("\n" + "="*60)
    print("CAPTURAS COMPLETADAS")
    print("="*60)

if __name__ == '__main__':
    main()
