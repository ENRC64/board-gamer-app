import 'package:material_ui/material_ui.dart';

/// Primärer Button mit eingebautem Ladezustand.
class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.outlined = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Widget child = isLoading
        ? SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: outlined ? scheme.primary : scheme.onPrimary,
            ),
          )
        : Text(label);
    final callback = isLoading ? null : onPressed;

    if (outlined) {
      return icon == null || isLoading
          ? OutlinedButton(onPressed: callback, child: child)
          : OutlinedButton.icon(
              onPressed: callback,
              icon: Icon(icon),
              label: child,
            );
    }
    return icon == null || isLoading
        ? FilledButton(onPressed: callback, child: child)
        : FilledButton.icon(
            onPressed: callback,
            icon: Icon(icon),
            label: child,
          );
  }
}
