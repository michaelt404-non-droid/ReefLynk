import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PurchaseService extends ChangeNotifier {
  static const String monthlyId = 'com.mikeyt.reeflynk.pro.monthly';
  static const String yearlyId = 'com.mikeyt.reeflynk.pro.yearly';
  static const Set<String> _productIds = {monthlyId, yearlyId};

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  List<ProductDetails> products = [];
  bool isAvailable = false;
  bool isLoading = false;
  String? errorMessage;

  Future<void> initialize() async {
    if (kIsWeb) return;

    isAvailable = await _iap.isAvailable();
    if (!isAvailable) return;

    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (error) {
        errorMessage = error.toString();
        notifyListeners();
      },
    );

    await loadProducts();
  }

  Future<void> loadProducts() async {
    if (!isAvailable) return;
    isLoading = true;
    notifyListeners();

    final response = await _iap.queryProductDetails(_productIds);
    products = response.productDetails;
    // Sort: monthly first, then yearly
    products.sort((a, b) => a.id == monthlyId ? -1 : 1);

    isLoading = false;
    notifyListeners();
  }

  Future<void> buyProduct(ProductDetails product) async {
    errorMessage = null;
    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restorePurchases() async {
    errorMessage = null;
    await _iap.restorePurchases();
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        await _grantPro();
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
      } else if (purchase.status == PurchaseStatus.error) {
        errorMessage = purchase.error?.message ?? 'Purchase failed';
        notifyListeners();
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
      } else if (purchase.status == PurchaseStatus.canceled) {
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
      }
    }
  }

  Future<void> _grantPro() async {
    try {
      await Supabase.instance.client.rpc('grant_pro_to_current_user');
      await Supabase.instance.client.auth.refreshSession();
    } catch (e) {
      errorMessage = 'Purchase succeeded but failed to activate Pro. Please contact support.';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
