import 'package:flutter/services.dart' show AssetManifest, rootBundle;

/// 一组卡牌内部的分类定义（对应卡组文件夹下的子文件夹）。
class DeckCategoryDef {
  const DeckCategoryDef({
    required this.folder,
    required this.labelZh,
    required this.labelEn,
    this.defaultOn = false,
  });

  final String folder;
  final String labelZh;
  final String labelEn;

  /// 进入抽卡界面时默认是否开启
  final bool defaultOn;
}

class DeckDef {
  const DeckDef({
    required this.id,
    required this.nameZh,
    required this.nameEn,
    this.categories = const [],
    this.thumbnailFolder,
  });

  final String id;
  final String nameZh;
  final String nameEn;

  /// 为空表示该卡组没有分类，整个文件夹即一组牌
  final List<DeckCategoryDef> categories;

  /// 主界面缩略图取哪个子文件夹的卡背（多分类卡组默认取 pic / peo）
  final String? thumbnailFolder;

  String get assetDir => 'assets/cards/$id';
}

/// 混卡入口（跨全部牌组抽取），仅用于主界面与抽卡界面的标示。
const String kMixedNameZh = '多组同抽';
const String kMixedNameEn = 'MIXED';

/// 主界面入口：可能是一个真实卡组，也可能是「混卡」这一特殊入口。
///
/// 用于统一主界面「快速抵达」与下方缩略图的顺序，以及个人主页里的解锁进度。
class HomeEntry {
  const HomeEntry({
    required this.id,
    required this.nameZh,
    required this.nameEn,
    this.deck,
  });

  final String id;
  final String nameZh;
  final String nameEn;

  /// 混卡入口没有对应的真实卡组，为 null
  final Deck? deck;

  bool get isMixed => deck == null;
}

/// 十一组卡牌（顺序即主界面展示顺序）。
///
/// 英文名与子卡组名对照 OH 卡官方资料（oh-cards.com），
/// 子卡组一律使用完整单词而非缩写。
const List<DeckDef> kDeckDefs = [
  DeckDef(
    id: 'based',
    nameZh: '基础卡',
    nameEn: 'OH CARDS',
    thumbnailFolder: 'pic',
    categories: [
      DeckCategoryDef(folder: 'pic', labelZh: '图卡', labelEn: 'PICTURE', defaultOn: true),
      DeckCategoryDef(folder: 'word', labelZh: '字卡', labelEn: 'WORD'),
    ],
  ),
  DeckDef(
    id: 'resilio',
    nameZh: '复原卡',
    nameEn: 'RESILIO',
    thumbnailFolder: 'pressure',
    categories: [
      DeckCategoryDef(folder: 'pressure', labelZh: '压力卡', labelEn: 'STRESS', defaultOn: true),
      DeckCategoryDef(folder: 'animal', labelZh: '动物卡', labelEn: 'ANIMAL'),
    ],
  ),
  DeckDef(id: 'cope', nameZh: '克服卡', nameEn: 'COPE'),
  DeckDef(
    id: 'tandoo',
    nameZh: '天度伴侣卡',
    nameEn: 'TANDOO',
    thumbnailFolder: 'pic',
    categories: [
      DeckCategoryDef(folder: 'pic', labelZh: '图卡', labelEn: 'PICTURE', defaultOn: true),
      DeckCategoryDef(folder: 'sign', labelZh: '互动卡', labelEn: 'INTERACTION'),
    ],
  ),
  DeckDef(
    id: 'personita',
    nameZh: '孩童卡',
    nameEn: 'PERSONITA',
    thumbnailFolder: 'peo',
    categories: [
      DeckCategoryDef(folder: 'peo', labelZh: '人物卡', labelEn: 'PEOPLE', defaultOn: true),
      DeckCategoryDef(folder: 'situ', labelZh: '情况卡', labelEn: 'SITUATION'),
    ],
  ),
  DeckDef(
    id: 'persona',
    nameZh: '成人卡',
    nameEn: 'PERSONA',
    thumbnailFolder: 'peo',
    categories: [
      DeckCategoryDef(folder: 'peo', labelZh: '人物卡', labelEn: 'PEOPLE', defaultOn: true),
      DeckCategoryDef(folder: 'int', labelZh: '互动卡', labelEn: 'INTERACTION'),
    ],
  ),
  DeckDef(id: 'inuk', nameZh: '因纽特卡', nameEn: 'INUK'),
  DeckDef(id: 'ecco', nameZh: '抽象卡', nameEn: 'ECCO'),
  DeckDef(id: 'saga', nameZh: '英雄卡', nameEn: 'SAGA'),
  DeckDef(id: 'shenhua', nameZh: '东方神话卡', nameEn: 'SHEN HUA'),
  DeckDef(id: 'mythos', nameZh: '西方神话卡', nameEn: 'MYTHOS'),
];

/// 运行时可用的一个分类（含卡背与全部卡面）
class CardCategory {
  const CardCategory({
    required this.id,
    required this.labelZh,
    required this.labelEn,
    required this.defaultOn,
    required this.backAsset,
    required this.cards,
  });

  final String id;
  final String labelZh;
  final String labelEn;
  final bool defaultOn;
  final String backAsset;
  final List<String> cards;
}

class Deck {
  const Deck({required this.def, required this.categories});

  final DeckDef def;
  final List<CardCategory> categories;

  /// 是否需要展示分类开关
  bool get hasChoices => categories.length > 1;

  /// 主界面缩略图使用的卡背
  CardCategory get thumbnailCategory {
    final wanted = def.thumbnailFolder;
    if (wanted != null) {
      for (final c in categories) {
        if (c.id == wanted) return c;
      }
    }
    for (final c in categories) {
      if (c.defaultOn) return c;
    }
    return categories.first;
  }
}

/// 卡牌库：启动时从打包资源清单里扫描各卡组的卡面与卡背。
class CardLibrary {
  CardLibrary._(this.decks);

  final List<Deck> decks;

  static CardLibrary? _instance;

  static CardLibrary get instance {
    final lib = _instance;
    if (lib == null) {
      throw StateError('CardLibrary 尚未加载，请先 await CardLibrary.load()');
    }
    return lib;
  }

  static Future<CardLibrary> load() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final all = manifest
        .listAssets()
        .where((a) => a.startsWith('assets/cards/'))
        .toList(growable: false);

    final decks = <Deck>[];
    for (final def in kDeckDefs) {
      decks.add(Deck(def: def, categories: _buildCategories(def, all)));
    }

    final lib = CardLibrary._(List.unmodifiable(decks));
    _instance = lib;
    return lib;
  }

  static Deck byId(String id) => instance.decks.firstWhere((d) => d.def.id == id);

  /// 主界面入口顺序：基础卡 → 混卡 → 其余卡组（按原顺序）。
  ///
  /// 「快速抵达」与下方缩略图共用这份顺序，个人主页的解锁进度也用它。
  List<HomeEntry> get homeEntries {
    final decks = this.decks;
    final based = decks.firstWhere((d) => d.def.id == 'based');
    return [
      HomeEntry(id: based.def.id, nameZh: based.def.nameZh, nameEn: based.def.nameEn, deck: based),
      const HomeEntry(id: 'mixed', nameZh: kMixedNameZh, nameEn: kMixedNameEn),
      for (final d in decks.where((d) => d.def.id != 'based'))
        HomeEntry(id: d.def.id, nameZh: d.def.nameZh, nameEn: d.def.nameEn, deck: d),
    ];
  }

  static List<CardCategory> _buildCategories(DeckDef def, List<String> all) {
    final prefix = '${def.assetDir}/';

    // 子文件夹 -> 该文件夹内的文件名
    final grouped = <String, List<String>>{};
    for (final path in all) {
      if (!path.startsWith(prefix)) continue;
      final rel = path.substring(prefix.length);
      final slash = rel.indexOf('/');
      if (slash < 0) {
        grouped.putIfAbsent('', () => []).add(rel);
      } else {
        grouped.putIfAbsent(rel.substring(0, slash), () => []).add(rel.substring(slash + 1));
      }
    }

    String? backIn(String folder) {
      final files = grouped[folder];
      if (files == null) return null;
      for (final f in files) {
        if (_isBackFile(f)) {
          return '$prefix${folder.isEmpty ? '' : '$folder/'}$f';
        }
      }
      return null;
    }

    // 没有子分类的卡组（克服卡、抽象卡 …）本身即一整组牌，
    // 标注直接用它自己的名字，而不是笼统的「全部卡牌」。
    final defs = def.categories.isNotEmpty
        ? def.categories
        : [
            DeckCategoryDef(
              folder: '',
              labelZh: def.nameZh,
              labelEn: def.nameEn,
              defaultOn: true,
            ),
          ];

    // 卡背兜底顺序：自身 -> 卡组指定缩略图分类 -> 其它分类
    final fallbackOrder = <String>[
      ...defs.map((d) => d.folder),
      if (def.thumbnailFolder != null) def.thumbnailFolder!,
    ];

    final categories = <CardCategory>[];
    for (final d in defs) {
      final files = grouped[d.folder];
      if (files == null || files.isEmpty) continue;

      final cards = files.where((f) => !_isBackFile(f)).toList()..sort(_compareCardName);
      if (cards.isEmpty) continue;

      String? back;
      for (final folder in fallbackOrder) {
        back = backIn(folder);
        if (back != null) break;
      }
      if (back == null) continue;

      categories.add(CardCategory(
        id: d.folder,
        labelZh: d.labelZh,
        labelEn: d.labelEn,
        defaultOn: d.defaultOn,
        backAsset: back,
        cards: [
          for (final f in cards) '$prefix${d.folder.isEmpty ? '' : '${d.folder}/'}$f',
        ],
      ));
    }

    return List.unmodifiable(categories);
  }

  static bool _isBackFile(String fileName) => _baseName(fileName).toLowerCase() == 'back';

  static String _baseName(String fileName) {
    final dot = fileName.lastIndexOf('.');
    return dot < 0 ? fileName : fileName.substring(0, dot);
  }

  /// 按「主序号 + 副序号」自然排序：1, 2, ... 88, 89-1, 89-2, ...
  static int _compareCardName(String a, String b) {
    final ka = _cardKey(a);
    final kb = _cardKey(b);
    if (ka == null && kb == null) return a.compareTo(b);
    if (ka == null) return 1;
    if (kb == null) return -1;
    final main = ka.$1.compareTo(kb.$1);
    return main != 0 ? main : ka.$2.compareTo(kb.$2);
  }

  static (int, int)? _cardKey(String fileName) {
    final m = RegExp(r'^(\d+)(?:-(\d+))?$').firstMatch(_baseName(fileName));
    if (m == null) return null;
    final sub = m.group(2);
    return (int.parse(m.group(1)!), sub == null ? 0 : int.parse(sub));
  }
}
