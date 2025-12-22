#!/usr/bin/env python3
"""Check and report figures for Ejercicio4."""
import os
base = os.path.normpath(os.path.join(os.path.dirname(__file__), '../../figures/Ejercicio4'))
expected = [
    'shocktube_comparacion_esquemas.png',
    'shocktube_detalle_discontinuidades.png',
    'shocktube_diagrama_xt.png',
    'shocktube_tabla_errores.png',
    'onedscalar_solution.png',
    'onedscalar_error.png'
]
print('Figures folder:', base)
for f in expected:
    p = os.path.join(base, f)
    print(f'{f}:', 'FOUND' if os.path.exists(p) else 'MISSING')
# Summary
found = [f for f in expected if os.path.exists(os.path.join(base,f))]
print('\nSummary: {}/{} expected figures present.'.format(len(found), len(expected)))
