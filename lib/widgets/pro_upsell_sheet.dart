import 'package:flutter/material.dart';
import 'package:reeflynk/screens/paywall_screen.dart';
import 'package:reeflynk/theme/app_theme.dart';

void showProUpsellSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => const ProUpsellSheet(),
  );
}

class ProUpsellSheet extends StatelessWidget {
  const ProUpsellSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline, size: 40, color: AppColors.primary),
          const SizedBox(height: 12),
          Text('ReefLynk Pro', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Upgrade to Pro to save your data across sessions.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.mutedFg),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PaywallScreen()),
              );
            },
            child: const Text('Upgrade to Pro'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
        ],
      ),
    );
  }
}
