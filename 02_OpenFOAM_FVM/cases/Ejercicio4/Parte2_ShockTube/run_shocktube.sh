#!/bin/bash
# Script para ejecutar los casos de Shock Tube - Parte 2 del Ejercicio 4
# OpenFOAM 13 en Docker

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_IMAGE="openfoam/openfoam13-graphical-apps:latest"

echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}  EJERCICIO 4 - PARTE 2: Shock Tube de Sod${NC}"
echo -e "${GREEN}================================================${NC}"

run_shocktube() {
    local case_name=$1
    local case_path="${SCRIPT_DIR}/${case_name}"

    echo -e "\n${YELLOW}>>> Ejecutando caso: ${case_name}${NC}"

    if [ ! -d "$case_path" ]; then
        echo -e "${RED}Error: No existe el directorio ${case_path}${NC}"
        return 1
    fi

    docker run --rm -v "${case_path}:/case" -w /case ${DOCKER_IMAGE} bash -c "
        source /opt/openfoam13/etc/bashrc

        # Limpiar caso anterior
        rm -rf 0.[0-9]* [1-9]* processor* postProcessing log.* 2>/dev/null

        # Copiar archivos originales
        cp 0/p.orig 0/p 2>/dev/null || true
        cp 0/T.orig 0/T 2>/dev/null || true
        cp 0/U.orig 0/U 2>/dev/null || true

        echo 'Generando malla...'
        blockMesh > log.blockMesh 2>&1

        echo 'Estableciendo campos iniciales...'
        setFields > log.setFields 2>&1

        echo 'Ejecutando solver (compressible rhoCentralFoam)...'
        foamRun > log.foamRun 2>&1

        echo 'Extrayendo datos de linea...'
        postProcess -func 'graphUniform' > log.postProcess 2>&1 || true

        echo 'Caso completado'
    "

    echo -e "${GREEN}<<< Caso ${case_name} completado${NC}"
}

# Ejecutar ambos casos
run_shocktube "shockTube_highOrder"
run_shocktube "shockTube_lowOrder"

echo -e "\n${GREEN}================================================${NC}"
echo -e "${GREEN}  Shock Tube simulaciones completadas${NC}"
echo -e "${GREEN}================================================${NC}"
