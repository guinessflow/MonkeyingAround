import 'package:in_app_purchase/in_app_purchase.dart';
import 'dart:async';

class InAppPurchaseManager {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  Future<void> initialize() async {
    // Initialize the plugin
    _inAppPurchase.purchaseStream;
    await _inAppPurchase.restorePurchases();
  }

  Future<List<ProductDetails>> fetchProducts(List<String> productIds) async {
    final ProductDetailsResponse response =
    await _inAppPurchase.queryProductDetails(productIds.toSet());
    if (response.notFoundIDs.isNotEmpty) {
      // Handle the case where products are not found.
    }
    return response.productDetails;
  }

  Future<void> initiatePurchase(ProductDetails productDetails) async {
    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: productDetails,
      // Optional: Add any additional parameters as needed.
    );
    await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<bool> isPurchaseAvailable() async {
    return await _inAppPurchase.isAvailable();
  }

  void setupPurchaseListener(Stream<List<PurchaseDetails>> purchaseUpdatedStream,
      void Function(List<PurchaseDetails>)? onPurchaseUpdated) async {
    bool isAvailable = await _inAppPurchase.isAvailable();
    if (isAvailable) {
      _subscription = purchaseUpdatedStream.listen(
            (List<PurchaseDetails> purchaseDetailsList) {
          onPurchaseUpdated?.call(purchaseDetailsList);
        },
        onError: (error) {
          print('Purchase error: $error');
        },
      );
    } else {
      // In-app purchase is not available on this device
      // Handle the case accordingly
    }
  }


  void dispose() {
    // No need to disconnect or end the connection in the updated version
  }
}
