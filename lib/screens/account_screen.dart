import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zalonidentalhub/models/user_model.dart';
import 'package:zalonidentalhub/providers/authprovider.dart';

class AccountScreen extends ConsumerWidget {
  static const routeName = '/account';

  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Selective rebuild: only rebuild when these specific fields change.
    final isLoading = ref.watch(authProvider.select((s) => s.isLoading));
    final isAuthenticated =
        ref.watch(authProvider.select((s) => s.isAuthenticated));
    final userModel = ref.watch(authProvider.select((s) => s.userModel));
    final errorMessage = ref.watch(authProvider.select((s) => s.errorMessage));
    final isEmailVerified =
        ref.watch(authProvider.select((s) => s.isEmailVerified));

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: isLoading && !isAuthenticated
          ? const Center(child: CircularProgressIndicator())
          : _AccountBody(
              isAuthenticated: isAuthenticated,
              userModel: userModel,
              errorMessage: errorMessage,
              isEmailVerified: isEmailVerified,
              isLoading: isLoading,
            ),
    );
  }
}

// ─── Body (stateless inner widget to keep rebuild scope tight) ────────────

class _AccountBody extends ConsumerWidget {
  final bool isAuthenticated;
  final UserModel? userModel;
  final String? errorMessage;
  final bool isEmailVerified;
  final bool isLoading;

  const _AccountBody({
    required this.isAuthenticated,
    required this.userModel,
    required this.errorMessage,
    required this.isEmailVerified,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Error banner
          if (errorMessage != null) ...[
            _ErrorBanner(
              message: errorMessage!,
              onDismiss: () => ref.read(authProvider.notifier).clearError(),
            ),
            const SizedBox(height: 12),
          ],

          // Profile header
          _ProfileHeader(
            isAuthenticated: isAuthenticated,
            userModel: userModel,
          ),
          const SizedBox(height: 20),

          if (!isAuthenticated) ...[
            _GuestActions(),
          ] else ...[
            // Email verification nudge
            if (!isEmailVerified) ...[
              _EmailVerificationBanner(),
              const SizedBox(height: 16),
            ],

            // Personal Info
            _SectionCard(
              title: 'Personal Information',
              icon: Icons.person_outlined,
              children: [
                _InfoTile(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: userModel?.email ?? '—',
                  semanticsLabel: 'Email address',
                ),
                _InfoTile(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: userModel?.phoneNumber ?? '—',
                  semanticsLabel: 'Phone number',
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showEditProfileSheet(context, ref),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit Profile'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Security
            _SectionCard(
              title: 'Security',
              icon: Icons.shield_outlined,
              children: [
                _ActionTile(
                  icon: Icons.lock_reset_outlined,
                  label: 'Reset Password',
                  subtitle: 'Send a reset link to your email',
                  onTap: () => _confirmPasswordReset(context, ref),
                ),
                _ActionTile(
                  icon: Icons.delete_forever_outlined,
                  label: 'Delete Account',
                  subtitle: 'Permanently remove your account and data',
                  isDestructive: true,
                  onTap: () => _showDeleteAccountDialog(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Preferences
            _SectionCard(
              title: 'Preferences',
              icon: Icons.tune_outlined,
              children: [
                _ActionTile(
                  icon: Icons.notifications_outlined,
                  label: 'Notification Settings',
                  subtitle: 'Manage push and email notifications',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Coming soon')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Support & Legal
            _SectionCard(
              title: 'Support & Legal',
              icon: Icons.help_outline,
              children: [
                _ActionTile(
                  icon: Icons.description_outlined,
                  label: 'Terms of Service',
                  onTap: () {},
                ),
                _ActionTile(
                  icon: Icons.privacy_tip_outlined,
                  label: 'Privacy Policy',
                  onTap: () {},
                ),
                _ActionTile(
                  icon: Icons.info_outline,
                  label: 'About Zaloni Dental Hub',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Logout
            FilledButton.tonalIcon(
              onPressed: isLoading
                  ? null
                  : () => _confirmLogout(context, ref),
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.logout),
              label: const Text('Log Out'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  // ─── Logout confirmation ─────────────────────────────────────

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logged out successfully')),
        );
      }
    }
  }

  // ─── Edit profile bottom sheet ───────────────────────────────

  void _showEditProfileSheet(BuildContext context, WidgetRef ref) {
    final user = userModel;
    if (user == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _EditProfileSheet(userModel: user),
    );
  }

  // ─── Password reset ──────────────────────────────────────────

  Future<void> _confirmPasswordReset(
      BuildContext context, WidgetRef ref) async {
    final email = userModel?.email;
    if (email == null || email.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password'),
        content: Text('Send a password reset link to $email?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Send Link'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success =
          await ref.read(authProvider.notifier).sendPasswordResetEmail(email);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Reset link sent to $email'
                : 'Failed to send reset link'),
          ),
        );
      }
    }
  }

  // ─── Delete account ──────────────────────────────────────────

  Future<void> _showDeleteAccountDialog(
      BuildContext context, WidgetRef ref) async {
    final passwordController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This action is permanent. All your data will be deleted and cannot be recovered.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Enter your password to confirm',
                prefixIcon: Icon(Icons.lock_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final password = passwordController.text.trim();
      if (password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password is required')),
        );
        return;
      }

      final success =
          await ref.read(authProvider.notifier).deleteAccount(password);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Account deleted'
                : 'Failed to delete account. Check your password.'),
          ),
        );
      }
    }

    passwordController.dispose();
  }
}

// ─── Reusable widgets ──────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _ErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return MaterialBanner(
      backgroundColor: colors.errorContainer,
      content: Text(
        message,
        style: TextStyle(color: colors.onErrorContainer),
      ),
      leading: Icon(Icons.error_outline, color: colors.error),
      actions: [
        TextButton(
          onPressed: onDismiss,
          child: const Text('Dismiss'),
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final bool isAuthenticated;
  final UserModel? userModel;

  const _ProfileHeader({
    required this.isAuthenticated,
    required this.userModel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      color: colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Semantics(
              label: isAuthenticated
                  ? 'Profile avatar for ${userModel?.fullName ?? "user"}'
                  : 'Guest avatar',
              child: CircleAvatar(
                radius: 32,
                backgroundColor: colors.primary,
                child: isAuthenticated && userModel != null
                    ? Text(
                        userModel!.initials,
                        style: textTheme.titleLarge?.copyWith(
                          color: colors.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : Icon(Icons.person, size: 32, color: colors.onPrimary),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAuthenticated && userModel != null
                        ? userModel!.fullName
                        : 'Welcome to Zaloni Dental Hub',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.onPrimaryContainer,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (isAuthenticated && userModel != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      userModel!.email,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onPrimaryContainer.withValues(alpha: 0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (!isAuthenticated) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Sign in to manage your account',
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onPrimaryContainer.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuestActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/loginScreen'),
          icon: const Icon(Icons.login),
          label: const Text('Log In'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/registerScreen'),
          icon: const Icon(Icons.person_add_outlined),
          label: const Text('Create Account'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
        const SizedBox(height: 24),
        _SectionCard(
          title: 'Support & Legal',
          icon: Icons.help_outline,
          children: [
            _ActionTile(
              icon: Icons.description_outlined,
              label: 'Terms of Service',
              onTap: () {},
            ),
            _ActionTile(
              icon: Icons.privacy_tip_outlined,
              label: 'Privacy Policy',
              onTap: () {},
            ),
            _ActionTile(
              icon: Icons.info_outline,
              label: 'About Zaloni Dental Hub',
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }
}

class _EmailVerificationBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final isLoading = ref.watch(authProvider.select((s) => s.isLoading));

    return Card(
      color: colors.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.mark_email_unread_outlined,
                color: colors.onTertiaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Verify your email to unlock all features.',
                style: TextStyle(color: colors.onTertiaryContainer),
              ),
            ),
            TextButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      final success = await ref
                          .read(authProvider.notifier)
                          .sendEmailVerification();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success
                                ? 'Verification email sent'
                                : 'Failed to send verification email'),
                          ),
                        );
                      }
                    },
              child: const Text('Verify'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? semanticsLabel;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      label: semanticsLabel ?? '$label: $value',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 20, color: colors.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: textTheme.labelSmall
                          ?.copyWith(color: colors.onSurfaceVariant)),
                  Text(value,
                      style: textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tileColor = isDestructive ? colors.error : colors.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 22, color: tileColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: tileColor)),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                size: 20, color: colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

// ─── Edit Profile Bottom Sheet ─────────────────────────────────────────────

class _EditProfileSheet extends ConsumerStatefulWidget {
  final UserModel userModel;

  const _EditProfileSheet({required this.userModel});

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _phoneCtrl;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _firstNameCtrl = TextEditingController(text: widget.userModel.firstName);
    _lastNameCtrl = TextEditingController(text: widget.userModel.lastName);
    _phoneCtrl = TextEditingController(text: widget.userModel.phoneNumber);
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).updateProfile(
          firstName: _firstNameCtrl.text.trim(),
          lastName: _lastNameCtrl.text.trim(),
          phoneNumber: _phoneCtrl.text.trim(),
        );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(success ? 'Profile updated' : 'Failed to update profile'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider.select((s) => s.isLoading));

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Edit Profile',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _firstNameCtrl,
              decoration: const InputDecoration(
                labelText: 'First Name',
                prefixIcon: Icon(Icons.person_outlined),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _lastNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Last Name',
                prefixIcon: Icon(Icons.person_outlined),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: isLoading ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
