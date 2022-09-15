export 'sign_in.dart';
export 'home.dart';
export 'splash.dart';

import 'package:flutter/material.dart';

import 'sign_in.dart';
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
      return HomeScreen.route();
    case SignInPage.routeName:
      return SignInPage.route();
    default:
      return SplashScreen.route();
  }
}
