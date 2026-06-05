#!/usr/bin/env python3
import json
import shutil
import sys
from pathlib import Path

PROJECT_DIR = Path(sys.argv[1]) if len(sys.argv) > 1 else Path('./4_dbt')
DOCS_DIR = Path(sys.argv[2]) if len(sys.argv) > 2 else Path('./docs')
TARGET_DIR = PROJECT_DIR / 'target'
MANIFEST = TARGET_DIR / 'manifest.json'
CATALOG = TARGET_DIR / 'catalog.json'

if not MANIFEST.exists():
    print(f'ERROR: No existe {MANIFEST}')
    print(f'Ejecuta antes: dbt docs generate --project-dir {PROJECT_DIR} --profiles-dir ~/.dbt')
    sys.exit(1)

DOCS_DIR.mkdir(parents=True, exist_ok=True)
shutil.copy2(MANIFEST, DOCS_DIR / 'manifest.json')
if CATALOG.exists():
    shutil.copy2(CATALOG, DOCS_DIR / 'catalog.json')

with MANIFEST.open(encoding='utf-8') as f:
    manifest = json.load(f)

catalog = None
if (DOCS_DIR / 'catalog.json').exists():
    with (DOCS_DIR / 'catalog.json').open(encoding='utf-8') as f:
        catalog = json.load(f)


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
        'meta': n.get('meta', {}) or {},
        'resource_type': n.get('resource_type', type_),
        'package_name': n.get('package_name', ''),
        'original_file_path': n.get('original_file_path', ''),
        'config': n.get('config', {}) or {},
        'materialized': (n.get('config', {}) or {}).get('materialized', ''),
        'label': n.get('label', '') or '',
        'metric_type': n.get('type', '') or '',
        'entities': n.get('entities', []) or [],
        'dimensions': n.get('dimensions', []) or [],
        'measures': n.get('measures', []) or []
    }

nodes = []
for n in (manifest.get('nodes', {}) or {}).values():
    if n.get('resource_type') in ('model', 'seed', 'snapshot'):
        nodes.append(pack(n, n['resource_type']))
for n in (manifest.get('sources', {}) or {}).values():
    nodes.append(pack(n, 'source'))
for n in (manifest.get('metrics', {}) or {}).values():
    nodes.append(pack(n, 'metric'))
for n in (manifest.get('semantic_models', {}) or {}).values():
    nodes.append(pack(n, 'semantic_model'))

site_data = {
    'nodes': nodes,
    'counts': {
        'all': len(nodes),
        'model': sum(1 for n in nodes if n['type'] == 'model'),
        'source': sum(1 for n in nodes if n['type'] == 'source'),
        'seed': sum(1 for n in nodes if n['type'] == 'seed'),
        'snapshot': sum(1 for n in nodes if n['type'] == 'snapshot'),
        'metric': sum(1 for n in nodes if n['type'] == 'metric'),
        'semantic_model': sum(1 for n in nodes if n['type'] == 'semantic_model')
    },
    'layers': sorted({n['path'].split('/')[0] for n in nodes if n.get('path') and '/' in n['path']} | {n['path'] for n in nodes if n.get('path') and '/' not in n['path']})
}

(DOCS_DIR / 'site-data.json').write_text(json.dumps(site_data, ensure_ascii=False, indent=2), encoding='utf-8')
(DOCS_DIR / '.nojekyll').write_text('', encoding='utf-8')

html = r'''<!DOCTYPE html>
<html lang="es" data-theme="dark">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>dbt Docs Viewer</title>
<meta name="description" content="Static dbt docs viewer for GitHub Pages">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@300..800&family=JetBrains+Mono:wght@400;600&display=swap" rel="stylesheet">
<script src="https://unpkg.com/vis-network/standalone/umd/vis-network.min.js"></script>
<style>
:root,[data-theme="light"]{--bg:#f7f6f2;--surface:#f9f8f5;--surface2:#fbfbf9;--offset:#f3f0ec;--dynamic:#e6e4df;--divider:#dcd9d5;--border:#d4d1ca;--text:#28251d;--muted:#7a7974;--faint:#bab9b4;--primary:#01696f;--primary-hi:#cedcd8;--blue:#006494;--gold:#d19900;--success:#437a22;--purple:#7a39bb;--shadow:0 4px 12px rgba(0,0,0,.08)}
[data-theme="dark"]{--bg:#171614;--surface:#1c1b19;--surface2:#201f1d;--offset:#1d1c1a;--dynamic:#2d2c2a;--divider:#262523;--border:#393836;--text:#cdccca;--muted:#797876;--faint:#5a5957;--primary:#4f98a3;--primary-hi:#313b3b;--blue:#5591c7;--gold:#e8af34;--success:#6daa45;--purple:#a86fdf;--shadow:0 8px 20px rgba(0,0,0,.22)}
*{box-sizing:border-box}html,body{margin:0;height:100%}body{font-family:Inter,system-ui,sans-serif;background:var(--bg);color:var(--text)}button,input,select{font:inherit}button{cursor:pointer}
a{color:var(--primary)}
.app{display:grid;grid-template-rows:56px 1fr;height:100vh}.topbar{display:flex;align-items:center;gap:1rem;padding:0 1.25rem;background:var(--surface);border-bottom:1px solid var(--divider);position:sticky;top:0;z-index:20}.brand{font-weight:800}.search{flex:1;max-width:460px;background:var(--bg);color:var(--text);border:1px solid var(--border);border-radius:999px;padding:.7rem 1rem}.topbtn{border:1px solid var(--border);background:var(--bg);color:var(--text);border-radius:.65rem;padding:.55rem .8rem}
.layout{display:grid;grid-template-columns:280px 1fr;height:calc(100vh - 56px)}.sidebar{overflow:auto;background:var(--surface);border-right:1px solid var(--divider);padding:1rem 0}.content{overflow:auto;padding:1.5rem}.side-title{font-size:.75rem;text-transform:uppercase;letter-spacing:.05em;color:var(--faint);padding:0 1rem .5rem}.sidebar-item{display:flex;justify-content:space-between;align-items:center;width:100%;padding:.7rem 1rem;background:none;border:0;color:var(--muted);text-align:left}.sidebar-item:hover,.sidebar-item.active{background:var(--offset);color:var(--text)}.badge{font-size:.75rem;border-radius:999px;padding:.1rem .45rem;background:var(--dynamic)}
.filters{padding:.25rem 1rem .75rem;display:flex;flex-wrap:wrap;gap:.35rem}.chip-btn{border:1px solid var(--border);background:var(--bg);color:var(--muted);border-radius:999px;padding:.3rem .6rem;font-size:.75rem}.chip-btn.active{background:var(--primary-hi);border-color:var(--primary);color:var(--primary)}
.stats{display:flex;flex-wrap:wrap;gap:1rem;margin-bottom:1rem}.stat{background:var(--surface);border:1px solid var(--divider);border-radius:.85rem;padding:1rem;min-width:130px;box-shadow:var(--shadow)}.n{font-size:1.6rem;font-weight:800}.label{color:var(--muted);font-size:.85rem}
.grid{display:grid;gap:.85rem}.card{background:var(--surface);border:1px solid var(--divider);border-radius:.9rem;padding:1rem;cursor:pointer;transition:.15s ease}.card:hover{border-color:var(--primary);transform:translateY(-1px)}.card.selected{border-color:var(--primary);background:var(--primary-hi)}.row{display:flex;gap:.5rem;align-items:center;flex-wrap:wrap}.mono{font-family:"JetBrains Mono",monospace}.muted{color:var(--muted)}.chips{display:flex;gap:.4rem;flex-wrap:wrap;margin-top:.5rem}.chip{font-size:.75rem;padding:.15rem .5rem;border-radius:999px;background:var(--offset);border:1px solid var(--border)}
.detail{margin-top:1rem;background:var(--surface2);border:1px solid var(--divider);border-radius:1rem;padding:1.25rem}.section{margin-bottom:1.25rem}.section h3{font-size:.8rem;text-transform:uppercase;letter-spacing:.05em;color:var(--faint);border-bottom:1px solid var(--divider);padding-bottom:.55rem;margin-bottom:.8rem}.table{width:100%;border-collapse:collapse;font-size:.86rem}.table th,.table td{text-align:left;padding:.55rem;border-bottom:1px solid var(--divider);vertical-align:top}.code{white-space:pre-wrap;overflow:auto;max-height:340px;background:var(--bg);border:1px solid var(--border);border-radius:.8rem;padding:1rem;font-family:"JetBrains Mono",monospace;font-size:.8rem}.lineage{height:440px;border:1px solid var(--divider);border-radius:.85rem;background:var(--bg)}
.kv{display:grid;grid-template-columns:180px 1fr;gap:.5rem 1rem}.kv div:nth-child(odd){color:var(--muted)}.empty{padding:2rem;background:var(--surface);border:1px solid var(--divider);border-radius:1rem;color:var(--muted)}
@media(max-width:980px){.layout{grid-template-columns:1fr}.sidebar{display:none}.kv{grid-template-columns:1fr}}
</style>
</head>
<body>
<div class="app">
  <div class="topbar">
    <div class="brand">dbt Docs Viewer</div>
    <input id="search" class="search" placeholder="Buscar modelos, columnas, descripción...">
    <button class="topbtn" onclick="toggleTheme()">Tema</button>
  </div>
  <div class="layout">
    <aside class="sidebar">
      <div class="side-title">Recursos</div>
      <div id="sidebarNav"></div>
      <div class="side-title">Capas</div>
      <div id="layerFilters" class="filters"></div>
    </aside>
    <main class="content">
      <div id="stats" class="stats"></div>
      <div id="list" class="grid"></div>
      <div id="detail"></div>
    </main>
  </div>
</div>
<script>
fetch('./site-data.json').then(r=>r.json()).then(data=>{
  const allNodes=data.nodes||[];
  const globalCounts=data.counts||{all:allNodes.length};
  const layers=data.layers||[];
  let state={view:'all',selectedId:null,currentLayer:null};
  const TYPES=['all','model','source','seed','snapshot','metric','semantic_model'];
  const LABELS={all:'Todos',model:'Modelos',source:'Sources',seed:'Seeds',snapshot:'Snapshots',metric:'Métricas',semantic_model:'Semantic Models'};
  const esc=s=>(s||'').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
  const search=document.getElementById('search');

  function getTypeColor(type){
    return ({model:'var(--primary)',source:'var(--blue)',seed:'var(--gold)',snapshot:'var(--purple)',metric:'var(--success)',semantic_model:'var(--primary)'})[type] || 'var(--primary)';
  }

  function renderSidebar(){
    document.getElementById('sidebarNav').innerHTML=TYPES.map(t=>`<button class="sidebar-item ${state.view===t?'active':''}" onclick="window.__setView('${t}')"><span>${LABELS[t]}</span><span class="badge">${globalCounts[t]||0}</span></button>`).join('');
    document.getElementById('layerFilters').innerHTML=layers.map(l=>`<button class="chip-btn ${state.currentLayer===l?'active':''}" onclick="window.__toggleLayer('${l}')">${l}</button>`).join('') || '<span class="muted">Sin capas detectadas</span>';
  }

  function filtered(){
    const q=(search.value||'').toLowerCase();
    let rows=allNodes.filter(n=>state.view==='all'||n.type===state.view);
    if(state.currentLayer) rows=rows.filter(n=>n.path && (n.path===state.currentLayer || n.path.startsWith(state.currentLayer+'/')));
    if(q){
      rows=rows.filter(n=>
        (n.name||'').toLowerCase().includes(q) ||
        (n.description||'').toLowerCase().includes(q) ||
        Object.keys(n.columns||{}).some(c=>c.toLowerCase().includes(q)) ||
        (n.path||'').toLowerCase().includes(q)
      );
    }
    return rows;
  }

  function render(){
    const rows=filtered();
    const c={}; rows.forEach(n=>c[n.type]=(c[n.type]||0)+1);
    document.getElementById('stats').innerHTML=Object.entries(c).map(([k,v])=>`<div class="stat"><div class="n">${v}</div><div class="label">${LABELS[k]||k}</div></div>`).join('') || '<div class="empty">No hay recursos para este filtro.</div>';
    document.getElementById('list').innerHTML=rows.map(n=>`<div class="card ${state.selectedId===n.id?'selected':''}" onclick="window.__showDetail('${n.id}')"><div class="row"><strong class="mono">${esc(n.name)}</strong><span class="chip" style="border-color:${getTypeColor(n.type)};color:${getTypeColor(n.type)}">${n.type}</span>${n.materialized?`<span class="chip">${esc(n.materialized)}</span>`:''}</div>${n.description?`<div class="muted" style="margin-top:.35rem">${esc(n.description.slice(0,180))}${n.description.length>180?'…':''}</div>`:''}<div class="chips">${n.schema?`<span class="chip">${esc((n.database?n.database+'.':'')+n.schema)}</span>`:''}${n.path?`<span class="chip">${esc(n.path)}</span>`:''}${Object.keys(n.columns||{}).length?`<span class="chip">${Object.keys(n.columns).length} columnas</span>`:''}${n.depends_on.length?`<span class="chip">${n.depends_on.length} deps</span>`:''}</div></div>`).join('');
    renderSidebar();
    if(state.selectedId) renderDetail();
  }

  function renderDetail(){
    const n=allNodes.find(x=>x.id===state.selectedId); if(!n) return;
    const mCols=n.columns||{};
    const cCols=(n.catalogNode&&n.catalogNode.columns)||{};
    const allCols={...mCols};
    Object.entries(cCols).forEach(([k,v])=>{const lk=k.toLowerCase(); if(!allCols[lk]) allCols[lk]={}; allCols[lk]={...allCols[lk], type:v.type};});
    const colRows=Object.keys(allCols).sort().map(k=>{const c=allCols[k]; const t=c.type||cCols[k]?.type||cCols[k.toUpperCase()]?.type||'—'; return `<tr><td class="mono">${esc(k)}</td><td class="mono">${esc(t)}</td><td>${esc(c.description||'—')}</td></tr>`;}).join('');
    document.getElementById('detail').innerHTML=`
      <div class="detail">
        <div class="section">
          <h3>Recurso</h3>
          <div class="row"><strong class="mono" style="font-size:1.1rem">${esc(n.name)}</strong><span class="chip">${n.type}</span>${n.materialized?`<span class="chip">${esc(n.materialized)}</span>`:''}</div>
          ${n.description?`<p class="muted">${esc(n.description)}</p>`:''}
        </div>
        <div class="section">
          <h3>Detalles</h3>
          <div class="kv">
            <div>Unique ID</div><div class="mono">${esc(n.id||'')}</div>
            <div>Schema</div><div>${esc(n.schema||'—')}</div>
            <div>Database</div><div>${esc(n.database||'—')}</div>
            <div>Path</div><div class="mono">${esc(n.path||n.original_file_path||'—')}</div>
            <div>Package</div><div>${esc(n.package_name||'—')}</div>
            <div>Dependencias</div><div>${n.depends_on.length}</div>
          </div>
        </div>
        <div class="section">
          <h3>Lineaje</h3>
          <div id="lineage" class="lineage"></div>
        </div>
        ${Object.keys(allCols).length?`<div class="section"><h3>Columnas</h3><table class="table"><thead><tr><th>Columna</th><th>Tipo</th><th>Descripción</th></tr></thead><tbody>${colRows}</tbody></table></div>`:''}
        ${n.depends_on.length?`<div class="section"><h3>Dependencias</h3><div class="chips">${n.depends_on.map(d=>`<button class="chip-btn mono" onclick="window.__jumpTo('${d}')">${esc(d.split('.').pop())}</button>`).join('')}</div></div>`:''}
        ${n.compiled_code?`<div class="section"><h3>SQL compilado</h3><div class="code">${esc(n.compiled_code)}</div></div>`:''}
      </div>`;
    renderLineage(n);
  }

  function renderLineage(n){
    const el=document.getElementById('lineage'); if(!el||typeof vis==='undefined') return;
    const upstream=n.depends_on.map(id=>allNodes.find(x=>x.id===id)).filter(Boolean);
    const downstream=allNodes.filter(x=>x.depends_on.includes(n.id));
    const graphNodes=[]; const graphEdges=[];
    upstream.forEach(x=>{graphNodes.push({id:x.id,label:x.name,color:{background:'#5591c7',border:'#5591c7'}}); graphEdges.push({from:x.id,to:n.id,arrows:'to'});});
    graphNodes.push({id:n.id,label:n.name,color:{background:'#4f98a3',border:'#4f98a3'}});
    downstream.forEach(x=>{graphNodes.push({id:x.id,label:x.name,color:{background:'#e8af34',border:'#e8af34'}}); graphEdges.push({from:n.id,to:x.id,arrows:'to'});});
    const dedup=[...new Map(graphNodes.map(x=>[x.id,x])).values()];
    const network=new vis.Network(el,{nodes:new vis.DataSet(dedup),edges:new vis.DataSet(graphEdges)},{layout:{improvedLayout:true},physics:{barnesHut:{springLength:170}},nodes:{shape:'box',margin:10,font:{face:'Inter',color:getComputedStyle(document.documentElement).getPropertyValue('--text').trim()}},edges:{smooth:{type:'dynamic'}}});
    network.on('click',params=>{if(params.nodes.length){state.selectedId=params.nodes[0]; render();}});
  }

  window.__setView=v=>{state.view=v; state.selectedId=null; render();};
  window.__toggleLayer=l=>{state.currentLayer=state.currentLayer===l?null:l; state.selectedId=null; render();};
  window.__showDetail=id=>{state.selectedId=id; render();};
  window.__jumpTo=id=>{const n=allNodes.find(x=>x.id===id)||allNodes.find(x=>x.name===id.split('.').pop()); if(n){state.selectedId=n.id; render();}};
  window.toggleTheme=()=>{document.documentElement.setAttribute('data-theme',document.documentElement.getAttribute('data-theme')==='dark'?'light':'dark'); if(state.selectedId) renderDetail();};
  search.addEventListener('input',render);
  render();
}).catch(err=>{document.body.innerHTML='<pre style="padding:20px">Error cargando site-data.json: '+err.message+'</pre>'});
</script>
</body>
</html>'''

(DOCS_DIR / 'index.html').write_text(html, encoding='utf-8')
print(f'OK: generado {DOCS_DIR / "index.html"}')
print(f'OK: generado {DOCS_DIR / "site-data.json"}')
print(f'OK: generado {DOCS_DIR / ".nojekyll"}')
