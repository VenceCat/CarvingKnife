import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../services/supabase_service.dart';
import '../ui/app_surfaces.dart';
import '../ui/app_tokens.dart';
import '../ui/app_visuals.dart';

enum _AccountMode { signIn, signUp }

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _signInEmailController = TextEditingController();
  final _signInPasswordController = TextEditingController();
  final _signUpNameController = TextEditingController();
  final _signUpEmailController = TextEditingController();
  final _signUpPasswordController = TextEditingController();
  final _signUpConfirmPasswordController = TextEditingController();
  final _profileNameController = TextEditingController();

  _AccountMode _mode = _AccountMode.signIn;
  bool _isSubmitting = false;
  bool _isUpdatingProfile = false;
  String? _seededUserId;

  @override
  void dispose() {
    _signInEmailController.dispose();
    _signInPasswordController.dispose();
    _signUpNameController.dispose();
    _signUpEmailController.dispose();
    _signUpPasswordController.dispose();
    _signUpConfirmPasswordController.dispose();
    _profileNameController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _signInEmailController.text.trim();
    final password = _signInPasswordController.text;
    if (email.isEmpty || password.isEmpty) {
      _showMessage(
        '\u8bf7\u8f93\u5165\u90ae\u7bb1\u548c\u5bc6\u7801\u3002',
        icon: Icons.info_outline,
        backgroundColor: Colors.orange,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await AuthService.signIn(email: email, password: password);
      _showMessage(
        '\u767b\u5f55\u6210\u529f\u3002',
        icon: Icons.check_circle_outline,
        backgroundColor: Colors.green,
      );
    } on AuthException catch (error) {
      _showMessage(
        AuthService.readableMessage(error),
        icon: Icons.error_outline,
        backgroundColor: Colors.redAccent,
      );
    } catch (error) {
      _showMessage(
        AuthService.readableMessage(error),
        icon: Icons.error_outline,
        backgroundColor: Colors.redAccent,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _signUp() async {
    final displayName = _signUpNameController.text.trim();
    final email = _signUpEmailController.text.trim();
    final password = _signUpPasswordController.text;
    final confirmPassword = _signUpConfirmPasswordController.text;

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showMessage(
        '\u8bf7\u5b8c\u6574\u586b\u5199\u5fc5\u586b\u4fe1\u606f\u3002',
        icon: Icons.info_outline,
        backgroundColor: Colors.orange,
      );
      return;
    }
    if (password != confirmPassword) {
      _showMessage(
        '\u4e24\u6b21\u8f93\u5165\u7684\u5bc6\u7801\u4e0d\u4e00\u81f4\u3002',
        icon: Icons.error_outline,
        backgroundColor: Colors.redAccent,
      );
      return;
    }
    if (password.length < 6) {
      _showMessage(
        '\u5bc6\u7801\u81f3\u5c11\u9700\u8981 6 \u4f4d\u3002',
        icon: Icons.info_outline,
        backgroundColor: Colors.orange,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final response = await AuthService.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );
      final needsConfirmation = response.session == null;
      _showMessage(
        needsConfirmation
            ? '\u6ce8\u518c\u6210\u529f\uff0c\u8bf7\u67e5\u6536\u90ae\u7bb1\u5b8c\u6210\u9a8c\u8bc1\u3002'
            : '\u6ce8\u518c\u5e76\u767b\u5f55\u6210\u529f\u3002',
        icon: Icons.check_circle_outline,
        backgroundColor: Colors.green,
      );
      if (needsConfirmation) {
        setState(() {
          _mode = _AccountMode.signIn;
          _signInEmailController.text = email;
        });
      }
    } on AuthException catch (error) {
      _showMessage(
        AuthService.readableMessage(error),
        icon: Icons.error_outline,
        backgroundColor: Colors.redAccent,
      );
    } catch (error) {
      _showMessage(
        AuthService.readableMessage(error),
        icon: Icons.error_outline,
        backgroundColor: Colors.redAccent,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _signOut() async {
    setState(() => _isSubmitting = true);
    try {
      await AuthService.signOut();
      _showMessage(
        '\u5df2\u9000\u51fa\u767b\u5f55\u3002',
        icon: Icons.logout,
        backgroundColor: Colors.blueGrey,
      );
    } on AuthException catch (error) {
      _showMessage(
        AuthService.readableMessage(error),
        icon: Icons.error_outline,
        backgroundColor: Colors.redAccent,
      );
    } catch (error) {
      _showMessage(
        AuthService.readableMessage(error),
        icon: Icons.error_outline,
        backgroundColor: Colors.redAccent,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<bool> _updateDisplayName() async {
    final displayName = _profileNameController.text.trim();
    if (displayName.isEmpty) {
      _showMessage(
        '\u6635\u79f0\u4e0d\u80fd\u4e3a\u7a7a\u3002',
        icon: Icons.info_outline,
        backgroundColor: Colors.orange,
      );
      return false;
    }

    setState(() => _isUpdatingProfile = true);
    try {
      await AuthService.updateDisplayName(displayName);
      _showMessage(
        '\u6635\u79f0\u5df2\u66f4\u65b0\u3002',
        icon: Icons.check_circle_outline,
        backgroundColor: Colors.green,
      );
      return true;
    } on AuthException catch (error) {
      _showMessage(
        AuthService.readableMessage(error),
        icon: Icons.error_outline,
        backgroundColor: Colors.redAccent,
      );
      return false;
    } catch (error) {
      _showMessage(
        AuthService.readableMessage(error),
        icon: Icons.error_outline,
        backgroundColor: Colors.redAccent,
      );
      return false;
    } finally {
      if (mounted) {
        setState(() => _isUpdatingProfile = false);
      }
    }
  }

  Future<void> _showEditDisplayNameDialog(User user) async {
    _profileNameController.text = _displayNameOf(user);
    final themeColor = Theme.of(context).colorScheme.primary;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        var isSaving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;

            Future<void> submit() async {
              if (isSaving) return;
              setDialogState(() => isSaving = true);
              final success = await _updateDisplayName();
              if (ctx.mounted && success) {
                Navigator.pop(ctx);
              }
              if (ctx.mounted) {
                setDialogState(() => isSaving = false);
              }
            }

            return AppBottomSheetSurface(
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: themeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Icon(
                          Icons.edit_outlined,
                          color: themeColor,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        '\u4fee\u6539\u6635\u79f0',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\u4f60\u7684\u6635\u79f0\u4f1a\u7528\u4e8e\u4e2a\u4eba\u4e3b\u9875\u4e0e\u8d26\u6237\u4fe1\u606f\u5c55\u793a\u3002',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.badge_outlined,
                                  size: 18,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '\u65b0\u6635\u79f0',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildTextField(
                              controller: _profileNameController,
                              label: '\u8f93\u5165\u6635\u79f0',
                              prefixIcon: Icons.person_outline,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) {
                                submit();
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isSaving ? null : () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey[700],
                              ),
                              child: const Text('\u53d6\u6d88'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: isSaving ? null : submit,
                              icon: isSaving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.check_rounded, size: 18),
                              label: Text(isSaving ? '\u4fdd\u5b58\u4e2d...' : '\u4fdd\u5b58'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: themeColor,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: themeColor.withValues(alpha: 0.6),
                                disabledForegroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _resendVerification(User user) async {
    final email = user.email;
    if (email == null || email.isEmpty) {
      _showMessage(
        '\u5f53\u524d\u8d26\u6237\u6ca1\u6709\u90ae\u7bb1\u5730\u5740\u3002',
        icon: Icons.info_outline,
        backgroundColor: Colors.orange,
      );
      return;
    }

    try {
      await AuthService.resendSignupConfirmation(email);
      _showMessage(
        '\u9a8c\u8bc1\u90ae\u4ef6\u5df2\u91cd\u65b0\u53d1\u9001\u3002',
        icon: Icons.mark_email_read_outlined,
        backgroundColor: Colors.green,
      );
    } on AuthException catch (error) {
      _showMessage(
        AuthService.readableMessage(error),
        icon: Icons.error_outline,
        backgroundColor: Colors.redAccent,
      );
    } catch (error) {
      _showMessage(
        AuthService.readableMessage(error),
        icon: Icons.error_outline,
        backgroundColor: Colors.redAccent,
      );
    }
  }

  Future<void> _showResetPasswordDialog() async {
    final controller = TextEditingController(text: _signInEmailController.text.trim());
    final themeColor = Theme.of(context).colorScheme.primary;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
        return AppBottomSheetSurface(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomInset),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '\u91cd\u7f6e\u5bc6\u7801',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  '\u7cfb\u7edf\u4f1a\u5411\u8be5\u90ae\u7bb1\u53d1\u9001\u91cd\u7f6e\u5bc6\u7801\u94fe\u63a5\u3002',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.5),
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: controller,
                  label: '\u90ae\u7bb1',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final email = controller.text.trim();
                      if (email.isEmpty) {
                        _showMessage(
                          '\u8bf7\u8f93\u5165\u90ae\u7bb1\u3002',
                          icon: Icons.info_outline,
                          backgroundColor: Colors.orange,
                        );
                        return;
                      }

                      try {
                        await AuthService.sendPasswordReset(email);
                        if (!mounted) return;
                        Navigator.pop(ctx);
                        _showMessage(
                          '\u91cd\u7f6e\u90ae\u4ef6\u5df2\u53d1\u9001\uff0c\u8bf7\u68c0\u67e5\u90ae\u7bb1\u3002',
                          icon: Icons.mark_email_read_outlined,
                          backgroundColor: Colors.green,
                        );
                      } on AuthException catch (error) {
                        _showMessage(
                          AuthService.readableMessage(error),
                          icon: Icons.error_outline,
                          backgroundColor: Colors.redAccent,
                        );
                      } catch (error) {
                        _showMessage(
                          AuthService.readableMessage(error),
                          icon: Icons.error_outline,
                          backgroundColor: Colors.redAccent,
                        );
                      }
                    },
                    style: _buildPrimaryButtonStyle(color: themeColor),
                    child: const Text('\u53d1\u9001\u91cd\u7f6e\u90ae\u4ef6'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    controller.dispose();
  }

  void _seedProfile(User? user) {
    if (user == null) {
      _seededUserId = null;
      _profileNameController.clear();
      return;
    }

    if (_seededUserId == user.id) return;
    _seededUserId = user.id;
    _profileNameController.text = _displayNameOf(user);
  }

  String _displayNameOf(User user) {
    final value = user.userMetadata?['display_name'];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return user.email?.split('@').first ?? '\u7528\u6237';
  }

  void _showMessage(
    String message, {
    required IconData icon,
    required Color backgroundColor,
  }) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visuals = AppVisuals.resolve(context);

    return Scaffold(
      backgroundColor: visuals.pageBackgroundColor,
      extendBodyBehindAppBar: true,
      body: AppWallpaperBackground(
        visuals: visuals,
        child: Stack(
          children: [
            Positioned.fill(
              top: MediaQuery.of(context).padding.top + 60,
              child: StreamBuilder<User?>(
                stream: AuthService.authStateChanges,
                initialData: AuthService.currentUser,
                builder: (context, snapshot) {
                  final user = snapshot.data;
                  _seedProfile(user);

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                    children: [
                      if (!SupabaseService.isConfigured)
                        _buildConfigHintCard()
                      else if (SupabaseService.hasInitializationError)
                        _buildInitializationErrorCard()
                      else if (user == null)
                        _buildGuestContent()
                      else
                        _buildSignedInContent(user),
                    ],
                  );
                },
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AppPageTitleBar(
                title: '\u8d26\u6237',
                visuals: visuals,
                left: 16,
                leading: _buildBackButton(visuals),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigHintCard() {
    return AppGlassCard(
      radius: AppRadii.lg,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLeadingBadge(
            icon: Icons.cloud_off_outlined,
            color: Colors.orange,
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '\u8d26\u6237\u6682\u65f6\u4e0d\u53ef\u7528',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '\u5f53\u524d\u65e0\u6cd5\u8fde\u63a5\u8d26\u6237\u670d\u52a1\uff0c\u8bf7\u7a0d\u540e\u518d\u8bd5\u3002',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitializationErrorCard() {
    return AppGlassCard(
      radius: AppRadii.lg,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLeadingBadge(
            icon: Icons.error_outline,
            color: Colors.redAccent,
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '\u8d26\u6237\u6682\u65f6\u4e0d\u53ef\u7528',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '\u5f53\u524d\u65e0\u6cd5\u5b8c\u6210\u8d26\u6237\u521d\u59cb\u5316\uff0c\u8bf7\u7a0d\u540e\u518d\u8bd5\u3002',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestContent() {
    final themeColor = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppGlassCard(
          radius: AppRadii.lg,
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildLeadingBadge(
                    icon: Icons.shield_outlined,
                    color: themeColor,
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '\u7ba1\u7406\u4f60\u7684\u8d26\u6237',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: const [
                  _AccountFeatureChip(
                    icon: Icons.mark_email_read_outlined,
                    label: '\u90ae\u7bb1\u9a8c\u8bc1',
                  ),
                  _AccountFeatureChip(
                    icon: Icons.lock_reset_outlined,
                    label: '\u91cd\u7f6e\u5bc6\u7801',
                  ),
                  _AccountFeatureChip(
                    icon: Icons.badge_outlined,
                    label: '\u8d26\u6237\u8d44\u6599',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: _buildModeChip(
                label: '\u767b\u5f55',
                icon: Icons.login,
                isSelected: _mode == _AccountMode.signIn,
                onTap: () => setState(() => _mode = _AccountMode.signIn),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildModeChip(
                label: '\u6ce8\u518c',
                icon: Icons.person_add_alt_1,
                isSelected: _mode == _AccountMode.signUp,
                onTap: () => setState(() => _mode = _AccountMode.signUp),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        AppGlassCard(
          radius: AppRadii.lg,
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _mode == _AccountMode.signIn
                    ? '\u767b\u5f55\u8d26\u6237'
                    : '\u521b\u5efa\u8d26\u6237',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (_mode == _AccountMode.signUp) ...[
                _buildTextField(
                  controller: _signUpNameController,
                  label: '\u6635\u79f0\uff08\u53ef\u9009\uff09',
                  prefixIcon: Icons.badge_outlined,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              _buildTextField(
                controller: _mode == _AccountMode.signIn
                    ? _signInEmailController
                    : _signUpEmailController,
                label: '\u90ae\u7bb1',
                prefixIcon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.md),
              _buildTextField(
                controller: _mode == _AccountMode.signIn
                    ? _signInPasswordController
                    : _signUpPasswordController,
                label: '\u5bc6\u7801',
                prefixIcon: Icons.lock_outline,
                obscureText: true,
                textInputAction: _mode == _AccountMode.signIn
                    ? TextInputAction.done
                    : TextInputAction.next,
                onSubmitted: (_) {
                  if (_mode == _AccountMode.signIn) {
                    _signIn();
                  }
                },
              ),
              if (_mode == _AccountMode.signUp) ...[
                const SizedBox(height: AppSpacing.md),
                _buildTextField(
                  controller: _signUpConfirmPasswordController,
                  label: '\u786e\u8ba4\u5bc6\u7801',
                  prefixIcon: Icons.lock_reset_outlined,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _signUp(),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : _mode == _AccountMode.signIn
                          ? _signIn
                          : _signUp,
                  style: _buildPrimaryButtonStyle(color: themeColor),
                  child: _isSubmitting
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _mode == _AccountMode.signIn
                              ? '\u767b\u5f55'
                              : '\u6ce8\u518c',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              if (_mode == _AccountMode.signIn) ...[
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _showResetPasswordDialog,
                    icon: const Icon(Icons.lock_reset_outlined, size: 18),
                    label: const Text('\u5fd8\u8bb0\u5bc6\u7801'),
                    style: TextButton.styleFrom(
                      foregroundColor: themeColor,
                      backgroundColor: themeColor.withValues(alpha: 0.1),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSignedInContent(User user) {
    final isEmailConfirmed = user.emailConfirmedAt != null;
    final themeColor = Theme.of(context).colorScheme.primary;
    final emailText = user.email ?? '\u65e0\u90ae\u7bb1';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppGlassCard(
          radius: AppRadii.lg,
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          themeColor.withValues(alpha: 0.16),
                          themeColor.withValues(alpha: 0.3),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppRadii.xl),
                    ),
                    child: Center(
                      child: Text(
                        _displayNameOf(user).characters.first.toUpperCase(),
                        style: TextStyle(
                          color: themeColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 28,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: GestureDetector(
                      onTap: _isUpdatingProfile
                          ? null
                          : () => _showEditDisplayNameDialog(user),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: themeColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(AppRadii.lg),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.badge_outlined,
                              size: 18,
                              color: themeColor,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '\u6635\u79f0',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _displayNameOf(user),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: Colors.grey[500],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                ),
                child: Column(
                  children: [
                    _buildAccountInfoRow(
                      icon: Icons.mail_outline,
                      label: '\u90ae\u7bb1',
                      value: emailText,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildAccountInfoRow(
                      icon: isEmailConfirmed
                          ? Icons.verified_outlined
                          : Icons.mark_email_unread_outlined,
                      label: '\u9a8c\u8bc1\u72b6\u6001',
                      value: isEmailConfirmed
                          ? '\u5df2\u5b8c\u6210\u90ae\u7bb1\u9a8c\u8bc1'
                          : '\u672a\u5b8c\u6210\u90ae\u7bb1\u9a8c\u8bc1',
                      valueColor: isEmailConfirmed ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildAccountInfoRow(
                      icon: Icons.login_outlined,
                      label: '\u767b\u5f55\u65b9\u5f0f',
                      value: '\u90ae\u7bb1 + \u5bc6\u7801',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (!isEmailConfirmed) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _resendVerification(user),
                    icon: const Icon(Icons.mark_email_unread_outlined),
                    label: const Text('\u91cd\u65b0\u53d1\u9001\u9a8c\u8bc1\u90ae\u4ef6'),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _signOut,
                  icon: const Icon(Icons.logout),
                  label: const Text('\u9000\u51fa\u767b\u5f55'),
                  style: _buildPrimaryButtonStyle(
                    color: const Color(0xFFD32F2F),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.24),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: valueColor ?? Colors.grey[700]),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                  color: valueColor ?? Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModeChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final themeColor = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: AppGlassCard(
        radius: AppRadii.lg,
        isSelected: isSelected,
        selectedColor: themeColor,
        borderColor: isSelected
            ? themeColor.withValues(alpha: 0.35)
            : Colors.white.withValues(alpha: 0.2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? themeColor.withValues(alpha: 0.14)
                    : Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? themeColor : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? themeColor : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? prefixIcon,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
  }) {
    final visuals = AppVisuals.resolve(context);
    final themeColor = Theme.of(context).colorScheme.primary;

    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 20),
        filled: true,
        fillColor: visuals.useGlassEffect
            ? Colors.white.withValues(alpha: visuals.useWallpaper ? 0.18 : 0.5)
            : Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(
            color: Colors.grey.withValues(alpha: 0.22),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(
            color: Colors.grey.withValues(alpha: 0.22),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(
            color: themeColor.withValues(alpha: 0.7),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  ButtonStyle _buildPrimaryButtonStyle({
    required Color color,
  }) {
    final visuals = AppVisuals.resolve(context);

    final backgroundColor = visuals.useGlassEffect
        ? color.withValues(alpha: visuals.useWallpaper ? 0.74 : 0.9)
        : color;
    final disabledBackgroundColor = visuals.useGlassEffect
        ? color.withValues(alpha: visuals.useWallpaper ? 0.42 : 0.56)
        : color.withValues(alpha: 0.6);

    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: Colors.white,
      disabledBackgroundColor: disabledBackgroundColor,
      disabledForegroundColor: Colors.white,
    );
  }

  Widget _buildLeadingBadge({
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Icon(icon, size: 26, color: color),
    );
  }

  Widget _buildBackButton(AppVisuals visuals) {
    return InkWell(
      onTap: () => Navigator.pop(context),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: visuals.useGlassEffect
              ? Colors.white.withValues(alpha: visuals.useWallpaper ? 0.34 : 0.62)
              : visuals.useWallpaper
                  ? Colors.white.withValues(alpha: 0.92)
                  : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: visuals.useWallpaper ? 0.08 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.arrow_back_ios_new,
          size: 18,
          color: visuals.useWallpaper ? Colors.black87 : Colors.grey[600],
        ),
      ),
    );
  }
}

class _AccountFeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _AccountFeatureChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: themeColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: themeColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
