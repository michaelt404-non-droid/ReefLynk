import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:reeflynk/services/purchase_service.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  static const String _lemonSqueezyUrl =
      'https://jachin.lemonsqueezy.com/checkout/buy/e81b8c72-205b-4e60-a938-23864ed039a6';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ReefLynk Pro'),
        automaticallyImplyLeading: false,
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
              if (kIsWeb)
                _buildWebCheckout(context)
              else
                _buildNativeIAP(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebCheckout(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () async {
        final uri = Uri.parse(_lemonSqueezyUrl);
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
        minimumSize: const Size(double.infinity, 50),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Widget _buildNativeIAP(BuildContext context) {
    return Consumer<PurchaseService>(
      builder: (context, purchaseService, _) {
        if (purchaseService.errorMessage != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(purchaseService.errorMessage!)),
            );
            purchaseService.errorMessage = null;
          });
        }

        if (purchaseService.isLoading) {
          return const CircularProgressIndicator();
        }

        if (!purchaseService.isAvailable) {
          return const Text(
            'In-app purchases are not available on this device.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          );
        }

        if (purchaseService.products.isEmpty) {
          return Column(
            children: [
              const Text(
                'Could not load subscription options. Please try again.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => purchaseService.loadProducts(),
                child: const Text('Retry'),
              ),
            ],
          );
        }

        return Column(
          children: [
            ...purchaseService.products.map((product) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ElevatedButton(
                    onPressed: () => purchaseService.buyProduct(product),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          product.title,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          product.price,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                )),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => purchaseService.restorePurchases(),
              child: const Text('Restore Purchase'),
            ),
          ],
        );
      },
    );
  }
}
