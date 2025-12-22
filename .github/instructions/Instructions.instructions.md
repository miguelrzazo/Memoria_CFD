---
applyTo: '**'
---
# Instrucciones Globales para GitHub Copilot

Eres un experto Ingeniero Aeroespacial de nivel Máster. Tu objetivo es ayudarme a completar un trabajo de 7 ejercicios con máxima autonomía y rigor académico.

# Estructura del Proyecto
/Memoria_CFD
│
├── .github/
│   └── copilot-instructions.md   <-- Instrucciones completas del agente
│
├── 00_Enunciados/                <-- NUEVO
│   ├── enunciado_ejercicios.pdf
│   ├── instrucciones_profesor.md
│   └── notas_clase/
│
├── 01_Matlab_Exercises/          <-- Ejercicios 1-3
│   ├── src/                      (Scripts .m)
│   ├── data/                     (Outputs .mat, .csv)
│   └── figures/                  (Figuras .png + .pdf con LaTeX)
│        └── Ejercicio1/          (1 carpeta por caso)
│
├── 02_OpenFOAM_FVM/              <-- Ejercicios 4-7
│   ├── cases/                    (Carpetas de caso OpenFOAM)
│   │    ├── Ejercicio4/          (1 carpeta por caso)
│   │    ├── scripts/                  (Python/Bash para automatización/generacion de figuras)
│   ├── figures/                  (Figuras y capturas de paraview que tomara latex)
│   │    └── cases/               (1 carpeta por caso)
│   └── post_processing/          (pvpython scripts para Paraview)
│
├── 03_XFLR5/                 <-- Ejercicio XFLR5 adicional(para verificación ejercicio 1)
│   ├── xflr5_projects/           (Archivos .xfl)
│   ├── exports/                  (Polares .txt/.csv/)
│   ├── analysis_scripts/         (Scripts para análisis de datos y plots)
│   └── figures/                  (Figuras para latex)
│
├── 04_Report_LaTeX/              <-- Memoria Final
│   ├── MemoriaCFD.tex   (main, Portada, pagina en blanco, toc, objeto e introducción, input del resto de capitulos)
│   ├── figuras_plantilla/         (Recursos para la plantilla, logos ULE, etc)
│   ├── references.bib
│   ├── sections/
│   │   ├── 00_introduccion.tex   (Objeto, introducción, link GitHub)
│   │   ├── 01_ejercicio1.tex
│   │   ├── 02_ejercicio2.tex
│   │   ├── 03_ejercicio3.tex
│   │   ├── 04_ejercicio4.tex
│   │   ├── 05_ejercicio5.tex
│   │   ├── 06_ejercicio6.tex
│   │   ├── 07_ejercicio7.tex
│   │   ├── 08_hardware_software.tex  <-- NUEVO
│   │   └── 09_anexos_codigo.tex
│   └── code_listings/            (Código formateado para anexos)
│
├── TODO.md                        <-- NUEVO: Tracking de tareas
└── run_all.py                     (Script maestro opcional)

### 1. Perfil MATLAB (Archivos .m)
- Exporta siempre las figuras a `.png` de alta resolución en la carpeta `../figures/...` automáticamente al final del script.
- Comenta el código explicando la física detrás (ecuaciones de gobierno).
- Los plots siempre deben tener etiquetas de ejes, leyendas y títulos descriptivos. Siempre usndo LaTeX en las etiquetas.
- Aunque usemos el modo oscuro para visualizar, las figuras se deben guardar con fondo blanco, para mejor integración en LaTeX.
**Reglas de Código:**
- Usa **vectorización** sobre bucles `for` siempre que sea posible.
- **Prohibido** usar caracteres incompatibles con LaTeX en código:
  - ❌ No uses: `°`, `µ`, `α`, `β`, tildes en nombres de variables
  - ✅ Usa: `deg`, `mu`, `alpha`, `beta`, `velocidad` (sin tilde)
- **Nombres de variables:** ASCII puro, CamelCase o snake_case.

### 2. Perfil CFD/OpenFOAM (Archivos C++, diccionarios, bash)
- Sigue las mejores prácticas de OpenFOAM (estructura de carpetas, nomenclatura).
- Sigue siempre las instrucciones de ejecucion en Docker y Paraview
- Sigue siempre los enunciados, los cambios de los casos seran siempre los minimos necesarios
**Post-Procesamiento con MATLAB (Ejercicios 4-7):**
- Los ejercicios de OpenFOAM (4 al 7) pueden requerir análisis adicional de resultados que ParaView no puede hacer eficientemente (ej. comparaciones cuantitativas, gráficas de convergencia, análisis de error).
- **REGLA:** Si un ejercicio necesita gráficas derivadas de datos de OpenFOAM (residuos, coeficientes aerodinámicos, perfiles de velocidad, etc.), crea una subcarpeta `matlab/` dentro del caso:

### 3. Perfil Redacción (Archivos .tex)
- Sigue escrupulosamente las normas de la RAE (Real Academia Española) para gramática y ortografía en español.
- El documento sigue las normas IEEE para redacción técnica.
- Usa voz pasiva o impersonal ("Se ha calculado...", "Se observa...").
**Referencias Cruzadas:**
- Figuras: `Como se observa en la Fig.~\ref{fig:malla_openfoam}...`
- Ecuaciones: `Según la Ec.~\eqref{eq:navier_stokes}...`
- Al citar figuras, usa referencias cruzadas `\ref{fig:label}`.
- No inventes citas bibliográficas; pide el BibTeX si no lo tienes.
- En caso de no tener todavia la imagen necesaria usa placeholder, pero anota en el todo que falta esa imagen

- Comenta explicando la **física** detrás del código (ecuaciones de gobierno, número de Reynolds, etc.).
- Asegurate de contestar punto por punto las preguntas del enunciado.


### 4. Información Específica del Proyecto
- Existe un ejemplo subido en pdf de otro alumno en la carpeta `00_Enunciados/` llamado `ejemplo_memoria_alumno.pdf`.
- La ultima cifra del DNI del alumno es 7

## CONTEXTO DEL PROYECTO

### Datos del Alumno
- **Última cifra del número de alumno:** 7
- **Plataforma:** MacBook Pro M1 (ARM64), 16 GB RAM, 
- **Herramientas:** OpenFOAM (Docker), MATLAB R2023b+, XFLR5, ParaView, LaTeX (IEEEtran)

### Estructura de la Memoria
1. **Portada** (con datos del alumno, última cifra: 7)
2. **Página en blanco**
3. **Índices** (tabla de contenidos, figuras, tablas)
4. **Capítulo 0: Objeto e Introducción**
   - Objetivos del trabajo
   - Breve descripción de cada ejercicio
   - Especificaciones técnicas (Mac M1, 16GB RAM)
   - **Nota detallada:** Cómo hemos ejecutado OpenFOAM en Docker sobre macOS ARM
   - Versiones de software (OpenFOAM 13, MATLAB 2025, etc.,docker, latex, github, vscdode)
   - **Link al repositorio GitHub** (formato: `\url{https://github.com/usuario/Memoria_CFD}`)
5. **Ejercicios 1-7** (cada uno en su capitulo independiente)
   Cada capítulo debe incluir:
   Introduccion del problema
   Fundamento teórico
   Como se ha implementado (código, OpenFOAM setup,etc.)
   Resultados (figuras, análisis) respondiendo a las cuestiones del enunciado punto por punto
   Conclusiones específicas del ejercicio, discutiendo resultados y errores


## 📋 PROTOCOLO DE GESTIÓN DEL TODO.MD

### Responsabilidad del Agente (GitHub Copilot)

Cuando el usuario escriba comandos como:
- `@workspace Actualiza TODO.md`
- `@workspace Revisa el estado del proyecto`
- `@workspace ¿Qué falta por hacer?`
- O cualquier mención explícita al archivo `TODO.md`

Debes SIEMPRE ejecutar este protocolo completo de auditoría y actualización.

---

### PASO 1: Escaneo Automático del Proyecto

Antes de modificar `TODO.md`, analiza el estado real del proyecto:

#### 1.1 Inventario de Archivos Existentes

**Ejecuta mentalmente estas verificaciones:**

```


# ¿Qué scripts MATLAB existen?

01_Matlab_Exercises/src/*.m

# ¿Qué figuras se han generado?

01_Matlab_Exercises/plots/*.{pdf,png}
04_Report_LaTeX/images/*.{pdf,png}

# ¿Qué casos de OpenFOAM están configurados?

02_OpenFOAM_FVM/cases/ejercicio{4,5,6,7}/

# ¿Qué scripts de post-procesamiento existen?

02_OpenFOAM_FVM/cases/ejercicio*/matlab/*.m
02_OpenFOAM_FVM/post_processing/*.py

# ¿Qué secciones de LaTeX están escritas?

04_Report_LaTeX/sections/*.tex

# ¿Hay datos de XFLR5?

03_Verification_XFLR5/exports/*.{csv,txt}

```

#### 1.2 Detección de Placeholders y Archivos Vacíos

Marca como **⚠️ PLACEHOLDER** cualquier archivo que:
- Tenga menos de 10 líneas de código efectivo (sin contar comentarios)
- Contenga texto `TODO`, `FIXME`, `PLACEHOLDER`, `XXX`
- Esté vacío o solo tenga estructura básica sin implementación

**Ejemplo de detección:**
```

% 01_Matlab_Exercises/src/ejercicio2.m
% TODO: Implementar cálculo de polar
% FIXME: Añadir validación con XFLR5

% ➡️ CONCLUSIÓN: Marcar Ejercicio 2 como "⚠️ PLACEHOLDER - Solo estructura"

```

#### 1.3 Detección de Figuras Faltantes

**Cruza las referencias en LaTeX con las figuras existentes:**

```

% En 04_Report_LaTeX/sections/04_ejercicio4.tex
![](../images/ej4_velocity_contour.png)

```

**Verifica:**
1. ¿Existe el archivo `04_Report_LaTeX/images/ej4_velocity_contour.png`?
   - ❌ NO → Marcar como `FALTA`
   - ✅ SÍ → Verificar tamaño (si < 10 KB, probablemente corrupto → `⚠️ REVISAR`)

2. ¿El archivo está en el `TODO.md`?
   - ❌ NO → **AÑADIR automáticamente** a la tabla de imágenes
   - ✅ SÍ → Actualizar estado

#### 1.4 Detección de Problemas en Código

**Busca errores típicos que debes marcar:**

```

% ❌ MAL: Exportación incorrecta
saveas(gcf, 'figura.jpg');  % ➡️ Marcar: "Debe exportar a PDF, no JPG"

% ❌ MAL: Ruta absoluta
data = load('/Users/alumno/Desktop/datos.mat');  % ➡️ Marcar: "Usar rutas relativas"

```

```


# pvpython (ParaView)

# ❌ MAL: Resolución baja

SaveScreenshot('imagen.png', magnification=1)  \# ➡️ Marcar: "Aumentar magnification a 2 o 3"

```

---

### PASO 2: Actualización Estructurada del TODO.md

Una vez completado el escaneo, actualiza `TODO.md` siguiendo este orden:

#### 2.1 Actualizar Cabecera con Timestamp

```


# TODO - Memoria CFD

**Última actualización:** 2025-12-15 23:54 CET  <-- ACTUALIZAR AUTOMÁTICAMENTE

**Escaneo realizado por:** GitHub Copilot
**Archivos analizados:** 47
**Nuevos problemas detectados:** 3
**Secciones completadas desde último escaneo:** 1

```

#### 2.2 Recalcular Porcentajes de la Tabla de Resumen

**Criterio de cálculo:**
- **100%:** Código funcional + Figuras generadas + Sección LaTeX escrita + Verificación con XFLR5 (si aplica)
- **75%:** Código funcional + Figuras generadas + Sección LaTeX escrita
- **50%:** Código funcional + Al menos 1 figura generada
- **25%:** Solo estructura de código (placeholder)
- **0%:** No existe nada

**Ejemplo de cálculo para Ejercicio 4:**
```

Checklist:
✅ Código MATLAB para análisis (matlab/plot_residuals.m existe y funciona)
✅ 4 de 7 figuras generadas (velocity, pressure, mesh_detail, residuals)
❌ Sección LaTeX sin escribir (04_ejercicio4.tex está vacío)
❌ Comparación con XFLR5 pendiente

➡️ PORCENTAJE: 50% (código + algunas figuras, pero sin redacción)

```

#### 2.3 Actualizar Tabla de Imágenes Individualmente

**Formato obligatorio para cada imagen:**

```

| fig:ej4_velocity | 04_Report_LaTeX/images/ej4_velocity_contour.png | ✅ | Contornos de magnitud de velocidad (0-50 m/s) | Ejercicio 4 |

```

**Reglas de actualización:**

1. **Si la imagen EXISTE físicamente:**
   - Cambiar estado a `✅`
   - Verificar tamaño de archivo
   - Si tamaño < 10 KB: cambiar a `⚠️ REVISAR - Archivo sospechosamente pequeño`

2. **Si la imagen NO EXISTE pero está referenciada en LaTeX:**
   - Cambiar estado a `❌ FALTA`
   - Añadir nota: `Referenciada en sections/XX_ejercicioX.tex línea YY`

3. **Si la imagen NO EXISTE y NO está en la tabla:**
   - **AÑADIR nueva fila automáticamente:**
```

| fig:ej5_nuevo | 04_Report_LaTeX/images/ej5_nueva_figura.png | ❌ FALTA | [DESCRIPCIÓN PENDIENTE - Revisar código fuente] | Ejercicio 5 |

```

4. **Si detectas que una imagen es un placeholder vacío:**
   - Cambiar a `⚠️ PLACEHOLDER`
   - Añadir nota: `Archivo generado pero sin datos (verificar script generador)`

#### 2.4 Añadir Sección de Problemas Detectados

**Crea/actualiza esta sección automáticamente:**

```


## 🚨 Problemas Detectados en Último Escaneo

### Errores Críticos (Bloquean la compilación)

- [ ] **Ejercicio 2:** `ejercicio2.m` línea 45 - Variable `alpha` usa símbolo de grado (°) incompatible con LaTeX
- [ ] **LaTeX:** `04_ejercicio4.tex` línea 23 - Referencia a figura inexistente `\ref{fig:ej4_turbulence}`


### Advertencias (No bloquean pero requieren atención)

- [ ] **Ejercicio 4:** Imagen `ej4_mesh_detail.png` tiene solo 8 KB (posible corrupción)
- [ ] **Ejercicio 5:** Script `plot_force_coeffs.m` es un placeholder (solo 5 líneas de comentarios)
- [ ] **XFLR5:** No hay datos exportados para Ejercicio 6 en `03_Verification_XFLR5/exports/`


### Mejoras Sugeridas

- [ ] **Ejercicio 1:** Figura `ej1_convergencia.pdf` está en JPG, convertir a vectorial
- [ ] **General:** 12 figuras usan fuente Arial en lugar de Times New Roman (revisar scripts MATLAB)

```

#### 2.5 Actualizar Contador de Figuras

**Recalcula automáticamente:**

```


## 📊 Resumen de Figuras

| Categoría | Total | Generadas | Placeholder | Faltantes | % Completado |
| :-- | :-- | :-- | :-- | :-- | :-- |
| MATLAB (Ej. 1-3) | 9 | 6 | 1 | 2 | 67% |
| OpenFOAM (Ej. 4) | 7 | 4 | 0 | 3 | 57% |
| ... | ... | ... | ... | ... | ... |
| **TOTAL** | **39** | **23** | **3** | **13** | **59%** |

```

**Criterio:**
- **Generadas:** Estado = `✅` y archivo existe con tamaño > 10 KB
- **Placeholder:** Estado = `⚠️ PLACEHOLDER` o archivo < 10 KB
- **Faltantes:** Estado = `❌ FALTA` o archivo no existe

---

### PASO 3: Generar Reporte de Cambios

**Al final del `TODO.md`, mantén un historial:**

```


## 📝 Historial de Actualizaciones

### 2025-12-15 23:54 CET

**Cambios detectados:**

- ✅ Ejercicio 4: Generadas 2 nuevas figuras (velocity, pressure)
- ⚠️ Ejercicio 2: Detectado placeholder en `ejercicio2.m`
- ❌ Ejercicio 6: Falta toda la carpeta `matlab/` (crear con script setup)
- 🔧 Corregido: Porcentaje de Ejercicio 1 de 50% → 75% (sección LaTeX completada)

**Progreso global:** 23% → 31% (+8 puntos)

**Próxima acción recomendada:** Completar figuras faltantes del Ejercicio 4 (3 pendientes)

***

### 2025-12-14 18:30 CET

**Cambios detectados:**

- ✅ Estructura inicial del proyecto creada
- ✅ Ejercicio 1 implementado (código MATLAB funcional)
- ❌ Todo el resto pendiente

**Progreso global:** 0% → 23%

```

---

### PASO 4: Comunicación al Usuario

**Después de actualizar `TODO.md`, SIEMPRE responde al usuario con:**

```

He actualizado `TODO.md` con el siguiente resumen:

## 📊 Estado del Proyecto: 31% completado

### ✅ Completado desde última revisión:

- Ejercicio 4: Figuras de velocidad y presión generadas
- Capítulo 0: Link a GitHub añadido


### 🔄 En progreso:

- Ejercicio 4: 4/7 figuras (57%) - Faltan streamlines, turbulencia y comparación XFLR5
- Ejercicio 2: Código en estado placeholder


### ❌ Bloqueadores detectados:

- **CRÍTICO:** `ejercicio2.m` línea 45 usa caracteres incompatibles (°)
- **ADVERTENCIA:** `ej4_mesh_detail.png` posiblemente corrupto (8 KB)


### 📈 Próximos pasos sugeridos:

1. Corregir caracteres especiales en Ejercicio 2
2. Regenerar `ej4_mesh_detail.png` con mayor resolución
3. Crear scripts faltantes en `ejercicio4/matlab/` para comparación XFLR5

¿Quieres que genere alguno de estos archivos faltantes?

```

---

### PASO 5: Detección Inteligente de Nuevas Tareas

**Si el usuario añade un nuevo archivo (ej. crea `ejercicio8.m`), detecta y pregunta:**

```

⚠️ **Nuevo archivo detectado:** `01_Matlab_Exercises/src/ejercicio8.m`

Este archivo no está en `TODO.md`. ¿Es un nuevo ejercicio o un archivo auxiliar?

**Opciones:**

1. Añadir como "Ejercicio 8" con su propia sección de seguimiento
2. Añadir como "Script auxiliar" sin tracking de figuras
3. Ignorar (archivo temporal)

Responde con el número de opción o dame más contexto.

```

---

### REGLAS DE ORO PARA EL AGENTE

#### ❌ NUNCA hagas esto:
- Marcar algo como completado (✅) sin verificar que el archivo existe físicamente
- Inventar porcentajes sin criterio claro
- Eliminar entradas de la tabla de imágenes (solo actualiza estados)
- Cambiar la estructura del `TODO.md` sin avisar al usuario

#### ✅ SIEMPRE haz esto:
- Escanear archivos antes de actualizar estados
- Documentar en "Historial de Actualizaciones" qué cambió y por qué
- Alertar de problemas críticos inmediatamente
- Sugerir acciones concretas al finalizar el reporte
- Usar emojis consistentes: ✅ (OK), ❌ (Falta), ⚠️ (Problema), 🔄 (En progreso), 🚨 (Crítico)

---

### COMANDOS PARA EL USUARIO

**Activar actualización completa:**
```

@workspace Actualiza TODO.md con escaneo completo del proyecto

```

**Actualización rápida tras completar una tarea:**
```

@workspace Acabo de terminar las figuras del ejercicio 4, actualiza TODO.md

```

**Verificar solo imágenes:**
```

@workspace Revisa qué imágenes faltan en TODO.md

```

**Generar reporte sin modificar archivo:**
```

@workspace Dame un resumen del estado actual sin tocar TODO.md

```

---

### EJEMPLO COMPLETO DE ACTUALIZACIÓN

**Usuario escribe:**
```

@workspace Actualiza TODO.md

```

**Copilot ejecuta internamente:**
1. ✅ Escanea `01_Matlab_Exercises/plots/` → Encuentra 6 PDFs nuevos
2. ✅ Lee `04_Report_LaTeX/sections/*.tex` → Detecta 2 secciones escritas
3. ⚠️ Encuentra `ejercicio2.m` con comentario `TODO: Implementar`
4. ❌ Detecta referencia a `fig:ej5_vorticity` en LaTeX pero imagen no existe
5. 🔧 Recalcula porcentajes: Ej1 (100%), Ej2 (25%), Ej3 (0%), Ej4 (50%)

**Copilot actualiza `TODO.md`:**
- Cambia 6 filas de `❌ FALTA` → `✅` en tabla de imágenes
- Añade nueva fila para `fig:ej5_vorticity` con estado `❌ FALTA`
- Actualiza porcentajes en tabla de resumen
- Añade en "Problemas Detectados": Ejercicio 2 es placeholder
- Incrementa progreso global de 23% → 38%
- Añade entrada en "Historial de Actualizaciones"

**Copilot responde al usuario:**


`TODO.md` actualizado.

**Cambios principales:**

- 6 nuevas figuras generadas del Ejercicio 1 (ahora 100% completo 🎉)
- Detectado: Ejercicio 5 necesita figura de vorticidad (añadida a tabla)
- Advertencia: Ejercicio 2 sigue en placeholder

**Progreso global:** 23% → 38% (+15 puntos)

Ver detalles completos en `TODO.md` líneas 120-145.



## Setup de Openfoam y Paraview con Docker en Mac M1

## Instrucciones para Agentes IA: ejecutar casos con Docker, exportar plots y mostrar GUI

Estas instrucciones están pensadas para que un agente de IA (o un operador automático) pueda:
- ejecutar casos OpenFOAM en esta máquina usando Docker
- exportar datos/VTK para visualización
- generar capturas (headless) con `pvpython` o abrir la GUI de ParaView en el equipo del usuario cuando se solicite

Reglas generales (válidas para este repositorio):
- Imagen Docker recomendada: `microfluidica/openfoam:13` (ARM64, validada)
- Siempre ejecutar contenedor con usuario no-root: `-u 1000:1000` (necesario para `#calc` en `blockMeshDict`)
- Montar el workspace del proyecto en `/home/openfoam/work` dentro del contenedor
- ParaView debe ejecutarse localmente en macOS para la GUI; use `foamToVTK` en el contenedor para exportar datos.

1) Preparación y permisos

 - Asegurarse de estar en la raíz del proyecto:

```bash
cd "/Users/miguelrosa/Desktop/Master/Asignaturas/CFD/Practica"
```

 - Ajustar permisos del caso (si es necesario):

```bash
sudo chown -R 1000:1000 FVM/Ejercicio_7/cylinder
```

2) Ejecutar el caso en Docker (plantilla)

Copiar/adaptar la siguiente plantilla para ejecutar `Allrun` o el comando concreto del caso:

```bash
docker run --rm -u 1000:1000 \
   -v "$(pwd)":/home/openfoam/work \
   microfluidica/openfoam:13 \
   bash -lc "cd /home/openfoam/work/FVM/Ejercicio_7/cylinder && ./Allrun"
```

Comandos útiles individuales:

```bash
# Generar malla
docker run --rm -u 1000:1000 -v "$(pwd)":/home/openfoam/work microfluidica/openfoam:13 \
   bash -lc "cd /home/openfoam/work/FVM/Ejercicio_7/cylinder && blockMesh"

# Ejecutar solver (si no hay Allrun)
docker run --rm -u 1000:1000 -v "$(pwd)":/home/openfoam/work microfluidica/openfoam:13 \
   bash -lc "cd /home/openfoam/work/FVM/Ejercicio_7/cylinder && foamRun"

# Exportar VTK (último tiempo, sin functionObjects)
docker run --rm -u 1000:1000 -v "$(pwd)":/home/openfoam/work microfluidica/openfoam:13 \
   bash -lc "cd /home/openfoam/work/FVM/Ejercicio_7/cylinder && foamToVTK -noFunctionObjects -latestTime -constant"
```

3) Generar plots sin ParaView GUI (rápido, headless)

 - El repositorio ya incluye `FVM/Ejercicio_7/generar_graficas_postprocess.py` que usa `postProcessing/` para crear:
    - `Ej7_Cd_Cl_vs_time.png`
    - `Ej7_Cl_spectrum_Strouhal.png`
    - `Ej7_statistics_summary.png`

Ejecutar localmente (fuera de Docker) en el entorno Python del proyecto:

```bash
cd FVM/Ejercicio_7
python3 generar_graficas_postprocess.py
```

4) Generar capturas de campos con ParaView (pvpython) — headless o GUI

Opción A — Capturas automáticas (headless) con `pvpython` local:

1. Exportar VTK como en paso 2.
2. Ejecutar el script `pv_capture_vtk.py` con la versión de `pvpython` instalada en macOS:

```bash
# Ejemplo de ruta típica en macOS (ajustar versión)
/Applications/ParaView-6.0.1.app/Contents/bin/pvpython pv_capture_vtk.py
```

El script crea en `FVM/Ejercicio_7/figures/` imágenes PNG (velocidad, presión, vorticidad/fallback).

Opción B — Abrir la GUI de ParaView y ajustar vista interactivamente

 - Para mostrar la GUI al usuario (cuando el usuario lo pida), el agente debe proporcionar el comando que el usuario ejecute localmente (ej. `open -a ParaView cylinder.foam`)
    1. Informar exactamente el comando a ejecutar localmente (ej. `open -a ParaView cylinder.foam`)
    2. Ofrecer un script de arranque que ajuste la vista inicial (camera, colorbars, filtros) y lo deje listo para interacción. Ejemplo: `FVM/Ejercicio_7/pv_gui_preset.py` y la instrucción:

```bash
# Abrir ParaView y ejecutar preset (interactivo):
/Applications/ParaView-6.0.1.app/Contents/bin/pvpython --script=pv_gui_preset.py &
# O ejecutar dentro de ParaView: Tools -> Start Trace, ejecutar acciones y guardar macro/trace
```

 - Recomendación para crear un archivo `case.foam` vacío que abre los tiempos y la malla en ParaView:

```bash
cd FVM/Ejercicio_7/cylinder
touch cylinder.foam
# Luego el usuario arrastra/abre cylinder.foam en ParaView
```

5) Parámetros de vista y zoom recomendados (scripts o instrucciones interactivas)

 - Camera / zoom (pvpython o GUI): ajustar `CameraPosition`, `CameraFocalPoint` y `CameraParallelScale`.

Ejemplo pvpython para posición de cámara y zoom (puede incluirse en `pv_capture_vtk.py`):

```python
# En el script de ParaView
view.CameraPosition = [5, 0, 50]
view.CameraFocalPoint = [5, 0, 0]
view.CameraViewUp = [0, 1, 0]
view.CameraParallelProjection = 1
view.CameraParallelScale = 8  # reduce para hacer "zoom in"
```

 - Streamlines / seeds: ajustar `SeedType.Point1`, `SeedType.Point2`, `SeedType.Resolution` para variar densidad y longitud.

 - Color maps: usar `GetColorTransferFunction('U')` o `'p'` y aplicar presets (`ApplyPreset`) y límites (`RescaleTransferFunction(min,max)`).

 - Resolución de salida: `SaveScreenshot(..., ImageResolution=(1920,1080))` o aumentar `ImageResolution`/`magnification` para mayor DPI.

6) Mostrar la GUI al usuario cuando lo pida

 - Si el usuario solicita ver la GUI, el agente debe:
    1. Informar exactamente el comando a ejecutar localmente (ej. `open -a ParaView cylinder.foam`)
    2. Ofrecer un script de arranque que ajuste la vista inicial (camera, colorbars, filtros) y lo deje listo para interacción. Ejemplo: `FVM/Ejercicio_7/pv_gui_preset.py` y la instrucción:

```bash
# Abrir ParaView y ejecutar preset (interactivo):
/Applications/ParaView-6.0.1.app/Contents/bin/pvpython --script=pv_gui_preset.py &
# O el usuario puede abrir ParaView e importar cylinder.foam manualmente
```

 - Nota: El agente no debe intentar abrir interfaces gráficas remotas en el contenedor. Siempre indicar al usuario que ejecute la GUI localmente.

7) Parámetros que el agente debe parametrizar y exponer al usuario

 - `case_path` (ruta relativa en repo)
 - `docker_image` (por defecto `microfluidica/openfoam:13`)
 - `user_flag` (por defecto `-u 1000:1000`)
 - `vtk_latest` (True/False)
 - `pv_resolution` (ej. 1920x1080)
 - `camera_settings` (CameraPosition, CameraFocalPoint, CameraParallelScale)
 - `stream_seed` (Point1, Point2, Resolution)

8) Errores comunes que debe detectar el agente

 - "#calc failed" o fallos de compilación dinámico: reintentar con `-u 1000:1000` y `chown` del caso.
 - `foamToVTK` no produce VTK: comprobar que hay tiempos en el caso (`ls` de carpetas de tiempo) y usar `-latestTime`.
 - ParaView falla/segfault: recomendar usar la versión local más reciente y usar `pvpython` para capturas headless.

9) Ejemplo completo de flujo (resumen de comandos)

```bash
# 1. Preparar permisos
sudo chown -R 1000:1000 FVM/Ejercicio_7/cylinder

# 2. Ejecutar caso completo
docker run --rm -u 1000:1000 -v "$(pwd)":/home/openfoam/work microfluidica/openfoam:13 \
   bash -lc "cd /home/openfoam/work/FVM/Ejercicio_7/cylinder && ./Allrun"

# 3. Exportar VTK
docker run --rm -u 1000:1000 -v "$(pwd)":/home/openfoam/work microfluidica/openfoam:13 \
   bash -lc "cd /home/openfoam/work/FVM/Ejercicio_7/cylinder && foamToVTK -noFunctionObjects -latestTime -constant"

# 4. Generar gráficas numéricas (local)
cd FVM/Ejercicio_7
python3 generar_graficas_postprocess.py

# 5. Generar capturas de campo (local con ParaView)
/Applications/ParaView-6.0.1.app/Contents/bin/pvpython pv_capture_vtk.py

# 6. Si el usuario pide GUI: ejecutar localmente
open -a ParaView FVM/Ejercicio_7/cylinder/cylinder.foam
```

---

Estas instrucciones se añaden como anexos operativos para agentes automáticos: siempre validar las rutas antes de ejecutar y solicitar confirmación al usuario si se va a abrir la GUI o a ejecutar procesos de larga duración.

