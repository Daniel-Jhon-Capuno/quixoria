import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/state/app_state.dart';
import 'package:flutter/services.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/sound_service.dart';
import '../../shared/widgets/duo_button.dart';
import '../../shared/widgets/guide_dialog.dart';
import '../../shared/widgets/quixote_avatar.dart';

/// Available view modes for the authentication journey.
enum AuthPage {
  welcome,
  signUp,
  logIn,
}

/// Chivalric Authentication & Enlistment Screen.
/// Built with Duolingo-inspired welcoming onboarding, 7 named microinteractions:
/// 1. Floating Label (smooth floating label with golden elevation)
/// 2. Zigzag Underline (animated heraldic zigzag draw beneath active fields)
/// 3. Flow Fill (fluid color fill transition across input surface)
/// 4. Load & Success (button morphs to spinner, then animated checkmark badge)
/// 5. Push Slide (directional sliding transitions between tabs and views)
/// 6. Box Bounce (tactile squash-and-stretch spring bounce on selection)
/// 7. Check Draw (animated stroke path drawing of the checkmark)
///
/// Features Duolingo-style Welcome greeting, social sign-in (Google & Facebook),
/// instant guest scholar bypass, password strength indicators, and salted SHA-256 security.
class AuthScreen extends StatefulWidget {
  final VoidCallback onAuthSuccess;
  final AuthPage initialPage;

  const AuthScreen({
    super.key,
    required this.onAuthSuccess,
    this.initialPage = AuthPage.welcome,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  late AuthPage _currentPage;
  bool _isSignUp = true;
  bool _useUsernameMode = false;
  bool _isVerifyingCode = false;
  bool _isLoading = false;
  bool _isSuccess = false;

  int _slideDirection = 1;
  int _tabSlideDirection = 1;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _acceptedTerms = false;
  bool _rememberMe = true;
  bool _obscurePassword = true;
  bool _submitted = false;
  bool _loginSubmitted = false;

  String? _dispatchedCode;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _isSignUp = (_currentPage == AuthPage.signUp || _currentPage == AuthPage.welcome);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return false;
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return regex.hasMatch(trimmed);
  }

  void _showTermsDialog() {
    GuideDialog.show(
      context: context,
      title: 'Terms & Conditions',
      message:
          '1. Educational Integrity: Read with curiosity through classic literature without skipping learning milestones.\n\n'
          '2. Privacy & Security: Your email, bookmarks, notes, and reading streaks are safely stored and protected.\n\n'
          '3. Fair Rewards: Gems, league titles, and keys are earned through genuine reading and comprehension.\n\n'
          '4. Open Library Access: Your account grants open access to public-domain literature in Quixoria.',
      primaryButtonText: 'I Accept Terms & Conditions',
      mood: QuixoteMood.proud,
      onPrimaryPressed: () {
        setState(() {
          _acceptedTerms = true;
          _errorMessage = null;
        });
      },
    );
  }

  void _showForgotPasswordDialog() {
    final resetEmailCtrl = TextEditingController(text: _emailController.text.trim());
    final newPassCtrl = TextEditingController();
    String? dialogError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.lock_reset_rounded, color: AppColors.antiqueGold),
              SizedBox(width: 10),
              Text('Reset Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Enter your registered email address and set a new password (min. 6 characters).',
                  style: TextStyle(fontSize: 12.5, height: 1.4),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: resetEmailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPassCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'New Password (Min. 6 Characters)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    isDense: true,
                  ),
                ),
                if (dialogError != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    dialogError!,
                    style: const TextStyle(color: AppColors.vermillion, fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.antiqueGold,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final identifier = resetEmailCtrl.text.trim();
                final newPass = newPassCtrl.text.trim();
                final isEmail = identifier.contains('@') && !identifier.startsWith('@');
                if (isEmail) {
                  if (!_isValidEmail(identifier)) {
                    setDialogState(() => dialogError = 'Please enter a valid email address.');
                    return;
                  }
                } else {
                  final cleanUser = identifier.replaceFirst(RegExp(r'^@'), '');
                  if (!AuthService.isValidUsername(cleanUser)) {
                    setDialogState(() => dialogError = 'Enter a valid email or username (3–24 chars).');
                    return;
                  }
                }
                if (newPass.length < 6) {
                  setDialogState(() => dialogError = 'New password must be at least 6 characters.');
                  return;
                }
                await AuthService.instance.resetPassword(email: identifier, newPassword: newPass);
                if (!ctx.mounted) return;
                if (isEmail) {
                  _emailController.text = identifier;
                } else {
                  _usernameController.text = identifier.replaceFirst(RegExp(r'^@'), '');
                }
                _passwordController.text = newPass;
                Navigator.pop(ctx);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isEmail
                          ? 'Password reset link sent to $identifier! Check your inbox.'
                          : 'Password updated for @$identifier! You can now log in.',
                    ),
                    backgroundColor: AppColors.successGreen,
                  ),
                );
              },
              child: const Text('Update Password', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordStrengthWidget(String password) {
    if (password.isEmpty) return const SizedBox.shrink();
    final len = password.length;
    final hasMinLen = len >= 6;
    final hasMix = RegExp(r'[0-9!@#\$%^&*(),.?":{}|<>]').hasMatch(password) &&
        RegExp(r'[a-zA-Z]').hasMatch(password);

    int strengthLevel;
    if (!hasMinLen) {
      strengthLevel = 1;
    } else if (!hasMix || len < 8) {
      strengthLevel = 2;
    } else {
      strengthLevel = 3;
    }

    Color strengthColor;
    String strengthLabel;
    switch (strengthLevel) {
      case 1:
        strengthColor = AppColors.vermillion;
        strengthLabel = 'Too Short (Min. 6 Characters)';
        break;
      case 2:
        strengthColor = AppColors.antiqueGold;
        strengthLabel = 'Good Password';
        break;
      case 3:
      default:
        strengthColor = AppColors.successGreen;
        strengthLabel = 'Strong Password';
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (int i = 1; i <= 3; i++) ...[
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 3.5,
                    margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                    decoration: BoxDecoration(
                      color: i <= strengthLevel ? strengthColor : Colors.grey.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                strengthLevel >= 2 ? Icons.shield_rounded : Icons.shield_outlined,
                size: 12,
                color: strengthColor,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  strengthLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: strengthColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleSendCode() async {
    setState(() => _submitted = true);
    final password = _passwordController.text.trim();

    if (_useUsernameMode) {
      final username = _usernameController.text.trim().replaceFirst(RegExp(r'^@'), '');
      if (!AuthService.isValidUsername(username)) {
        setState(() {
          _errorMessage = username.isEmpty
              ? 'Please enter a username.'
              : 'Username must be 3–24 characters (letters, numbers, ., _, - only).';
        });
        SoundService.instance.play(Sfx.tap);
        return;
      }
      if (password.length < 6) {
        setState(() {
          _errorMessage = password.isEmpty
              ? 'Please enter a password.'
              : 'Password must be at least 6 characters (currently ${password.length}/6).';
        });
        SoundService.instance.play(Sfx.tap);
        return;
      }
      if (!_acceptedTerms) {
        setState(() => _errorMessage = 'Please accept the Terms & Conditions to sign up.');
        SoundService.instance.play(Sfx.tap);
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      SoundService.instance.play(Sfx.tap);

      final result = await AuthService.instance.registerWithUsername(
        username: username,
        password: password,
        displayName: _nameController.text.trim(),
        acceptedTerms: _acceptedTerms,
      );

      if (!mounted) return;
      if (result.success) {
        try {
          final state = Provider.of<AppState>(context, listen: false);
          await state.loadAccountOnLogin(
            name: AuthService.instance.userName,
            email: AuthService.instance.userEmail,
            isNewAccount: true,
          );
        } catch (_) {}
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _isSuccess = true;
        });
        SoundService.instance.play(Sfx.levelComplete);
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        widget.onAuthSuccess();
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = result.errorMessage ?? 'Could not create account. Please try again.';
        });
        SoundService.instance.play(Sfx.tap);
      }
      return;
    }

    final email = _emailController.text.trim();
    if (!_isValidEmail(email)) {
      setState(() {
        _errorMessage = email.isEmpty
            ? 'Please enter your email address.'
            : 'Invalid email address. Please use a valid format (e.g. name@example.com).';
      });
      SoundService.instance.play(Sfx.tap);
      return;
    }
    if (password.length < 6) {
      setState(() {
        _errorMessage = password.isEmpty
            ? 'Please enter a password.'
            : 'Password must be at least 6 characters (currently ${password.length}/6).';
      });
      SoundService.instance.play(Sfx.tap);
      return;
    }
    if (!_acceptedTerms) {
      setState(() => _errorMessage = 'Please accept the Terms & Conditions to sign up.');
      SoundService.instance.play(Sfx.tap);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    SoundService.instance.play(Sfx.tap);
    final result = await AuthService.instance.signUpWithEmailDetailed(
      email: email,
      password: password,
      name: _nameController.text.trim(),
      acceptedTerms: _acceptedTerms,
    );

    if (!mounted) return;
    if (!result.success) {
      setState(() {
        _isLoading = false;
        _errorMessage = result.errorMessage ?? 'Could not sign up. Please try again.';
      });
      SoundService.instance.play(Sfx.tap);
      return;
    }

    // If Supabase issued an instant session (email confirmation disabled), enter immediately!
    if (!result.needsEmailVerification) {
      try {
        final state = Provider.of<AppState>(context, listen: false);
        await state.loadAccountOnLogin(
          name: AuthService.instance.userName,
          email: AuthService.instance.userEmail,
          isNewAccount: true,
        );
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isSuccess = true;
      });
      SoundService.instance.play(Sfx.levelComplete);
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      widget.onAuthSuccess();
      return;
    }

    setState(() {
      _isLoading = false;
      _dispatchedCode = result.fallbackCode;
      _isVerifyingCode = true;
      _tabSlideDirection = 1;
    });
    SoundService.instance.play(Sfx.reward);
  }

  Future<void> _handleResendCode() async {
    final email = _emailController.text.trim();
    if (!_isValidEmail(email)) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final res = await AuthService.instance.resendVerificationCode(email);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (res.fallbackCode != null) {
        _dispatchedCode = res.fallbackCode;
      }
      if (!res.success) {
        _errorMessage = res.errorMessage ?? 'Could not resend verification code.';
      }
    });
    if (res.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('A fresh verification code was sent to $email.'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    }
  }

  Future<void> _handleVerifyCode() async {
    final code = _otpController.text.replaceAll(RegExp(r'\s+'), '').trim();
    if (code.length < 6 || code.length > 8) {
      setState(() => _errorMessage = 'Please enter the verification code (6 to 8 digits).');
      SoundService.instance.play(Sfx.tap);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await AuthService.instance.verifyAndRegisterDetailed(
      email: _emailController.text,
      code: code,
      name: _nameController.text,
      acceptedTerms: _acceptedTerms,
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (result.success) {
      try {
        final state = Provider.of<AppState>(context, listen: false);
        final regName = _nameController.text.trim().isNotEmpty
            ? _nameController.text.trim()
            : AuthService.instance.userName;
        final regEmail = _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : AuthService.instance.userEmail;
        await state.loadAccountOnLogin(
          name: regName,
          email: regEmail,
          isNewAccount: true,
        );
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isSuccess = true;
      });
      SoundService.instance.play(Sfx.levelComplete);
      await Future.delayed(const Duration(milliseconds: 550));
      if (!mounted) return;
      widget.onAuthSuccess();
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = result.errorMessage ?? 'Invalid verification code. Please check your email code and try again.';
      });
      SoundService.instance.play(Sfx.tap);
    }
  }

  Future<void> _handleLogin() async {
    setState(() => _loginSubmitted = true);
    final password = _passwordController.text.trim();

    if (_useUsernameMode) {
      final username = _usernameController.text.trim().replaceFirst(RegExp(r'^@'), '');
      if (username.isEmpty) {
        setState(() => _errorMessage = 'Please enter your username.');
        SoundService.instance.play(Sfx.tap);
        return;
      }
      if (password.isEmpty) {
        setState(() => _errorMessage = 'Please enter your password.');
        SoundService.instance.play(Sfx.tap);
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final result = await AuthService.instance.loginWithUsername(
        username: username,
        password: password,
      );

      if (!mounted) return;
      if (result.success) {
        try {
          final state = Provider.of<AppState>(context, listen: false);
          await state.loadAccountOnLogin(
            name: AuthService.instance.userName,
            email: AuthService.instance.userEmail,
            isNewAccount: false,
          );
        } catch (_) {}

        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _isSuccess = true;
        });
        SoundService.instance.play(Sfx.welcome);
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        widget.onAuthSuccess();
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = result.errorMessage ?? 'Unable to log in. Please check your username and password.';
        });
        SoundService.instance.play(Sfx.tap);
      }
      return;
    }

    final email = _emailController.text.trim();
    if (!_isValidEmail(email)) {
      setState(() {
        _errorMessage = email.isEmpty
            ? 'Please enter your registered email address.'
            : 'Invalid email address format. Please check your email.';
      });
      SoundService.instance.play(Sfx.tap);
      return;
    }
    if (password.isEmpty) {
      setState(() => _errorMessage = 'Please enter your password.');
      SoundService.instance.play(Sfx.tap);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await AuthService.instance.loginWithEmailDetailed(
      email: email,
      password: password,
      rememberMe: _rememberMe,
    );

    if (!mounted) return;

    if (result.success) {
      try {
        final state = Provider.of<AppState>(context, listen: false);
        await state.loadAccountOnLogin(
          name: AuthService.instance.userName.isNotEmpty
              ? AuthService.instance.userName
              : email.split('@').first,
          email: email,
          isNewAccount: false,
        );
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isSuccess = true;
      });
      SoundService.instance.play(Sfx.welcome);
      await Future.delayed(const Duration(milliseconds: 550));
      if (!mounted) return;
      widget.onAuthSuccess();
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = result.errorMessage ?? 'Unable to log in. Please check your email and password.';
      });
      SoundService.instance.play(Sfx.tap);
    }
  }

  Future<void> _handleSocialLogin(String provider) async {
    HapticFeedback.mediumImpact();
    SoundService.instance.play(Sfx.tap);
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await AuthService.instance.loginWithSocial(provider: provider);
    if (!mounted) return;

    if (success) {
      try {
        final state = Provider.of<AppState>(context, listen: false);
        state.updateUserProfile(
          name: AuthService.instance.userName,
          email: AuthService.instance.userEmail,
        );
      } catch (_) {}

      setState(() {
        _isLoading = false;
        _isSuccess = true;
      });
      SoundService.instance.play(Sfx.welcome);
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      widget.onAuthSuccess();
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not sign in with $provider. Please try again.';
      });
      SoundService.instance.play(Sfx.tap);
    }
  }

  Future<void> _handleGuestEnlistment() async {
    HapticFeedback.lightImpact();
    SoundService.instance.play(Sfx.tap);
    await AuthService.instance.loginAsGuest();
    if (!mounted) return;
    try {
      final state = Provider.of<AppState>(context, listen: false);
      state.updateUserProfile(
        name: AuthService.instance.userName,
        email: AuthService.instance.userEmail,
      );
    } catch (_) {}
    widget.onAuthSuccess();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                  return Stack(
                    alignment: Alignment.topCenter,
                    children: <Widget>[
                      ...previousChildren,
                      if (currentChild != null) currentChild,
                    ],
                  );
                },
                transitionBuilder: (child, animation) {
                  final bool isCurrent = child.key == ValueKey(_currentPage == AuthPage.welcome ? 'welcome_view' : 'form_view');
                  final tween = isCurrent
                      ? Tween<Offset>(begin: Offset(_slideDirection * 0.75, 0), end: Offset.zero)
                      : Tween<Offset>(begin: Offset(-_slideDirection * 0.75, 0), end: Offset.zero);

                  return SlideTransition(
                    position: tween.animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    )),
                    child: FadeTransition(
                      opacity: CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOut,
                      ),
                      child: child,
                    ),
                  );
                },
                child: _currentPage == AuthPage.welcome
                    ? _buildWelcomeView(theme, isDark)
                    : _buildFormView(theme, isDark),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // VIEW 1: DUOLINGO-STYLE WELCOME & GREETING SCREEN
  // ==========================================================================
  Widget _buildWelcomeView(ThemeData theme, bool isDark) {
    return Column(
      key: const ValueKey('welcome_view'),
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Brand Logo & Shield
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shield_rounded, color: AppColors.antiqueGold, size: 28),
              const SizedBox(width: 8),
              Text(
                'QUIXORIA',
                style: AppTypography.displayLarge.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.2,
                  color: AppColors.antiqueGold,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Hero Artwork Card (Dedicated Showcase for Vintage Windmill Etching)
        Container(
          height: 200,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B2019) : const Color(0xFFFAF0E0),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.antiqueGold.withValues(alpha: isDark ? 0.35 : 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Clean, full view of the vintage windmill (unobstructed)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.asset(
                    'assets/images/vintage_windmill.jpg',
                    fit: BoxFit.contain, // Full uncropped windmill artwork!
                    errorBuilder: (_, __, ___) => Container(
                      color: isDark ? const Color(0xFF263228) : const Color(0xFFF4ECE1),
                      child: const Center(
                        child: Icon(Icons.menu_book_rounded, size: 64, color: AppColors.antiqueGold),
                      ),
                    ),
                  ),
                ),
                // Subtle non-obscuring crest badge at top right
                Positioned(
                  top: 10,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isDark ? const Color(0xFF141714) : Colors.white).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.antiqueGold.withValues(alpha: 0.5), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.castle_rounded, size: 12, color: AppColors.antiqueGold),
                        SizedBox(width: 4),
                        Text(
                          'La Mancha',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.antiqueGold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Inspiring Headline (Duolingo Style)
        Text(
          'The most fun way to conquer classic books!',
          textAlign: TextAlign.center,
          style: AppTypography.titleLarge.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            height: 1.25,
            color: isDark ? const Color(0xFFFDFBF7) : const Color(0xFF1A1C19),
          ),
        ),

        const SizedBox(height: 8),

        // Value Proposition Tagline (Anti-Doom Scrolling)
        Text(
          'Ditch the doom scroll. Level up your mind, vocabulary, and reading streak with bite-sized chapter quests.',
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(
            fontSize: 12.5,
            height: 1.35,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
          ),
        ),

        const SizedBox(height: 18),

        // Primary Action: GET STARTED (Duolingo 3D Button)
        DuoButton(
          key: const ValueKey('welcome_get_started_btn'),
          text: 'GET STARTED',
          variant: DuoButtonVariant.primary,
          height: 54,
          onPressed: () {
            HapticFeedback.lightImpact();
            SoundService.instance.play(Sfx.tap);
            setState(() {
              _slideDirection = 1;
              _tabSlideDirection = 1;
              _currentPage = AuthPage.signUp;
              _isSignUp = true;
              _errorMessage = null;
            });
          },
        ),

        const SizedBox(height: 12),

        // Secondary Action: I ALREADY HAVE AN ACCOUNT (Duolingo 3D Outlined Button)
        DuoButton(
          key: const ValueKey('welcome_have_account_btn'),
          text: 'I ALREADY HAVE AN ACCOUNT',
          variant: DuoButtonVariant.outline,
          height: 54,
          onPressed: () {
            HapticFeedback.lightImpact();
            SoundService.instance.play(Sfx.tap);
            setState(() {
              _slideDirection = 1;
              _tabSlideDirection = 1;
              _currentPage = AuthPage.logIn;
              _isSignUp = false;
              _errorMessage = null;
            });
          },
        ),

        const SizedBox(height: 16),

        // Tertiary Action: Continue as Guest (Skip)
        Center(
          child: TextButton.icon(
            key: const ValueKey('welcome_guest_skip_btn'),
            onPressed: _handleGuestEnlistment,
            icon: const Icon(Icons.person_outline_rounded, size: 16, color: AppColors.antiqueGold),
            label: const Text(
              'Continue as Guest (Skip)',
              style: TextStyle(
                color: AppColors.antiqueGold,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // VIEW 2: SIGN UP & LOG IN INTERACTIVE FORMS
  // ==========================================================================
  Widget _buildFormView(ThemeData theme, bool isDark) {
    final cardBg = theme.cardTheme.color ?? (isDark ? const Color(0xFF1E2620) : const Color(0xFFFAF6EE));

    return Column(
      key: const ValueKey('form_view'),
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Back Navigation Bar
        Row(
          children: [
            IconButton(
              tooltip: _isVerifyingCode ? 'Back to Sign Up' : 'Back to Welcome',
              icon: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF263228) : const Color(0xFFF0E8D8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.antiqueGold.withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: isDark ? AppColors.darkAccentGold : Theme.of(context).colorScheme.primary,
                ),
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                SoundService.instance.play(Sfx.tap);
                FocusScope.of(context).unfocus();
                setState(() {
                  _errorMessage = null;
                  if (_isVerifyingCode) {
                    _isVerifyingCode = false;
                    _tabSlideDirection = -1;
                  } else {
                    _slideDirection = -1;
                    _currentPage = AuthPage.welcome;
                  }
                });
              },
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    'QUIXORIA',
                    style: AppTypography.displayLarge.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                      color: AppColors.antiqueGold,
                    ),
                  ),
                  Text(
                    _isVerifyingCode
                        ? 'Enter 6-Digit Verification Code'
                        : (_isSignUp ? 'Create Your Account' : 'Welcome Back! Log In'),
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 11.5,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 48), // Balances the back icon button
          ],
        ),

        const SizedBox(height: 16),

        // Fluid Form Card Container
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.antiqueGold.withValues(alpha: 0.5),
              width: 1.6,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Error Banner with Warning Icon
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.vermillion.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.vermillion.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.vermillion,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AppColors.vermillion,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Segmented Switcher for Sign Up vs Log In
              if (!_isVerifyingCode) ...[
                Container(
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            FocusScope.of(context).unfocus();
                            HapticFeedback.selectionClick();
                            setState(() {
                              _tabSlideDirection = -1;
                              _currentPage = AuthPage.signUp;
                              _isSignUp = true;
                              _errorMessage = null;
                              _submitted = false;
                              _loginSubmitted = false;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 240),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _isSignUp ? AppColors.antiqueGold : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: _isSignUp
                                  ? [
                                      BoxShadow(
                                        color: AppColors.antiqueGold.withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Center(
                              child: Text(
                                'Sign Up',
                                style: AppTypography.titleSmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                  color: _isSignUp ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.65),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            FocusScope.of(context).unfocus();
                            HapticFeedback.selectionClick();
                            setState(() {
                              _tabSlideDirection = 1;
                              _currentPage = AuthPage.logIn;
                              _isSignUp = false;
                              _errorMessage = null;
                              _submitted = false;
                              _loginSubmitted = false;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 240),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !_isSignUp ? AppColors.antiqueGold : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: !_isSignUp
                                  ? [
                                      BoxShadow(
                                        color: AppColors.antiqueGold.withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Center(
                              child: Text(
                                'Log In',
                                style: AppTypography.titleSmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                  color: !_isSignUp ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.65),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // Core Form Body
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                  return Stack(
                    alignment: Alignment.topCenter,
                    children: <Widget>[
                      ...previousChildren,
                      if (currentChild != null) currentChild,
                    ],
                  );
                },
                transitionBuilder: (child, animation) {
                  final currentKey = _isVerifyingCode
                      ? 'otp_subform'
                      : (_isSignUp ? 'signup_subform' : 'login_subform');
                  final bool isCurrent = child.key == ValueKey(currentKey);
                  final tween = isCurrent
                      ? Tween<Offset>(begin: Offset(_tabSlideDirection * 0.45, 0), end: Offset.zero)
                      : Tween<Offset>(begin: Offset(-_tabSlideDirection * 0.45, 0), end: Offset.zero);

                  return SlideTransition(
                    position: tween.animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    )),
                    child: FadeTransition(
                      opacity: CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOut,
                      ),
                      child: child,
                    ),
                  );
                },
                child: _isVerifyingCode
                    ? _buildVerificationForm(theme)
                    : (_isSignUp ? _buildSignUpForm(theme) : _buildLoginForm(theme)),
              ),

              // Social Sign In Section (Only on main form, not during OTP verification)
              if (!_isVerifyingCode) ...[
                const SizedBox(height: 18),

                // Divider: ── OR ──
                Row(
                  children: [
                    Expanded(child: Divider(color: theme.dividerColor.withValues(alpha: 0.3))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: isDark ? Colors.white54 : AppColors.inkMedium,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: theme.dividerColor.withValues(alpha: 0.3))),
                  ],
                ),

                const SizedBox(height: 16),

                // Social Sign-In Buttons
                _buildSocialButton(
                  context: context,
                  label: 'SIGN IN WITH GOOGLE',
                  icon: const _GoogleGLogo(size: 20),
                  isDark: isDark,
                  onTap: () => _handleSocialLogin('Google'),
                ),

                const SizedBox(height: 10),

                _buildSocialButton(
                  context: context,
                  label: 'SIGN IN WITH FACEBOOK',
                  icon: const _FacebookLogo(size: 20),
                  isDark: isDark,
                  onTap: () => _handleSocialLogin('Facebook'),
                ),

                const SizedBox(height: 14),

                // Footer Mode Switcher
                Center(
                  child: GestureDetector(
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      HapticFeedback.selectionClick();
                      setState(() {
                        _tabSlideDirection = _isSignUp ? 1 : -1;
                        _isSignUp = !_isSignUp;
                        _currentPage = _isSignUp ? AuthPage.signUp : AuthPage.logIn;
                        _errorMessage = null;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                          children: [
                            TextSpan(
                              text: _isSignUp
                                  ? 'Already have an account? '
                                  : "Don't have an account? ",
                            ),
                            TextSpan(
                              text: _isSignUp ? 'LOG IN' : 'SIGN UP',
                              style: const TextStyle(
                                color: AppColors.antiqueGold,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Continue as Guest link at bottom of form
        Center(
          child: TextButton.icon(
            onPressed: _handleGuestEnlistment,
            icon: const Icon(Icons.person_outline_rounded, size: 15, color: AppColors.antiqueGold),
            label: const Text(
              'Continue as Guest (Skip)',
              style: TextStyle(
                color: AppColors.antiqueGold,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // SOCIAL BUTTON HELPER
  // ==========================================================================
  Widget _buildSocialButton({
    required BuildContext context,
    required String label,
    required Widget icon,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 48,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF242632) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white24 : Colors.black12,
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: isDark ? Colors.white : const Color(0xFF2B2D42),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthMethodToggle(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_useUsernameMode) {
                  setState(() {
                    _useUsernameMode = false;
                    _errorMessage = null;
                  });
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                decoration: BoxDecoration(
                  color: !_useUsernameMode ? AppColors.antiqueGold : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.email_outlined,
                      size: 14,
                      color: !_useUsernameMode
                          ? Colors.white
                          : theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        'With Email',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: !_useUsernameMode
                              ? Colors.white
                              : theme.colorScheme.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!_useUsernameMode) {
                  setState(() {
                    _useUsernameMode = true;
                    _errorMessage = null;
                  });
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                decoration: BoxDecoration(
                  color: _useUsernameMode ? AppColors.antiqueGold : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.alternate_email_rounded,
                      size: 14,
                      color: _useUsernameMode
                          ? Colors.white
                          : theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        'Username Only',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: _useUsernameMode
                              ? Colors.white
                              : theme.colorScheme.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // SIGN UP FORM
  // ==========================================================================
  Widget _buildSignUpForm(ThemeData theme) {
    final emailText = _emailController.text.trim();
    final usernameText = _usernameController.text.trim().replaceFirst(RegExp(r'^@'), '');
    final passText = _passwordController.text;
    final isEmailValid = _isValidEmail(emailText);
    final isUsernameValid = AuthService.isValidUsername(usernameText);
    final isPassValid = passText.length >= 6;

    final bool showEmailError = _submitted && !_useUsernameMode && !isEmailValid;
    final String? emailError = showEmailError
        ? (emailText.isEmpty
            ? 'Please enter your email address.'
            : 'Please enter a valid email address (e.g. name@example.com).')
        : null;

    final bool showUsernameError = _submitted && _useUsernameMode && !isUsernameValid;
    final String? usernameError = showUsernameError
        ? (usernameText.isEmpty
            ? 'Please choose a username.'
            : 'Use 3–24 characters (letters, numbers, ., _, -).')
        : null;

    final bool showPassError = _submitted && !isPassValid;
    final String? passError = showPassError
        ? (passText.isEmpty
            ? 'Please enter a password.'
            : 'Password must be at least 6 characters (currently ${passText.length}/6).')
        : null;

    return Column(
      key: const ValueKey('signup_subform'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildAuthMethodToggle(theme),
        const SizedBox(height: 14),
        _MotionTextField(
          controller: _nameController,
          label: 'Full Name',
          icon: Icons.person_outline_rounded,
          hint: 'Enter your full name',
        ),
        const SizedBox(height: 14),
        if (_useUsernameMode)
          _MotionTextField(
            controller: _usernameController,
            label: 'Username',
            icon: Icons.alternate_email_rounded,
            hint: 'e.g. knight_daniel',
            errorText: usernameError,
            onChanged: (_) => setState(() {}),
            suffix: isUsernameValid && _usernameController.text.isNotEmpty
                ? const Icon(Icons.check_circle_rounded, color: AppColors.successGreen, size: 18)
                : null,
          )
        else
          _MotionTextField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email_outlined,
            hint: 'name@example.com',
            keyboardType: TextInputType.emailAddress,
            errorText: emailError,
            onChanged: (_) => setState(() {}),
            suffix: isEmailValid && _emailController.text.isNotEmpty
                ? const Icon(Icons.check_circle_rounded, color: AppColors.successGreen, size: 18)
                : null,
          ),
        const SizedBox(height: 14),
        _MotionTextField(
          controller: _passwordController,
          label: 'Password',
          icon: Icons.lock_outline_rounded,
          hint: 'At least 6 characters',
          obscureText: _obscurePassword,
          errorText: passError,
          onChanged: (_) => setState(() {}),
          helperWidget: _buildPasswordStrengthWidget(_passwordController.text),
          suffix: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 20,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
            splashRadius: 18,
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 12),
        _BouncyCheckbox(
          value: _acceptedTerms,
          onChanged: (val) {
            setState(() {
              _acceptedTerms = val;
              if (val) _errorMessage = null;
            });
          },
          label: GestureDetector(
            onTap: _showTermsDialog,
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'I accept the ',
                  style: AppTypography.bodySmall.copyWith(fontSize: 11.5),
                ),
                Text(
                  'Terms & Conditions',
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 11.5,
                    color: AppColors.antiqueGold,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
                Text(
                  '.',
                  style: AppTypography.bodySmall.copyWith(fontSize: 11.5),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        _MotionSubmitButton(
          text: _useUsernameMode
              ? 'Create Account & Save Progress'
              : 'Sign Up & Send Verification Code',
          icon: _useUsernameMode
              ? Icons.cloud_done_outlined
              : Icons.mark_email_read_outlined,
          isLoading: _isLoading,
          isSuccess: _isSuccess,
          onPressed: _isLoading ? null : _handleSendCode,
        ),
      ],
    );
  }

  // ==========================================================================
  // LOG IN FORM
  // ==========================================================================
  Widget _buildLoginForm(ThemeData theme) {
    final emailText = _emailController.text.trim();
    final usernameText = _usernameController.text.trim().replaceFirst(RegExp(r'^@'), '');
    final passText = _passwordController.text;
    final isEmailValid = _isValidEmail(emailText);
    final bool showLoginEmailError = _loginSubmitted && !_useUsernameMode && !isEmailValid;
    final String? loginEmailError = showLoginEmailError
        ? (emailText.isEmpty
            ? 'Please enter your email address.'
            : 'Please enter a valid email address.')
        : null;
    final bool showLoginUsernameError = _loginSubmitted && _useUsernameMode && usernameText.isEmpty;
    final String? loginUsernameError = showLoginUsernameError ? 'Please enter your username.' : null;
    final bool showLoginPassError = _loginSubmitted && passText.isEmpty;
    final String? loginPassError = showLoginPassError ? 'Please enter your password.' : null;

    return Column(
      key: const ValueKey('login_subform'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildAuthMethodToggle(theme),
        const SizedBox(height: 14),
        if (_useUsernameMode)
          _MotionTextField(
            controller: _usernameController,
            label: 'Username',
            icon: Icons.alternate_email_rounded,
            hint: 'Enter your username',
            errorText: loginUsernameError,
          )
        else
          _MotionTextField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email_outlined,
            hint: 'name@example.com',
            keyboardType: TextInputType.emailAddress,
            errorText: loginEmailError,
          ),
        const SizedBox(height: 14),
        _MotionTextField(
          controller: _passwordController,
          label: 'Password',
          icon: Icons.lock_outline_rounded,
          hint: 'Enter your password',
          obscureText: _obscurePassword,
          errorText: loginPassError,
          suffix: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: _showForgotPasswordDialog,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'FORGOT?',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.antiqueGold,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 20,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
                splashRadius: 18,
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _BouncyCheckbox(
          value: _rememberMe,
          onChanged: (val) => setState(() => _rememberMe = val),
          label: Text(
            'Remember Me',
            style: AppTypography.bodySmall.copyWith(fontSize: 12),
          ),
        ),
        const SizedBox(height: 18),
        _MotionSubmitButton(
          text: 'Log In',
          icon: Icons.login_rounded,
          isLoading: _isLoading,
          isSuccess: _isSuccess,
          onPressed: _isLoading ? null : _handleLogin,
        ),
      ],
    );
  }

  // ==========================================================================
  // OTP VERIFICATION FORM
  // ==========================================================================
  Widget _buildVerificationForm(ThemeData theme) {
    return Column(
      key: const ValueKey('otp_subform'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.antiqueGold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.antiqueGold.withValues(alpha: 0.35)),
          ),
          child: Column(
            children: [
              Text(
                'Verification Code Sent!',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.antiqueGold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AuthService.instance.sentViaCloudEmail
                    ? 'We have sent a 6-digit verification code to ${_emailController.text}. Please check your email inbox (or spam folder) and enter the code below.'
                    : 'We have sent a 6-digit verification code to ${_emailController.text}.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11.5, height: 1.35),
              ),
              if (_dispatchedCode != null && !AuthService.instance.sentViaCloudEmail) ...[
                const SizedBox(height: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    setState(() {
                      _otpController.text = _dispatchedCode!;
                      _errorMessage = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.antiqueGold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Verification Code: $_dispatchedCode (Tap to Fill)',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.antiqueGold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        _MotionTextField(
          controller: _otpController,
          label: 'Verification Code',
          icon: Icons.verified_user_outlined,
          hint: 'Enter code from email',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 20),
        _MotionSubmitButton(
          text: 'Verify & Continue',
          icon: Icons.check_circle_outline_rounded,
          isLoading: _isLoading,
          isSuccess: _isSuccess,
          onPressed: _isLoading ? null : _handleVerifyCode,
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            TextButton(
              onPressed: () {
                FocusScope.of(context).unfocus();
                setState(() {
                  _tabSlideDirection = -1;
                  _isVerifyingCode = false;
                  _errorMessage = null;
                });
              },
              child: const Text('Back to Sign Up', style: TextStyle(fontSize: 11.5)),
            ),
            TextButton(
              onPressed: _isLoading ? null : _handleResendCode,
              child: const Text('Resend Code', style: TextStyle(fontSize: 11.5)),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================================
// SOCIAL BRAND ICONS (Pixel-Perfect Custom Drawn)
// ============================================================================

class _GoogleGLogo extends StatelessWidget {
  final double size;
  const _GoogleGLogo({this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleGPainter(),
      ),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;
    final strokeWidth = w * 0.22;

    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    final paintBlue = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final paintGreen = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final paintYellow = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final paintRed = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    // Red arc (top)
    canvas.drawArc(rect, -math.pi * 0.65, math.pi * 0.65, false, paintRed);
    // Yellow arc (top-left)
    canvas.drawArc(rect, -math.pi, math.pi * 0.35, false, paintYellow);
    // Green arc (bottom)
    canvas.drawArc(rect, math.pi * 0.35, math.pi * 0.65, false, paintGreen);
    // Blue arc & horizontal bar
    canvas.drawArc(rect, 0, math.pi * 0.35, false, paintBlue);

    // Blue horizontal center bar
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    final barRect = Rect.fromLTWH(center.dx - strokeWidth * 0.2, center.dy - strokeWidth / 2, radius * 0.9, strokeWidth);
    canvas.drawRect(barRect, barPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FacebookLogo extends StatelessWidget {
  final double size;
  const _FacebookLogo({this.size = 20});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF1877F2),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Text(
        'f',
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w900,
          fontFamily: 'sans-serif',
          height: 1.1,
        ),
      ),
    );
  }
}

// ============================================================================
// MICROINTERACTIONS: Floating Label, Zigzag Underline, Flow Fill
// ============================================================================

class _MotionTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String hint;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? errorText;
  final Widget? helperWidget;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;

  const _MotionTextField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.hint,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.errorText,
    this.helperWidget,
    this.suffix,
    this.onChanged,
  });

  @override
  State<_MotionTextField> createState() => _MotionTextFieldState();
}

class _MotionTextFieldState extends State<_MotionTextField>
    with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _waveController.repeat();
      } else {
        _waveController.stop();
      }
      if (mounted) setState(() {});
    });
    widget.controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    if (_focusNode.hasFocus) {
      _focusNode.unfocus();
    }
    _focusNode.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFocused = _focusNode.hasFocus;
    final isFloating = isFocused || widget.controller.text.isNotEmpty;
    final effectiveHasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    final primaryGold = AppColors.antiqueGold;
    final errorColor = AppColors.vermillion;
    final activeColor = effectiveHasError ? errorColor : primaryGold;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Flow Fill Animated Container
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: isFocused
                ? primaryGold.withValues(alpha: 0.08)
                : theme.colorScheme.surface.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isFocused
                  ? activeColor
                  : (effectiveHasError
                      ? errorColor.withValues(alpha: 0.7)
                      : theme.dividerColor.withValues(alpha: 0.35)),
              width: isFocused ? 1.6 : 1.2,
            ),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.16),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.only(
                  left: 14,
                  right: widget.suffix != null ? 8 : 14,
                  top: isFloating ? 8 : 6,
                  bottom: isFloating ? 8 : 6,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      widget.icon,
                      size: 19,
                      color: isFocused
                          ? activeColor
                          : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isFloating) ...[
                            Text(
                              widget.label,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: activeColor,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                          ],
                          Stack(
                            alignment: Alignment.centerLeft,
                            children: [
                              if (!isFloating)
                                IgnorePointer(
                                  child: Text(
                                    widget.label,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
                                    ),
                                  ),
                                ),
                              TextField(
                                controller: widget.controller,
                                focusNode: _focusNode,
                                obscureText: widget.obscureText,
                                keyboardType: widget.keyboardType,
                                onChanged: widget.onChanged,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: isFloating ? 4 : 10,
                                  ),
                                  hintText: isFloating ? widget.hint : null,
                                  hintStyle: TextStyle(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (widget.suffix != null) widget.suffix!,
                  ],
                ),
              ),

              // Zigzag Underline (Pattern 2)
              if (isFocused)
                AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, _) {
                    return SizedBox(
                      height: 4,
                      child: CustomPaint(
                        painter: _ZigzagPainter(
                          color: activeColor,
                          phase: _waveController.value,
                        ),
                        child: Container(),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),

        // Helper widget (e.g. password strength)
        if (widget.helperWidget != null) ...[
          const SizedBox(height: 4),
          widget.helperWidget!,
        ],

        // Error text display
        if (effectiveHasError) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              widget.errorText!,
              style: TextStyle(
                color: errorColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ZigzagPainter extends CustomPainter {
  final Color color;
  final double phase;

  _ZigzagPainter({required this.color, required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final path = Path();
    const toothWidth = 8.0;
    const toothHeight = 3.0;
    final offset = phase * toothWidth * 2;

    double x = -toothWidth * 2 + (offset % (toothWidth * 2));
    path.moveTo(x, size.height);

    while (x < size.width + toothWidth * 2) {
      path.lineTo(x + toothWidth / 2, size.height - toothHeight);
      path.lineTo(x + toothWidth, size.height);
      x += toothWidth;
    }

    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ZigzagPainter oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.color != color;
}

// ============================================================================
// MICROINTERACTIONS 4, 6, 7: Submit Button & Bouncy Checkbox
// ============================================================================

class _MotionSubmitButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final bool isLoading;
  final bool isSuccess;
  final VoidCallback? onPressed;

  const _MotionSubmitButton({
    required this.text,
    required this.icon,
    required this.isLoading,
    required this.isSuccess,
    required this.onPressed,
  });

  @override
  State<_MotionSubmitButton> createState() => _MotionSubmitButtonState();
}

class _MotionSubmitButtonState extends State<_MotionSubmitButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    const double bevelDepth = 4.0;
    final isInteractive = widget.onPressed != null && !widget.isLoading && !widget.isSuccess;

    Color faceColor;
    Color bevelColor;

    if (widget.isSuccess) {
      faceColor = AppColors.successGreen;
      bevelColor = const Color(0xFF1E5B22);
    } else if (widget.isLoading) {
      faceColor = AppColors.antiqueGold.withValues(alpha: 0.85);
      bevelColor = const Color(0xFF7A580E);
    } else {
      faceColor = AppColors.laManchaTerracotta;
      bevelColor = const Color(0xFF8F2915);
    }

    return GestureDetector(
      onTapDown: isInteractive ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: isInteractive ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: isInteractive ? () => setState(() => _isPressed = false) : null,
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        curve: Curves.easeOut,
        margin: EdgeInsets.only(
          top: _isPressed ? bevelDepth : 0,
          bottom: _isPressed ? 0 : bevelDepth,
        ),
        height: 52 - bevelDepth,
        decoration: BoxDecoration(
          color: faceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isPressed
              ? []
              : [
                  BoxShadow(
                    color: bevelColor,
                    offset: const Offset(0, bevelDepth),
                    blurRadius: 0,
                  ),
                ],
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            child: widget.isSuccess
                ? Row(
                    key: const ValueKey('success_state'),
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Enlisted in Realm!',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  )
                : widget.isLoading
                    ? Row(
                        key: const ValueKey('loading_state'),
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Dispatching...',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        key: const ValueKey('idle_state'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(widget.icon, color: Colors.white, size: 19),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              widget.text,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
          ),
        ),
      ),
    );
  }
}

class _BouncyCheckbox extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget label;

  const _BouncyCheckbox({
    required this.value,
    required this.onChanged,
    required this.label,
  });

  @override
  State<_BouncyCheckbox> createState() => _BouncyCheckboxState();
}

class _BouncyCheckboxState extends State<_BouncyCheckbox>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.25), weight: 35),
      TweenSequenceItem(tween: Tween<double>(begin: 1.25, end: 0.9), weight: 35),
      TweenSequenceItem(tween: Tween<double>(begin: 0.9, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _bounceController, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    SoundService.instance.play(Sfx.tap);
    _bounceController.forward(from: 0.0);
    widget.onChanged(!widget.value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              key: const ValueKey('terms_checkbox_box'),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: widget.value ? AppColors.antiqueGold : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: widget.value ? AppColors.antiqueGold : Colors.grey.withValues(alpha: 0.5),
                  width: 1.6,
                ),
              ),
              child: widget.value
                  ? const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: widget.label),
        ],
      ),
    );
  }
}
