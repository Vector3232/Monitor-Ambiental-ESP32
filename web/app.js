'use strict';
const $ = (id) => document.getElementById(id);
let config = null;
let timeout = null;
function demoData() {
  return Array.from({length:24}, (_,i)=>({id:i,dispositivo:'esp32-01',temperatura: +(24.3+Math.sin(i/3)*2.3+(i%3)*.11).toFixed(1),humedad:+(58+Math.cos(i/4)*9).toFixed(1),simulada:true,creada_en:new Date(Date.now()-(23-i)*15*60*1000).toISOString()})).reverse();
}
function fmtDate(date){return new Date(date).toLocaleString('es-MX',{dateStyle:'short',timeStyle:'short'});}
function text(id,value){$(id).textContent=value;}
function render(data, isDemo=false){
  const list=[...data].sort((a,b)=>new Date(b.creada_en)-new Date(a.creada_en));
  const last=list[0];
  text('temp',last?Number(last.temperatura).toFixed(1)+' °C':'-- °C');
  text('hum',last?Number(last.humedad).toFixed(1)+' %':'-- %');
  text('count',list.length);
  text('lastSeen',last?'Última lectura: '+fmtDate(last.creada_en):'Sin registros');
  text('tempDetail',last?(last.simulada?'Dato simulado':'Dato del sensor'):'Sin mediciones');
  text('humDetail',last?'Dispositivo: '+last.dispositivo:'Sin mediciones');
  $('readings').replaceChildren();
  for(const r of list.slice(0,15)){
    const tr=document.createElement('tr');
    for(const val of [fmtDate(r.creada_en),r.dispositivo,Number(r.temperatura).toFixed(1)+' °C',Number(r.humedad).toFixed(1)+' %',r.simulada?'Simulada':'Real']){
      const td=document.createElement('td');td.textContent=val;tr.append(td);
    }
    $('readings').append(tr);
  }
  drawChart([...list].reverse());
  $('status').textContent=isDemo?'Modo demostración':'Conectado a Supabase';
  $('status').classList.toggle('connected',!isDemo);
}
function drawChart(rows){
  window.lastRows=rows;
  const canvas=$('chart'),ctx=canvas.getContext('2d');
  const w=canvas.clientWidth || 700,h=240,dpr=window.devicePixelRatio||1;
  canvas.width=Math.round(w*dpr);canvas.height=Math.round(h*dpr);ctx.scale(dpr,dpr);ctx.clearRect(0,0,w,h);
  const left=45,right=w-15,top=15,bottom=h-30;
  ctx.strokeStyle='#2c3c4c';ctx.lineWidth=1;ctx.fillStyle='#8394aa';ctx.font='11px system-ui';
  for(let i=0;i<=4;i++){let y=top+(bottom-top)*i/4;ctx.beginPath();ctx.moveTo(left,y);ctx.lineTo(right,y);ctx.stroke();ctx.fillText(String(100-i*25),8,y+4);}
  if(!rows.length)return;
  const plot=(key,color,min,max)=>{
    ctx.beginPath();ctx.lineWidth=2.6;ctx.strokeStyle=color;
    rows.forEach((r,i)=>{const x=left+(right-left)*(rows.length===1?.5:i/(rows.length-1));const y=bottom-(Number(r[key])-min)/(max-min)*(bottom-top);if(i===0)ctx.moveTo(x,y);else ctx.lineTo(x,y);});ctx.stroke();
  };
  plot('temperatura','#56d4ba',0,50);plot('humedad','#89a8f6',0,100);
  ctx.fillStyle='#8296ac';ctx.textAlign='left';ctx.fillText(fmtDate(rows[0].creada_en),left,bottom+19);ctx.textAlign='right';ctx.fillText(fmtDate(rows.at(-1).creada_en),right,bottom+19);ctx.textAlign='left';
}

async function load() {
  if (!config) {
    render(demoData(), true);
    return;
  }

  const { url, key } = config;

  try {
    const endpoint =
      url +
      '/rest/v1/lecturas_ambientales' +
      '?select=id,dispositivo_id,temperatura,humedad,simulada,creado_en' +
      '&order=creado_en.desc&limit=50';

    const res = await fetch(endpoint, {
      headers: { apikey: key }
    });

    if (!res.ok) {
      throw new Error(
        'HTTP ' + res.status + ' ' + (await res.text())
      );
    }

    const datos = await res.json();

    const lecturas = datos.map(r => ({
      id: r.id,
      dispositivo: r.dispositivo_id,
      temperatura: Number(r.temperatura),
      humedad: Number(r.humedad),
      simulada: r.simulada,
      creada_en: r.creado_en
    }));

    render(lecturas, false);

  } catch (err) {
    $('status').textContent = 'Error de conexión';
    $('status').classList.remove('connected');
    text('lastSeen', String(err.message));
    console.error(err);
  }
}

$('configBtn').onclick=()=>{ $('projectUrl').value=config?.url||'';$('publishableKey').value=config?.key||'';$('configDialog').showModal();};
$('cancelBtn').onclick=()=>$('configDialog').close();
$('demoBtn').onclick=()=>{config=null;sessionStorage.removeItem('monitorConfig');$('configDialog').close();load();};
$('configForm').onsubmit=(ev)=>{ev.preventDefault();const url=$('projectUrl').value.trim().replace(/\/$/,'');const key=$('publishableKey').value.trim();if(!/^https:\/\/[a-z0-9-]+\.supabase\.co$/i.test(url)||!key.startsWith('sb_publishable_')){alert('Revisa la URL y utiliza una clave publishable (sb_publishable_...).');return;}config={url,key};sessionStorage.setItem('monitorConfig',JSON.stringify(config));$('configDialog').close();load();};
$('refreshBtn').onclick=load;
window.addEventListener('resize',()=>{if(window.lastRows)drawChart(window.lastRows);else load();});
try{config=JSON.parse(sessionStorage.getItem('monitorConfig')||'null');}catch{config=null;}
load();setInterval(()=>{if(config)load();},15000);
