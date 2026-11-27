/* Cinematic home (preview): builds the poster floor, the reel, the stats and the spotlight from the posters already on the home page. */
(function(){
  var R=document.documentElement; if(!R.classList.contains('look-cine')) return;
  var home=document.getElementById('home-intro'), top=document.getElementById('top'); if(!home||!top) return;
  var links=[].slice.call(home.querySelectorAll('.home-posters a')); if(!links.length) return;
  var items=links.map(function(a){var img=a.querySelector('img'),sm=a.querySelector('small'),t=a.querySelector('.pi-title');
    return {href:a.getAttribute('href'),thumb:img?img.getAttribute('src'):'',name:(t?t.textContent:a.getAttribute('aria-label')||'').trim(),tag:sm?sm.textContent.trim().replace(/^New\s*·\s*/,''):'',c:(a.getAttribute('style')||'').replace(/.*--c:\s*([^;"]+).*/,'$1')||'#7aa2ff'}});
  function full(t){return t.replace('/thumbs/','/').replace('-thumb','')}
  function el(tag,cls,html){var e=document.createElement(tag);if(cls)e.className=cls;if(html!=null)e.innerHTML=html;return e}
  // 1. Poster floor behind the hero
  var floor=el('div');floor.id='cine-floor';floor.setAttribute('aria-hidden','true');
  for(var i=0;i<35;i++){var d=el('div');d.innerHTML='<img alt="" loading="lazy" src="'+items[(i*5+3)%items.length].thumb+'">';floor.appendChild(d)}
  var fade=el('div');fade.id='cine-floor-fade';fade.setAttribute('aria-hidden','true');
  top.insertBefore(fade,top.firstChild);top.insertBefore(floor,top.firstChild);
  // 2. Reel of every project
  var reel=el('div');reel.id='cine-reel';reel.setAttribute('aria-label','All projects');
  function row(list){var r=el('div','row');list.concat(list).forEach(function(it,k){var a=el('a');a.href=it.href;a.style.setProperty('--c',it.c);a.setAttribute('aria-label',it.name);if(k>=list.length){a.setAttribute('aria-hidden','true');a.tabIndex=-1}a.innerHTML='<img alt="" loading="lazy" src="'+it.thumb+'">';r.appendChild(a)});return r}
  var half=Math.ceil(items.length/2);reel.appendChild(row(items.slice(0,half)));reel.appendChild(row(items.slice(half)));
  home.parentNode.insertBefore(reel,home);
  // 3. Stats under the intro
  var copy=home.querySelector('.home-copy');
  if(copy){var groups=home.querySelectorAll('.home-group').length,st=el('div');st.id='cine-stats';
    st.innerHTML='<span><b>'+items.length+'</b> projects</span>'+(groups>1?'<span><b>'+groups+'</b> regions</span>':'')+'<span>Evidence before conclusions</span>';
    var act=copy.querySelector('.hero-actions');copy.insertBefore(st,act?act.nextSibling:null)}
  // 4. Spotlight on the newest projects
  var work=home.querySelector('.home-work'),firstGroup=work&&work.querySelector('.home-group');
  if(work&&firstGroup){var pick=items.slice(0,5),spot=el('div');spot.id='cine-spot';
    spot.innerHTML='<div class="pics">'+pick.map(function(it){return '<img alt="" loading="lazy" src="'+full(it.thumb)+'" data-fallback="'+it.thumb+'">'}).join('')+'</div><div class="txt"><small></small><h3></h3><p></p><a class="button primary go">Open project <span aria-hidden="true">→</span></a><div class="dots">'+pick.map(function(it,i){return '<button type="button" aria-label="Show '+it.name.replace(/"/g,'')+'"></button>'}).join('')+'</div></div>';
    work.insertBefore(spot,firstGroup);
    var pics=[].slice.call(spot.querySelectorAll('.pics img')),dots=[].slice.call(spot.querySelectorAll('.dots button')),cur=-1,timer=0,DUR=5200;
    pics.forEach(function(im){im.addEventListener('error',function(){if(im.dataset.fallback&&im.src.indexOf(im.dataset.fallback)<0)im.src=im.dataset.fallback})});
    function desc(it){var id=(it.href||'').replace('#',''),tag=document.getElementById(id);if(!tag)return '';var n=tag.nextElementSibling,p=n&&n.querySelector&&n.querySelector('p');var t=p?p.textContent.trim():'';return t.length>190?t.slice(0,187).replace(/\s+\S*$/,'')+'…':t}
    function show(k){k=(k+pick.length)%pick.length;if(k===cur)return;cur=k;var it=pick[k];spot.style.setProperty('--c',it.c);spot.style.setProperty('--dur',DUR+'ms');
      pics.forEach(function(im,i){im.classList.toggle('on',i===k)});dots.forEach(function(b,i){b.classList.remove('on');if(i===k){void b.offsetWidth;b.classList.add('on')}});
      spot.querySelector('small').textContent=it.tag;spot.querySelector('h3').textContent=it.name;spot.querySelector('p').textContent=desc(it);spot.querySelector('.go').href=it.href}
    function play(){clearInterval(timer);if(matchMedia('(prefers-reduced-motion: reduce)').matches)return;timer=setInterval(function(){if(!document.hidden&&R.dataset.view==='home')show(cur+1)},DUR)}
    dots.forEach(function(b,i){b.addEventListener('click',function(){show(i);play()})});
    spot.addEventListener('mouseenter',function(){clearInterval(timer)});spot.addEventListener('mouseleave',play);
    show(0);play()}
})();
