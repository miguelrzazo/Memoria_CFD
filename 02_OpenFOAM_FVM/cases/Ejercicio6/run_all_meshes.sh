#!/bin/bash
# Script para re-ejecutar todos los niveles de malla del Ejercicio 6

echo "=========================================="
echo "RE-EJECUTANDO EJERCICIO 6 - Convergencia"
echo "=========================================="
echo ""

CASES=("cylinder_coarse" "cylinder_medium" "cylinder_fine")

for case in "${CASES[@]}"; do
    echo ">>> Limpiando $case..."
    cd "$case"
    ./Allclean 2>/dev/null || rm -rf [1-9]* processor* postProcessing dynamicCode
    
    echo ">>> Ejecutando $case con Docker..."
    docker run --rm -u 1000:1000 \
        -v "$(pwd):/home/openfoam/work" \
        microfluidica/openfoam:13 \
        bash -lc "cd /home/openfoam/work && ./Allrun"
    
    echo "✓ $case completado"
    echo ""
    cd ..
done

echo "=========================================="
echo "✓ Todas las mallas completadas"
echo "=========================================="
