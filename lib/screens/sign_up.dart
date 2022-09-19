import 'package:api_client/api_client.dart';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:template_flutter/providers/providers.dart';

import 'sign_in.dart';

class SignUpPage extends ConsumerStatefulWidget {
  static const String routeName = "/signUp";

  static Route route(RouteSettings settings) => MaterialPageRoute(
        settings: settings,
        builder: (context) => const SignUpPage(),
      );

  const SignUpPage({Key? key}) : super(key: key);

  @override
  ConsumerState<SignUpPage> createState() => _State();
}

final usernameRegexp = RegExp(r'^[a-zA-Z0-9]+([_ -]?[a-zA-Z0-9])*$');
final emailRegexp = RegExp(
    r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$');
const minUsernameLen = 5;
const maxUsernameLen = 25;

final _signUpCubitProvider =
    StateNotifierProvider.autoDispose<_Cubit, AsyncValue<User>?>(
  (ref) => _Cubit(ref),
);

class _Cubit extends StateNotifier<AsyncValue<User>?> {
  final Ref ref;

  _Cubit(this.ref) : super(null);
  void signUp(String username, String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final userRepo = ref.read(userRepoProvider);
      try {
        return await userRepo
            .create(CreateUserRequest(username, email, password));
      } on EndpointError catch (err) {
        switch (err.type) {
          case "usernameOccupied":
            throw "Provided username is occupied.";
          case "emailOccupied":
            throw "Provided email is occupied.";
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

class _State extends ConsumerState<SignUpPage> {
  final _formKey = GlobalKey<FormState>();

  String? _username;
  String? _email;
  String? _password;

  @override
  Widget build(BuildContext context) {
    ref.listen(
      _signUpCubitProvider,
      (_, cubitState) => cubitState?.whenOrNull(
        data: (_) {
          Navigator.popAndPushNamed(
            context,
            SignInPage.routeName,
            arguments: SignInPage.routeArgs(
              initialIdentifier: _username,
              initialPassword: _password,
            ),
          );
        },
        error: (err, _) => ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $err"))),
      ),
    );
    final isLoading = ref.watch(_signUpCubitProvider) is AsyncLoading;
    return Scaffold(
      body: Form(
        key: _formKey,
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text("Sign Up Page"),
              TextFormField(
                enabled: !isLoading,
                validator: (value) {
                  if ((value == null || value.isEmpty)) {
                    return "Please provide a username.";
                  }
                  if (value.length < minUsernameLen) {
                    return "Username must be at least $minUsernameLen characters long";
                  }
                  if (value.length > maxUsernameLen) {
                    return "Username must not be longer than $maxUsernameLen characters";
                  }
                  if ((!usernameRegexp.hasMatch(value))) {
                    return "A username can only contain a-z, A-Z, _ and - and can't start or end with _ or -";
                  }
                  return null;
                },
                onSaved: (value) => setState(() => _username = value),
                decoration: const InputDecoration(
                  hintText: "Username",
                ),
              ),
              TextFormField(
                enabled: !isLoading,
                validator: (value) => (value == null || value.isEmpty)
                    ? "Please provide an email address."
                    : (!emailRegexp.hasMatch(value))
                        ? "Provided email was invalid."
                        : null,
                onSaved: (value) => setState(() => _email = value),
                decoration: const InputDecoration(
                  hintText: "Email",
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
                              .read(_signUpCubitProvider.notifier)
                              .signUp(_username!, _email!, _password!);
                        }
                      },
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text("Sign Up"),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () {
                        Navigator.popAndPushNamed(
                          context,
                          SignInPage.routeName,
                        );
                      },
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text("Sign In"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
