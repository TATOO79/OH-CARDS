/// 抽出的单张卡：自带卡组与子卡组信息，便于在汇总框、本轮结果里独立展示。
class DrawnCard {
  const DrawnCard({
    required this.deckId,
    required this.deckNameZh,
    required this.deckNameEn,
    required this.categoryId,
    required this.categoryLabelZh,
    required this.categoryLabelEn,
    required this.asset,
  });

  final String deckId;
  final String deckNameZh;
  final String deckNameEn;
  final String categoryId;
  final String categoryLabelZh;
  final String categoryLabelEn;
  final String asset;

  /// 「基础卡（字卡）」形式的中文标注
  String get labelZh => '$deckNameZh（$categoryLabelZh）';

  /// 「OH CARDS (WORD)」形式的英文标注
  String get labelEn => '$deckNameEn ($categoryLabelEn)';

  /// 卡组没有子卡组（克服卡、抽象卡 …）：标注只有卡组名一行
  bool get isWholeDeck => categoryLabelZh == deckNameZh;
}

class DrawRecord {
  const DrawRecord({required this.deckId, required this.cards});

  final String deckId;
  final List<DrawnCard> cards;
}

/// 只保留「最近一次」抽卡结果，用于右上角的还原按钮。不做持久化，也不留历史记录。
class DrawHistory {
  DrawHistory._();

  static final DrawHistory instance = DrawHistory._();

  DrawRecord? last;
}
