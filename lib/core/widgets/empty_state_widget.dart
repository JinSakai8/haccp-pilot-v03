import 'package:flutter/material.dart';
import '../constants/design_tokens.dart';

class HaccpEmptyState extends StatelessWidget {
  final String headline;
  final String subtext;
  final String? buttonLabel;
  final VoidCallback? onButtonPressed;
  final IconData icon;

  const HaccpEmptyState({
    super.key,
    this.headline = 'Brak danych',
    this.subtext = 'Nie znaleziono żadnych wpisów.',
    this.buttonLabel,
    this.onButtonPressed,
    this.icon = Icons.inbox,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.white24),
            const SizedBox(height: 24),
            Text(
              headline,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtext,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white54,
                  ),
              textAlign: TextAlign.center,
            ),
            if (buttonLabel != null && onButtonPressed != null) ...[
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: onButtonPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: HaccpDesignTokens.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: Text(buttonLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
