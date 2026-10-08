// =============================================================================
// Utilitários de UI partilhados por todas as páginas
// =============================================================================

// --- Tema claro/escuro ---
export function initTema() {
  try {
    const saved = localStorage.getItem('ls-tema');
    if (saved) setTema(saved);
  } catch(e) {}
}

export function setTema(t) {
  document.documentElement.setAttribute('data-theme', t);
  document.querySelectorAll('[data-tema-btn]').forEach(btn => {
    btn.classList.toggle('active', btn.dataset.temabtn === t ||
      (btn.dataset.temabtn === 'light' && t === 'light') ||
      (btn.dataset.temabtn === 'dark'  && t === 'dark'));
  });
  try { localStorage.setItem('ls-tema', t); } catch(e) {}
}

export function toggleTema() {
  const cur = document.documentElement.getAttribute('data-theme') || 'light';
  setTema(cur === 'light' ? 'dark' : 'light');
}

// --- Relógio do footer ---
export function initRelogio() {
  function tick() {
    const now = new Date();
    const el_d = document.getElementById('footer-data');
    const el_h = document.getElementById('footer-hora');
    if (el_d) el_d.textContent = now.toLocaleDateString('pt-PT');
    if (el_h) el_h.textContent = now.toLocaleTimeString('pt-PT', {hour:'2-digit',minute:'2-digit'});
  }
  tick();
  setInterval(tick, 30000);
}

// --- Flash messages ---
export function flash(msg, tipo = 'success', duracao = 3500) {
  const el = document.getElementById('flash-msg');
  if (!el) return;
  el.textContent = msg;
  el.className = `flash ${tipo}`;
  el.hidden = false;
  if (duracao > 0) setTimeout(() => { el.hidden = true; }, duracao);
}

// --- Toggle formulário ---
export function toggleForm(id) {
  const el = document.getElementById(id);
  if (el) el.hidden = !el.hidden;
}

// --- Toggle linha de detalhe ---
export function toggleDetail(btn) {
  const row = btn.closest('tr');
  const detail = row?.nextElementSibling;
  if (!detail?.classList.contains('row-detail')) return;
  detail.hidden = !detail.hidden;
  btn.textContent = detail.hidden ? '⊕' : '⊖';
}

// --- Badge de temperatura (aquários) ---
export function tempBadge(minTemp) {
  const t = parseFloat(minTemp);
  if (isNaN(t)) return '';
  if (t <= 18) return '<span class="temp-badge temp-fria">🧊 Fria</span>';
  if (t <= 22) return '<span class="temp-badge temp-temperada">🌡️ Temperada</span>';
  return '<span class="temp-badge temp-tropical">🔥 Tropical</span>';
}

// --- Confirmar e eliminar linha da tabela ---
export function confirmarEliminar(btn, msg = 'Eliminar este registo?') {
  if (confirm(msg)) {
    btn.closest('tr')?.remove();
    return true;
  }
  return false;
}

// --- Sidebar mobile ---
export function initSidebar() {
  document.addEventListener('click', e => {
    if (window.innerWidth >= 900) return;
    const sidebar = document.getElementById('sidebar');
    if (!sidebar) return;
    if (!sidebar.contains(e.target) && !e.target.closest('.menu-toggle-btn')) {
      document.body.classList.remove('menu-open');
    }
  });
}

// --- Formatar data PT ---
export function fmtData(iso) {
  if (!iso) return '—';
  const d = new Date(iso);
  return d.toLocaleDateString('pt-PT');
}

// --- Formatar datetime PT ---
export function fmtDatetime(iso) {
  if (!iso) return '—';
  const d = new Date(iso);
  return d.toLocaleString('pt-PT', {
    day:'2-digit', month:'2-digit', year:'numeric',
    hour:'2-digit', minute:'2-digit'
  });
}

// --- Token de sessão (localStorage) ---
export function getToken()      { try { return localStorage.getItem('ls-token'); }  catch(e) { return null; } }
export function setToken(t)     { try { localStorage.setItem('ls-token', t); }       catch(e) {} }
export function clearToken()    { try { localStorage.removeItem('ls-token'); }        catch(e) {} }
export function estaLogado()    { return !!getToken(); }
