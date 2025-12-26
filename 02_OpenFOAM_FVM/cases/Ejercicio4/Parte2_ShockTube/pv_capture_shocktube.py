from paraview.simple import *
import os

# Configuración
case_base = "/Users/miguelrosa/CFD/Practica/Memoria_CFD/02_OpenFOAM_FVM/cases/Ejercicio4/Parte2_ShockTube"
cases = ["shockTube_loworder", "shockTube_highorder"]
out_dir = "/Users/miguelrosa/CFD/Practica/Memoria_CFD/02_OpenFOAM_FVM/figures/Ejercicio4"
os.makedirs(out_dir, exist_ok=True)

times = [0.1, 0.15]

for case_name in cases:
    case_path = os.path.join(case_base, case_name)
    foam_file = os.path.join(case_path, f"{case_name}.foam")

    # Crear .foam si no existe
    if not os.path.exists(foam_file):
        with open(foam_file, 'w') as f:
            f.write("")

    # Leer caso
    reader = OpenFOAMReader(FileName=foam_file)
    reader.MeshRegions = ['internalMesh']
    reader.CellArrays = ['p', 'T', 'U']

    # Vista para campos
    view = GetActiveViewOrCreate('RenderView')
    Show(reader, view)
    view.ViewSize = [1800, 700]
    view.InteractionMode = '2D'

    # Función para capturar campo
    def save_field_screenshot(field_name, t, fname):
        animation = GetAnimationScene()
        animation.UpdateAnimationUsingDataTimeSteps()
        animation.TimeKeeper.Time = t

        display = GetDisplayProperties(reader, view=view)
        ColorBy(display, ('CELLS', field_name))
        display.RescaleTransferFunctionToDataRange(True, False)
        view.Update()
        SaveScreenshot(os.path.join(out_dir, fname), view)

    # Vista para perfiles
    plot_view = CreateView('XYChartView')
    plot_view.ViewSize = [1800, 700]

    # Plot over line
    plot_line = PlotOverLine(Input=reader)
    plot_line.Point1 = [-5, 0, 0]
    plot_line.Point2 = [5, 0, 0]

    display_line = Show(plot_line, plot_view)

    def save_lineplot(field_name, t, fname):
        animation = GetAnimationScene()
        animation.UpdateAnimationUsingDataTimeSteps()
        animation.TimeKeeper.Time = t
        plot_view.Update()
        SaveScreenshot(os.path.join(out_dir, fname), plot_view)

    # Capturar para cada tiempo
    for t in times:
        # Campos
        save_field_screenshot('p', t, f"{case_name}_p_field_t{t:.2f}.png")
        save_field_screenshot('T', t, f"{case_name}_T_field_t{t:.2f}.png")

        # Perfiles
        save_lineplot('p', t, f"{case_name}_p_line_t{t:.2f}.png")
        save_lineplot('T', t, f"{case_name}_T_line_t{t:.2f}.png")

    # Limpiar
    Delete(reader)
    Delete(view)
    Delete(plot_view)