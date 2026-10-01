import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/stayeasy_colors.dart';
import '../../../core/theme/stayeasy_spacing.dart';
import '../../../core/theme/stayeasy_typography.dart';
import '../../booking/application/booking_provider.dart';
import '../../../app/router/app_routes.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({
    super.key,
    this.signUp = false,
    this.next = AppRoutes.explore,
  });
  final bool signUp;
  final String next;

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _working = false;
  String? _message;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSignUp = widget.signUp;
    return Scaffold(
      appBar: AppBar(title: const Text('StayEasy'), centerTitle: true),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(StayEasySpacing.space24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(StayEasySpacing.space24),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        isSignUp ? 'Create your account' : 'Welcome back',
                        style: StayEasyTypography.editorialHero.copyWith(
                          fontSize: 30,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to keep your trips together and book with confidence.',
                        style: StayEasyTypography.bodyMedium.copyWith(
                          color: StayEasyColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (isSignUp) ...[
                        TextFormField(
                          controller: _name,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Full name',
                          ),
                          validator: (v) => (v?.trim().length ?? 0) < 2
                              ? 'Enter your name'
                              : null,
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (v) => v == null || !v.contains('@')
                            ? 'Enter a valid email'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _password,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                        ),
                        validator: (v) => (v?.length ?? 0) < 8
                            ? 'Use at least 8 characters'
                            : null,
                      ),
                      if (_message != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _message!,
                          style: TextStyle(
                            color: _message!.startsWith('Check')
                                ? StayEasyColors.success
                                : StayEasyColors.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _working ? null : _submit,
                        child: Text(
                          _working
                              ? 'Please wait…'
                              : isSignUp
                              ? 'Create account'
                              : 'Sign in',
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go(
                          '${isSignUp ? AppRoutes.signIn : AppRoutes.signUp}?next=${Uri.encodeComponent(widget.next)}',
                        ),
                        child: Text(
                          isSignUp
                              ? 'Already have an account? Sign in'
                              : 'New to StayEasy? Create an account',
                        ),
                      ),
                      const Divider(height: 24),
                      OutlinedButton(
                        onPressed: () => context.go(
                          widget.next == AppRoutes.bookingConfirmation
                              ? AppRoutes.explore
                              : widget.next,
                        ),
                        child: const Text('Continue as guest'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _working = true;
      _message = null;
    });
    try {
      final repo = ref.read(authRepositoryProvider);
      final profile = widget.signUp
          ? await repo.signUp(_email.text, _password.text, _name.text)
          : await repo.signIn(_email.text, _password.text);
      ref.invalidate(authProfileProvider);
      if (!mounted) return;
      if (profile == null) {
        setState(
          () => _message =
              'Check your email to finish creating your account, then sign in.',
        );
      } else {
        context.go(widget.next);
      }
    } catch (error) {
      if (mounted) setState(() => _message = _authError(error));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  String _authError(Object error) {
    final value = error.toString().toLowerCase();
    if (value.contains('invalid login credentials')) {
      return 'Email or password is incorrect.';
    }
    if (value.contains('already registered')) {
      return 'An account already exists for this email.';
    }
    return 'We couldn’t sign you in. Check your connection and try again.';
  }
}
