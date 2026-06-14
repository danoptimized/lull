import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lull/core/theme/theme.dart';
import 'package:lull/features/auth/application/auth_controller.dart';
import 'package:lull/ui/animations/lull_entrance.dart';
import 'package:lull/ui/components/aurora_backdrop.dart';
import 'package:lull/ui/components/lull_pill_button.dart';

/// The gate: a calm, aurora-lit email one-time-passcode flow. On a verified
/// code the auth stream flips and the router redirects on its own — this screen
/// never navigates.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

enum _Step { email, code }

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  _Step _step = _Step.email;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => _error = _humanError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendCode() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      setState(() => _error = 'that doesn’t look like an email');
      return;
    }
    await _run(() async {
      await ref.read(authControllerProvider.notifier).sendOtp(email);
      if (mounted) setState(() => _step = _Step.code);
    });
  }

  Future<void> _verify() => _run(
    () => ref
        .read(authControllerProvider.notifier)
        .verifyOtp(email: _email.text, token: _code.text),
  );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;

    return Scaffold(
      backgroundColor: colors.bg0,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AuroraBackdrop(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: spacing.xl),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: _step == _Step.email
                      ? _emailStep(context)
                      : _codeStep(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emailStep(BuildContext context) {
    final spacing = context.spacing;
    final type = context.type;
    final colors = context.colors;

    return Column(
      key: const ValueKey(_Step.email),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        LullEntrance(
          index: 0,
          child: Text('lull', style: type.display.copyWith(fontSize: 56)),
        ),
        SizedBox(height: spacing.sm),
        LullEntrance(
          index: 1,
          child: Text(
            'a quiet place for your three things.\nsign in to begin.',
            style: type.bodySoft.copyWith(color: colors.textSecondary),
          ),
        ),
        SizedBox(height: spacing.xxxl),
        LullEntrance(
          index: 2,
          child: _Field(
            controller: _email,
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            enabled: !_busy,
            onSubmitted: (_) => _sendCode(),
          ),
        ),
        if (_error != null) ...[
          SizedBox(height: spacing.md),
          _ErrorText(_error!),
        ],
        SizedBox(height: spacing.lg),
        LullEntrance(
          index: 3,
          child: LullPillButton(
            label: _busy ? 'sending…' : 'send code',
            onPressed: _busy ? null : _sendCode,
          ),
        ),
      ],
    );
  }

  Widget _codeStep(BuildContext context) {
    final spacing = context.spacing;
    final type = context.type;
    final colors = context.colors;

    return Column(
      key: const ValueKey(_Step.code),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        LullEntrance(
          index: 0,
          child: Text('check your email', style: type.title),
        ),
        SizedBox(height: spacing.sm),
        LullEntrance(
          index: 1,
          child: Text(
            'enter the code we sent to ${_email.text.trim()}',
            style: type.bodySoft.copyWith(color: colors.textSecondary),
          ),
        ),
        SizedBox(height: spacing.xxxl),
        LullEntrance(
          index: 2,
          child: _Field(
            controller: _code,
            hint: '000000',
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            maxLength: 6,
            textAlign: TextAlign.center,
            letterSpacing: 8,
            enabled: !_busy,
            onSubmitted: (_) => _verify(),
          ),
        ),
        if (_error != null) ...[
          SizedBox(height: spacing.md),
          _ErrorText(_error!),
        ],
        SizedBox(height: spacing.lg),
        LullEntrance(
          index: 3,
          child: LullPillButton(
            label: _busy ? 'verifying…' : 'verify',
            onPressed: _busy ? null : _verify,
          ),
        ),
        SizedBox(height: spacing.sm),
        LullEntrance(
          index: 4,
          child: TextButton(
            onPressed: _busy
                ? null
                : () => setState(() {
                    _step = _Step.email;
                    _code.clear();
                    _error = null;
                  }),
            child: Text(
              'use a different email',
              style: type.caption.copyWith(color: colors.textFaint),
            ),
          ),
        ),
      ],
    );
  }
}

String _humanError(Object e) {
  final message = e.toString().toLowerCase();
  if (message.contains('expired') || message.contains('invalid')) {
    return 'that code didn’t work — try again';
  }
  if (message.contains('network') || message.contains('socket')) {
    return 'no connection — check your network';
  }
  return 'something went wrong — try again';
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.autofillHints,
    this.maxLength,
    this.textAlign = TextAlign.start,
    this.letterSpacing,
    this.enabled = true,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final int? maxLength;
  final TextAlign textAlign;
  final double? letterSpacing;
  final bool enabled;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: context.radii.brMd,
      borderSide: BorderSide(color: color),
    );

    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      maxLength: maxLength,
      textAlign: textAlign,
      textInputAction: TextInputAction.done,
      onSubmitted: onSubmitted,
      style: type.body.copyWith(letterSpacing: letterSpacing),
      cursorColor: colors.accentTeal,
      decoration: InputDecoration(
        counterText: '',
        hintText: hint,
        hintStyle: type.body.copyWith(
          color: colors.textFaint,
          letterSpacing: letterSpacing,
        ),
        filled: true,
        fillColor: colors.bg2,
        contentPadding: EdgeInsets.symmetric(
          horizontal: context.spacing.lg,
          vertical: context.spacing.lg,
        ),
        enabledBorder: border(colors.hairline),
        focusedBorder: border(colors.accentTeal),
        disabledBorder: border(colors.hairline),
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: context.type.caption.copyWith(color: context.colors.danger),
    );
  }
}
