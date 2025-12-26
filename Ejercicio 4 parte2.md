 Enunciado: 
 Para estudiar el efecto que tienen los esquemas de discretización en la solución de un problema de volúmenes finitos se plantea simular el tubo de onda de choque de Tod.
a. Proceder a realizar las simulaciones (durante 0.1 segundos) utilizando:
• Esquemas del mínimo orden posible en todas las operaciones
• Esquemas de orden superior (mayor que en el caso anterior) en todas las operaciones
Cuestiones
1) ¿Qué es un tubo de onda de choque de Tod? ¿Para qué se usa?
2) Realice una simulación del problema con esquemas numéricos de alto orden. Sabiendo que
este problema tiene solución analítica, dada por los valores adjuntados como anexo en el
Moodle, valide la simulación para t=0.1s.
3) Explique de forma breve que fórmulas está aplicando cada uno de los métodos
seleccionados. Indique cuales son las ventajas e inconvenientes los mismos.
4) Ahora, compare el efecto de realizar la misma simulación con esquemas de alto orden (los
del apartado anterior) con otros esquemas de bajo orden. Compare los resultados obtenidos
identificando las características principales y efectos de los esquemas utilizados. Para ello,
estudie los perfiles horizontales de las distintas variables en cada uno de los casos, para
t=0.15s.
[text](02_OpenFOAM_FVM/cases/Ejercicio4/Parte2_ShockTube)
[text](02_OpenFOAM_FVM/cases/Ejercicio4/Parte2_ShockTube/ResultadosAnalaticos.csv)
3) Analizar los resultados obtenidos.

text
GUÍA PASO A PASO — Parte 2 (Tubo de choque de Sod) con el caso del profesor
(Objetivo: comparar esquemas de bajo orden vs alto orden, y generar figuras/gráficas + validación)

======================================================================
0) Qué te piden exactamente (y qué vas a entregar)
======================================================================
- Simular el tubo de choque de Sod y estudiar el efecto de los esquemas de discretización. [file:1]
- Hacer 2 simulaciones:
  (A) “Esquemas del mínimo orden posible” en todas las operaciones. [file:1]
  (B) “Esquemas de orden superior” en todas las operaciones. [file:1]
- Cuestiones a responder:
  1) Qué es el tubo de choque de Sod y para qué se usa. [file:1]
  2) Validar tu simulación de alto orden en t=0.1 s comparando con la solución analítica (adjunta en Moodle). [file:1]
  3) Explicar brevemente qué fórmulas/métodos aplican tus esquemas elegidos + ventajas/inconvenientes. [file:1]
  4) Comparar alto orden vs bajo orden usando perfiles horizontales a t=0.15 s (ojo: hay que simular también hasta 0.15 s). [file:1]

Recomendación práctica:
- Mantén el caso del profesor como “BASE”.
- Crea 2 copias: case_low/ y case_high/.
- Corre ambos y automatiza:
  - extracción de perfiles (para MATLAB),
  - capturas de ParaView (pvpython).

======================================================================
1) Entender el caso del profesor (lo que ya está montado)
======================================================================
1.1 Dominio y malla
- Dominio: x ∈ [-5, 5], y ∈ [-1, 1], z ∈ [-1, 1] con 1000 celdas en x y 1 en y y 1 en z. [file:30]
- Esto equivale a un tubo 1D (una sola celda transversal) usando caras tipo “empty” para que el problema sea esencialmente 1D. [file:30]

1.2 Condiciones iniciales (Sod)
- Estado “alto” por defecto: U=(0,0,0), T=348.432 K, p=100000 Pa. [file:27]
- Región “baja presión” para x ∈ [0, 5]: T=278.746 K, p=10000 Pa. [file:27]
- Por tanto, el diafragma está en x=0 (izquierda alta presión, derecha baja presión). [file:27]

1.3 Control temporal (tal como está)
- Un controlDict del profesor deja endTime=0.1 s, deltaT=1e-6 y writeInterval=0.01. [file:24]
- El enunciado pide además perfiles a t=0.15 s, así que tendrás que extender endTime a 0.15 para la parte comparativa. [file:1][file:24]

1.4 Extracción de perfiles ya preparada (muy útil)
- En system/functions está activado graphCell para muestrear a lo largo del eje x (start/end) y sacar T, mag(U) y p. [file:31]
- Esto te permite generar automáticamente archivos de perfil por tiempo sin depender de ParaView. [file:31]

1.5 Esquemas actuales (caso profesor = “mixto”)
- ddt: Euler (1er orden en tiempo). [file:28]
- div(phi,U): Gauss upwind (1er orden). [file:28]
- Otras convecciones (p, e, K, etc.): Gauss vanAlbada (TVD/limitado, típicamente de mayor orden en zonas suaves y estable en shocks). [file:28]

Conclusión:
- Este caso del profesor NO es “todo mínimo orden” ni “todo alto orden”, es un punto intermedio. [file:28]
- Para el ejercicio, crea dos variantes “puristas”: todo-upwind/Euler (bajo) y todo-limitado + 2º orden tiempo (alto).

======================================================================
2) Preparar dos casos: bajo orden y alto orden
======================================================================
2.1 Estructura de carpetas
- Duplica el caso del profesor:
  cp -r shockTubeProf case_low
  cp -r shockTubeProf case_high

- Mantén constant/ y 0/ iguales en ambos; cambia principalmente system/fvSchemes (y si quieres, controlDict). [file:28][file:24]

2.2 Caso “LOW” (mínimo orden posible)
Objetivo numérico:
- 1er orden en tiempo y 1er orden espacial en todas las convecciones (upwind). [file:1]

Edición sugerida: system/fvSchemes (case_low)
- ddtSchemes: Euler (como ya). [file:28]
- divSchemes: TODO upwind en todas las div convectivas:
  div(phi,U)          Gauss upwind;
  div(phid,p)         Gauss upwind;
  div(phi,e)          Gauss upwind;
  div(phi,K)          Gauss upwind;
  div(phi,(p|rho))    Gauss upwind;  (si lo estás usando en tu solver/config)
  (Deja el término viscoso tal cual si aparece.)

Motivo:
- Con esto fuerzas una solución muy estable pero más difusiva: shocks más “anchos” y discontinuidad de contacto más suavizada. [file:1]

2.3 Caso “HIGH” (orden superior)
Objetivo numérico:
- Mayor orden en tiempo (p.ej. backward) y esquemas convectivos limitados (TVD) en todas las convecciones relevantes. [file:1]

Edición sugerida: system/fvSchemes (case_high)
- ddtSchemes: cambia a backward (2º orden) si tu solver lo admite.
- divSchemes: usa un limitado tipo vanAlbada (como ya usa el caso para p/e/K) también para U, o usa otro TVD (vanLeer/limitedLinear) pero de forma consistente.
  Ejemplo coherente con el caso del profesor:
  div(phi,U)          Gauss vanAlbada;
  div(phid,p)         Gauss vanAlbada;
  div(phi,e)          Gauss vanAlbada;
  div(phi,K)          Gauss vanAlbada;
  div(phi,(p|rho))    Gauss vanAlbada;  (si aplica)
- Mantén gradSchemes Gauss linear (ya). [file:28]

Motivo:
- Mantendrás shocks y contacto más nítidos (menos difusión numérica), pero puedes ver overshoot/undershoot cerca de discontinuidades si el limitado no es suficientemente restrictivo o si el CFL no está bien controlado. [file:1]

2.4 Ajuste de tiempos (para cumplir t=0.1 y t=0.15)
- Para validación: endTime=0.1. [file:1][file:24]
- Para comparación del punto 4: endTime=0.15 (o corre otra vez hasta 0.15). [file:1]
- Recomendación: en ambos casos usa endTime=0.15 y luego extraes t=0.1 y t=0.15. [file:1]

En system/controlDict:
- Cambia endTime a 0.15. [file:24]
- Mantén writeInterval suficientemente fino para tener exactamente 0.1 y 0.15 escritos (p.ej. 0.01 ya te da 0.10 y 0.15). [file:24]

======================================================================
3) Ejecución del caso (comandos y checks)
======================================================================
3.1 Mesh + IC
En cada caso:
- blockMesh  (crea malla [-5,5] con 1000 celdas en x). [file:30]
- setFields  (impone la región x∈[0,5] de baja presión). [file:27]

3.2 Correr el solver
- Ejecuta el solver configurado por el caso (tu Allrun del prof probablemente ya lo hace).
- Checks mínimos:
  - Que existan time folders 0.10 y 0.15 (si endTime=0.15). [file:24]
  - Que en postProcessing (o carpeta equivalente) aparezcan perfiles del graphCell si está activo. [file:31]

3.3 Extracción automática de perfiles (sin ParaView)
- Si graphCell está activo, te generará ficheros por tiempo con campos (T, mag(U), p) a lo largo de x. [file:31]
- Esto es ideal para MATLAB: un perfil 1D por variable y por instante. [file:31]

======================================================================
4) Automatizar capturas con pvpython (plantilla)
======================================================================
Idea:
- Hacer 2 tipos de salida visual:
  A) “Campos” (p, T, |U|) con una vista 2D (aunque sea 1 celda transversal).
  B) “Perfiles 1D” (PlotOverLine) como imagen (PNG) para meter en el informe.


------------------ pvpython: render_shocktube.py (PLANTILLA) ------------------
from paraview.simple import *
import os

caseFoam = os.path.abspath("case.foam")  # crea el .foam con: touch case.foam
outDir = os.path.abspath("figures_pv")
os.makedirs(outDir, exist_ok=True)

reader = OpenFOAMReader(FileName=caseFoam)
reader.MeshRegions = ['internalMesh']
reader.CellArrays = ['p', 'T', 'U']

view = GetActiveViewOrCreate('RenderView')
Show(reader, view)
view.ViewSize = [1800, 700]
view.InteractionMode = '2D'

# Colormap helper
def save_field_screenshot(fieldName, t, fname):
    animation = GetAnimationScene()
    animation.UpdateAnimationUsingDataTimeSteps()
    animation.TimeKeeper.Time = t

    display = GetDisplayProperties(reader, view=view)
    ColorBy(display, ('CELLS', fieldName))
    display.RescaleTransferFunctionToDataRange(True, False)
    view.Update()
    SaveScreenshot(os.path.join(outDir, fname), view)

# Plot over line: x from -5 to 5 (coherente con blockMeshDict) [file:30]
plotLine = PlotOverLine(Input=reader)
plotLine.Point1 = [-5, 0, 0]
plotLine.Point2 = [ 5, 0, 0]

plotView = CreateView('XYChartView')
plotView.ViewSize = [1800, 700]
displayLine = Show(plotLine, plotView)

def save_lineplot(fieldName, t, fname):
    animation = GetAnimationScene()
    animation.UpdateAnimationUsingDataTimeSteps()
    animation.TimeKeeper.Time = t
    plotView.Update()
    # En ParaView, el PlotOverLine expone arrays; a veces hay que ajustar series visibles:
    # displayLine.SeriesVisibility = [fieldName]  # depende de versión
    SaveScreenshot(os.path.join(outDir, fname), plotView)

# Tiempos clave
times = [0.10, 0.15]

for t in times:
    save_field_screenshot('p', t, f"p_field_t{t:.2f}.png")
    save_field_screenshot('T', t, f"T_field_t{t:.2f}.png")
    save_lineplot('p', t, f"p_line_t{t:.2f}.png")
    save_lineplot('T', t, f"T_line_t{t:.2f}.png")
------------------------------------------------------------------------------

Notas:
- El .foam se crea con “touch case.foam” en el directorio del caso.
- Si solo quieres perfiles (y no campos), puedes saltarte RenderView y quedarte con XYChartView.
- El rango de la línea (-5,5) está alineado con el dominio del caso del profesor. [file:30]

======================================================================
5) Gráficas en MATLAB (LaTeX + automatización)
======================================================================
Objetivo:
- 1) VALIDACIÓN a t=0.1 (alto orden vs analítica).
- 2) COMPARACIÓN a t=0.15 (alto vs bajo) para p, rho (si la sacas), T, U.

5.1 Lectura de perfiles desde OpenFOAM
Opción A (si usas graphCell de system/functions):
- Busca los ficheros en postProcessing/... generados por graphCell con campos (T, mag(U), p). [file:31]
- Suelen ser formato “x y” o “x value”; MATLAB lo lee con readmatrix/importdata.

Opción B (si exportas desde ParaView):
- Exporta CSV desde PlotOverLine con pvpython y léelo con readtable/readmatrix.

5.2 Plantilla MATLAB (guárdala como plot_shocktube.m)
- Configura intérprete LaTeX:
  set(groot,'defaultTextInterpreter','latex');
  set(groot,'defaultLegendInterpreter','latex');
  set(groot,'defaultAxesTickLabelInterpreter','latex');

- Estilo recomendado:
  lw = 1.8; ms = 6;
  colors = lines(4);

- Ejemplo de plot p(x) comparando low vs high vs analítica:
  figure('Color','w'); hold on; grid on; box on;
  plot(x_high, p_high, '-',  'LineWidth', lw, 'DisplayName', 'High order');
  plot(x_low,  p_low,  '--', 'LineWidth', lw, 'DisplayName', 'Low order');
  plot(x_an,   p_an,   ':',  'LineWidth', lw, 'DisplayName', 'Analytic');
  xlabel('$x$');
  ylabel('$p~[\mathrm{Pa}]$');
  legend('Location','best');
  title(sprintf('Sod shock tube at $t=%.2f~\\mathrm{s}$', t));
  exportgraphics(gcf, sprintf('fig_p_t%0.2f.png', t), 'Resolution', 300);

5.3 Error de validación (en t=0.1)
- Interpola tu solución numérica a la malla x de la analítica:
  p_num_i = interp1(x_num, p_num, x_an, 'linear', 'extrap');
- Norma L1 relativa:
  errL1 = sum(abs(p_num_i - p_an)) / sum(abs(p_an));
- Reporta al menos en p y/o densidad si la tienes (rho), y comenta dónde falla (shock/contacto). [file:1]

======================================================================
6) Lista de figuras recomendadas (lo que “queda redondo” en el informe)
======================================================================
(Usa la misma numeración en el documento.)

Figura 1 — Dominio y malla 1D (vista en ParaView), mostrando longitud [-5,5] y discretización 1000×1×1. [file:30]

Figura 2 — Condición inicial: p(x) a t=0 (salto en x=0; izquierda 100 kPa, derecha 10 kPa). [file:27]

Figura 3 — VALIDACIÓN (alto orden) a t=0.10 s: p(x) numérico vs analítico (superpuesto). [file:1]

Figura 4 — VALIDACIÓN (alto orden) a t=0.10 s: T(x) numérico vs analítico (o U si tu anexo analítico incluye esas variables). [file:1][file:31]

Figura 5 — COMPARACIÓN a t=0.15 s: p(x) low vs high, con zoom cerca del shock (zona derecha del diafragma). [file:1]

Figura 6 — COMPARACIÓN a t=0.15 s: variable de contacto (típicamente densidad si la sacas; si no, usa T y/o U) low vs high, con zoom cerca de la discontinuidad de contacto. [file:1][file:31]

Figura 7 — Campos : mapa de p o T en ParaView a t=0.10 y/o t=0.15 (aunque sea 1 celda transversal, sirve de “snapshot” visual). [file:24]

Tabla 1 — Resumen de esquemas: ddt (Euler vs backward), div convectivos (upwind vs vanAlbada), y comentario “difusivo vs nítido”. [file:28][file:1]

======================================================================
7) Respuesta corta (plantilla) para las cuestiones del enunciado
======================================================================
Q1) ¿Qué es el tubo de choque de Sod y para qué se usa? [file:1]
- Definición: problema 1D Riemann con un diafragma que separa dos estados (p, T, rho) y al romperse genera: onda de choque, discontinuidad de contacto y abanico de rarefacción. [file:1]
- Uso: validación de solvers compresibles y de esquemas capturadores de choques, porque existe solución analítica de referencia. [file:1]

Q2) Validación alto orden a t=0.1 s (vs analítica Moodle). [file:1]
- Inserta Figuras 3–4.
- Reporta un error (L1 relativo) en p y/o T (y/o rho) y comenta discrepancias en shock/contacto. [file:1]

Q3) Qué fórmulas aplica cada método + pros/contras. [file:1]
- Upwind (bajo orden): 1er orden, usa valores “a barlovento”; pro: robusto/estable; contra: mucha difusión numérica. [file:1]
- Limitados TVD (vanAlbada, alto orden): mayor orden en zonas suaves y limitación cerca de discontinuidades; pro: shocks más nítidos; contra: posible overshoot/undershoot o sensibilidad a CFL. [file:28][file:1]

Q4) Comparación high vs low a t=0.15 s con perfiles horizontales. [file:1]
- Inserta Figuras 5–6.
- Identifica:
  - shock: low “lo engorda” (smearing), high lo mantiene más abrupto;
  - contacto: low lo difunde, high lo preserva;
  - rarefacción: high suele aproximar mejor la pendiente. [file:1]


## Escribir en latex

Seccion 4.2
Similar al ejercicio 7, en estilo de escritura y estructura