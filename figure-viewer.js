import * as THREE from 'https://cdn.jsdelivr.net/npm/three@0.166.1/build/three.module.js';
import { GLTFLoader } from 'https://cdn.jsdelivr.net/npm/three@0.166.1/examples/jsm/loaders/GLTFLoader.js';

const mount = document.querySelector('#heroFigure');

if (mount) {
  const scene = new THREE.Scene();
  const camera = new THREE.PerspectiveCamera(34, 1, 0.1, 100);
  camera.position.set(0, 1.2, 5.3);

  const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
  renderer.outputColorSpace = THREE.SRGBColorSpace;
  renderer.setAnimationLoop(render);
  mount.appendChild(renderer.domElement);

  const key = new THREE.DirectionalLight(0xffffff, 2.6);
  key.position.set(3, 5, 4);
  scene.add(key);
  const fill = new THREE.DirectionalLight(0x87d9ff, 1.4);
  fill.position.set(-4, 1, 3);
  scene.add(fill);
  scene.add(new THREE.HemisphereLight(0xa78bfa, 0x121b32, 1.8));

  const pedestal = new THREE.Mesh(
    new THREE.CylinderGeometry(1.1, 1.35, 0.16, 48),
    new THREE.MeshStandardMaterial({ color: 0x101b34, metalness: 0.4, roughness: 0.35 })
  );
  pedestal.position.y = -1.48;
  scene.add(pedestal);

  const figure = new THREE.Group();
  scene.add(figure);

  new GLTFLoader().load(
    'graduation-figure.glb',
    (gltf) => {
      const object = gltf.scene;
      const bounds = new THREE.Box3().setFromObject(object);
      const size = bounds.getSize(new THREE.Vector3());
      const center = bounds.getCenter(new THREE.Vector3());
      const scale = 2.7 / Math.max(size.x, size.y, size.z);
      object.scale.setScalar(scale);
      object.position.set(-center.x * scale, -center.y * scale - 1.38, -center.z * scale);
      figure.add(object);
    },
    undefined,
    () => {
      mount.classList.add('hero__figure--unavailable');
    }
  );

  let targetRotation = -0.35;
  let dragging = false;
  let startX = 0;
  let startRotation = 0;

  mount.addEventListener('pointerdown', (event) => {
    dragging = true;
    startX = event.clientX;
    startRotation = targetRotation;
    mount.setPointerCapture(event.pointerId);
  });
  mount.addEventListener('pointermove', (event) => {
    if (dragging) targetRotation = startRotation + (event.clientX - startX) * 0.012;
  });
  mount.addEventListener('pointerup', () => { dragging = false; });
  mount.addEventListener('pointercancel', () => { dragging = false; });

  function resize() {
    const { width, height } = mount.getBoundingClientRect();
    if (!width || !height) return;
    camera.aspect = width / height;
    camera.updateProjectionMatrix();
    renderer.setSize(width, height, false);
  }

  function render() {
    if (!dragging) targetRotation += 0.0018;
    figure.rotation.y += (targetRotation - figure.rotation.y) * 0.06;
    renderer.render(scene, camera);
  }

  new ResizeObserver(resize).observe(mount);
  resize();
<<<<<<< HEAD
}
=======
}
>>>>>>> 7317293a36d9c483c372e1db50011a893c8c15a4
