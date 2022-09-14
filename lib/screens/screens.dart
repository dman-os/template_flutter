import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:template_flutter/providers/providers.dart';

final _isLoggedInProvider = FutureProvider((ref) async {
  final authRepo = ref.watch(authRepoProvider);
  final token = await authRepo.tryGetAccessToken();
  if (token != null) {
    ref.read(authStateProvider.notifier).state =
        AuthState(token.item1, await authRepo.getLoggedInId(), token.item2);
    return true;
  }
  return false;
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

class HomeScreen extends ConsumerWidget {
  static const String routeName = "/home";

  static Route route() => MaterialPageRoute(
        settings: const RouteSettings(name: routeName),
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

class SignInPage extends ConsumerStatefulWidget {
  static const String routeName = "/signIn";

  static Route route() => MaterialPageRoute(
        settings: const RouteSettings(name: routeName),
        builder: (context) => const SignInPage(),
      );

  const SignInPage({Key? key}) : super(key: key);

  @override
  SignInPageState createState() => SignInPageState();
}

class SignInPageState extends ConsumerState {
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [Text("Sign In Page")],
          ),
        ),
      );
}

Route onGenerateRoute(RouteSettings settings) {
  switch (settings.name) {
    case HomeScreen.routeName:
      return HomeScreen.route();
    case SignInPage.routeName:
      return SignInPage.route();
    default:
      return SplashScreen.route();
  }
}
