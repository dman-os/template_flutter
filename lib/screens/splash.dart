import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:template_flutter/providers/providers.dart';

import 'home.dart';
import 'sign_in.dart';

final _isLoggedInProvider = FutureProvider.autoDispose((ref) async {
  final authState = ref.watch(authStateProvider);
  return authState != null;
});

class SplashScreen extends ConsumerWidget {
  static const String routeName = "/";

  static Route route() => MaterialPageRoute(
        settings: const RouteSettings(name: routeName),
        builder: (context) => const SplashScreen(),
      );

  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(
      _isLoggedInProvider,
      (_, AsyncValue<bool> val) => val.whenOrNull(
        data: (isLoggedIn) {
          if (isLoggedIn) {
            Navigator.pushReplacementNamed(context, HomeScreen.routeName);
          } else {
            Navigator.pushReplacementNamed(context, SignInPage.routeName);
          }
        },
        error: (err, _) => throw err,
      ),
    );
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: const [CircularProgressIndicator()],
        ),
      ),
    );
  }
}
