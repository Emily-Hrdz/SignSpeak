import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/widgets/app_brand_logo.dart';
import '../../../core/widgets/clay_components.dart';
import '../../../data/services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (nameController.text.trim().isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos.')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden.')),
      );
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      final authService = AuthService();
      await authService.signUp(
        email: email,
        password: password,
        displayName: nameController.text.trim(),
      );

      var verificationSent = true;
      String? verificationErrorCode;
      try {
        await authService.sendEmailVerification();
        debugPrint('Firebase aceptó el correo de verificación para $email.');
      } on FirebaseAuthException catch (error) {
        verificationSent = false;
        verificationErrorCode = error.code;
        debugPrint(
          'Error al enviar verificación: ${error.code} - ${error.message}',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              verificationSent
                  ? 'Cuenta creada. Revisa tu correo para verificarla.'
                  : 'Cuenta creada, pero el correo falló (${verificationErrorCode ?? 'desconocido'}). Puedes reenviarlo en la siguiente pantalla.',
            ),
          ),
        );

        Navigator.pushNamedAndRemoveUntil(
          context,
          '/verify-email',
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'No se pudo crear la cuenta.';

      if (e.code == 'email-already-in-use') {
        message =
            'Ese correo ya está registrado. Inicia sesión para continuar o reenviar la verificación.';
      } else if (e.code == 'invalid-email') {
        message = 'El correo no es válido.';
      } else if (e.code == 'weak-password') {
        message = 'La contraseña es demasiado débil.';
      } else if (e.code == 'operation-not-allowed') {
        message =
            'El acceso con correo y contraseña no está habilitado en Firebase.';
      } else if (e.code == 'network-request-failed') {
        message = 'Comprueba tu conexión a internet e inténtalo nuevamente.';
      } else if (e.code == 'too-many-requests') {
        message = 'Se realizaron demasiados intentos. Espera unos minutos.';
      } else {
        message = 'No se pudo crear la cuenta (código: ${e.code}).';
      }

      debugPrint('Error al crear cuenta: ${e.code} - ${e.message}');

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ocurrió un error inesperado.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrarse')),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: ClaySurface(
              borderRadius: 24,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const AppBrandLogo(size: 76),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre completo',
                      hintText: 'Tu nombre',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      hintText: 'usuario@ejemplo.com',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      hintText: '••••••••',
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirmar contraseña',
                      hintText: '••••••••',
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            obscureConfirmPassword = !obscureConfirmPassword;
                          });
                        },
                        icon: Icon(
                          obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ClayButton(
                    label: 'Crear cuenta',
                    icon: Icons.person_add_alt_1_rounded,
                    isLoading: isLoading,
                    onPressed: register,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            Navigator.pop(context);
                          },
                    child: const Text('¿Ya tienes cuenta? Inicia sesión'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
