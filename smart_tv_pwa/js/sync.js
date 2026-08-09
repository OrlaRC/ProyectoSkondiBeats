// Sincronización teléfono → TV (P3.3).
// El teléfono publica su beat actual + posición en la tabla `now_playing`
// de Supabase; la TV la consulta cada 2s y la sigue (si el toggle está ON).
// Si el toggle está OFF, la TV opera independiente.

const SYNC_CFG = window.SKONDIT_CONFIG || {};
const SYNC_URL = SYNC_CFG.SUPABASE_URL || '';
const SYNC_KEY = SYNC_CFG.SUPABASE_ANON_KEY || '';

let tvSync = localStorage.getItem('tvSync') !== 'off'; // default ON
let tvSynced = false;
let syncLast = null;

// Reloj interpolado: entre actualización y actualización del teléfono (cada ~2s),
// la TV avanza la posición con su propio reloj para que el conteo sea fluido.
let syncBasePos = 0;
let syncBaseTime = 0;
let syncPlaying = false;
let syncDur = 0;
let syncClockTimer = null;

// Posición más alta ya mostrada (monótona): evita que la barra "se regrese" un
// poco cada vez que el teléfono publica un nuevo snapshot entero.
let syncShownPos = 0;
// Nombre del beat que se está sincronizando; si cambia, el contador se reinicia.
let syncBeat = '';

function stopSyncClock() {
  if (syncClockTimer) { clearInterval(syncClockTimer); syncClockTimer = null; }
}

function startSyncClock() {
  if (syncClockTimer) return;
  syncClockTimer = setInterval(() => {
    if (!tvSynced || !syncPlaying) return;
    const next = syncBasePos + (Date.now() - syncBaseTime) / 1000;
    if (next > syncShownPos) syncShownPos = next;
    const pos = syncShownPos;
    if (typeof setTimeText === 'function') {
      setTimeText(fmtTime(pos) + ' / ' + fmtTime(syncDur));
    }
    if (typeof setProgress === 'function') {
      const pct = syncDur > 0 ? (pos / syncDur) * 100 : 0;
      setProgress(Math.min(100, Math.max(0, pct)));
    }
  }, 200);
}

/// Rompe la sincronización para que el audio local de la TV tome el control
/// (p.ej. al reproducir un beat directamente en la TV).
function resetTvSync() {
  tvSynced = false;
  syncShownPos = 0;
  syncBasePos = 0;
  syncBaseTime = 0;
  syncPlaying = false;
  syncBeat = '';
  stopSyncClock();
}

function fmtTime(sec) {
  const s = Math.max(0, Math.floor(sec || 0));
  return Math.floor(s / 60) + ':' + String(s % 60).padStart(2, '0');
}

function setSyncUI() {
  const b = document.getElementById('sync-toggle');
  if (b) {
    b.textContent = 'Sync: ' + (tvSync ? 'ON' : 'OFF');
    b.classList.toggle('on', tvSync);
    b.classList.toggle('off', !tvSync);
  }
}

function toggleSync() {
  tvSync = !tvSync;
  localStorage.setItem('tvSync', tvSync ? 'on' : 'off');
  if (!tvSync) {
    tvSynced = false;
    stopSyncClock();
    if (audio) audio.play().catch(() => {});
  }
  setSyncUI();
  return tvSync;
}

async function syncPoll() {
  if (!tvSync || !SYNC_URL || !SYNC_KEY) return;
  try {
    const res = await fetch(
      `${SYNC_URL}/rest/v1/now_playing?select=beat_id,beat_name,genre,bpm,position_sec,duration_sec,playing,target,updated_at&id=eq.1&limit=1`,
      { headers: { apikey: SYNC_KEY, Authorization: 'Bearer ' + SYNC_KEY } },
    );
    if (!res.ok) return;
    const rows = await res.json();
    if (!Array.isArray(rows) || rows.length === 0) return;
    const p = rows[0];
    if (p.updated_at && syncLast === p.updated_at) return;
    syncLast = p.updated_at || Date.now();
    tvSynced = true;

    // Nuevo beat desde el teléfono → reinicia el contador.
    const newBeat = (p.beat_name || '').trim().toLowerCase();
    if (newBeat !== syncBeat) {
      syncBeat = newBeat;
      syncShownPos = 0;
    }
    syncBasePos = p.position_sec || 0;
    syncBaseTime = Date.now();
    // Posición 0 o beat nuevo desde el teléfono → reinicia el contador.
    if (syncBasePos <= 0) syncShownPos = 0;
    if (syncBasePos > syncShownPos) syncShownPos = syncBasePos;
    syncPlaying = !!p.playing;
    syncDur = p.duration_sec || 0;

    const applyPos = syncShownPos;
    const timeEl = document.getElementById('player-time');
    const timeText = fmtTime(applyPos) + ' / ' + fmtTime(syncDur);
    if (typeof setTimeText === 'function') setTimeText(timeText);
    else if (timeEl) timeEl.textContent = timeText;
    if (typeof setProgress === 'function') {
      const pct = syncDur > 0 ? (applyPos / syncDur) * 100 : 0;
      setProgress(Math.min(100, Math.max(0, pct)));
    }
    syncBasePos = syncShownPos;
    if (syncPlaying) startSyncClock();
    else stopSyncClock();
    const status = document.getElementById('playback-status');
    if (status) {
      if (p.target === 'app') {
        status.textContent = p.playing ? 'REPRODUCIENDO EN EL TELÉFONO' : 'EN PAUSA · TELÉFONO';
        status.className = p.playing ? 'phone' : 'paused';
      } else {
        status.textContent = p.playing ? 'SINCRONIZADO · TELÉFONO' : 'EN PAUSA · TELÉFONO';
        status.className = p.playing ? 'playing' : 'paused';
      }
    }
    if (typeof updateMiniPlayer === 'function') updateMiniPlayer();

    const curIdx = (typeof focusedIndex !== 'undefined') ? focusedIndex : 0;
    const cur = beats && beats[curIdx];
    const target = (p.beat_name || '').trim().toLowerCase();
    const idx = beats ? beats.findIndex((b) => b.name.toLowerCase() === target) : -1;
    const targetBeat = idx >= 0 ? beats[idx] : null;
    if (targetBeat && (!cur || cur.name.toLowerCase() !== target)) {
      focusedIndex = idx;
      if (typeof setPlayerBeat === 'function') setPlayerBeat(idx);
      if (typeof showView === 'function') showView('player');
    }
    // La TV solo reproduce audio cuando el teléfono elige 'tv'.
    // Con target 'app' el audio suena en el teléfono (evita doble reproducción).
    const shouldPlayHere = p.target !== 'app';
    const srcChanged = (targetBeat && typeof loadBeatAudio === 'function') ? loadBeatAudio(targetBeat) : false;
    const a = audio;
    if (a) {
      if (shouldPlayHere && p.playing) {
        // Sincroniza el audio con la posición publicada por el teléfono:
        // si el teléfono reanuda donde se quedó, la TV hace seek ahí; si
        // empezó de cero (posición 0), la TV reinicia.
        const targetPos = syncShownPos;
        const syncAudio = () => {
          try {
            if (Math.abs(a.currentTime - targetPos) > 1.5) a.currentTime = targetPos;
          } catch (_) {}
          if (a.paused) a.play().catch(() => {});
        };
        if (srcChanged) {
          a.addEventListener('loadedmetadata', syncAudio, { once: true });
        } else {
          syncAudio();
        }
      } else if ((!shouldPlayHere || !p.playing) && !a.paused) {
        a.pause();
      }
    }
  } catch (_) {}
}

function startSyncPolling() {
  setSyncUI();
  const b = document.getElementById('sync-toggle');
  if (b) b.addEventListener('click', toggleSync);
  setInterval(syncPoll, 2000);
}

startSyncPolling();
