import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 默认免费解锁的卡组：基础卡。
const String kDefaultUnlockedDeckId = 'based';

/// 混卡入口的固定 id（与 CardLibrary.homeEntries 中的 'mixed' 保持一致）。
const String kMixedDeckId = 'mixed';

/// 兑换码兑换失败时抛出的异常，message 为可直接展示给用户的中文。
class RedeemException implements Exception {
  const RedeemException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 账号与解锁进度状态：负责登录 / 注册 / 退出，以及各卡组解锁进度的读写。
///
/// 解锁进度存放在 Supabase 的 `deck_unlocks` 表（user_id + deck_id），
/// 未登录时只有基础卡可用；登录后按账号读取。
class AccountStore extends ChangeNotifier {
  AccountStore._();

  static final AccountStore instance = AccountStore._();

  final SupabaseClient _client = Supabase.instance.client;

  User? _user;
  Set<String> _unlocked = {};
  bool _loaded = false;

  /// 当前登录用户；null 表示未登录
  User? get user => _user;

  bool get isLoggedIn => _user != null;

  /// 展示名称：取邮箱 @ 前的部分，兜底用「未登录」
  String get displayName {
    final email = _user?.email;
    if (email == null || email.isEmpty) return '未登录';
    final at = email.indexOf('@');
    return at > 0 ? email.substring(0, at) : email;
  }

  String get displayEmail => _user?.email ?? '';

  /// 某卡组是否已解锁。基础卡始终免费解锁。
  bool isUnlocked(String deckId) {
    if (deckId == kDefaultUnlockedDeckId || deckId == kMixedDeckId) return true;
    return _unlocked.contains(deckId);
  }

  /// 按解锁状态稳定排序：已解锁在前、未解锁在后，同组内保持原顺序。
  ///
  /// 用于主界面快速抵达、牌组缩略图、个人主页解锁进度、抽卡页切换卡组侧栏。
  List<T> sortUnlockedFirst<T>(List<T> items, String Function(T) idOf) {
    final unlocked = <T>[];
    final locked = <T>[];
    for (final item in items) {
      (isUnlocked(idOf(item)) ? unlocked : locked).add(item);
    }
    return [...unlocked, ...locked];
  }

  /// 启动时初始化：恢复会话并读取解锁进度
  Future<void> init() async {
    _user = _client.auth.currentUser;
    if (_user != null) {
      await _loadUnlocks();
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _loadUnlocks() async {
    final uid = _user?.id;
    if (uid == null) return;
    try {
      final rows = await _client
          .from('deck_unlocks')
          .select('deck_id')
          .eq('user_id', uid);
      _unlocked = rows.map<String>((r) => r['deck_id'] as String).toSet();
    } catch (_) {
      // 表尚未建立等情况：保持空集合，只有基础卡解锁
      _unlocked = {};
    }
  }

  /// 注册账号。
  ///
  /// 返回 true 表示注册后已自动登录（邮箱确认关闭时）；
  /// 返回 false 表示需要先查收邮件完成邮箱确认再登录。
  Future<bool> signUp(String email, String password) async {
    final res = await _client.auth.signUp(email: email, password: password);
    final session = res.session;
    if (session != null) {
      _user = res.user;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> signIn(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
    _user = _client.auth.currentUser;
    await _loadUnlocks();
    notifyListeners();
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    _user = null;
    _unlocked = {};
    notifyListeners();
  }

  /// 解锁某个卡组的落库动作（本地先解锁，再写入 Supabase 兜底）。
  Future<void> unlockDeck(String deckId) async {
    final uid = _user?.id;
    if (uid == null) return;
    _unlocked.add(deckId);
    notifyListeners();
    try {
      await _client.from('deck_unlocks').upsert({
        'user_id': uid,
        'deck_id': deckId,
      });
    } catch (_) {
      // 写库失败不阻断本地体验；下次登录会重新对齐
    }
  }

  /// 兑换码兑换：调用 Supabase RPC `redeem_code`，成功后本地解锁对应卡组。
  ///
  /// 成功返回解锁的卡组 id；失败抛出 [RedeemException]。
  Future<String> redeemCode(String code) async {
    if (_user == null) {
      throw const RedeemException('请先登录账号');
    }
    try {
      final deckId = await _client.rpc(
        'redeem_code',
        params: {'p_code': code.trim()},
      ) as String?;
      if (deckId == null || deckId.isEmpty) {
        throw const RedeemException('兑换码无效或已被使用');
      }
      if (deckId == 'all') {
        // 服务端已写入全部卡组，重新拉取一次对齐
        await _loadUnlocks();
      } else {
        _unlocked.add(deckId);
      }
      notifyListeners();
      return deckId;
    } on RedeemException {
      rethrow;
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('not_logged_in')) {
        throw const RedeemException('请先登录账号');
      }
      if (msg.contains('invalid_code')) {
        throw const RedeemException('兑换码无效或已被使用');
      }
      final detail = e is PostgrestException ? e.message : e.toString();
      throw RedeemException('兑换失败：$detail');
    }
  }

  bool get isLoaded => _loaded;
}
