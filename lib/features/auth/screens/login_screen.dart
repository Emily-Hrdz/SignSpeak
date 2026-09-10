import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/widgets/app_brand_logo.dart';
import '../../../core/widgets/clay_components.dart';
import '../../../core/widgets/gradient_background.dart';
import '../../../data/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _routeMessageShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeMessageShown) return;
    final message = ModalRoute.of(context)?.settings.arguments as String?;
    if (message == null) return;
    _routeMessageShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showMessage(message);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      _showMessage('Completa correo y contraseña.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final credential = await AuthService().signIn(
        email: email,
        password: password,
      );
      if (mounted) {
        final destination = credential.user?.emailVerified == true
            ? '/home'
            : '/verify-email';
        Navigator.pushNamedAndRemoveUntil(
          context,
          destination,
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (error) {
      var message = 'Ocurrió un error al iniciar sesión.';
      if (error.code == 'user-not-found') {
        message = 'No existe una cuenta con ese correo.';
      } else if (error.code == 'wrong-password' ||
          error.code == 'invalid-credential') {
        message = 'Correo o contraseña incorrectos.';
      } else if (error.code == 'invalid-email') {
        message = 'El correo no es válido.';
      }
      if (mounted) _showMessage(message);
    } catch (_) {
      if (mounted) _showMessage('No se pudo iniciar sesión.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: ClaySurface(
                  borderRadius: 28,
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const AppBrandLogo(size: 58),
                          const SizedBox(width: 12),
                          const Text(
                            'SignSpeak',
                            style: TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Comunicación sin barreras',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF68738A),
                        ),
                      ),
                      const SizedBox(height: 34),
                      Text(
                        'BIENVENIDO A SIGNSPEAK',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Iniciar sesión',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Ingresa para continuar aprendiendo y traduciendo LENSEGUA.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF68738A),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Correo electrónico',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          hintText: 'usuario@ejemplo.com',
                          prefixIcon: Icon(Icons.mail_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Contraseña',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) {
                          if (!_isLoading) _login();
                        },
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword
                                ? 'Mostrar contraseña'
                                : 'Ocultar contraseña',
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.pushNamed(
                                  context,
                                  '/forgot-password',
                                ),
                          child: const Text('¿Olvidaste tu contraseña?'),
                        ),
                      ),
                      ClayButton(
                        label: 'Entrar a SignSpeak',
                        icon: Icons.arrow_forward_rounded,
                        isLoading: _isLoading,
                        onPressed: _login,
                      ),
                      const SizedBox(height: 22),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text('¿No tienes cuenta?'),
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () => Navigator.pushNamed(context, '/signup'),
                            child: const Text('Regístrate'),
                          ),
                        ],
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
}
