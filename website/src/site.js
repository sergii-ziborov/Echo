'use strict';
// Navigation works with native links; only the compact menu needs enhancement.
const menu = document.querySelector('.menu-toggle');
const closeMenu = () => { menu?.setAttribute('aria-expanded', 'false'); document.body.classList.remove('menu-open'); };
menu?.addEventListener('click', () => {
  const open = menu.getAttribute('aria-expanded') !== 'true';
  menu.setAttribute('aria-expanded', String(open));
  document.body.classList.toggle('menu-open', open);
});
document.querySelectorAll('#main-nav a').forEach(a => a.addEventListener('click', closeMenu));
document.addEventListener('keydown', e => { if (e.key === 'Escape' && document.body.classList.contains('menu-open')) { closeMenu(); menu.focus(); } });
document.addEventListener('click', e => { if (!e.target.closest('.site-header')) closeMenu(); });

// The region texts are the same canon strings that ship with Echo.
document.querySelectorAll('.atlas-browser').forEach(atlas => {
  const tabs = [...atlas.querySelectorAll('[role=tab]')];
  const activate = tab => {
    tabs.forEach(item => {
      const selected = item === tab;
      item.setAttribute('aria-selected', String(selected));
      item.tabIndex = selected ? 0 : -1;
      document.getElementById(item.getAttribute('aria-controls')).hidden = !selected;
    });
  };
  tabs.forEach((tab, index) => {
    tab.addEventListener('click', () => activate(tab));
    tab.addEventListener('keydown', e => {
      let next;
      if (e.key === 'ArrowRight' || e.key === 'ArrowDown') next = (index + 1) % tabs.length;
      if (e.key === 'ArrowLeft' || e.key === 'ArrowUp') next = (index + tabs.length - 1) % tabs.length;
      if (e.key === 'Home') next = 0;
      if (e.key === 'End') next = tabs.length - 1;
      if (next !== undefined) { e.preventDefault(); activate(tabs[next]); tabs[next].focus(); tabs[next].scrollIntoView({ block:'nearest', inline:'nearest' }); }
    });
  });
});

const reducedMotion = matchMedia('(prefers-reduced-motion: reduce)');
document.querySelectorAll('[data-echo-demo]').forEach(element => {
  const canvas = element.querySelector('canvas');
  const ctx = canvas.getContext('2d');
  const W = 720, H = 460, delay = 2000;
  const sample = [[.18,.68],[.18,.29],[.36,.18],[.68,.20],[.83,.40],[.72,.72],[.51,.77],[.39,.60],[.53,.43],[.67,.49],[.59,.64],[.31,.77],[.18,.68]];
  let history = [], current = { x:130,y:310 }, auto = !reducedMotion.matches, autoStart = performance.now(), pointer = false, visible = false, frame = null;
  let lastRecord = 0;
  function pathPoint(time) {
    const progress = (time % 14000) / 14000 * (sample.length - 1);
    const a = Math.floor(progress), b = Math.min(a + 1, sample.length - 1), amount = progress - a;
    return { x:(sample[a][0] + (sample[b][0] - sample[a][0]) * amount)*W, y:(sample[a][1] + (sample[b][1] - sample[a][1]) * amount)*H };
  }
  function dot(x,y,color,r) {
    const glow=ctx.createRadialGradient(x,y,0,x,y,r*5);
    glow.addColorStop(0,color+'80');glow.addColorStop(1,color+'00');
    ctx.fillStyle=glow;ctx.beginPath();ctx.arc(x,y,r*5,0,Math.PI*2);ctx.fill();
    ctx.fillStyle=color;ctx.beginPath();ctx.arc(x,y,r,0,Math.PI*2);ctx.fill();
    ctx.strokeStyle='#e7f9ffb0';ctx.lineWidth=1;ctx.stroke();
  }
  function render(now) {
    frame=null;
    if (!visible) return;
    ctx.clearRect(0,0,W,H);
    ctx.strokeStyle='#6387a918';ctx.lineWidth=1;
    for(let x=40;x<W;x+=40){ctx.beginPath();ctx.moveTo(x,20);ctx.lineTo(x,H-20);ctx.stroke();}
    for(let y=20;y<H;y+=40){ctx.beginPath();ctx.moveTo(40,y);ctx.lineTo(W-40,y);ctx.stroke();}
    for(let i=0;i<30;i++){ctx.fillStyle='#a6caed55';ctx.beginPath();ctx.arc(30+(i*179)%650,25+(i*113)%380,.8,0,Math.PI*2);ctx.fill();}
    // A few records and a gate establish the visual vocabulary of the illustration.
    [[235,92],[500,94],[598,192],[520,325],[287,272]].forEach(([x,y])=>{
      ctx.save();ctx.translate(x,y);ctx.rotate(Math.PI/4);ctx.fillStyle='#dcc68c';ctx.shadowColor='#ddc381';ctx.shadowBlur=10;ctx.fillRect(-3,-3,6,6);ctx.restore();
    });
    ctx.strokeStyle='#d9be8555';ctx.lineWidth=1;ctx.beginPath();ctx.arc(123,313,19,0,Math.PI*2);ctx.stroke();
    if(auto)current=pathPoint(now-autoStart);
    if((auto||pointer) && now-lastRecord>24){history.push({...current,time:now});lastRecord=now;}
    history=history.filter(p=>now-p.time<18000);
    if(history.length>1){ctx.beginPath();history.forEach((p,i)=>i?ctx.lineTo(p.x,p.y):ctx.moveTo(p.x,p.y));ctx.strokeStyle='#68caff66';ctx.lineWidth=1.5;ctx.stroke();}
    const echo=history.findLast(p=>p.time<=now-delay);
    if(echo){
      const trailing=history.filter(p=>p.time<=now-delay && p.time>=now-delay-2200);
      ctx.beginPath();trailing.forEach((p,i)=>i?ctx.lineTo(p.x,p.y):ctx.moveTo(p.x,p.y));ctx.strokeStyle='#bd8aea99';ctx.lineWidth=2;ctx.stroke();dot(echo.x,echo.y,'#bf92eb',8);
    }
    dot(current.x,current.y,'#8be7ff',9);
    if(auto||pointer||history.length)frame=requestAnimationFrame(render);
  }
  function requestDraw(){if(visible && !frame)frame=requestAnimationFrame(render);}
  const observer=new IntersectionObserver(entries=>{
    visible=entries[0].isIntersecting;
    if(visible)requestDraw();else if(frame){cancelAnimationFrame(frame);frame=null;}
  },{threshold:.08});observer.observe(element);
  function point(e){const r=canvas.getBoundingClientRect();current={x:Math.max(15,Math.min(W-15,(e.clientX-r.left)/r.width*W)),y:Math.max(15,Math.min(H-15,(e.clientY-r.top)/r.height*H))};}
  canvas.addEventListener('pointerdown',e=>{if(e.button!==0)return;auto=false;pointer=true;canvas.classList.add('drawing');canvas.setPointerCapture(e.pointerId);point(e);requestDraw();});
  canvas.addEventListener('pointermove',e=>{if(pointer)point(e);});
  const release=()=>{pointer=false;canvas.classList.remove('drawing');};
  canvas.addEventListener('pointerup',release);canvas.addEventListener('pointercancel',release);canvas.addEventListener('lostpointercapture',release);
  element.querySelector('[data-demo-play]').addEventListener('click',()=>{history=[];auto=true;autoStart=performance.now();requestDraw();});
  element.querySelector('[data-demo-clear]').addEventListener('click',()=>{history=[];auto=false;pointer=false;current={x:130,y:310};requestDraw();});
  reducedMotion.addEventListener('change',e=>{if(e.matches){auto=false;history=[];requestDraw();}});
  document.addEventListener('visibilitychange',()=>{if(document.hidden){if(frame)cancelAnimationFrame(frame);frame=null;}else requestDraw();});
});

// A compact location marker helps readers navigate the long field guide.
const chapters = [...document.querySelectorAll('.guide-body > section')];
if(chapters.length && 'IntersectionObserver' in window){
  const tocLinks=[...document.querySelectorAll('.guide-toc nav a')];
  const tocObserver=new IntersectionObserver(entries=>{
    entries.filter(e=>e.isIntersecting).forEach(entry=>tocLinks.forEach(a=>{
      const active=a.getAttribute('href')==='#'+entry.target.id;
      a.classList.toggle('active',active);
      if(active)a.setAttribute('aria-current','location');else a.removeAttribute('aria-current');
    }));
  },{rootMargin:'-15% 0px -65% 0px'});
  chapters.forEach(chapter=>tocObserver.observe(chapter));
}
