import * as THREE from './vendor/three.module.js';

const host = document.querySelector('.gse-orbital');
const canvas = host?.querySelector('.gse-globe');
if (host && canvas) {
  const reduced = matchMedia('(prefers-reduced-motion: reduce)');
  const textureUrl = '/__l5e/assets-v1/4be7472d-ad1d-484c-9099-b5e1045c0fac/nasa-earth-4k.webp';
  let renderer;
  try {
    renderer = new THREE.WebGLRenderer({ canvas, alpha: true, antialias: true, powerPreference: 'low-power' });
  } catch {
    const image = document.createElement('img');
    image.src = '/__l5e/assets-v1/d3d5aba6-959c-4770-b7e8-9709c79f0440/nasa-blue-marble.webp';
    image.alt = 'Earth — NASA Blue Marble';
    canvas.replaceWith(image);
  }
  if (renderer) {
    renderer.setPixelRatio(Math.min(devicePixelRatio, 1.5));
    renderer.outputColorSpace = THREE.SRGBColorSpace;
    const scene = new THREE.Scene();
    const camera = new THREE.PerspectiveCamera(34, 1, 0.1, 30);
    camera.position.z = 4.4;
    const earth = new THREE.Mesh(new THREE.SphereGeometry(1, 64, 48), new THREE.MeshPhongMaterial({ shininess: 8 }));
    earth.rotation.set(0.12, -1.1, 0.16);
    scene.add(earth);
    scene.add(new THREE.AmbientLight(0xffffff, 1.65));
    const sun = new THREE.DirectionalLight(0xffffff, 2.2);
    sun.position.set(-3, 3, 5);
    scene.add(sun);
    const ring = new THREE.Group();
    scene.add(ring);
    const css = () => getComputedStyle(document.documentElement);
    for (let i = 0; i < 17; i++) {
      const shape = new THREE.RingGeometry(1.19, 1.25, 24, 1, i * Math.PI * 2 / 17 + 0.035, Math.PI * 2 / 17 - 0.07);
      ring.add(new THREE.Mesh(shape, new THREE.MeshBasicMaterial({ color: css().getPropertyValue('--sdg-' + (i + 1)).trim(), side: THREE.DoubleSide })));
    }
    let visible = false, ready = false, raf = 0, last = 0;
    const draw = () => renderer.render(scene, camera);
    function stop() { cancelAnimationFrame(raf); raf = 0; last = 0; }
    function tick(now) {
      raf = requestAnimationFrame(tick);
      if (last && now - last < 40) return;
      const delta = last ? Math.min((now - last) / 1000, 0.08) : 0;
      last = now;
      earth.rotation.y += delta * 0.095;
      draw();
    }
    function play() {
      if (ready && visible && !document.hidden && !reduced.matches && !raf) raf = requestAnimationFrame(tick);
    }
    function fit() {
      const size = Math.max(1, Math.round(host.getBoundingClientRect().width));
      renderer.setSize(size, size, false);
      draw();
    }
    new THREE.TextureLoader().load(textureUrl, texture => {
      texture.colorSpace = THREE.SRGBColorSpace;
      texture.anisotropy = Math.min(4, renderer.capabilities.getMaxAnisotropy());
      earth.material.map = texture;
      earth.material.needsUpdate = true;
      ready = true;
      canvas.dataset.earthReady = 'true';
      draw(); play();
    });
    new IntersectionObserver(entries => {
      visible = entries[0].isIntersecting;
      visible ? play() : stop();
    }, { threshold: 0.05 }).observe(host);
    new ResizeObserver(fit).observe(host);
    document.addEventListener('visibilitychange', () => document.hidden ? stop() : play());
    reduced.addEventListener('change', () => { stop(); draw(); play(); });
    canvas.addEventListener('webglcontextlost', stop);
    canvas.setAttribute('role', 'img');
    canvas.setAttribute('aria-label', 'Rotating Earth with NASA satellite imagery, surrounded by the 17 SDG colours');
    fit();
  }
}