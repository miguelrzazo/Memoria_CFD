#!/bin/bash
# Build and save OpenFOAM Docker image for reproducibility
# This script creates a reproducible Docker image that can be committed to Git

set -e

IMAGE_NAME="memoria-cfd-openfoam"
IMAGE_TAG="13"
FULL_IMAGE_NAME="${IMAGE_NAME}:${IMAGE_TAG}"
TAR_FILE="${IMAGE_NAME}-${IMAGE_TAG}.tar"

echo "Building Docker image: ${FULL_IMAGE_NAME}"
echo "This may take several minutes..."

# Build the image
docker build -t ${FULL_IMAGE_NAME} .

echo "Saving image to ${TAR_FILE}..."
echo "This ensures the exact same environment can be reproduced"

# Save the image as a tar file
docker save ${FULL_IMAGE_NAME} -o ${TAR_FILE}

echo "Image saved successfully!"
echo "File: ${TAR_FILE}"
echo "Size: $(du -h ${TAR_FILE} | cut -f1)"

echo ""
echo "To load this image on another machine:"
echo "  docker load -i ${TAR_FILE}"
echo ""
echo "To use with docker-compose:"
echo "  docker-compose up -d"
echo ""
echo "To run a case:"
echo "  docker-compose run --rm openfoam bash -c 'cd cases/Ejercicio4/Parte1_FVM/OneDScalar_5celdas && ./Allrun'"