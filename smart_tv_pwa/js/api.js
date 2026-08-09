const CFG = window.SKONDIT_CONFIG || {};
const SUPABASE_URL = CFG.SUPABASE_URL || '';
const SUPABASE_ANON_KEY = CFG.SUPABASE_ANON_KEY || '';
const USER_ID = CFG.USER_ID || '';

const LOCAL_COVERS = {
  'Chill LoFi': 'images/trap1.png',
};

const LOCAL_BEATS = [
  { id: '1', name: 'Night City', genre: 'Trap', bpm: 140, price: 29.99, audio: 'audio/night_city.wav', cover_url: null },
  { id: '2', name: 'Drill King', genre: 'Drill', bpm: 150, price: 34.99, audio: 'audio/drill_king.wav', cover_url: null },
  { id: '3', name: 'Old School', genre: 'Rap', bpm: 85, price: 24.99, audio: 'audio/old_school.wav', cover_url: null },
  { id: '4', name: 'Dark Trap', genre: 'Trap', bpm: 145, price: 39.99, audio: 'audio/dark_trap.wav', cover_url: null },
];

async function fetchBeats() {
  if (!SUPABASE_URL || !SUPABASE_ANON_KEY || !USER_ID) return LOCAL_BEATS;
  try {
    const url = `${SUPABASE_URL}/rest/v1/orders` +
      `?select=order_items(beat_id,beats(id,nombre,genero,bpm,precio,audio_url,imagen_url))` +
      `&user_id=eq.${USER_ID}&status=eq.COMPLETADO`;
    const res = await fetch(url, {
      headers: { 'apikey': SUPABASE_ANON_KEY, 'Authorization': `Bearer ${SUPABASE_ANON_KEY}` }
    });
    if (!res.ok) return LOCAL_BEATS;
    const data = await res.json();
    if (!Array.isArray(data) || data.length === 0) return LOCAL_BEATS;

    const beats = [];
    const seen = new Set();
    data.forEach((order) => {
      (order.order_items || []).forEach((item) => {
        const b = item.beats;
        if (!b) return;
        if (seen.has(b.id)) return;
        seen.add(b.id);
        beats.push({
          id: b.id,
          name: b.nombre,
          genre: b.genero,
          bpm: b.bpm,
          price: Number(b.precio),
          cover_url: b.imagen_url || LOCAL_COVERS[b.nombre] || null,
          audio: b.audio_url || 'audio/night_city.wav',
        });
      });
    });
    return beats.length > 0 ? beats : LOCAL_BEATS;
  } catch (e) {
    return LOCAL_BEATS;
  }
}