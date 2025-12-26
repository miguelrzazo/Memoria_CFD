

import os
import sys
import math
import numpy as np
import matplotlib.pyplot as plt
from paraview.simple import *

# ============================================================
# CONFIGURACIÓN GLOBAL
# ============================================================
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
CASE_DIR = os.path.dirname(SCRIPT_DIR)  # Ejercicio5/
OUTPUT_DIR = os.path.join(CASE_DIR, '..', '..', 'figures', 'Ejercicio5')

# Casos OpenFOAM
CASE_LOWRE = os.path.join(CASE_DIR, 'planarCouette_LowRe')
CASE_HIGHRE = os.path.join(CASE_DIR, 'planarCouette_HighRe')

# Parámetros físicos
RE = 535000
H = 0.1
U_WALL = 10.0
NU = U_WALL * H / RE
RHO = 1.0

# Configuración de visualización
VIEW_SIZE = [1600, 900]
IMAGE_RES = [1920, 1080]
BACKGROUND_COLOR = [1, 1, 1]  # Blanco

# ============================================================
# FUNCIONES AUXILIARES
# ============================================================

def ensure_output_dir():
    """Crear directorio de salida si no existe"""
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    print(f"Directorio de salida: {OUTPUT_DIR}")

def create_foam_file(case_path, case_name):
    """Crear archivo .foam si no existe"""
    foam_file = os.path.join(case_path, f'{case_name}.foam')
    if not os.path.exists(foam_file):
        open(foam_file, 'w').close()
    return foam_file

def setup_view():
    """Configurar vista de renderizado"""
    view = GetActiveViewOrCreate('RenderView')
    view.ViewSize = VIEW_SIZE
    view.Background = BACKGROUND_COLOR
    return view

def save_screenshot(view, filename, resolution=VIEW_SIZE):
    """Guardar captura de pantalla"""
    filepath = os.path.join(OUTPUT_DIR, filename)
    SaveScreenshot(filepath, view, ImageResolution=resolution, TransparentBackground=0)
    print(f"  ✓ Guardada: {filename}")
    return filepath

def set_2d_camera(view, center_x, center_y, scale, z_pos=1.0):
    """Configurar cámara 2D"""
    view.InteractionMode = '2D'
    view.CameraPosition = [center_x, center_y, z_pos]
    view.CameraFocalPoint = [center_x, center_y, 0.0]
    view.CameraViewUp = [0.0, 1.0, 0.0]
    view.CameraParallelScale = scale
    view.CameraParallelProjection = 1

# ============================================================
# FUNCIONES DE PARAVIEW
# ============================================================

def load_openfoam_case(case_path, case_name):
    """Cargar caso de OpenFOAM"""
    foam_file = create_foam_file(case_path, case_name)
    print(f"\nCargando: {foam_file}")

    reader = OpenFOAMReader(registrationName=case_name, FileName=foam_file)
    reader.MeshRegions = ['internalMesh']
    reader.CellArrays = ['U', 'p', 'k', 'epsilon', 'nut']

    # Obtener tiempos disponibles
    reader.UpdatePipeline()
    times = reader.TimestepValues

    if len(times) == 0:
        print("  ⚠️  No se encontraron tiempos en el caso")
        return None

    # Usar último tiempo
    latest_time = times[-1]
    reader.UpdatePipeline(time=latest_time)
    print(f"  ✓ Tiempo final: {latest_time:.1f} s")

    return reader

def capture_velocity_field(reader, case_name):
    """Capturar campo de velocidad"""
    print(f"\n[1/4] Capturando velocidad - {case_name}...")

    view = setup_view()
    display = Show(reader, view)
    display.Representation = 'Surface'

    # Configurar coloración
    ColorBy(display, ('CELLS', 'U', 'Magnitude'))
    uLUT = GetColorTransferFunction('U')
    uLUT.RescaleTransferFunction(0.0, 10.0)
    uLUT.ApplyPreset('Rainbow Uniform', True)

    # Barra de color
    colorBar = GetScalarBar(uLUT, view)
    colorBar.Title = '|U| [m/s]'
    colorBar.ComponentTitle = ''
    colorBar.Visibility = 1

    # Configurar vista
    set_2d_camera(view, 0.05, 0.05, 0.055)
    Render()

    # Guardar
    save_screenshot(view, f'velocity_field_{case_name}.png')

    Hide(reader, view)
    return display

def capture_turbulent_fields(reader, case_name):
    """Capturar campos turbulentos (k, nut)"""
    print(f"\n[2/4] Capturando campos turbulentos - {case_name}...")

    view = setup_view()
    display = Show(reader, view)
    display.Representation = 'Surface'

    fields_config = [
        ('k', 'Cool to Warm', 'k [m²/s²]'),
        ('nut', 'Viridis (matplotlib)', 'νₜ [m²/s]')
    ]

    for field, colormap, title in fields_config:
        ColorBy(display, ('CELLS', field))
        lut = GetColorTransferFunction(field)
        lut.ApplyPreset(colormap, True)

        colorBar = GetScalarBar(lut, view)
        colorBar.Title = title
        colorBar.ComponentTitle = ''
        colorBar.Visibility = 1

        set_2d_camera(view, 0.05, 0.05, 0.055)
        Render()

        save_screenshot(view, f'{field}_field_{case_name}.png')

    Hide(reader, view)

def capture_mesh(reader, case_name):
    """Capturar visualización de malla"""
    print(f"\n[3/4] Capturando malla - {case_name}...")

    view = setup_view()
    display = Show(reader, view)
    display.Representation = 'Wireframe'
    display.AmbientColor = [0, 0, 0]
    display.LineWidth = 1.0

    # Vista completa
    set_2d_camera(view, 0.05, 0.05, 0.055)
    Render()
    save_screenshot(view, f'malla_completa_{case_name}.png')

    # Zoom en pared
    set_2d_camera(view, 0.05, 0.01, 0.015, 0.5)
    Render()
    save_screenshot(view, f'malla_detalle_pared_{case_name}.png')

    Hide(reader, view)

def extract_velocity_profile(reader, case_name):
    """Extraer perfil de velocidad para análisis posterior"""
    print(f"\n[4/4] Extrayendo perfil de velocidad - {case_name}...")

    # Crear línea de muestreo
    plotLine = PlotOverLine(registrationName=f'Profile{case_name}', Input=reader)
    plotLine.Point1 = [0.05, 0.0, 0.005]  # Desde pared inferior
    plotLine.Point2 = [0.05, 0.1, 0.005]  # Hasta pared superior
    plotLine.Resolution = 500

    # Exportar datos CSV
    csv_file = os.path.join(OUTPUT_DIR, f'perfil_velocidad_{case_name}.csv')
    SaveData(csv_file, proxy=plotLine, WriteTimeSteps=0, FieldAssociation='Point Data')
    print(f"  ✓ Datos exportados: {os.path.basename(csv_file)}")

    # Limpiar
    Delete(plotLine)

    return csv_file

# ============================================================
# FUNCIONES DE ANÁLISIS MATLAB-LIKE
# ============================================================

def read_csv_profile(csv_path):
    """Leer perfil de velocidad desde CSV"""
    try:
        with open(csv_path, 'r', encoding='utf-8') as f:
            header = f.readline().strip().replace('"','').split(',')

        data = np.loadtxt(csv_path, delimiter=',', skiprows=1)

        # Encontrar índices de columnas
        i_arc = header.index('arc_length')
        i_u0 = header.index('U:0')
        i_u1 = header.index('U:1')
        i_u2 = header.index('U:2')
        i_y = header.index('Points:1')

        # Calcular magnitud de velocidad
        U = np.sqrt(data[:, i_u0]**2 + data[:, i_u1]**2 + data[:, i_u2]**2)
        y = data[:, i_y]

        return y, U
    except Exception as e:
        print(f"  ⚠️  Error leyendo CSV: {e}")
        return None, None

def spalding_law(y_plus, kappa=0.41, B=5.2):
    """Calcular ley de Spalding para U+ vs y+"""
    U_plus = np.zeros_like(y_plus)
    for i, yp in enumerate(y_plus):
        if yp <= 0:
            U_plus[i] = 0.0
            continue
        Up = yp if yp < 1 else np.log(yp) / kappa + B
        for _ in range(60):  # Iteración para resolver ecuación implícita
            exp_term = math.exp(kappa * Up)
            f = Up + math.exp(-kappa * B) * (exp_term - 1 - kappa * Up - (kappa * Up)**2 / 2 - (kappa * Up)**3 / 6) - yp
            df = 1 + math.exp(-kappa * B) * (kappa * exp_term - kappa - kappa**2 * Up - 0.5 * kappa**3 * Up**2)
            Up_new = Up - f / df if df != 0 else Up
            if abs(Up_new - Up) < 1e-8:
                Up = Up_new
                break
            Up = Up_new
        U_plus[i] = Up
    return U_plus

def generate_velocity_profile_plot():
    """Generar plot comparativo de perfiles de velocidad"""
    print("\n[POST] Generando perfil de velocidad comparativo...")

    csv_low = os.path.join(OUTPUT_DIR, 'perfil_velocidad_lowRe.csv')
    csv_high = os.path.join(OUTPUT_DIR, 'perfil_velocidad_highRe.csv')

    if not (os.path.exists(csv_low) and os.path.exists(csv_high)):
        print("  ⚠️  Faltan archivos CSV de perfiles")
        return

    # Leer datos
    y_low, U_low = read_csv_profile(csv_low)
    y_high, U_high = read_csv_profile(csv_high)

    if y_low is None or y_high is None:
        return

    # Crear figura
    plt.figure(figsize=(8, 6), dpi=150)
    plt.plot(U_low, y_low*1000, 'b-', linewidth=2.5, label='Low-Re (Launder-Sharma)')
    plt.plot(U_high, y_high*1000, 'r--', linewidth=2.5, label='High-Re (Wall Functions)')
    plt.plot([0, U_WALL], [0, H*1000], 'k:', linewidth=2, label='Couette laminar teórico')

    plt.xlabel('U [m/s]', fontsize=12)
    plt.ylabel('y [mm]', fontsize=12)
    plt.title(f'Perfil de Velocidad - Couette (Re = {RE})', fontsize=14)
    plt.legend(fontsize=11)
    plt.grid(True, alpha=0.3)
    plt.tight_layout()

    # Guardar
    output_file = os.path.join(OUTPUT_DIR, 'perfil_velocidad_comparacion.png')
    plt.savefig(output_file, bbox_inches='tight', dpi=300)
    plt.close()
    print(f"  ✓ Guardada: {os.path.basename(output_file)}")

def generate_wall_law_plot():
    """Generar plot de ley de pared usando datos High-Re"""
    print("\n[POST] Generando ley de pared...")

    csv_high = os.path.join(OUTPUT_DIR, 'perfil_velocidad_highRe.csv')
    if not os.path.exists(csv_high):
        print("  ⚠️  Falta archivo CSV de High-Re")
        return

    y, U = read_csv_profile(csv_high)
    if y is None:
        return

    # Calcular parámetros adimensionales
    Cf = 0.074 * RE**(-0.2)  # Coeficiente de fricción
    tau_w = 0.5 * RHO * U_WALL**2 * Cf
    u_tau = math.sqrt(tau_w / RHO)
    y_plus = y * u_tau / NU
    U_plus = U / u_tau

    # Ley de Spalding
    mask = (y_plus > 0.1) & (y_plus < 1000)  # Rango válido
    y_plus_plot = y_plus[mask]
    U_plus_spalding = spalding_law(y_plus_plot)

    # Crear figura
    plt.figure(figsize=(10, 8), dpi=150)

    # Datos simulados
    plt.semilogx(y_plus, U_plus, 'ro', markersize=4, alpha=0.7, label='Simulación CFD')

    # Ley de Spalding
    plt.semilogx(y_plus_plot, U_plus_spalding, 'b-', linewidth=2.5, label='Ley de Spalding')

    # Región viscosa
    y_plus_visc = np.logspace(-1, 1, 50)
    U_plus_visc = y_plus_visc
    plt.semilogx(y_plus_visc, U_plus_visc, 'k--', linewidth=2, label='$U^+ = y^+$')

    # Región logarítmica
    y_plus_log = np.logspace(1, 3, 50)
    kappa, B = 0.41, 5.2
    U_plus_log = (1/kappa) * np.log(y_plus_log) + B
    plt.semilogx(y_plus_log, U_plus_log, 'g--', linewidth=2, label='Ley logarítmica')

    plt.xlabel('$y^+$', fontsize=14)
    plt.ylabel('$U^+$', fontsize=14)
    plt.title('Ley de Pared - Couette Turbulento', fontsize=16)
    plt.legend(fontsize=12)
    plt.grid(True, alpha=0.3)
    plt.xlim(0.1, 1000)
    plt.ylim(0, 30)
    plt.tight_layout()

    # Guardar
    output_file = os.path.join(OUTPUT_DIR, 'ley_de_pared.png')
    plt.savefig(output_file, bbox_inches='tight', dpi=300)
    plt.close()
    print(f"  ✓ Guardada: {os.path.basename(output_file)}")

def generate_turbulent_fields_montage():
    """Generar montaje de campos turbulentos"""
    print("\n[POST] Generando montaje de campos turbulentos...")

    try:
        import matplotlib.image as mpimg

        fields = ['k', 'nut']
        cases = ['lowRe', 'highRe']

        fig, axes = plt.subplots(2, 2, figsize=(12, 10), dpi=150)

        for i, field in enumerate(fields):
            for j, case in enumerate(cases):
                img_file = os.path.join(OUTPUT_DIR, f'{field}_field_{case}.png')
                if os.path.exists(img_file):
                    img = mpimg.imread(img_file)
                    ax = axes[i, j]
                    ax.imshow(img)
                    ax.axis('off')
                    ax.set_title(f'{field.upper()} - {case}', fontsize=12)
                else:
                    axes[i, j].text(0.5, 0.5, f'Imagen no encontrada\n{field}_{case}',
                                  ha='center', va='center', transform=axes[i, j].transAxes)

        plt.tight_layout()
        output_file = os.path.join(OUTPUT_DIR, 'campos_turbulentos_montaje.png')
        plt.savefig(output_file, bbox_inches='tight', dpi=300)
        plt.close()
        print(f"  ✓ Guardada: {os.path.basename(output_file)}")

    except ImportError:
        print("  ⚠️  matplotlib.image no disponible, saltando montaje")

# ============================================================
# FUNCIÓN PRINCIPAL
# ============================================================

def main():
    """Función principal"""
    print("=" * 70)
    print("  POST-PROCESAMIENTO EJERCICIO 5: PLANAR COUETTE FLOW")
    print("  Master Ingeniería Aeronáutica - CFD 2025")
    print("=" * 70)

    # Verificar casos
    if not os.path.exists(CASE_LOWRE):
        print(f"❌ ERROR: No se encuentra caso Low-Re: {CASE_LOWRE}")
        print("   Ejecute primero: ./run_couette.sh")
        return 1

    if not os.path.exists(CASE_HIGHRE):
        print(f"❌ ERROR: No se encuentra caso High-Re: {CASE_HIGHRE}")
        print("   Ejecute primero: ./run_couette.sh")
        return 1

    # Crear directorio de salida
    ensure_output_dir()

    try:
        # FASE 1: Capturas con ParaView
        print("\n" + "="*50)
        print("FASE 1: CAPTURAS CON PARAVIEW")
        print("="*50)

        # Procesar Low-Re
        print("\n🔹 PROCESANDO LOW-REYNOLDS CASE")
        reader_low = load_openfoam_case(CASE_LOWRE, 'planarCouette_LowRe')
        if reader_low:
            capture_velocity_field(reader_low, 'lowRe')
            capture_turbulent_fields(reader_low, 'lowRe')
            capture_mesh(reader_low, 'lowRe')
            extract_velocity_profile(reader_low, 'lowRe')
            Delete(reader_low)

        # Procesar High-Re
        print("\n🔹 PROCESANDO HIGH-REYNOLDS CASE")
        reader_high = load_openfoam_case(CASE_HIGHRE, 'planarCouette_HighRe')
        if reader_high:
            capture_velocity_field(reader_high, 'highRe')
            capture_turbulent_fields(reader_high, 'highRe')
            capture_mesh(reader_high, 'highRe')
            extract_velocity_profile(reader_high, 'highRe')
            Delete(reader_high)

        # FASE 2: Análisis adicional con matplotlib
        print("\n" + "="*50)
        print("FASE 2: ANÁLISIS ADICIONAL")
        print("="*50)

        generate_velocity_profile_plot()
        generate_wall_law_plot()
        generate_turbulent_fields_montage()

        # Resumen final
        print("\n" + "="*70)
        print("✅ POST-PROCESAMIENTO COMPLETADO")
        print("="*70)

        # Listar archivos generados
        if os.path.exists(OUTPUT_DIR):
            files = [f for f in os.listdir(OUTPUT_DIR) if f.endswith(('.png', '.csv'))]
            print(f"\n📁 Archivos generados en {OUTPUT_DIR}:")
            for f in sorted(files):
                print(f"   • {f}")

        print("\n🎯 Listo para incluir en la memoria LaTeX!")
        return 0

    except Exception as e:
        print(f"\n❌ ERROR durante el post-procesamiento: {e}")
        import traceback
        traceback.print_exc()
        return 1

if __name__ == '__main__':
    sys.exit(main())