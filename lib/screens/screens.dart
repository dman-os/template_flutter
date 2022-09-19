export 'sign_in.dart';
export 'sign_up.dart';
export 'home.dart';
export 'splash.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'sign_in.dart';
import 'sign_up.dart';
import 'home.dart';
import 'splash.dart';

/* 
typedef ActionFn = Future<void> Function();

class AsyncFnCubit<T> extends StateNotifier<AsyncValue<T>?> {
  final ActionFn fn;

  AsyncFnCubit(this.fn) : super(null);
} */

Route onGenerateRoute(RouteSettings settings) {
  switch (settings.name) {
    case HomeScreen.routeName:
      return HomeScreen.route(settings);
    case SignInPage.routeName:
      return SignInPage.route(settings);
    case SignUpPage.routeName:
      return SignUpPage.route(settings);
    default:
      if (kDebugMode) {
        print("route ${settings.name} didn't match any known routes");
      }
      return SplashScreen.route(settings);
  }
}
