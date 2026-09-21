// 扫描 assets/cards 目录，生成与 lib/data/card_library.dart 完全一致的卡牌清单 cards.json。
// 运行：node tools/gen-cards-json.mjs
import { readdirSync, writeFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const cardsDir = join(root, 'assets', 'cards');

// 与 card_library.dart 中的 kDeckDefs 保持一致
const deckDefs = [
  { id: 'based', nameZh: '基础卡', nameEn: 'OH CARDS', thumbnailFolder: 'pic', categories: [
    { folder: 'pic', labelZh: '图卡', labelEn: 'PICTURE', defaultOn: true },
    { folder: 'word', labelZh: '字卡', labelEn: 'WORD', defaultOn: false },
  ]},
  { id: 'resilio', nameZh: '复原卡', nameEn: 'RESILIO', thumbnailFolder: 'pressure', categories: [
    { folder: 'pressure', labelZh: '压力卡', labelEn: 'STRESS', defaultOn: true },
    { folder: 'animal', labelZh: '动物卡', labelEn: 'ANIMAL', defaultOn: false },
  ]},
  { id: 'cope', nameZh: '克服卡', nameEn: 'COPE', categories: [] },
  { id: 'tandoo', nameZh: '天度伴侣卡', nameEn: 'TANDOO', thumbnailFolder: 'pic', categories: [
    { folder: 'pic', labelZh: '图卡', labelEn: 'PICTURE', defaultOn: true },
    { folder: 'sign', labelZh: '互动卡', labelEn: 'INTERACTION', defaultOn: false },
  ]},
  { id: 'personita', nameZh: '孩童卡', nameEn: 'PERSONITA', thumbnailFolder: 'peo', categories: [
    { folder: 'peo', labelZh: '人物卡', labelEn: 'PEOPLE', defaultOn: true },
    { folder: 'situ', labelZh: '情况卡', labelEn: 'SITUATION', defaultOn: false },
  ]},
  { id: 'persona', nameZh: '成人卡', nameEn: 'PERSONA', thumbnailFolder: 'peo', categories: [
    { folder: 'peo', labelZh: '人物卡', labelEn: 'PEOPLE', defaultOn: true },
    { folder: 'int', labelZh: '互动卡', labelEn: 'INTERACTION', defaultOn: false },
  ]},
  { id: 'inuk', nameZh: '因纽特卡', nameEn: 'INUK', categories: [] },
  { id: 'ecco', nameZh: '抽象卡', nameEn: 'ECCO', categories: [] },
  { id: 'saga', nameZh: '英雄卡', nameEn: 'SAGA', categories: [] },
  { id: 'shenhua', nameZh: '东方神话卡', nameEn: 'SHEN HUA', categories: [] },
  { id: 'mythos', nameZh: '西方神话卡', nameEn: 'MYTHOS', categories: [] },
];

function listFiles(dir) {
  const out = [];
  for (const name of readdirSync(dir, { withFileTypes: true })) {
    const full = join(dir, name.name);
    if (name.isDirectory()) out.push(...listFiles(full));
    else out.push(full);
  }
  return out;
}

function basename(fileName) {
  const dot = fileName.lastIndexOf('.');
  return dot < 0 ? fileName : fileName.slice(0, dot);
}

function isBack(fileName) {
  return basename(fileName).toLowerCase() === 'back';
}

function cardKey(fileName) {
  const m = /^(\d+)(?:-(\d+))?$/.exec(basename(fileName));
  if (!m) return null;
  return [parseInt(m[1], 10), m[2] ? parseInt(m[2], 10) : 0];
}

function compare(a, b) {
  const ka = cardKey(a);
  const kb = cardKey(b);
  if (ka == null && kb == null) return a < b ? -1 : a > b ? 1 : 0;
  if (ka == null) return 1;
  if (kb == null) return -1;
  return ka[0] - kb[0] || ka[1] - kb[1];
}

function buildCategories(def) {
  const prefix = `assets/cards/${def.id}/`;
  const grouped = {};
  for (const file of listFiles(join(cardsDir, def.id))) {
    const rel = file.replace(/\\/g, '/').slice((join(cardsDir, def.id) + '/').replace(/\\/g, '/').length);
    const slash = rel.indexOf('/');
    if (slash < 0) (grouped[''] ||= []).push(rel);
    else (grouped[rel.slice(0, slash)] ||= []).push(rel.slice(slash + 1));
  }

  const backIn = (folder) => {
    const files = grouped[folder];
    if (!files) return null;
    for (const f of files) if (isBack(f)) return `${prefix}${folder ? folder + '/' : ''}${f}`;
    return null;
  };

  const defs = def.categories.length > 0
    ? def.categories
    : [{ folder: '', labelZh: def.nameZh, labelEn: def.nameEn, defaultOn: true }];

  const fallbackOrder = [...defs.map((d) => d.folder), ...(def.thumbnailFolder ? [def.thumbnailFolder] : [])];

  const categories = [];
  for (const d of defs) {
    const files = grouped[d.folder];
    if (!files || files.length === 0) continue;
    const cards = files.filter((f) => !isBack(f)).sort(compare);
    if (cards.length === 0) continue;
    let back = null;
    for (const folder of fallbackOrder) {
      back = backIn(folder);
      if (back) break;
    }
    if (!back) continue;
    categories.push({
      folder: d.folder,
      labelZh: d.labelZh,
      labelEn: d.labelEn,
      defaultOn: d.defaultOn,
      back,
      cards: cards.map((f) => `${prefix}${d.folder ? d.folder + '/' : ''}${f}`),
    });
  }
  return categories;
}

const decks = deckDefs.map((def) => ({
  id: def.id,
  nameZh: def.nameZh,
  nameEn: def.nameEn,
  thumbnailFolder: def.thumbnailFolder ?? null,
  categories: buildCategories(def),
}));

const manifest = { decks };
writeFileSync(join(root, 'cards.json'), JSON.stringify(manifest, null, 2));
const total = decks.reduce((n, d) => n + d.categories.reduce((m, c) => m + c.cards.length, 0), 0);
console.log(`cards.json generated: ${decks.length} decks, ${total} card faces`);
