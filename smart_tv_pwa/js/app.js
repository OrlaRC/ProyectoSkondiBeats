let beats = [];
let focusedIndex = 0;
let currentView = 'library';
let navFocus = null; // null = sin foco en la barra lateral; 0=Biblioteca, 1=Reproductor
let audio = null;
let isPlaying = false;
let libraryView = localStorage.getItem('tvView') || 'grid';
const GRID_COLS = 3;

const VIDEOS = [
  'videos/lofi1.mp4',
  'videos/lofi2.mp4',
  'videos/lofi3.mp4',
  'videos/lofi4.mp4',
  'videos/lofi5.mp4',
];

function fmt(sec) {
  const s = Math.max(0, Math.floor(sec || 0));
  return Math.floor(s / 60) + ':' + String(s % 60).padStart(2, '0');
}

function setTimeText(text) {
  const p = document.getElementById('player-time');
  const m = document.getElementById('mini-time');
  if (p) p.textContent = text;
  if (m) m.textContent = text.split(' / ')[0];
}

function setProgress(pct) {
  const pf = document.getElementById('progress-fill');
  const mf = document.getElementById('mini-fill');
  if (pf) pf.style.width = pct + '%';
  if (mf) mf.style.width = pct + '%';
}

function setBgVideo(i) {
  const v = document.getElementById('bg-video');
  if (!v) return;
  const src = VIDEOS[i % VIDEOS.length];
  if (v.getAttribute('data-src') === src) return;
  v.setAttribute('data-src', src);
  v.src = src;
  v.load();
  v.play().catch(() => {});
}

// ===== Escalado para caber en cualquier pantalla =====
function fitScreen() {
  const app = document.getElementById('app');
  const scale = Math.min(window.innerWidth / 1920, window.innerHeight / 1080);
  const x = (window.innerWidth - 1920 * scale) / 2;
  const y = (window.innerHeight - 1080 * scale) / 2;
  app.style.transform = `translate(${x}px, ${y}px) scale(${scale})`;
}
window.addEventListener('resize', fitScreen);
fitScreen();

function updateClock() {
  const now = new Date();
  document.getElementById('clock').textContent = now.toLocaleTimeString('es-MX', { hour: '2-digit', minute: '2-digit' });
  const date = now.toLocaleDateString('es-MX', { weekday: 'long', day: 'numeric', month: 'long' });
  document.getElementById('date').textContent = date.charAt(0).toUpperCase() + date.slice(1);
}
setInterval(updateClock, 1000);
updateClock();

function genreClass(g) {
  const s = (g || '').toLowerCase();
  if (s.includes('trap')) return 'genre-trap';
  if (s.includes('drill')) return 'genre-drill';
  if (s.includes('rap')) return 'genre-rap';
  return 'genre-unknown';
}

async function loadLibrary() {
  try {
    beats = await fetchBeats();
    renderLibrary();
    document.title = `OK:${beats.length}`;
  } catch (err) {
    document.title = 'LOADERR:' + (err && err.message);
  }
}

function renderLibrary() {
  const car = document.getElementById('library-carousel');
  car.classList.toggle('as-grid', libraryView === 'grid');
  car.innerHTML = '';
  beats.forEach((b, i) => {
    const card = document.createElement('div');
    card.className = 'beat-card' + (i === 0 ? ' focused' : '');
    card.tabIndex = -1;
    card.innerHTML = `
      <div class="beat-cover ${genreClass(b.genre)}">
        ${b.cover_url
          ? `<img class="cover-img" src="${b.cover_url}" alt="">`
          : `<span class="big-letter">${b.name.charAt(0).toUpperCase()}</span>`}
        <span class="play-badge">▶</span>
      </div>
      <h2>${b.name}</h2>
      <div>
        <span class="genre-chip">${b.genre}</span>
        <span class="detail">${b.bpm} BPM</span>
      </div>`;
    card.addEventListener('click', () => launchPlayer(i));
    car.appendChild(card);
  });
  const count = document.getElementById('library-count');
  const viewLabel = libraryView === 'grid' ? 'Grid' : 'Carrusel';
  count.textContent = `Tienes ${beats.length} ${beats.length === 1 ? 'beat' : 'beats'} · Vista: ${viewLabel} · V: cambiar`;
  focusedIndex = 0;
  car.tabIndex = -1;
  car.focus();
  refreshFocus();
}

function toggleLibraryView() {
  libraryView = libraryView === 'grid' ? 'carousel' : 'grid';
  localStorage.setItem('tvView', libraryView);
  const car = document.getElementById('library-carousel');
  car.classList.toggle('as-grid', libraryView === 'grid');
  const count = document.getElementById('library-count');
  const viewLabel = libraryView === 'grid' ? 'Grid' : 'Carrusel';
  count.textContent = `Tienes ${beats.length} ${beats.length === 1 ? 'beat' : 'beats'} · Vista: ${viewLabel} · V: cambiar`;
  refreshFocus();
}

function moveGrid(dx, dy) {
  const n = beats.length;
  if (!n) return;
  if (libraryView === 'carousel') {
    if (dy !== 0) return;
    focusedIndex = (focusedIndex + dx + n) % n;
  } else {
    const rows = Math.ceil(n / GRID_COLS);
    let r = Math.floor(focusedIndex / GRID_COLS);
    let c = focusedIndex % GRID_COLS;
    const nc = c + dx;
    const nr = r + dy;
    if (nc < 0 || nc >= GRID_COLS || nr < 0 || nr >= rows) return;
    const idx = nr * GRID_COLS + nc;
    if (idx >= n) return;
    focusedIndex = idx;
  }
  refreshFocus();
}

function refreshFocus() {
  document.querySelectorAll('.beat-card').forEach((c, i) => {
    const f = i === focusedIndex;
    c.classList.toggle('focused', f);
    c.style.opacity = f ? '1' : '0.6';
  });
  const card = document.querySelector('.beat-card.focused');
  if (card) card.scrollIntoView({ block: 'nearest', inline: 'center', behavior: 'smooth' });
  setBgVideo(focusedIndex);
}

// ===== Barra lateral (vistas Biblioteca / Reproductor) =====

/// true si el beat enfocado está en el borde izquierdo (para poder salir al menú).
function atLeftEdge() {
  if (libraryView === 'carousel') return focusedIndex === 0;
  return focusedIndex % GRID_COLS === 0;
}

function refreshNavFocus() {
  document.querySelectorAll('.nav-item').forEach((btn, i) => {
    btn.classList.toggle('nav-focus', navFocus === i);
  });
}

function activateNav() {
  const idx = navFocus;
  navFocus = null;
  refreshNavFocus();
  if (idx === 1) {
    if (!audio || !isPlaying) launchPlayer(focusedIndex);
    else showView('player');
  } else {
    showView('library');
    const car = document.getElementById('library-carousel');
    if (car) car.focus();
  }
}

function setPlayerBeat(idx) {
  const b = beats[idx];
  document.getElementById('player-title').textContent = b.name;
  document.getElementById('player-details').textContent = `${b.genre} · ${b.bpm} BPM`;
  updateAlbumArt(b);
  setBgVideo(idx);
}

function launchPlayer(idx) {
  if (idx == null) idx = focusedIndex;
  if (!beats.length) return;
  focusedIndex = idx;
  setPlayerBeat(idx);
  showView('player');
  playBeat(beats[idx]);
}

function updateAlbumArt(beat) {
  const img = document.getElementById('album-img');
  const fallback = document.getElementById('album-fallback');
  fallback.className = beat.cover_url ? 'hidden' : '';
  fallback.textContent = beat.name.charAt(0).toUpperCase();
  if (beat.cover_url) {
    img.src = beat.cover_url;
    img.classList.remove('hidden');
  } else {
    img.classList.add('hidden');
  }
}

function ensureAudio() {
  if (audio) return;
  audio = new Audio();
  audio.loop = true;
  audio.addEventListener('timeupdate', () => {
    if (!audio.duration) return;
    if (!tvSynced) {
      setProgress(audio.currentTime / audio.duration * 100);
      setTimeText(fmt(audio.currentTime) + ' / ' + fmt(audio.duration));
    }
  });
}

function loadBeatAudio(beat) {
  ensureAudio();
  const src = beat.audio;
  if (audio.src.split('/').pop() !== src.split('/').pop()) {
    audio.src = src;
    audio.load();
    return true;
  }
  return false;
}

function playBeat(beat) {
  // Reproducción local directa: rompe la sincronización para que el audio de
  // la TV tome el control y el contador se reinicie en este beat.
  resetTvSync();
  loadBeatAudio(beat);
  audio.currentTime = 0;
  audio.play().then(() => {
    isPlaying = true;
    updatePlaybackUI();
  }).catch(() => {
    isPlaying = false;
    updatePlaybackUI();
  });
}

function togglePlay() {
  if (!audio) { playBeat(beats[focusedIndex]); return; }
  if (isPlaying) { audio.pause(); isPlaying = false; }
  else { resetTvSync(); audio.play(); isPlaying = true; }
  updatePlaybackUI();
}

function nextBeat() {
  focusedIndex = (focusedIndex + 1) % beats.length;
  if (currentView === 'player') launchPlayer(focusedIndex);
  else { setPlayerBeat(focusedIndex); playBeat(beats[focusedIndex]); updateMiniPlayer(); }
}
function prevBeat() {
  focusedIndex = (focusedIndex - 1 + beats.length) % beats.length;
  if (currentView === 'player') launchPlayer(focusedIndex);
  else { setPlayerBeat(focusedIndex); playBeat(beats[focusedIndex]); updateMiniPlayer(); }
}

function updateMiniPlayer() {
  const mini = document.getElementById('mini-player');
  if (!mini) return;
  const show = !!(audio && beats.length && currentView === 'library');
  mini.classList.toggle('hidden', !show);
  if (!show) return;
  const b = beats[focusedIndex];
  const t = document.getElementById('mini-title');
  if (t && b) t.textContent = b.name;
}

function updatePlaybackUI() {
  const status = document.getElementById('playback-status');
  const icon = document.getElementById('playback-icon');
  if (isPlaying) {
    if (!tvSynced) { status.textContent = 'REPRODUCIENDO'; status.className = 'playing'; }
    icon.textContent = '⏸';
  } else {
    if (!tvSynced) { status.textContent = 'PAUSADO'; status.className = 'paused'; }
    icon.textContent = '▶';
  }
  updateMiniPlayer();
}

function handleAction(act) {
  if (act === 'sync') { toggleSync(); return; }
  if (!beats.length) return;
  // Navegando en la barra lateral (Biblioteca / Reproductor).
  if (navFocus != null) {
    switch (act) {
      case 'up': navFocus = 0; break;
      case 'down': navFocus = 1; break;
      case 'left': case 'back': navFocus = null; break;
      case 'right': case 'ok': activateNav(); return;
    }
    refreshNavFocus();
    return;
  }
  if (currentView === 'library') {
    switch (act) {
      case 'left':
        if (atLeftEdge()) { navFocus = 0; refreshNavFocus(); }
        else moveGrid(-1, 0);
        break;
      case 'right': moveGrid(1, 0); break;
      case 'up': moveGrid(0, -1); break;
      case 'down': moveGrid(0, 1); break;
      case 'ok': launchPlayer(focusedIndex); break;
      case 'toggle': launchPlayer(focusedIndex); break;
      case 'next': nextBeat(); break;
      case 'prev': prevBeat(); break;
      case 'toggleview': toggleLibraryView(); break;
    }
  } else {
    switch (act) {
      case 'back': case 'ok': showView('library'); break;
      case 'toggle': togglePlay(); break;
      case 'next': case 'right': nextBeat(); break;
      case 'prev': case 'left': prevBeat(); break;
      case 'toggleview': showView('library'); toggleLibraryView(); break;
    }
  }
}

window.addEventListener('keydown', (e) => {
  const k = e.key;
  const c = e.keyCode || e.which;
  let act = null;
  switch (k) {
    case 'ArrowUp': act = 'up'; break;
    case 'ArrowDown': act = 'down'; break;
    case 'ArrowLeft': act = 'left'; break;
    case 'ArrowRight': act = 'right'; break;
    case 'Escape': case 'Backspace': act = 'back'; break;
    case 'Enter': case 'OK': act = 'ok'; break;
    case ' ': case 'p': case 'P': act = 'toggle'; break;
    case 'n': case 'N': act = 'next'; break;
    case 'b': case 'B': act = 'prev'; break;
    case 'v': case 'V': act = 'toggleview'; break;
    case 's': case 'S': act = 'sync'; break;
  }
  if (!act) {
    switch (c) {
      case 19: act = 'up'; break;      // DPAD_UP
      case 20: act = 'down'; break;    // DPAD_DOWN
      case 21: act = 'left'; break;    // DPAD_LEFT
      case 22: act = 'right'; break;   // DPAD_RIGHT
      case 13: case 23: case 66: case 160: act = 'ok'; break; // ENTER, DPAD_CENTER, KEYCODE_ENTER
      case 32: act = 'toggle'; break;  // SPACE
      case 4: case 27: act = 'back'; break; // KEYCODE_BACK, ESCAPE
    }
  }
  if (act) {
    e.preventDefault();
    e.stopPropagation();
    handleAction(act);
  }
}, true);

document.getElementById('app').addEventListener('click', () => {
  const car = document.getElementById('library-carousel');
  if (document.activeElement !== car) car.focus();
});

function showView(view) {
  currentView = view;
  const lib = document.getElementById('library-view');
  const player = document.getElementById('player-view');
  if (view === 'player') {
    lib.classList.add('hidden');
    player.classList.remove('hidden');
  } else {
    lib.classList.remove('hidden');
    player.classList.add('hidden');
    refreshFocus();
  }
  updateMiniPlayer();
}

document.getElementById('btn-toggle').addEventListener('click', togglePlay);
document.getElementById('btn-next').addEventListener('click', () => { if (beats.length) nextBeat(); });
document.getElementById('btn-prev').addEventListener('click', () => { if (beats.length) prevBeat(); });
document.getElementById('btn-back').addEventListener('click', () => showView('library'));

document.querySelectorAll('.nav-item').forEach((btn) => {
  btn.addEventListener('click', () => {
    const view = btn.dataset.view;
    document.querySelectorAll('.nav-item').forEach((b) => b.classList.toggle('active', b === btn));
    if (view === 'player') {
      if (!audio || !isPlaying) launchPlayer(focusedIndex);
      else showView('player');
    } else {
      showView(view);
    }
  });
});

window.addEventListener('error', (e) => {
  try { document.title = 'JSERR:' + (e.message || e.type); } catch (_) {}
}, true);

loadLibrary();