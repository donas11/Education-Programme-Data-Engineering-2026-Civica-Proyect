#!/usr/bin/env python3
import json, shutil, sys
from pathlib import Path

PROJECT_DIR = Path(sys.argv[1]) if len(sys.argv) > 1 else Path('./4_dbt')
DOCS_DIR = Path(sys.argv[2]) if len(sys.argv) > 2 else Path('./docs')
TARGET_DIR = PROJECT_DIR / 'target'
MANIFEST = TARGET_DIR / 'manifest.json'
CATALOG = TARGET_DIR / 'catalog.json'

if not MANIFEST.exists():
    print(f'ERROR: No existe {MANIFEST}')
    print(f'Ejecuta antes: dbt compile --write-catalog --write-index --project-dir {PROJECT_DIR} --profiles-dir ~/.dbt')
    sys.exit(1)

DOCS_DIR.mkdir(parents=True, exist_ok=True)
shutil.copy2(MANIFEST, DOCS_DIR / 'manifest.json')
if CATALOG.exists():
    shutil.copy2(CATALOG, DOCS_DIR / 'catalog.json')
else:
    print(f'WARN: No existe {CATALOG}; se generará el sitio sin tipos de columna del catálogo')

manifest = json.loads((DOCS_DIR / 'manifest.json').read_text(encoding='utf-8'))
catalog = None
if (DOCS_DIR / 'catalog.json').exists():
    catalog = json.loads((DOCS_DIR / 'catalog.json').read_text(encoding='utf-8'))

def pack(n, type_):
    cn = None
    if catalog:
        cn = catalog.get('nodes', {}).get(n.get('unique_id')) or catalog.get('sources', {}).get(n.get('unique_id'))
    return {
        'id': n.get('unique_id'),
        'name': n.get('name'),
        'type': type_,
        'schema': n.get('schema', ''),
        'database': n.get('database', ''),
        'description': n.get('description', '') or '',
        'path': n.get('path', '') or '',
        'depends_on': (n.get('depends_on', {}) or {}).get('nodes', []) or [],
        'compiled_code': n.get('compiled_code') or n.get('raw_code') or '',
        'columns': n.get('columns', {}) or {},
        'catalogNode': cn,
        'tags': n.get('tags', []) or [],
        'label': n.get('label', '') or '',
        'metric_type': n.get('type', '') or '',
        'entities': n.get('entities', []) or [],
        'dimensions': n.get('dimensions', []) or [],
        'measures': n.get('measures', []) or []
    }

nodes=[]
for n in (manifest.get('nodes', {}) or {}).values():
    if n.get('resource_type') in ('model', 'seed', 'snapshot'):
        nodes.append(pack(n, n['resource_type']))
for n in (manifest.get('sources', {}) or {}).values():
    nodes.append(pack(n, 'source'))
for n in (manifest.get('metrics', {}) or {}).values():
    nodes.append(pack(n, 'metric'))
for n in (manifest.get('semantic_models', {}) or {}).values():
    nodes.append(pack(n, 'semantic_model'))

site_data = {'nodes': nodes, 'counts': {'all': len(nodes)}, 'layers': sorted({n['path'].split('/')[0] for n in nodes if n.get('path')})}
(DOCS_DIR / 'site-data.json').write_text(json.dumps(site_data, ensure_ascii=False, indent=2), encoding='utf-8')
(DOCS_DIR / '.nojekyll').write_text('', encoding='utf-8')
(DOCS_DIR / 'index.html').write_text('<!doctype html><html><body><h1>dbt docs viewer</h1><p>Generado correctamente. Usa site-data.json para la UI.</p></body></html>', encoding='utf-8')
print(f'OK: generado {DOCS_DIR / "index.html"}')
print(f'OK: generado {DOCS_DIR / "site-data.json"}')
print(f'OK: generado {DOCS_DIR / ".nojekyll"}')
