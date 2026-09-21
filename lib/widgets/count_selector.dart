import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// 本次抽出张数选择：可在 1-9 之间下拉选择，也可直接键入。
class CountSelector extends StatefulWidget {
  const CountSelector({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  State<CountSelector> createState() => _CountSelectorState();
}

class _CountSelectorState extends State<CountSelector> {
  static const int minValue = 1;
  static const int maxValue = 9;

  late final TextEditingController _controller = TextEditingController(text: '${widget.value}');
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) _syncText();
    });
  }

  @override
  void didUpdateWidget(covariant CountSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && !_focusNode.hasFocus) _syncText();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _syncText() {
    final text = '${widget.value}';
    if (_controller.text != text) _controller.text = text;
  }

  void _submit(String raw) {
    final parsed = int.tryParse(raw);
    if (parsed == null || parsed < minValue || parsed > maxValue) return;
    if (parsed != widget.value) widget.onChanged(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.hairline),
      ),
      padding: const EdgeInsets.only(left: 14, right: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.label,
            style: AppText.eyebrow.copyWith(fontSize: 11, letterSpacing: 1),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 22,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 1,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[1-9]'))],
              style: AppText.title.copyWith(fontSize: 15),
              decoration: const InputDecoration(
                isDense: true,
                counterText: '',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: _submit,
            ),
          ),
          PopupMenuButton<int>(
            padding: EdgeInsets.zero,
            tooltip: '选择张数',
            onSelected: widget.onChanged,
            child: const SizedBox(
              width: 28,
              height: 30,
              child: Icon(Icons.arrow_drop_down_rounded, size: 22, color: AppColors.inkSoft),
            ),
            itemBuilder: (context) => [
              for (var i = minValue; i <= maxValue; i++)
                PopupMenuItem<int>(
                  value: i,
                  height: 40,
                  child: Text('$i', style: AppText.body),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
