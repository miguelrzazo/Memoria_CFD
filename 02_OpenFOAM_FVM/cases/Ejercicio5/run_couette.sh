#!/bin/bash
# Script para ejecutar los casos de Couette - Ejercicio 5
# Comparacion Low-Reynolds vs High-Reynolds (Wall Functions)
# OpenFOAM 13 en Docker

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_IMAGE="openfoam/openfoam13-graphical-apps:latest"

echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}  EJERCICIO 5: Couette Flow - Wall Functions${NC}"
echo -e "${GREEN}================================================${NC}"

run_couette() {
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
        rm -rf 0.[0-9]* [1-9]* processor* postProcessing log.* constant/polyMesh 2>/dev/null

        echo 'Generando malla...'
        blockMesh > log.blockMesh 2>&1

        echo 'Ejecutando solver (simpleFoam/foamRun)...'
        foamRun > log.foamRun 2>&1

        # Calcular yPlus
        echo 'Calculando yPlus...'
        postProcess -func 'yPlus' -latestTime > log.yPlus 2>&1 || true

        # Extraer perfil vertical
        echo 'Extrayendo perfiles...'
        postProcess -func 'graphUniform' -latestTime > log.postProcess 2>&1 || true

        echo 'Caso completado'
    "

    echo -e "${GREEN}<<< Caso ${case_name} completado${NC}"
}

# Ejecutar ambos casos
echo -e "\n${YELLOW}Ejecutando caso Low-Reynolds (sin wall functions)...${NC}"
run_couette "planarCouette_LowRe"

echo -e "\n${YELLOW}Ejecutando caso High-Reynolds (con wall functions)...${NC}"
run_couette "planarCouette_HighRe"

echo -e "\n${GREEN}================================================${NC}"
echo -e "${GREEN}  Ejercicio 5 simulaciones completadas${NC}"
echo -e "${GREEN}================================================${NC}"
