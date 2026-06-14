import 'package:flutter/material.dart';

import 'package:lull/core/theme/theme.dart';

/// The standard page backdrop: a bg1 [Scaffold] with safe-area insets applied.
///
/// LullScaffold owns the [SafeArea]; screens must not wrap their content in
/// another one.
class LullScaffold extends StatelessWidget {
  const LullScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bg1,
      body: SafeArea(child: child),
    );
  }
}
