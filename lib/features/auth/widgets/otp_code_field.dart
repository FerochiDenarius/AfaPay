import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OtpCodeField extends StatefulWidget {
  const OtpCodeField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.otp,
    required this.onChanged,
    this.autofocus = true,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String otp;
  final ValueChanged<String> onChanged;
  final bool autofocus;

  @override
  State<OtpCodeField> createState() => _OtpCodeFieldState();
}

class _OtpCodeFieldState extends State<OtpCodeField> {
  static const _gold = Color(0xFFF5B81F);
  static const _field = Color(0xFF0B111D);
  static const _border = Color(0xFF303541);

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final activeIndex = math.min(widget.otp.length, 5);
    return Semantics(
      label: 'Six digit verification code',
      textField: true,
      child: GestureDetector(
        onTap: widget.focusNode.requestFocus,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            Row(
              children: List.generate(6, (index) {
                final selected =
                    widget.focusNode.hasFocus && index == activeIndex;
                final digit = index < widget.otp.length
                    ? widget.otp[index]
                    : '';
                return Expanded(
                  child: Container(
                    height: 62,
                    margin: EdgeInsets.only(right: index == 5 ? 0 : 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _field.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? _gold : _border,
                        width: selected ? 2 : 1.2,
                      ),
                    ),
                    child: Text(
                      digit,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                );
              }),
            ),
            Positioned.fill(
              child: Opacity(
                opacity: 0.01,
                child: TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  autofocus: widget.autofocus,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  enableSuggestions: false,
                  autocorrect: false,
                  showCursor: false,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    counterText: '',
                  ),
                  onChanged: widget.onChanged,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
