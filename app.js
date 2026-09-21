/* ============================================================
   OH CARDS 网页版逻辑
   对齐 lib/data 与 lib/screens 的行为：
   - 卡牌清单来自 cards.json（与 App 资源一致）
   - 账号 / 解锁进度 / 兑换码走现有 Supabase 后端，与 Flutter App 互通
   ============================================================ */

// ---------- Supabase 配置（与 lib/data/supabase_config.dart 一致） ----------
const SUPABASE_URL = 'https://snzhiqhykcdknhjurzme.supabase.co';
const SUPABASE_KEY = 'sb_publishable_7BqHqaZijzwSQPPeiwzX1A_8S0NuI-J';

const DEFAULT_UNLOCKED = 'based';
const MIXED_ID = 'mixed';
const MIXED_NAME_ZH = '多组同抽';
const MIXED_NAME_EN = 'MIXED';

// ---------- 全局状态 ----------
let supabaseClient = null;

const state = {
  decks: [],                 // 来自 cards.json
  user: null,                // Supabase 当前用户
  unlocked: new Set(),       // 已解锁卡组 id
  view: 'home',              // home | draw | mixed | result | auth

  // 单卡组抽卡
  draw: null,

  // 混卡抽卡
  mixed: null,

  // 最近一次抽卡结果（还原用）
  lastDraw: null,

  // 结果页数据
  result: null,
};

const $app = document.getElementById('app');

// ============================================================
// 工具函数
// ============================================================
function h(html) {
  const t = document.createElement('template');
  t.innerHTML = html.trim();
  return t.content.firstElementChild;
}

function shuffle(arr) {
  const a = arr.slice();
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

function pick(cards) {
  return cards[Math.floor(Math.random() * cards.length)];
}

function columnsFor() {
  const w = window.innerWidth;
  return w >= 1024 ? 4 : w >= 700 ? 3 : 2;
}

// ---------- 图标 ----------
const ICONS = {
  menu: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M4 6h16M4 12h16M4 18h16"/></svg>',
  home: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 10.5 12 3l9 7.5"/><path d="M5 9.5V21h14V9.5"/></svg>',
  back: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M19 12H5M11 18l-6-6 6-6"/></svg>',
  restore: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 12a9 9 0 1 0 3-6.7L3 8"/><path d="M3 3v5h5"/></svg>',
  person: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="8" r="4"/><path d="M4 21c0-4 3.6-6 8-6s8 2 8 6"/></svg>',
  personOutline: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="8" r="3.5"/><path d="M4 21c0-4 3.6-6 8-6s8 2 8 6"/></svg>',
  lock: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="4" y="10" width="16" height="10" rx="2"/><path d="M8 10V7a4 4 0 0 1 8 0v3"/></svg>',
  check: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/><path d="m8 12 3 3 5-6"/></svg>',
  checkCircle: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/><path d="m8.5 12.5 2.5 2.5 4.5-5"/></svg>',
  circleOutline: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="8.5"/></svg>',
  sparkle: '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2l1.8 6.2L20 10l-6.2 1.8L12 18l-1.8-6.2L4 10l6.2-1.8z"/><path d="M19 15l.9 3.1L23 19l-3.1.9L19 23l-.9-3.1L15 19l3.1-.9z"/></svg>',
  flag: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 21V4"/><path d="M5 4c4-2 8 2 12 0v9c-4 2-8-2-12 0"/></svg>',
  eye: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M2 12s3.5-6 10-6 10 6 10 6-3.5 6-10 6-10-6-10-6z"/><circle cx="12" cy="12" r="2.5"/></svg>',
  eyeOff: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 3l18 18"/><path d="M10.5 5.2A10 10 0 0 1 12 5c6.5 0 10 7 10 7a17 17 0 0 1-3 3.6M6.6 6.6A17 17 0 0 0 2 12s3.5 7 10 7a9.8 9.8 0 0 0 4.5-1.1"/></svg>',
  mail: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="5" width="18" height="14" rx="2"/><path d="m3 7 9 6 9-6"/></svg>',
  swipe: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M8 7 3 12l5 5M16 7l5 5-5 5"/><path d="M9 12h6"/></svg>',
  drop: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m7 10 5-5 5 5"/><path d="M7 14l5 5 5-5"/></svg>',
};

function icon(name, cls) {
  return `<span class="${cls || 'svg18'}" aria-hidden="true">${ICONS[name] || ''}</span>`;
}

// ============================================================
// 卡组数据访问
// ============================================================
function getDeck(id) {
  return state.decks.find((d) => d.id === id);
}

function deckHasChoices(deck) {
  return deck.categories.length > 1;
}

function thumbnailCategory(deck) {
  const wanted = deck.thumbnailFolder;
  if (wanted) {
    const c = deck.categories.find((x) => x.folder === wanted);
    if (c) return c;
  }
  return deck.categories.find((x) => x.defaultOn) || deck.categories[0];
}

function isUnlocked(deckId) {
  if (deckId === DEFAULT_UNLOCKED || deckId === MIXED_ID) return true;
  return state.unlocked.has(deckId);
}

// 主页入口顺序：基础卡 → 混卡 → 其余卡组
function homeEntries() {
  const decks = state.decks;
  const based = decks.find((d) => d.id === 'based');
  const rest = decks.filter((d) => d.id !== 'based');
  const entries = [
    { id: based.id, nameZh: based.nameZh, nameEn: based.nameEn, deck: based, isMixed: false },
    { id: MIXED_ID, nameZh: MIXED_NAME_ZH, nameEn: MIXED_NAME_EN, deck: null, isMixed: true },
    ...rest.map((d) => ({ id: d.id, nameZh: d.nameZh, nameEn: d.nameEn, deck: d, isMixed: false })),
  ];
  // 稳定排序：已解锁在前
  return entries.sort((a, b) => (isUnlocked(a.id) === isUnlocked(b.id) ? 0 : isUnlocked(a.id) ? -1 : 1));
}

function sortedDecks() {
  const decks = state.decks.slice();
  return decks.sort((a, b) => (isUnlocked(a.id) === isUnlocked(b.id) ? 0 : isUnlocked(a.id) ? -1 : 1));
}

// ============================================================
// Toast / Drawer / Modal
// ============================================================
let toastTimer = null;
function toast(msg) {
  const el = document.getElementById('toast');
  el.textContent = msg;
  el.hidden = false;
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => { el.hidden = true; }, 2400);
}

const drawerEl = document.getElementById('drawer');
const drawerOverlay = document.getElementById('drawer-overlay');
function openDrawer(side, html) {
  drawerEl.className = 'drawer ' + side;
  drawerEl.innerHTML = html;
  drawerEl.hidden = false;
  drawerOverlay.hidden = false;
}
function closeDrawer() {
  drawerEl.hidden = true;
  drawerOverlay.hidden = true;
}
drawerOverlay.addEventListener('click', closeDrawer);

const modalEl = document.getElementById('modal');
const modalOverlay = document.getElementById('modal-overlay');
function openModal(html) {
  modalEl.innerHTML = html;
  modalEl.hidden = false;
  modalOverlay.hidden = false;
}
function closeModal() {
  modalEl.hidden = true;
  modalOverlay.hidden = true;
}
modalOverlay.addEventListener('click', closeModal);

// ============================================================
// 账号（Supabase）
// ============================================================
function accountReady() {
  return !!supabaseClient;
}

function displayName() {
  const email = state.user && state.user.email;
  if (!email) return '未登录';
  const at = email.indexOf('@');
  return at > 0 ? email.slice(0, at) : email;
}

async function loadUnlocks() {
  if (!state.user) { state.unlocked = new Set(); return; }
  try {
    const { data, error } = await supabaseClient
      .from('deck_unlocks')
      .select('deck_id')
      .eq('user_id', state.user.id);
    if (error) throw error;
    state.unlocked = new Set((data || []).map((r) => r.deck_id));
  } catch (_) {
    state.unlocked = new Set();
  }
}

function friendlyAuthError(raw) {
  const s = (raw || '').toLowerCase();
  if (s.includes('already registered') || s.includes('already exists')) return '该邮箱已注册，请直接登录';
  if (s.includes('invalid login credentials') || s.includes('invalid email or password')) return '邮箱或密码错误';
  if (s.includes('password')) return '密码需至少 6 位';
  if (s.includes('email')) return '邮箱格式不正确';
  return '操作失败：' + raw;
}

async function signUp(email, password) {
  const { data, error } = await supabaseClient.auth.signUp({ email, password });
  if (error) throw error;
  if (data.session) {
    state.user = data.user;
    await loadUnlocks();
    return true; // 已自动登录
  }
  return false; // 需要邮件确认
}

async function signIn(email, password) {
  const { error } = await supabaseClient.auth.signInWithPassword({ email, password });
  if (error) throw error;
  const { data } = await supabaseClient.auth.getSession();
  state.user = data.session ? data.session.user : null;
  await loadUnlocks();
}

async function signOut() {
  await supabaseClient.auth.signOut();
  state.user = null;
  state.unlocked = new Set();
}

async function redeemCode(code) {
  if (!state.user) throw new Error('请先登录账号');
  const { data, error } = await supabaseClient.rpc('redeem_code', { p_code: code.trim() });
  if (error) {
    const s = (error.message || '').toLowerCase();
    if (s.includes('not_logged_in')) throw new Error('请先登录账号');
    if (s.includes('invalid_code')) throw new Error('兑换码无效或已被使用');
    throw new Error('兑换失败：' + error.message);
  }
  const deckId = data;
  if (!deckId) throw new Error('兑换码无效或已被使用');
  if (deckId === 'all') {
    await loadUnlocks();
  } else {
    state.unlocked.add(deckId);
  }
  return deckId;
}

// ============================================================
// 抽卡会话
// ============================================================
function newDrawSession(deck, restore) {
  const enabled = new Set();
  if (deckHasChoices(deck)) {
    deck.categories.filter((c) => c.defaultOn).forEach((c) => enabled.add(c.folder));
    if (enabled.size === 0) enabled.add(deck.categories[0].folder);
  } else {
    deck.categories.forEach((c) => enabled.add(c.folder));
  }
  const counts = {};
  deck.categories.forEach((c) => (counts[c.folder] = 1));

  const session = {
    deck,
    enabled,
    drawn: {},       // folder -> 当前牌面 asset
    round: [],       // DrawnCard[]
    counts,
    busy: false,
  };

  if (restore) {
    session.round = restore.cards.slice();
    for (const card of restore.cards) {
      const cat = deck.categories.find((c) => c.folder === card.categoryId);
      if (cat) session.drawn[cat.folder] = card.asset;
    }
    const drawnIds = Object.keys(session.drawn);
    if (drawnIds.length > 0) {
      enabled.clear();
      drawnIds.forEach((id) => enabled.add(id));
    }
  }
  return session;
}

function categoryOf(deck, folder) {
  return deck.categories.find((c) => c.folder === folder);
}

function drawnCard(deck, cat, asset) {
  return {
    deckId: deck.id,
    deckNameZh: deck.nameZh,
    deckNameEn: deck.nameEn,
    categoryId: cat.folder,
    categoryLabelZh: cat.labelZh,
    categoryLabelEn: cat.labelEn,
    asset,
    isWholeDeck: cat.labelZh === deck.nameZh,
  };
}

// ============================================================
// 渲染入口
// ============================================================
function render() {
  switch (state.view) {
    case 'home': renderHome(); break;
    case 'draw': renderDrawScreen(); break;
    case 'mixed': renderMixedScreen(); break;
    case 'result': renderResult(); break;
    case 'auth': renderAuth(); break;
    default: renderHome();
  }
}

// ============================================================
// 主页
// ============================================================

// 主页神秘学背景装饰：弦月、星点、曼陀罗圆环（极淡线条，冥想沉思感）
function mysticLayerHTML() {
  // 曼陀罗花瓣：12 片，内外两圈交错
  const petals = [];
  for (let i = 0; i < 12; i++) {
    petals.push(`<ellipse cx="0" cy="-172" rx="24" ry="66" transform="rotate(${i * 30})"/>`);
  }
  for (let i = 0; i < 12; i++) {
    petals.push(`<ellipse cx="0" cy="-116" rx="14" ry="40" transform="rotate(${i * 30 + 15})"/>`);
  }
  // 四角星芒
  const star = 'M0,-7 L1.8,-1.8 L7,0 L1.8,1.8 L0,7 L-1.8,1.8 L-7,0 L-1.8,-1.8 Z';

  return `
  <div class="mystic-layer" aria-hidden="true">
    <svg class="ml ml-moon" viewBox="0 0 160 200">
      <!-- 弦月 -->
      <path class="m-moon" d="M 22 0 A 22 22 0 1 0 22 44 A 30 30 0 1 1 22 0 Z" transform="translate(18,10)"/>
      <!-- 星点 -->
      <path class="m-star" d="${star}" transform="translate(104,20) scale(.8)"/>
      <path class="m-star" d="${star}" transform="translate(132,66) scale(.5)"/>
      <circle class="m-dot" cx="84" cy="78" r="1.6"/>
      <circle class="m-dot" cx="118" cy="104" r="1.2"/>
      <path class="m-star" d="${star}" transform="translate(40,128) scale(.45)"/>
    </svg>
    <svg class="ml ml-mandala" viewBox="0 0 560 560">
      <g transform="translate(280,280)">
        <circle r="268"/>
        <circle r="232"/>
        <circle r="150"/>
        <circle r="104"/>
        <circle r="46"/>
        ${petals.join('')}
        <g class="m-rays">
          ${Array.from({ length: 24 }, (_, i) => `<line x1="0" y1="-232" x2="0" y2="-250" transform="rotate(${i * 15})"/>`).join('')}
        </g>
      </g>
    </svg>
    <svg class="ml ml-rings" viewBox="0 0 200 200">
      <g transform="translate(100,100)">
        <circle r="92"/>
        <circle r="64"/>
        <circle r="36"/>
      </g>
    </svg>
  </div>`;
}

function renderHome() {
  const entries = homeEntries();
  const cols = columnsFor();

  const chips = entries.map((e, i) => {
    const locked = !isUnlocked(e.id);
    return `<div class="qa-chip ${i === state.quickIndex ? 'on' : ''} ${locked ? 'locked' : ''}" data-quick="${i}" ${locked ? '' : 'role="button"'}>
      <span class="zh">${e.nameZh}</span>
      <span class="en">${e.nameEn}</span>
      ${locked ? icon('lock', 'lock') : ''}
    </div>`;
  }).join('');

  const tiles = entries.map((e, i) => {
    const locked = !isUnlocked(e.id);
    if (e.isMixed) return mixedTile(e, locked, i);
    return deckTile(e.deck, locked, i);
  }).join('');

  $app.innerHTML = `
    <div class="screen home">
      ${mysticLayerHTML()}
      <div class="scroll">
        <div class="home-header">
          <div class="mark">OH CARDS</div>
          <div class="big">OH卡</div>
          <div class="sub">点击牌组进入抽卡</div>
          <button class="icon-btn profile-btn" data-action="profile" aria-label="个人主页">${icon('person')}</button>
        </div>
        <div class="quick-access">
          <div class="qa-label-row">
            <div class="qa-label">您想要抽取的卡组是（点击抵达）</div>
            <div class="qa-hint">左右滑动浏览</div>
          </div>
          <div class="qa-row">${chips}</div>
        </div>
        <div class="grid cols-${cols}">${tiles}</div>
      </div>
    </div>`;

  $app.querySelector('[data-action="profile"]').addEventListener('click', () => openProfileDrawer());
  $app.querySelectorAll('[data-quick]').forEach((el) => {
    el.addEventListener('click', () => {
      const i = Number(el.dataset.quick);
      if (!isUnlocked(entries[i].id)) return;
      state.quickIndex = i;
      const tile = $app.querySelector(`[data-tile="${i}"]`);
      if (tile) tile.scrollIntoView({ behavior: 'smooth', block: 'center' });
    });
  });
  $app.querySelectorAll('[data-enter]').forEach((el) => {
    el.addEventListener('click', () => {
      const id = el.dataset.enter;
      if (!isUnlocked(id)) return;
      if (id === MIXED_ID) openMixed();
      else openDraw(id);
    });
  });
}

function mixedTile(entry, locked, index) {
  const decks = state.decks;
  const backs = [
    thumbnailCategory(decks[0]).back,
    thumbnailCategory(decks[Math.floor(decks.length / 2)]).back,
    thumbnailCategory(decks[decks.length - 1]).back,
  ];
  return `
    <div class="tile ${locked ? 'locked' : ''}" data-tile="${index}" data-enter="mixed" ${locked ? '' : 'role="button"'}>
      <div class="tile-img ${locked ? 'gray' : ''}">
        <div class="mixed-stack">
          <div class="ms-card m0"><img src="${backs[0]}" alt="" loading="lazy"/></div>
          <div class="ms-card m1"><img src="${backs[1]}" alt="" loading="lazy"/></div>
          <div class="ms-card m2"><img src="${backs[2]}" alt="" loading="lazy"/></div>
        </div>
        ${locked ? icon('lock', 'lock') : ''}
      </div>
      <div class="t-zh">${entry.nameZh}</div>
      <div class="t-en">${entry.nameEn}</div>
    </div>`;
}

function deckTile(deck, locked, index) {
  const back = thumbnailCategory(deck).back;
  return `
    <div class="tile ${locked ? 'locked' : ''}" data-tile="${index}" data-enter="${deck.id}" ${locked ? '' : 'role="button"'}>
      <div class="tile-img ${locked ? 'gray' : ''}">
        <img src="${back}" alt="${deck.nameZh}" loading="lazy"/>
        ${locked ? icon('lock', 'lock') : ''}
      </div>
      <div class="t-zh">${deck.nameZh}</div>
      <div class="t-en">${deck.nameEn}</div>
    </div>`;
}

// ============================================================
// 单卡组抽卡界面
// ============================================================
function openDraw(deckId) {
  const deck = getDeck(deckId);
  state.draw = newDrawSession(deck, null);
  state.view = 'draw';
  render();
}

function renderDrawScreen() {
  const s = state.draw;
  const deck = s.deck;
  const hasChoices = deckHasChoices(deck);
  const enabledCats = deck.categories.filter((c) => s.enabled.has(c.folder));

  const categoryBar = hasChoices
    ? `<div class="category-bar">${deck.categories.map((c) => `
        <div class="toggle-chip ${s.enabled.has(c.folder) ? 'on' : ''}" data-toggle="${c.folder}" role="button">
          ${icon(s.enabled.has(c.folder) ? 'checkCircle' : 'circleOutline')}
          <span>${c.labelZh} ${c.labelEn}</span>
        </div>`).join('')}
      </div>`
    : '';

  const hint = Object.keys(s.drawn).length > 0
    ? '单击牌面可直接抽出下一张\n结束本轮抽卡后，点击退出按键查看结果汇总'
    : '单击牌堆进行抽卡\n也可在下方设置次数一次性抽出';

  $app.innerHTML = `
    <div class="screen">
      <div class="content">
        ${topBar({
          left: 'menu',
          titleZh: deck.nameZh,
          titleEn: deck.nameEn,
          right: ['restore', 'home'],
        })}
        ${categoryBar}
        <div class="stage">
          <div class="stage-hint">${escapeHtml(hint)}</div>
          <div class="stage-area" data-stage>${enabledCats.map((c) => stageSlot(c, enabledCats.length > 1)).join('')}</div>
        </div>
        <div class="bottom-area" data-bottom>${drawBottom(s)}</div>
      </div>
    </div>`;

  // 事件绑定
  bindTopBar(deck);
  $app.querySelectorAll('[data-toggle]').forEach((el) => {
    el.addEventListener('click', () => toggleCategory(el.dataset.toggle));
  });
  $app.querySelectorAll('[data-slot]').forEach((el) => {
    el.addEventListener('click', () => tapCategory(el.dataset.slot));
  });
  bindDrawBottom(s);
}

function stageSlot(cat, multi) {
  const label = multi ? `${cat.labelZh} ${cat.labelEn}` : '';
  return `
    <div class="stage-slot" data-slot="${cat.folder}">
      <div class="pile-wrap">
        ${pileUnderlays(cat.back)}
        <div class="flip-card" data-flip="${cat.folder}">
          <div class="flip-inner">
            <div class="flip-face back"><img src="${cat.back}" alt=""/></div>
            <div class="flip-face front"><img src="" alt=""/></div>
          </div>
        </div>
      </div>
      ${label ? `<div class="slot-label">${label}</div>` : ''}
    </div>`;
}

function pileUnderlays(back) {
  // 被抽走的顶牌下方露出两张错位牌背
  return `
    <div class="pile-underlay u2"><img src="${back}" alt=""/></div>
    <div class="pile-underlay u1"><img src="${back}" alt=""/></div>`;
}

function topBar({ left, titleZh, titleEn, right }) {
  const leftBtn = left === 'menu'
    ? `<button class="icon-btn" data-tb="menu" aria-label="切换卡组">${icon('menu')}</button>`
    : `<button class="icon-btn" data-tb="back" aria-label="返回">${icon('back')}</button>`;
  const rightBtns = (right || []).map((r) => {
    if (r === 'restore') return `<button class="icon-btn" data-tb="restore" aria-label="还原上次结果">${icon('restore')}</button>`;
    if (r === 'home') return `<button class="icon-btn" data-tb="home" aria-label="回到主页面">${icon('home')}</button>`;
    if (r === 'back') return `<button class="icon-btn" data-tb="back" aria-label="返回">${icon('back')}</button>`;
    return '';
  }).join('');
  return `
    <div class="topbar">
      <div>${leftBtn}</div>
      <div class="title"><div class="zh">${titleZh}</div><div class="en">${titleEn}</div></div>
      <div style="display:flex;gap:8px">${rightBtns}</div>
    </div>`;
}

function bindTopBar(deck) {
  const on = (k, fn) => {
    const el = $app.querySelector(`[data-tb="${k}"]`);
    if (el) el.addEventListener('click', fn);
  };
  on('menu', () => openDeckDrawer(deck.id, (d) => { closeDrawer(); openDraw(d.id); }));
  on('restore', () => restoreDraw());
  on('home', () => goHome());
  on('back', () => { state.view = 'home'; state.draw = null; render(); });
}

// ---------- 单卡组：抽卡动作 ----------
function enabledCatsOf(session) {
  return session.deck.categories.filter((c) => session.enabled.has(c.folder));
}

function tapCategory(folder) {
  const s = state.draw;
  if (s.busy) return;
  const cat = categoryOf(s.deck, folder);
  if (!cat) return;
  drawOne(s, cat, false);
}

async function drawOne(s, cat, batch) {
  if (s.busy) return;
  s.busy = true;
  const asset = pick(cat.cards);
  s.drawn[cat.folder] = asset;
  await flipSlot(cat.folder, asset, batch ? 220 : 640);
  s.round.push(drawnCard(s.deck, cat, asset));
  s.busy = false;
  rememberResult();
  refreshDrawBottom();
}

function flipSlot(folder, asset, duration) {
  return new Promise((resolve) => {
    const card = $app.querySelector(`[data-flip="${folder}"]`);
    if (!card) return resolve();
    const inner = card.querySelector('.flip-inner');
    const frontImg = card.querySelector('.flip-face.front img');
    card.classList.toggle('batch', duration < 400);

    const wasFlipped = card.classList.contains('flipped');
    if (wasFlipped) {
      card.classList.remove('flipped');
      inner.style.transition = 'none';
      void inner.offsetWidth;
      inner.style.transition = '';
    }
    // 设置新牌面并翻到正面
    frontImg.src = asset;
    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        card.classList.add('flipped');
        setTimeout(resolve, duration + 60);
      });
    });
  });
}

async function drawAll() {
  const s = state.draw;
  if (s.busy) return;
  const targets = enabledCatsOf(s).filter((c) => !(c.folder in s.drawn));
  if (targets.length === 0) return;
  s.busy = true;
  for (const cat of targets) {
    const count = Math.min(Math.max(s.counts[cat.folder] || 1, 1), 9);
    const picks = shuffle(cat.cards).slice(0, count);
    for (const asset of picks) {
      s.drawn[cat.folder] = asset;
      await flipSlot(cat.folder, asset, 220);
      s.round.push(drawnCard(s.deck, cat, asset));
    }
  }
  s.busy = false;
  rememberResult();
  refreshDrawBottom();
}

function toggleCategory(folder, on) {
  const s = state.draw;
  if (s.busy) return;
  if (on === undefined) on = !s.enabled.has(folder);
  if (on) {
    s.enabled.add(folder);
  } else {
    if (s.enabled.size <= 1) return;
    s.enabled.delete(folder);
  }
  // 重开一轮
  s.drawn = {};
  s.round = [];
  render();
}

function rememberResult() {
  const s = state.draw;
  if (s.round.length === 0) return;
  // 全部已开启的分类都已翻到正面才算一轮完整
  const cats = enabledCatsOf(s);
  if (cats.length === 0) return;
  const allRevealed = cats.every((c) => c.folder in s.drawn);
  if (!allRevealed) return;
  state.lastDraw = { deckId: s.deck.id, cards: s.round.slice() };
}

function restoreDraw() {
  const last = state.lastDraw;
  if (!last) { toast('还没有可以还原的抽卡结果'); return; }
  if (last.deckId === state.draw.deck.id) {
    state.draw = newDrawSession(state.draw.deck, last);
    render();
  } else {
    const deck = getDeck(last.deckId);
    state.draw = newDrawSession(deck, last);
    render();
  }
}

function exitRound() {
  const s = state.draw;
  if (s.busy || s.round.length === 0) return;
  state.result = {
    cards: s.round.slice(),
    eyebrow: s.deck.nameEn,
    backLabel: '返回抽卡界面',
    backView: 'draw',
  };
  state.view = 'result';
  render();
}

// ---------- 单卡组：底部控制区 ----------
function drawBottom(s) {
  const drawn = Object.keys(s.drawn).length > 0;
  const controls = drawn
    ? `<div class="controls single"><button class="pill-btn" data-bottom-action="exit">退出本轮</button></div>`
    : `<div class="controls">
        <div class="dock-selectors">${enabledCatsOf(s).map((c) => countSelector(c)).join('')}</div>
        <button class="pill-btn dock-go" data-bottom-action="drawall">${icon('sparkle')}一键抽出</button>
      </div>`;

  const summary = s.round.length > 0
    ? summaryPanel(s.round, false, '本次汇总')
    : '';

  return `${controls}${summary}`;
}

function countSelector(cat) {
  const v = state.draw.counts[cat.folder] || 1;
  return `
    <div class="count-selector">
      <span class="label">${cat.labelZh}</span>
      <select data-count="${cat.folder}" aria-label="${cat.labelZh} 张数">
        ${[1,2,3,4,5,6,7,8,9].map((n) => `<option value="${n}" ${n === v ? 'selected' : ''}>${n}</option>`).join('')}
      </select>
    </div>`;
}

function bindDrawBottom(s) {
  const area = $app.querySelector('[data-bottom]');
  area.querySelectorAll('[data-count]').forEach((el) => {
    el.addEventListener('change', () => {
      s.counts[el.dataset.count] = Number(el.value);
    });
  });
  area.querySelectorAll('[data-bottom-action]').forEach((el) => {
    const act = el.dataset.bottomAction;
    if (act === 'exit') el.addEventListener('click', exitRound);
    if (act === 'drawall') el.addEventListener('click', drawAll);
  });
}

function refreshDrawBottom() {
  const area = $app.querySelector('[data-bottom]');
  if (!area) return;
  area.innerHTML = drawBottom(state.draw);
  bindDrawBottom(state.draw);
}

function summaryPanel(cards, showDeck, title) {
  const items = cards.map((card, i) => {
    const lines = [];
    if (showDeck && !card.isWholeDeck) lines.push(`<div class="lbl">${card.deckNameZh}</div>`);
    lines.push(`<div class="lbl">${card.isWholeDeck ? card.deckNameZh : card.categoryLabelZh}</div>`);
    return `
      <div class="summary-item">
        <div class="ord">${i + 1}</div>
        <div class="thumb"><img src="${card.asset}" alt="" loading="lazy"/></div>
        ${lines.join('')}
      </div>`;
  }).join('');
  return `
    <div class="summary-panel">
      <div class="summary-head"><span class="t">${title}</span><span class="n">共 ${cards.length} 张</span></div>
      <div class="summary-grid">${items}</div>
    </div>`;
}

// ============================================================
// 混卡抽卡界面
// ============================================================
function openMixed() {
  const deck = state.decks.find((d) => d.id === 'based');
  state.mixed = newDrawSession(deck, null);
  state.view = 'mixed';
  render();
}

function renderMixedScreen() {
  const s = state.mixed;
  const deck = s.deck;
  const decks = sortedDecks();

  const deckBar = `<div class="chip-row" style="padding-top:8px">${decks.map((d) => {
    const locked = !isUnlocked(d.id);
    const on = d.id === deck.id;
    return `
      <div class="qa-chip ${on ? 'on' : ''} ${locked ? 'locked' : ''}" data-mdeck="${d.id}" ${locked ? '' : 'role="button"'} style="flex:none">
        <span class="zh">${d.nameZh}</span>
        <span class="en">${d.nameEn}</span>
        ${locked ? icon('lock', 'lock') : ''}
      </div>`;
  }).join('')}</div>`;

  const hint = Object.keys(s.drawn).length === 0
    ? '单击牌堆进行抽卡\n可切换上方卡组抽取任意牌组'
    : '单击牌面可直接抽出下一张\n结束本轮抽卡后，点击下方按键查看结果汇总';

  $app.innerHTML = `
    <div class="screen">
      <div class="content">
        ${topBar({ left: 'menu', titleZh: MIXED_NAME_ZH, titleEn: MIXED_NAME_EN, right: ['back', 'home'] })}
        ${deckBar}
        <div class="stage">
          <div class="stage-hint" style="padding-top:24px">${escapeHtml(hint)}</div>
          <div class="stage-area" data-stage>${deck.categories.map((c) => stageSlot(c, deck.categories.length > 1)).join('')}</div>
        </div>
        <div class="bottom-area" data-bottom>${mixedBottom(s)}</div>
      </div>
    </div>`;

  // 事件
  const on = (k, fn) => { const el = $app.querySelector(`[data-tb="${k}"]`); if (el) el.addEventListener('click', fn); };
  on('menu', () => openDeckDrawer(deck.id, (d) => { closeDrawer(); switchMixedDeck(d.id); }));
  on('back', () => { state.view = 'home'; state.mixed = null; render(); });
  on('home', () => goHome());

  $app.querySelectorAll('[data-mdeck]').forEach((el) => {
    el.addEventListener('click', () => {
      const id = el.dataset.mdeck;
      if (!isUnlocked(id)) return;
      switchMixedDeck(id);
    });
  });
  $app.querySelectorAll('[data-slot]').forEach((el) => {
    el.addEventListener('click', () => tapMixedCategory(el.dataset.slot));
  });
  bindMixedBottom(s);
}

function switchMixedDeck(deckId) {
  const s = state.mixed;
  if (s.deck.id === deckId) return;
  s.deck = getDeck(deckId);
  s.drawn = {};
  s.enabled = new Set(s.deck.categories.map((c) => c.folder));
  s.round = [];
  render();
}

async function tapMixedCategory(folder) {
  const s = state.mixed;
  if (s.busy) return;
  const cat = categoryOf(s.deck, folder);
  if (!cat) return;
  s.busy = true;
  const asset = pick(cat.cards);
  s.drawn[cat.folder] = asset;
  await flipSlot(cat.folder, asset, 640);
  s.round.push(drawnCard(s.deck, cat, asset));
  s.busy = false;
  refreshMixedBottom();
}

function mixedBottom(s) {
  const enabled = s.round.length > 0;
  const controls = `
    <div class="controls single">
      <button class="pill-btn dock-go" data-bottom-action="finish" ${enabled ? '' : 'disabled'}>${icon('flag')}结束本轮抽卡</button>
    </div>`;
  const summary = s.round.length > 0 ? summaryPanel(s.round, true, '本次汇总') : '';
  return `${controls}${summary}`;
}

function bindMixedBottom(s) {
  const area = $app.querySelector('[data-bottom]');
  area.querySelectorAll('[data-bottom-action]').forEach((el) => {
    if (el.dataset.bottomAction === 'finish') el.addEventListener('click', finishMixedRound);
  });
}

function refreshMixedBottom() {
  const area = $app.querySelector('[data-bottom]');
  if (!area) return;
  area.innerHTML = mixedBottom(state.mixed);
  bindMixedBottom(state.mixed);
}

function finishMixedRound() {
  const s = state.mixed;
  if (s.round.length === 0) return;
  state.result = {
    cards: s.round.slice(),
    eyebrow: MIXED_NAME_EN,
    backLabel: '返回多组同抽界面',
    backView: 'mixed',
  };
  state.view = 'result';
  render();
}

// ============================================================
// 本轮结果
// ============================================================
function renderResult() {
  const { cards, eyebrow, backLabel, backView } = state.result;
  const cols = columnsFor();

  const cells = cards.map((card, i) => `
    <div class="result-cell">
      <div class="ord">${i + 1}</div>
      <div class="img"><img src="${card.asset}" alt="" loading="lazy"/></div>
      <div class="deck">${card.deckNameZh}</div>
      ${card.isWholeDeck ? '' : `<div class="cat">${card.categoryLabelZh}</div>`}
    </div>`).join('');

  $app.innerHTML = `
    <div class="screen">
      <div class="content">
        <div class="result-header">
          <div class="eyebrow">${eyebrow}</div>
          <div class="big">本轮结果</div>
          <div class="en">ROUND RESULTS</div>
        </div>
        <div class="scroll" style="flex:1">
          <div class="result-grid cols-${cols}" style="grid-template-columns:repeat(${cols},1fr)">
            ${cells}
          </div>
        </div>
        <div class="result-actions">
          <button class="pill-btn" data-result="back">${icon('back')}${backLabel}</button>
          <button class="pill-btn ghost" data-result="home">${icon('home')}返回主菜单</button>
        </div>
      </div>
    </div>`;

  $app.querySelector('[data-result="back"]').addEventListener('click', () => {
    // 返回后开始新一轮：清空本轮牌面，保留卡组与分类开关
    if (backView === 'draw' && state.draw) {
      state.draw.drawn = {};
      state.draw.round = [];
    } else if (backView === 'mixed' && state.mixed) {
      state.mixed.drawn = {};
      state.mixed.round = [];
    }
    state.view = backView;
    render();
  });
  $app.querySelector('[data-result="home"]').addEventListener('click', goHome);
}

// ============================================================
// 卡组侧栏（抽屉）
// ============================================================
function openDeckDrawer(currentId, onSelect) {
  const decks = sortedDecks();
  const html = `
    <div class="drawer-head">
      <div class="eyebrow">DECKS</div>
      <div class="title">切换卡组</div>
    </div>
    <div class="drawer-divider"></div>
    ${decks.map((d) => {
      const locked = !isUnlocked(d.id);
      return `
        <div class="drawer-item ${d.id === currentId ? 'active' : ''} ${locked ? 'locked' : ''}" data-ddeck="${d.id}" ${locked ? '' : 'role="button"'}>
          <div class="bar"></div>
          <div class="txt">
            <div class="zh">${d.nameZh}</div>
            <div class="en">${d.nameEn}</div>
          </div>
          ${locked ? icon('lock', 'lock') : ''}
        </div>`;
    }).join('')}`;
  openDrawer('left', html);
  drawerEl.querySelectorAll('[data-ddeck]').forEach((el) => {
    el.addEventListener('click', () => {
      const id = el.dataset.ddeck;
      if (!isUnlocked(id)) return;
      const deck = getDeck(id);
      onSelect(deck);
    });
  });
}

// ============================================================
// 个人主页（抽屉）
// ============================================================
function openProfileDrawer() {
  const loggedIn = !!state.user;
  const entries = homeEntries();

  const header = `
    <div class="profile-head">
      <div class="profile-row">
        <div class="avatar">${icon(loggedIn ? 'person' : 'personOutline', '')}</div>
        <div class="profile-meta">
          <div class="name">${displayName()}</div>
          ${loggedIn ? `<div class="email">${state.user.email}</div>` : ''}
        </div>
      </div>
      <div class="profile-actions">
        ${loggedIn
          ? `<button class="pill-btn block" data-p="redeem">输入兑换码</button>
             <button class="pill-btn ghost block" data-p="signout">退出登录</button>`
          : `<button class="pill-btn block" data-p="login">登录 / 注册</button>`}
      </div>
    </div>
    <div class="drawer-divider"></div>
    <div class="unlock-title">解锁进度</div>
    <div class="unlock-list">
      ${entries.map((e) => {
        const unlocked = isUnlocked(e.id);
        return `
          <div class="unlock-item ${unlocked ? '' : 'locked'}">
            ${unlockThumb(e, unlocked)}
            <div class="meta">
              <div class="zh">${e.nameZh}</div>
              <div class="en">${e.nameEn}</div>
            </div>
            <div class="status">${icon(unlocked ? 'checkCircle' : 'lock')}</div>
          </div>`;
      }).join('')}
    </div>`;

  openDrawer('right', header);

  const act = (k, fn) => { const el = drawerEl.querySelector(`[data-p="${k}"]`); if (el) el.addEventListener('click', fn); };
  act('login', () => { closeDrawer(); openAuth(); });
  act('signout', async () => {
    try { await signOut(); } catch (_) {}
    closeDrawer();
    render();
  });
  act('redeem', () => { closeDrawer(); openRedeemModal(); });
}

function unlockThumb(entry, unlocked) {
  if (entry.isMixed) {
    return `<div class="thumb mixed-thumb">${icon('sparkle', '')}</div>`;
  }
  const back = thumbnailCategory(entry.deck).back;
  return `<div class="thumb ${unlocked ? '' : 'gray'}"><img src="${back}" alt=""/></div>`;
}

function openRedeemModal() {
  openModal(`
    <div class="m-title">输入兑换码</div>
    <div class="m-body">
      <input id="redeem-input" placeholder="请输入兑换码" autocomplete="off"/>
      <div class="m-error" id="redeem-error"></div>
    </div>
    <div class="m-actions">
      <button class="text-btn" data-modal="cancel">取消</button>
      <button class="text-btn" data-modal="ok">兑换</button>
    </div>`);
  const input = modalEl.querySelector('#redeem-input');
  const err = modalEl.querySelector('#redeem-error');
  input.focus();

  modalEl.querySelector('[data-modal="cancel"]').addEventListener('click', closeModal);
  modalEl.querySelector('[data-modal="ok"]').addEventListener('click', async () => {
    const code = input.value.trim();
    if (!code) return;
    const btn = modalEl.querySelector('[data-modal="ok"]');
    btn.disabled = true; btn.textContent = '兑换中…';
    try {
      await redeemCode(code);
      closeModal();
      toast('兑换成功，卡组已解锁');
      render();
    } catch (e) {
      err.textContent = e.message || '兑换失败，请稍后重试';
      btn.disabled = false; btn.textContent = '兑换';
    }
  });
}

// ============================================================
// 登录 / 注册
// ============================================================
function openAuth() {
  state.view = 'auth';
  render();
}

function renderAuth() {
  const register = state.authRegister || false;
  $app.innerHTML = `
    <div class="screen">
      <div class="content">
        <div class="topbar">
          <div><button class="icon-btn" data-auth="back" aria-label="返回">${icon('back')}</button></div>
          <div class="title"></div>
          <div style="width:38px"></div>
        </div>
        <div class="auth-wrap">
          <div class="auth-card">
            <div class="big">${register ? '注册账号' : '登录账号'}</div>
            <div class="en">${register ? 'SIGN UP' : 'SIGN IN'}</div>
            <div class="field">
              <div class="f-label">邮箱</div>
              <div class="f-input-wrap">
                ${icon('mail', 'f-icon')}
                <input id="auth-email" class="with-icon" type="email" placeholder="you@example.com" autocomplete="email"/>
              </div>
              <div class="f-error" id="err-email"></div>
            </div>
            <div class="field">
              <div class="f-label">密码</div>
              <div class="f-input-wrap">
                ${icon('lock', 'f-icon')}
                <input id="auth-password" class="with-icon" type="password" placeholder="请设置密码（至少 6 位）" autocomplete="${register ? 'new-password' : 'current-password'}"/>
                <button class="f-toggle" data-auth="toggle" type="button" aria-label="显示/隐藏密码">${icon('eye')}</button>
              </div>
              <div class="f-error" id="err-password"></div>
            </div>
            <div style="margin-top:28px">
              <button class="pill-btn block" data-auth="submit">${register ? '注册' : '登录'}</button>
            </div>
            <div class="auth-switch">
              <button data-auth="switch">${register ? '已有账号？去登录' : '没有账号？去注册'}</button>
            </div>
          </div>
        </div>
      </div>
    </div>`;

  const emailEl = $app.querySelector('#auth-email');
  const passEl = $app.querySelector('#auth-password');

  $app.querySelector('[data-auth="back"]').addEventListener('click', () => { state.view = 'home'; render(); });
  $app.querySelector('[data-auth="toggle"]').addEventListener('click', () => {
    passEl.type = passEl.type === 'password' ? 'text' : 'password';
  });
  $app.querySelector('[data-auth="switch"]').addEventListener('click', () => {
    state.authRegister = !register;
    renderAuth();
  });
  $app.querySelector('[data-auth="submit"]').addEventListener('click', () => submitAuth(emailEl, passEl, register));
  passEl.addEventListener('keydown', (e) => { if (e.key === 'Enter') submitAuth(emailEl, passEl, register); });

  const restore = state.authDraft || { email: '', password: '' };
  emailEl.value = restore.email;
  passEl.value = restore.password;
}

function validateEmail(v) {
  return v && v.includes('@') && v.includes('.');
}

async function submitAuth(emailEl, passEl, register) {
  const email = emailEl.value.trim();
  const password = passEl.value;
  const errEmail = $app.querySelector('#err-email');
  const errPass = $app.querySelector('#err-password');
  errEmail.textContent = '';
  errPass.textContent = '';

  if (!email) { errEmail.textContent = '请输入邮箱'; return; }
  if (!validateEmail(email)) { errEmail.textContent = '邮箱格式不正确'; return; }
  if (!password) { errPass.textContent = '请输入密码'; return; }
  if (password.length < 6) { errPass.textContent = '密码需至少 6 位'; return; }

  state.authDraft = { email, password };

  const btn = $app.querySelector('[data-auth="submit"]');
  btn.disabled = true;
  btn.textContent = register ? '注册中…' : '登录中…';
  try {
    if (register) {
      const autoLogin = await signUp(email, password);
      if (!autoLogin) {
        toast('注册成功，请查收邮件确认后再登录');
        state.authRegister = false;
        state.authDraft = null;
        renderAuth();
        return;
      }
      toast('注册成功，已自动登录');
    } else {
      await signIn(email, password);
      toast('登录成功');
    }
    state.authDraft = null;
    state.authRegister = false;
    state.view = 'home';
    render();
  } catch (e) {
    toast(friendlyAuthError(e.message || e.toString()));
    btn.disabled = false;
    btn.textContent = register ? '注册' : '登录';
  }
}

// ============================================================
// 导航
// ============================================================
function goHome() {
  state.view = 'home';
  state.draw = null;
  state.mixed = null;
  render();
}

function escapeHtml(s) {
  return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

// ============================================================
// 启动
// ============================================================
async function boot() {
  // 初始化 Supabase（CDN 未加载时降级为未登录，仅基础卡可用）
  try {
    if (window.supabase && window.supabase.createClient) {
      supabaseClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_KEY);
      const { data } = await supabaseClient.auth.getSession();
      state.user = data.session ? data.session.user : null;
      if (state.user) await loadUnlocks();
    }
  } catch (_) {
    supabaseClient = null;
    state.user = null;
  }

  // 加载卡牌清单
  try {
    const res = await fetch('cards.json');
    const manifest = await res.json();
    state.decks = manifest.decks;
  } catch (e) {
    $app.innerHTML = `<div class="boot"><div class="boot-logo">OH CARDS</div><div class="boot-sub">卡牌清单加载失败：${escapeHtml(e.message)}</div></div>`;
    return;
  }

  state.quickIndex = 0;
  render();
}

document.addEventListener('DOMContentLoaded', boot);
