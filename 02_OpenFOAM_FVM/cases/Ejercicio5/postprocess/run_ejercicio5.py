#!/usr/bin/env python3
"""Check and report figures for Ejercicio5."""
import os
base = os.path.normpath(os.path.join(os.path.dirname(__file__), '../../figures/Ejercicio5'))
print('Figures folder:', base)
if os.path.exists(base):
    imgs = [f for f in os.listdir(base) if f.lower().endswith('.png') or f.lower().endswith('.pdf')]
    print('Found {} image(s):'.format(len(imgs)))
    for f in imgs:
        print(' -', f)
else:
    print('Figures folder does not exist or is empty.')
