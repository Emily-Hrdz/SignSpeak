import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/widgets/app_brand_logo.dart';
import '../../../core/widgets/clay_components.dart';
import '../../../core/widgets/gradient_background.dart';
import '../../../data/services/auth_service.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _authService = AuthService();
  Timer? _verificationTimer;
  bool _isChecking = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _verificationTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkVerification(showPendingMessage: false),
    );
  }

  @override
  void dispose() {
    _verificationTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkVerification({bool showPendingMessage = true}) async {
    if (_isChecking) return;
    _isChecking = true;
    try {
      final user = await _authService.reloadCurrentUser();
      if (!mounted) return;
      if (user?.emailVerified == true) {
        _verificationTimer?.cancel();
        await _authService.signOut();
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/',
          (route) => false,
          arguments: 'Correo verificado. Ya puedes iniciar sesión.',
        );
      } else if (showPendingMessage) {
        _showMessage('El correo todavía no ha sido verificado.');
      }
    } catch (_) {
      if (mounted && showPendingMessage) {
        _showMessage('No se pudo comprobar la verificación.');
      }
    } finally {
      _isChecking = false;
    }
  }

  Future<void> _resend() async {
    setState(() => _isSending = true);
    try {
      await _authService.sendEmailVerification();
      debugPrint(
        'Firebase aceptó el reenvío para ${_authService.currentUser?.email}.',
      );
      if (mounted) {
        _showMessage(
          'Firebase aceptó el envío. Revisa también Spam o Correo no deseado.',
        );
      }
    } on FirebaseAuthException catch (error) {
      debugPrint(
        'Error al reenviar verificación: ${error.code} - ${error.message}',
      );
      final message = switch (error.code) {
        'too-many-requests' =>
          'Espera unos minutos antes de volver a enviarlo.',
        'network-request-failed' =>
          'No hay conexión con Firebase. Comprueba internet.',
        'user-disabled' => 'Esta cuenta fue deshabilitada en Firebase.',
        _ => 'No se pudo enviar el correo (código: ${error.code}).',
      };
      if (mounted) _showMessage(message);
    } catch (error) {
      debugPrint('Error no controlado al reenviar verificación: $error');
      if (mounted) _showMessage('No se pudo enviar el correo: $error');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _changeAccount() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final email = _authService.currentUser?.email ?? 'tu correo';
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: ClaySurface(
                  borderRadius: 28,
                  padding: const EdgeInsets.all(26),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AppBrandLogo(size: 86),
                      const SizedBox(height: 24),
                      Text(
                        'Verifica tu correo',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Enviamos un enlace a\n$email',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Abre el mensaje, pulsa el enlace de verificación y vuelve a SignSpeak.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 26),
                      ClayButton(
                        label: _isChecking ? 'Comprobando…' : 'Ya verifiqué',
                        icon: Icons.verified_rounded,
                        isLoading: _isChecking,
                        onPressed: _checkVerification,
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: _isSending ? null : _resend,
                        icon: const Icon(Icons.send_rounded),
                        label: Text(
                          _isSending ? 'Enviando…' : 'Reenviar correo',
                        ),
                      ),
                      TextButton(
                        onPressed: _changeAccount,
                        child: const Text('Usar otra cuenta'),
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
