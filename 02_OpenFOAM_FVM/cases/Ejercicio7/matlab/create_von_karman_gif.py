#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script para crear GIF animado de la estela de von Karman - Ejercicio 7
Combina las imágenes velocity_estela_t*.png en un GIF animado
"""

import os
from PIL import Image
import glob

def create_von_karman_gif():
    """
    Crea un GIF animado con la evolución de la estela de von Karman
    """

    # Configuración de rutas
    script_dir = os.path.dirname(os.path.abspath(__file__))
    fig_dir = os.path.join(script_dir, '..', '..', '..', 'figures', 'Ejercicio7')

    # Patrón para encontrar las imágenes de la estela
    pattern = os.path.join(fig_dir, 'velocity_estela_t*.png')
    image_files = sorted(glob.glob(pattern))

    if not image_files:
        print("Error: No se encontraron imágenes de la estela de von Karman")
        return

    print(f"Encontradas {len(image_files)} imágenes:")
    for img_file in image_files:
        print(f"  {os.path.basename(img_file)}")

    # Cargar las imágenes
    images = []
    for img_file in image_files:
        img = Image.open(img_file)
        images.append(img)

    # Configuración del GIF
    gif_filename = os.path.join(fig_dir, 'von_karman_estela.gif')

    # Crear GIF animado
    # Duración: 500ms por frame (2 fps para ver la evolución claramente)
    # loop=0 significa bucle infinito
    images[0].save(
        gif_filename,
        save_all=True,
        append_images=images[1:],
        duration=500,  # milisegundos por frame
        loop=0,        # bucle infinito
        optimize=True
    )

    print(f"\nGIF creado exitosamente: {gif_filename}")
    print(f"Tamaño: {len(images)} frames")
    print(f"Duración por frame: 500ms (2 fps)")

    # Información adicional
    file_size = os.path.getsize(gif_filename) / 1024  # KB
    print(".1f")

if __name__ == "__main__":
    print("=" * 60)
    print("  Creando GIF de la estela de von Karman - Ejercicio 7")
    print("=" * 60)

    create_von_karman_gif()

    print("\n" + "=" * 60)
    print("  GIF completado")
    print("=" * 60)