import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:template_flutter/providers/providers.dart';

class HomeScreen extends ConsumerWidget {
  static const String routeName = "/home";

  static Route route(RouteSettings settings) => MaterialPageRoute(
        settings: settings,
        builder: (context) => const HomeScreen(),
      );

  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider)!;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [Text("Hello ${authState.loggedInId}")],
        ),
      ),
    );
  }
}
