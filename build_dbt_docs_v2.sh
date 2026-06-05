#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="${1:-./4_dbt}"
DOCS_DIR="${2:-./docs}"
TARGET_DIR="$PROJECT_DIR/target"
MANIFEST="$TARGET_DIR/manifest.json"
CATALOG="$TARGET_DIR/catalog.json"
INDEX="$DOCS_DIR/index.html"
NOJEKYLL="$DOCS_DIR/.nojekyll"

if [[ ! -f "$MANIFEST" ]]; then
  echo "ERROR: No existe $MANIFEST"
  echo "Ejecuta antes: dbt compile --write-catalog --write-index --project-dir $PROJECT_DIR --profiles-dir ~/.dbt"
  exit 1
fi

mkdir -p "$DOCS_DIR"
cp "$MANIFEST" "$DOCS_DIR/manifest.json"
if [[ -f "$CATALOG" ]]; then
  cp "$CATALOG" "$DOCS_DIR/catalog.json"
else
  echo "WARN: No existe $CATALOG; el viewer funcionará sin tipos de columnas del catálogo"
fi
printf '' > "$NOJEKYLL"

cat > "$INDEX" <<'HTML'
<!DOCTYPE html>
<html lang="es" data-theme="dark">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>dbt Docs Viewer</title>
<meta name="description" content="Static dbt docs viewer for GitHub Pages">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@300..700&family=JetBrains+Mono:wght@400;600&display=swap" rel="stylesheet">
<script src="https://unpkg.com/vis-network/standalone/umd/vis-network.min.js"></script>
<style>
:root,[data-theme="light"]{--bg:#f7f6f2;--surface:#f9f8f5;--surface2:#fbfbf9;--offset:#f3f0ec;--dynamic:#e6e4df;--divider:#dcd9d5;--border:#d4d1ca;--text:#28251d;--muted:#7a7974;--faint:#bab9b4;--primary:#01696f;--primary-hover:#0c4e54;--primary-hi:#cedcd8;--success:#437a22;--success-hi:#d4dfcc;--warning:#964219;--warning-hi:#ddcfc6;--error:#a12c7b;--error-hi:#e0ced7;--blue:#006494;--blue-hi:#c6d8e4;--gold:#d19900;--gold-hi:#e9e0c6;--purple:#7a39bb;--purple-hi:#dacfde;--shadow:0 4px 12px rgba(0,0,0,.08);--r-sm:.375rem;--r-md:.5rem;--r-lg:.75rem;--r-xl:1rem}
[data-theme="dark"]{--bg:#171614;--surface:#1c1b19;--surface2:#201f1d;--offset:#1d1c1a;--dynamic:#2d2c2a;--divider:#262523;--border:#393836;--text:#cdccca;--muted:#797876;--faint:#5a5957;--primary:#4f98a3;--primary-hover:#227f8b;--primary-hi:#313b3b;--success:#6daa45;--success-hi:#3a4435;--warning:#bb653b;--warning-hi:#564942;--error:#d163a7;--error-hi:#4c3d46;--blue:#5591c7;--blue-hi:#3a4550;--gold:#e8af34;--gold-hi:#4d4332;--purple:#a86fdf;--purple-hi:#4e4652;--shadow:0 8px 20px rgba(0,0,0,.22)}
*{box-sizing:border-box}html,body{margin:0;height:100%}body{font-family:Inter,system-ui,sans-serif;background:var(--bg);color:var(--text)}button,input,select{font:inherit}button{cursor:pointer}
.app{display:grid;grid-template-rows:56px 1fr;height:100vh}.topbar{display:flex;align-items:center;gap:1rem;padding:0 1.25rem;background:var(--surface);border-bottom:1px solid var(--divider);position:sticky;top:0;z-index:20}.brand{font-weight:700}.search{flex:1;max-width:460px;background:var(--bg);color:var(--text);border:1px solid var(--border);border-radius:999px;padding:.7rem 1rem}.topbtn{border:1px solid var(--border);background:var(--bg);color:var(--text);border-radius:.65rem;padding:.55rem .8rem}
.layout{display:grid;grid-template-columns:280px 1fr;height:calc(100vh - 56px)}.sidebar{overflow:auto;background:var(--surface);border-right:1px solid var(--divider);padding:1rem 0}.content{overflow:auto;padding:1.5rem}.side-title{font-size:.75rem;text-transform:uppercase;letter-spacing:.05em;color:var(--faint);padding:0 1rem .5rem}.sidebar-item{display:flex;justify-content:space-between;align-items:center;width:100%;padding:.7rem 1rem;background:none;border:0;color:var(--muted);text-align:left}.sidebar-item:hover,.sidebar-item.active{background:var(--offset);color:var(--text)}.badge{font-size:.75rem;border-radius:999px;padding:.1rem .45rem;background:var(--dynamic)}
.filters{padding:.25rem 1rem .75rem;display:flex;flex-wrap:wrap;gap:.35rem}.chip-btn{border:1px solid var(--border);background:var(--bg);color:var(--muted);border-radius:999px;padding:.3rem .6rem;font-size:.75rem}.chip-btn.active{background:var(--primary-hi);border-color:var(--primary);color:var(--primary)}
.stats{display:flex;flex-wrap:wrap;gap:1rem;margin-bottom:1rem}.stat{background:var(--surface);border:1px solid var(--divider);border-radius:.85rem;padding:1rem;min-width:130px;box-shadow:var(--shadow)}.n{font-size:1.6rem;font-weight:700}.label{color:var(--muted);font-size:.85rem}
.grid{display:grid;gap:.85rem}.card{background:var(--surface);border:1px solid var(--divider);border-radius:.9rem;padding:1rem;cursor:pointer;transition:.15s ease}.card:hover{border-color:var(--primary);transform:translateY(-1px)}.card.selected{border-color:var(--primary);background:var(--primary-hi)}.row{display:flex;gap:.5rem;align-items:center;flex-wrap:wrap}.mono{font-family:"JetBrains Mono",monospace}.muted{color:var(--muted)}.chips{display:flex;gap:.4rem;flex-wrap:wrap;margin-top:.5rem}.chip{font-size:.75rem;padding:.15rem .5rem;border-radius:999px;background:var(--offset);border:1px solid var(--border)}
.detail{margin-top:1rem;background:var(--surface2);border:1px solid var(--divider);border-radius:1rem;padding:1.25rem}.section{margin-bottom:1.25rem}.section h3{font-size:.8rem;text-transform:uppercase;letter-spacing:.05em;color:var(--faint);border-bottom:1px solid var(--divider);padding-bottom:.55rem;margin-bottom:.8rem}.table{width:100%;border-collapse:collapse;font-size:.86rem}.table th,.table td{text-align:left;padding:.55rem;border-bottom:1px solid var(--divider);vertical-align:top}.code{white-space:pre-wrap;overflow:auto;max-height:340px;background:var(--bg);border:1px solid var(--border);border-radius:.8rem;padding:1rem;font-family:"JetBrains Mono",monospace;font-size:.8rem}
.lineage-wrap{display:grid;grid-template-columns:1fr 280px;gap:1rem}.lineage{height:460px;border:1px solid var(--divider);border-radius:.85rem;background:var(--bg)}.legend{background:var(--bg);border:1px solid var(--border);border-radius:.85rem;padding:1rem}.legend-item{display:flex;align-items:center;gap:.5rem;margin-bottom:.55rem}.dot{width:12px;height:12px;border-radius:999px}.dot.up{background:var(--blue)}.dot.sel{background:var(--primary)}.dot.down{background:var(--gold)}
.empty{padding:2rem;background:var(--surface);border:1px solid var(--divider);border-radius:1rem;color:var(--muted)}
@media(max-width:980px){.layout{grid-template-columns:1fr}.sidebar{display:none}.lineage-wrap{grid-template-columns:1fr}}
</style>
</head>
<body>
<div class="app">
  <div class="topbar">
    <div class="brand">dbt Docs Viewer</div>
    <input id="search" class="search" placeholder="Buscar modelos, columnas, descripción...">
    <button class="topbtn" onclick="toggleTheme()">Tema</button>
    <button class="topbtn" onclick="location.reload()">Recargar</button>
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
let manifest=null,catalog=null,allNodes=[],view='all',selectedId=null,currentLayer=null,network=null;
const TYPES=['all','model','source','seed','snapshot','metric','semantic_model'];
const LABELS={all:'Todos',model:'Modelos',source:'Sources',seed:'Seeds',snapshot:'Snapshots',metric:'Métricas',semantic_model:'Semantic Models'};
const esc=s=>(s||'').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
async function boot(){manifest=await fetch('./manifest.json').then(r=>r.json());catalog=await fetch('./catalog.json').then(r=>r.json()).catch(()=>null);buildNodes();renderSidebar();render();document.getElementById('search').addEventListener('input',render)}
function buildNodes(){const nodes=manifest.nodes||{},sources=manifest.sources||{},metrics=manifest.metrics||{},sms=manifest.semantic_models||{};Object.values(nodes).forEach(n=>{if(!['model','seed','snapshot'].includes(n.resource_type))return;allNodes.push(pack(n,n.resource_type));});Object.values(sources).forEach(n=>allNodes.push(pack(n,'source')));Object.values(metrics).forEach(n=>allNodes.push(pack(n,'metric')));Object.values(sms).forEach(n=>allNodes.push(pack(n,'semantic_model')))}
function pack(n,type){const cn=(catalog&&((catalog.nodes||{})[n.unique_id]||(catalog.sources||{})[n.unique_id]))||null;return{id:n.unique_id,name:n.name,type,schema:n.schema||'',database:n.database||'',description:n.description||'',path:n.path||'',depends_on:(n.depends_on&&n.depends_on.nodes)||[],compiled_code:n.compiled_code||n.raw_code||'',columns:n.columns||{},catalogNode:cn,tags:n.tags||[],label:n.label||'',metric_type:n.type||'',entities:n.entities||[],dimensions:n.dimensions||[],measures:n.measures||[]}}
function renderSidebar(){const counts={all:allNodes.length};allNodes.forEach(n=>counts[n.type]=(counts[n.type]||0)+1);document.getElementById('sidebarNav').innerHTML=TYPES.map(t=>`<button class="sidebar-item ${view===t?'active':''}" onclick="setView('${t}')"><span>${LABELS[t]}</span><span class="badge">${counts[t]||0}</span></button>`).join('');const layers=[...new Set(allNodes.filter(n=>n.path).map(n=>n.path.split('/')[0]))].sort();document.getElementById('layerFilters').innerHTML=layers.map(l=>`<button class="chip-btn ${currentLayer===l?'active':''}" onclick="toggleLayer('${l}')">${l}</button>`).join('')||'<span class="muted">Sin capas detectadas</span>'}
function setView(v){view=v;selectedId=null;renderSidebar();render()}
function toggleLayer(l){currentLayer=currentLayer===l?null:l;selectedId=null;renderSidebar();render()}
function filtered(){const q=document.getElementById('search').value.toLowerCase();let rows=allNodes.filter(n=>view==='all'||n.type===view);if(currentLayer)rows=rows.filter(n=>n.path&&n.path.startsWith(currentLayer+'/'));if(q)rows=rows.filter(n=>n.name.toLowerCase().includes(q)||n.description.toLowerCase().includes(q)||Object.keys(n.columns||{}).some(c=>c.toLowerCase().includes(q)));return rows}
function render(){const rows=filtered();const counts={};rows.forEach(n=>counts[n.type]=(counts[n.type]||0)+1);document.getElementById('stats').innerHTML=Object.entries(counts).map(([k,v])=>`<div class="stat"><div class="n">${v}</div><div class="label">${LABELS[k]||k}</div></div>`).join('')||'<div class="empty">No hay recursos para este filtro.</div>';document.getElementById('list').innerHTML=rows.map(n=>`<div class="card ${selectedId===n.id?'selected':''}" onclick="showDetail('${n.id.replace(/'/g,"\\'")}')"><div class="row"><strong class="mono">${esc(n.name)}</strong><span class="chip">${n.type}</span>${n.tags.slice(0,3).map(t=>`<span class="chip">${esc(t)}</span>`).join('')}</div>${n.description?`<div class="muted" style="margin-top:.35rem">${esc(n.description.slice(0,160))}${n.description.length>160?'…':''}</div>`:''}<div class="chips">${n.schema?`<span class="chip">${esc((n.database?n.database+'.':'')+n.schema)}</span>`:''}${n.path?`<span class="chip">${esc(n.path)}</span>`:''}${Object.keys(n.columns||{}).length?`<span class="chip">${Object.keys(n.columns).length} columnas</span>`:''}${n.depends_on.length?`<span class="chip">${n.depends_on.length} deps</span>`:''}</div></div>`).join('');if(selectedId)renderDetail()}
function showDetail(id){selectedId=id;render();window.scrollTo({top:0,behavior:'smooth'})}
function renderDetail(){const n=allNodes.find(x=>x.id===selectedId);if(!n)return;const mCols=n.columns||{};const cCols=(n.catalogNode&&n.catalogNode.columns)||{};const allCols={...mCols};Object.entries(cCols).forEach(([k,v])=>{const lk=k.toLowerCase();if(!allCols[lk])allCols[lk]={};allCols[lk]={...allCols[lk],type:v.type}});const colRows=Object.keys(allCols).map(k=>{const c=allCols[k];const t=c.type||cCols[k]?.type||cCols[k.toUpperCase()]?.type||'—';return `<tr><td class="mono">${esc(k)}</td><td class="mono">${esc(t)}</td><td>${esc(c.description||'—')}</td></tr>`}).join('');document.getElementById('detail').innerHTML=`<div class="detail"><div class="section"><h3>Recurso</h3><div class="row"><strong class="mono" style="font-size:1.1rem">${esc(n.name)}</strong><span class="chip">${n.type}</span>${n.path?`<span class="chip">${esc(n.path)}</span>`:''}</div>${n.description?`<p class="muted">${esc(n.description)}</p>`:''}</div><div class="section"><h3>Lineaje</h3><div class="lineage-wrap"><div id="lineage" class="lineage"></div><div class="legend"><div class="legend-item"><span class="dot up"></span><span>Upstream</span></div><div class="legend-item"><span class="dot sel"></span><span>Seleccionado</span></div><div class="legend-item"><span class="dot down"></span><span>Downstream</span></div><p class="muted">Haz clic en un nodo del grafo para abrir su detalle.</p></div></div></div>${Object.keys(allCols).length?`<div class="section"><h3>Columnas</h3><table class="table"><thead><tr><th>Columna</th><th>Tipo</th><th>Descripción</th></tr></thead><tbody>${colRows}</tbody></table></div>`:''}${n.depends_on.length?`<div class="section"><h3>Dependencias</h3><div class="chips">${n.depends_on.map(d=>`<button class="chip-btn mono" onclick="jumpTo('${d}')">${esc(d.split('.').pop())}</button>`).join('')}</div></div>`:''}${n.compiled_code?`<div class="section"><h3>SQL compilado</h3><div class="code">${esc(n.compiled_code)}</div></div>`:''}</div>`;renderLineage(n)}
function jumpTo(id){const n=allNodes.find(x=>x.id===id)||allNodes.find(x=>x.name===id.split('.').pop());if(n){selectedId=n.id;render();}}
function renderLineage(n){const el=document.getElementById('lineage');if(!el||typeof vis==='undefined')return;const upstream=n.depends_on.map(id=>allNodes.find(x=>x.id===id)).filter(Boolean);const downstream=allNodes.filter(x=>x.depends_on.includes(n.id));const graphNodes=[];const graphEdges=[];upstream.forEach(x=>{graphNodes.push({id:x.id,label:x.name,color:getColor('up')});graphEdges.push({from:x.id,to:n.id,arrows:'to'})});graphNodes.push({id:n.id,label:n.name,color:getColor('selected')});downstream.forEach(x=>{graphNodes.push({id:x.id,label:x.name,color:getColor('down')});graphEdges.push({from:n.id,to:x.id,arrows:'to'})});const dedup=[...new Map(graphNodes.map(x=>[x.id,x])).values()];network=new vis.Network(el,{nodes:new vis.DataSet(dedup),edges:new vis.DataSet(graphEdges)},{layout:{improvedLayout:true},physics:{barnesHut:{springLength:170}},nodes:{shape:'box',margin:10,font:{face:'Inter',color:getCss('--text')}},edges:{smooth:{type:'dynamic'},color:{color:getCss('--muted')}}});network.on('click',params=>{if(params.nodes.length){selectedId=params.nodes[0];render();}})}
function getCss(v){return getComputedStyle(document.documentElement).getPropertyValue(v).trim()}
function getColor(kind){if(kind==='up')return{background:getCss('--blue'),border:getCss('--blue')};if(kind==='down')return{background:getCss('--gold'),border:getCss('--gold')};return{background:getCss('--primary'),border:getCss('--primary')}}
function toggleTheme(){document.documentElement.setAttribute('data-theme',document.documentElement.getAttribute('data-theme')==='dark'?'light':'dark');if(selectedId)renderDetail()}
boot();
</script>
</body>
</html>
HTML

chmod +x "$INDEX"

echo "OK: generado $INDEX"
echo "OK: copiados manifest.json y catalog.json en $DOCS_DIR" 
echo "OK: creado $NOJEKYLL para GitHub Pages"
echo "Publica la carpeta /docs en Settings > Pages"
