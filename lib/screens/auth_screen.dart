import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/account_store.dart';
import '../theme/app_theme.dart';
import '../widgets/app_controls.dart';
import '../widgets/parchment_background.dart';

/// 登录 / 注册界面：邮箱 + 自行设置密码。
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _register = false;
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _busy = true);
    final email = _email.text.trim();
    final password = _password.text;

    try {
      if (_register) {
        final autoLogin = await AccountStore.instance.signUp(email, password);
        if (!mounted) return;
        if (!autoLogin) {
          _showMessage('注册成功，请查收邮件确认后再登录');
          return;
        }
        _showMessage('注册成功，已自动登录');
      } else {
        await AccountStore.instance.signIn(email, password);
        if (!mounted) return;
        _showMessage('登录成功');
      }
      Navigator.of(context).pop();
    } on AuthException catch (e) {
      if (!mounted) return;
      _showMessage(_friendlyAuthError(e.message));
    } catch (_) {
      if (!mounted) return;
      _showMessage('操作失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _friendlyAuthError(String raw) {
    final s = raw.toLowerCase();
    if (s.contains('already registered') || s.contains('already exists')) {
      return '该邮箱已注册，请直接登录';
    }
    if (s.contains('invalid login credentials') || s.contains('invalid email or password')) {
      return '邮箱或密码错误';
    }
    if (s.contains('password')) return '密码需至少 6 位';
    if (s.contains('email')) return '邮箱格式不正确';
    return '操作失败：$raw';
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ParchmentBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _register ? '注册账号' : '登录账号',
                        textAlign: TextAlign.center,
                        style: AppText.displaySm,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _register ? 'SIGN UP' : 'SIGN IN',
                        textAlign: TextAlign.center,
                        style: AppText.eyebrow.copyWith(color: AppColors.wood, fontSize: 10),
                      ),
                      const SizedBox(height: 28),
                      _buildField(
                        controller: _email,
                        label: '邮箱',
                        hint: 'you@example.com',
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          final s = (v ?? '').trim();
                          if (s.isEmpty) return '请输入邮箱';
                          if (!s.contains('@') || !s.contains('.')) return '邮箱格式不正确';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        controller: _password,
                        label: '密码',
                        hint: '请设置密码（至少 6 位）',
                        icon: Icons.lock_outline_rounded,
                        obscure: _obscure,
                        onToggleObscure: () => setState(() => _obscure = !_obscure),
                        validator: (v) {
                          final s = v ?? '';
                          if (s.isEmpty) return '请输入密码';
                          if (s.length < 6) return '密码需至少 6 位';
                          return null;
                        },
                        onSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 28),
                      AppPillButton(
                        label: _busy
                            ? (_register ? '注册中…' : '登录中…')
                            : (_register ? '注册' : '登录'),
                        onTap: _submit,
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          onPressed: _busy
                              ? null
                              : () => setState(() => _register = !_register),
                          child: Text(
                            _register ? '已有账号？去登录' : '没有账号？去注册',
                            style: AppText.caption.copyWith(color: AppColors.wood),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    bool obscure = false,
    VoidCallback? onToggleObscure,
    ValueChanged<String>? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.eyebrow.copyWith(fontSize: 11, color: AppColors.wood)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscure,
          validator: validator,
          onFieldSubmitted: onSubmitted,
          style: AppText.body.copyWith(color: AppColors.ink),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppText.caption.copyWith(color: AppColors.faint),
            prefixIcon: Icon(icon, size: 20, color: AppColors.muted),
            suffixIcon: onToggleObscure != null
                ? IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 20,
                      color: AppColors.muted,
                    ),
                    onPressed: onToggleObscure,
                  )
                : null,
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: const BorderSide(color: AppColors.hairline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: const BorderSide(color: AppColors.wood, width: 1.4),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: const BorderSide(color: AppColors.clay),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: const BorderSide(color: AppColors.clay, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}
