import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  final String lemonSqueezyCheckoutUrl = 'https://jachin.lemonsqueezy.com/checkout/buy/e81b8c72-205b-4e60-a938-23864ed039a6';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ReefLynk Pro'),
        automaticallyImplyLeading: false, // Prevent back button
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.workspace_premium,
                size: 100,
                color: Colors.amber,
              ),
              const SizedBox(height: 32),
              const Text(
                'Unlock ReefLynk Pro Features',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Subscribe to get full access to real-time tracking, advanced controls, unlimited data, and all premium features.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(lemonSqueezyCheckoutUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not open checkout page.')),
                    );
                  }
                },
                icon: const Icon(Icons.shopping_cart),
                label: const Text(
                  'Upgrade to Pro',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50), // Full width button
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // TODO: Implement restore purchase logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Restore purchase not yet implemented.')),
                  );
                },
                child: const Text('Restore Purchase'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
