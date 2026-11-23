import 'package:board_gamer_app/core/utils/name_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/user_model.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/user_repository.dart';

/// Profil anzeigen und bearbeiten (Name, Adresse) sowie abmelden (A-02).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            tooltip: 'Abmelden',
            icon: const Icon(Icons.logout),
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: profile.when(
        loading: () => const LoadingIndicator(message: 'Profil wird geladen'),
        error: (e, _) => ErrorView(
          message: 'Profil konnte nicht geladen werden.',
          onRetry: () => ref.invalidate(currentUserProfileProvider),
        ),
        data: (user) {
          if (user == null) {
            final authUser = ref.watch(authStateProvider).value;
            return EmptyState(
              icon: Icons.person_off_outlined,
              title: 'Noch kein Profil vorhanden',
              message: 'Lege dein Profil an, um Termine ausrichten zu können.',
              actionLabel: 'Profil anlegen',
              onAction: authUser == null
                  ? null
                  : () => ref
                        .read(userRepositoryProvider)
                        .updateProfile(
                          uid: authUser.uid,
                          email: authUser.email ?? '',
                          displayName: authUser.displayName ?? '',
                          address: '',
                        ),
            );
          }
          return _ProfileForm(user: user);
        },
      ),
    );
  }
}

class _ProfileForm extends ConsumerStatefulWidget {
  const _ProfileForm({required this.user});

  final UserModel user;

  @override
  ConsumerState<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<_ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.user.displayName,
  );
  late final _addressController = TextEditingController(
    text: widget.user.address,
  );
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(userRepositoryProvider)
          .updateProfile(
            uid: widget.user.uid,
            email: widget.user.email,
            displayName: _nameController.text,
            address: _addressController.text,
          );
      messenger.showSnackBar(
        const SnackBar(content: Text('Profil gespeichert.')),
      );
    } on Exception {
      messenger.showSnackBar(
        const SnackBar(content: Text('Speichern fehlgeschlagen.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  foregroundColor: theme.colorScheme.onPrimaryContainer,
                  child: Text(initialsOf(widget.user.displayName)),
                ),
                title: Text(widget.user.displayName),
                subtitle: Text(widget.user.email),
              ),
            ),
            if (!widget.user.hasAddress) ...[
              const SizedBox(height: AppSpacing.md),
              Card(
                color: theme.colorScheme.tertiaryContainer,
                child: ListTile(
                  leading: Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                  title: Text(
                    'Ohne Adresse kannst du keinen Spieltermin ausrichten.',
                    style: TextStyle(
                      color: theme.colorScheme.onTertiaryContainer,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              key: const Key('profileNameField'),
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Anzeigename',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) => (v == null || v.trim().length < 2)
                  ? 'Bitte einen Namen mit mindestens 2 Zeichen eingeben.'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              key: const Key('profileAddressField'),
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Adresse (Straße, PLZ, Ort)',
                prefixIcon: Icon(Icons.home_outlined),
              ),
              maxLines: 2,
              minLines: 1,
            ),
            const SizedBox(height: AppSpacing.lg),
            CustomButton(
              key: const Key('profileSaveButton'),
              label: 'Speichern',
              icon: Icons.save_outlined,
              isLoading: _saving,
              onPressed: _save,
            ),
            const SizedBox(height: AppSpacing.md),
            CustomButton(
              label: 'Abmelden',
              icon: Icons.logout,
              outlined: true,
              onPressed: () =>
                  ref.read(authControllerProvider.notifier).signOut(),
            ),
          ],
        ),
      ),
    );
  }
}
