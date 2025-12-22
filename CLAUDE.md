# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a master's thesis project in computational fluid dynamics (CFD) at Universidad de León. The work consists of 7 interconnected exercises combining theoretical aerodynamics methods (MATLAB) with numerical CFD simulations (OpenFOAM) and wind tunnel verification (XFLR5). All documentation is written in Spanish (LaTeX with IEEE style, RAE grammar standards).

**Key Context:**
- Student last digit of ID: 7
- Platform: macOS M1 (ARM64), 16GB RAM
- Target progress: 71% complete as of 2025-12-20

## Commands and Build Instructions

### MATLAB Scripts (Exercises 1-3: Aerodynamic Theory)

**Run individual exercises:**
```bash
cd 01_Matlab_Exercises/src/
matlab -batch "Ejercicio1_HessSmith"
matlab -batch "Ejercicio2_Multhopp"
matlab -batch "Ejercicio3_VortexLattice"
```

**Output locations:**
- Figures: `01_Matlab_Exercises/figures/Ejercicio{1,2,3}/`
- Data: `01_Matlab_Exercises/data/`

**Important MATLAB rules:**
- Export figures to `../figures/...` automatically as `.png` with white background
- Use LaTeX interpreter in axis labels and titles
- Vectorize code (avoid `for` loops where possible)
- **CRITICAL:** No LaTeX-incompatible characters in variable names (no `°`, `µ`, `α`, etc. — use `deg`, `mu`, `alpha` instead)

### OpenFOAM Simulations (Exercises 4-7: CFD)

**Mac M1 Docker Setup Required:**

```bash
# Pull ARM64-compatible image
docker pull microfluidica/openfoam:13

# Example: Run Ejercicio 7 (cylinder case)
docker run --rm -u 1000:1000 \
  -v "$(pwd)":/home/openfoam/work \
  microfluidica/openfoam:13 \
  bash -lc "cd /home/openfoam/work/02_OpenFOAM_FVM/cases/Ejercicio7 && ./Allrun"

# Export VTK for ParaView (last timestep)
docker run --rm -u 1000:1000 \
  -v "$(pwd)":/home/openfoam/work \
  microfluidica/openfoam:13 \
  bash -lc "cd /home/openfoam/work/02_OpenFOAM_FVM/cases/Ejercicio7 && foamToVTK -noFunctionObjects -latestTime -constant"
```

**Post-processing:**

```bash
# Generate plots from postprocessing data (local)
cd 02_OpenFOAM_FVM/post_processing/
python3 generate_ej5_plots.py

# Capture ParaView fields (local with installed ParaView)
/Applications/ParaView-6.0.1.app/Contents/bin/pvpython pv_capture_all.py
```

**Output locations:**
- Case setup: `02_OpenFOAM_FVM/cases/Ejercicio{4,5,6,7}/`
- Figures: `02_OpenFOAM_FVM/figures/Ejercicio{4,5,6,7}/`
- MATLAB analysis scripts: `02_OpenFOAM_FVM/matlab/`
- Python post-processing: `02_OpenFOAM_FVM/post_processing/`

### LaTeX Report Compilation

**Compile main document:**
```bash
cd 04_Report_LaTeX/
pdflatex -interaction=nonstopmode MemoriaCFD.tex
bibtex MemoriaCFD
pdflatex -interaction=nonstopmode MemoriaCFD.tex
pdflatex -interaction=nonstopmode MemoriaCFD.tex
```

Or use a LaTeX editor (VS Code with LaTeX Workshop, TeXShop, etc.)

**Structure:**
- Main: `MemoriaCFD.tex`
- Sections: `sections/{00..09}_*.tex`
- Figure paths: Configured via `\graphicspath` to find figures in `../01_Matlab_Exercises/figures/`, `../02_OpenFOAM_FVM/figures/`, `../03_XFLR5/figures/`
- Bibliography: `references.bib`

### XFLR5 Verification (Exercise 1 validation)

**Scripts for data export and comparison:**
```bash
cd 03_XFLR5/analysis_scripts/
matlab -batch "verificar_xflr5"  # Compares MATLAB results vs XFLR5 polars
```

**Output:**
- Exported polars: `03_XFLR5/exports/`
- Comparison figures: `03_XFLR5/figures/`
- Geometry files: `.dat` and `.txt` files in `xflr5_projects/`

## Architecture and Key Design Decisions

### Exercise Organization

The project is structured as **7 self-contained exercises**, each building on previous theoretical knowledge:

1. **Exercise 1 (Hess-Smith):** Panel method for airfoil pressure coefficient
   - Input: Airfoil coordinates (NACA-like profile)
   - Output: $C_p$ distribution, $C_L$, $C_M$ vs angle of attack
   - Method: Doublet and source panels
   - Verification: XFLR5

2. **Exercise 2 (Multhopp):** Lifting line theory for finite wings
   - Input: Wing planform (straight wing with ailerons)
   - Output: $C_L$, $C_{D_i}$, $C_M$ distributions along span
   - Method: Numerical lifting line with Schrenk's approximation

3. **Exercise 3 (Vortex Lattice):** 3D VLM for tandem wing configuration
   - Input: Biplane/tandem geometry (main wing + canard)
   - Output: Aerodynamic derivatives (CL, CDi, CM per wing)
   - Method: Lattice of vortex filaments

4. **Exercise 4 (Numerical Schemes):** Finite Volume discretization tests
   - Input: OpenFOAM setup for Couette flow and cylinder wake
   - Output: Convergence analysis of upwind/central/high-order schemes
   - Method: Manufactured solution and comparison

5. **Exercise 5 (Wall Functions):** RANS turbulence modeling near walls
   - Input: Flat plate with boundary layer mesh
   - Output: $u^+$ vs $y^+$, comparison with log-law
   - Method: $k$-$\epsilon$ with standard wall functions
   - MATLAB post-processing in `02_OpenFOAM_FVM/matlab/plot_ejercicio5.m`

6. **Exercise 6 (Laminar Cylinder):** 2D laminar flow around cylinder
   - Input: Structured mesh, Re = 40 (low Reynolds)
   - Output: Streamlines, separation bubbles, pressure coefficient
   - Method: SIMPLE algorithm, transient
   - **Status:** Pending LaTeX section and figure generation

7. **Exercise 7 (Turbulent Cylinder):** 2D turbulent flow around cylinder
   - Input: Structured mesh, Re = 3900 (transitional-turbulent)
   - Output: Vortex shedding frequency (Strouhal), drag/lift time series, spectral analysis
   - Method: URANS ($k$-$\omega$-SST), transient
   - Complete with 15+ analysis figures

### Code Organization Patterns

**MATLAB Exercises (1-3):**
- Single script per exercise (`Ejercicio{1,2,3}_*.m`)
- Auto-creates output directory if missing
- All figures exported at script end with high DPI settings
- No file paths hardcoded; use relative paths from script location

**OpenFOAM Cases (4-7):**
- Each exercise is a separate case directory under `02_OpenFOAM_FVM/cases/`
- Follow OpenFOAM structure: `system/`, `constant/`, `0/` directories
- `Allrun` script orchestrates the full simulation workflow
- Docker execution for cross-platform consistency (critical for M1 Mac)

**Post-processing:**
- Python scripts in `02_OpenFOAM_FVM/post_processing/` for headless ParaView automation
- MATLAB scripts in `02_OpenFOAM_FVM/matlab/` for numerical analysis and plotting
- All output figures go to `02_OpenFOAM_FVM/figures/Ejercicio{X}/`

**LaTeX Integration:**
- Each exercise gets one section file: `sections/{N}_{ejercicio}{X}.tex`
- Figures referenced via `\ref{fig:label}` (labels defined where images are included)
- All theoretical equations in proper LaTeX environments
- Cross-references use `~\eqref{}` for equations, `~\ref{fig:}` for figures

### Critical Configuration Files

**`.github/instructions/Instructions.instructions.md`:**
  - Contains comprehensive guidelines for Copilot on code style, grammar standards (RAE), OpenFOAM Docker setup, and project structure
  - Read this first for context on aerodynamic concepts and implementation philosophy

**`TODO.md`:**
  - Tracks project completion status with detailed inventory of figures and code
  - Updated whenever tasks are completed or problems detected
  - Includes timestamp and specific line references for debugging

**`04_Report_LaTeX/MemoriaCFD.tex`:**
  - Main LaTeX document; imports all sections
  - Defines `\graphicspath` for automatic figure location discovery
  - Configured for IEEE technical writing style in Spanish

## Important Constraints and Conventions

### Language and Writing
- **Spanish only** for LaTeX documents (RAE grammar standards)
- **English comments** acceptable in code (MATLAB, Python, C++)
- Use voz pasiva ("Se ha calculado...", "Se observa...") in technical writing
- No made-up citations; verify all BibTeX entries in `references.bib`

### Figure Generation
- **All MATLAB figures must export as `.png` with white background** for LaTeX integration
- Axis labels must use LaTeX formatting (e.g., `xlabel('$\alpha$ (°)')`)
- Automatic save-at-end-of-script pattern (don't rely on manual export)
- High DPI for print quality (use `saveas(..., 'png')` or `print(..., '-dpng')`)

### Variable Naming in Code
- **No accents or special characters** in MATLAB/Python variable names
- Use `alpha`, `beta`, `velocidad` instead of `α`, `β`, `velocidad`
- Use `deg` for degrees, `mu` for microns/viscosity
- This prevents LaTeX compilation errors if code appears in annexes

### Docker and Execution
- Always use `-u 1000:1000` flag to avoid permission issues with `#calc` in `blockMeshDict`
- Mount workspace at `/home/openfoam/work` inside container
- Export VTK with `-latestTime` flag for most recent results
- ParaView GUI must run locally on macOS (not in Docker)

### File Organization
- Never use absolute paths; all paths relative to project root or script location
- Create output directories automatically in MATLAB (`mkdir()`) and Python (`os.makedirs()`)
- Figure filenames should match their `\ref{}` labels for easy cross-referencing

## Status and Priority Tasks

**Current Progress:** 71% complete

**High Priority (Blocking compilation):**
- Ejercicio 6: LaTeX section needs to be written with results and analysis
- Ejercicio 5: Missing figures (2 of 4) for wall function plots



**Low Priority:**
- Annexes with complete source code
- Hardware/software specifications section (partially done)

See `TODO.md` for exhaustive tracking of figures and code status with individual line references.

## Troubleshooting Common Issues

**Docker errors with `#calc`:**
- Problem: `blockMeshDict` calculation fails
- Solution: Ensure `-u 1000:1000` is set and case directory has correct permissions
- Fallback: Use `chown -R 1000:1000 case_path` on Mac before running

**ParaView headless capture fails:**
- Problem: `pvpython` script crashes or produces blank images
- Solution: Use installed ParaView binary path (check `/Applications/ParaView-*.app/`)
- Fallback: Open GUI manually (`open -a ParaView case.foam`) and save screenshots interactively

**MATLAB figure exports missing:**
- Problem: `.png` files not generated after running script
- Solution: Check that `fig_dir` is writable; scripts auto-create if missing
- Verify: Look for `mkdir()` in first section of script and confirm it succeeds

**LaTeX compilation with figure paths:**
- Problem: `! Package graphics Error: File 'fig.png' not found`
- Solution: Verify `\graphicspath` includes all source directories
- Check: Ensure figures are actually in `01_Matlab_Exercises/figures/`, etc. (run MATLAB scripts first)

**OpenFOAM case divergence:**
- Problem: Solver fails to converge or produces NaN
- Solution: Check initial conditions in `0/` directory; adjust time step and relaxation factors
- Reference: Each case has commented notes in `system/fvSolution` explaining tuning parameters

---

**Last Updated:** 2025-12-20
**Repository:** GitHub (reference in Chapter 0 introduction)
