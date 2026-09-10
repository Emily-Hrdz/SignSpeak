import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/widgets/clay_components.dart';
import '../../../data/services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> resetPassword() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa tu correo electrónico.')),
      );
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      await AuthService().sendPasswordResetEmail(email: email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Se enviaron instrucciones a tu correo.'),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'No se pudo enviar el correo de recuperación.';

      if (e.code == 'invalid-email') {
        message = 'El correo no es válido.';
      } else if (e.code == 'user-not-found') {
        message = 'No existe una cuenta con ese correo.';
      }

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
      appBar: AppBar(title: const Text('Recuperar Contraseña')),
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
                  const Text(
                    'Ingresa tu correo electrónico para enviarte instrucciones de recuperación.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      hintText: 'usuario@ejemplo.com',
                    ),
                  ),
                  const SizedBox(height: 24),
                  ClayButton(
                    label: 'Enviar instrucciones',
                    icon: Icons.send_rounded,
                    isLoading: isLoading,
                    onPressed: resetPassword,
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
