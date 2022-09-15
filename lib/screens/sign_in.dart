import 'package:api_client/api_client.dart';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:template_flutter/providers/providers.dart';

import 'home.dart';

final _signInCubitProvider =
    StateNotifierProvider.autoDispose<_SignInCubit, AsyncValue<AuthState>?>(
  (ref) => _SignInCubit(ref),
);

class _SignInCubit extends StateNotifier<AsyncValue<AuthState>?> {
  final Ref ref;

  _SignInCubit(this.ref) : super(null);
  void signIn(String identifier, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authRepo = ref.watch(authRepoProvider);
      try {
        final resp = await authRepo.authenticate(identifier, password);
        final authState = AuthState(resp.token, resp.userId, resp.expiresAt);
        ref.read(authStateProvider.notifier).state = authState;
        return authState;
      } on EndpointError catch (err) {
        switch (err.type) {
          case "credentialsRejected":
            throw "Provided credentials were rejected";
          case "internalError":
            throw "Server error: please try again later";
          default:
            throw "Unexpected error: $err";
        }
      } on TimeoutException catch (_) {
        throw "Timeout trying to contact server: check connection";
      }
    });
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
  final _formKey = GlobalKey<FormState>();

  String? _identifier;
  String? _password;

  @override
  Widget build(BuildContext context) {
    ref.listen(
      _signInCubitProvider,
      (_, cubitState) => cubitState?.whenOrNull(
        data: (succ) {
          Navigator.popAndPushNamed(context, HomeScreen.routeName);
        },
        error: (err, _) => ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $err"))),
      ),
    );
    final isLoading = ref.watch(_signInCubitProvider) is AsyncLoading;
    return Scaffold(
      body: Form(
        key: _formKey,
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text("Sign In Page"),
              TextFormField(
                enabled: !isLoading,
                validator: (value) => (value == null || value.isEmpty)
                    ? "Please provide your username or email."
                    : null,
                onSaved: (value) => setState(() => _identifier = value),
                decoration: const InputDecoration(
                  hintText: "Email or username",
                ),
              ),
              TextFormField(
                enabled: !isLoading,
                validator: (value) => (value == null || value.isEmpty)
                    ? "Please provide your password."
                    : (value.length < 8)
                        ? "Password can't be shorter than 8 characters"
                        : null,
                onSaved: (value) => setState(() => _password = value),
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: "Password",
                ),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () {
                        final form = _formKey.currentState;
                        if (form != null && form.validate()) {
                          form.save();
                          ref
                              .read(_signInCubitProvider.notifier)
                              .signIn(_identifier!, _password!);
                        }
                      },
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text("Sign In"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
