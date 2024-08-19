import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdContainers {
  static AdSize getAdaptiveBannerAdSize(BuildContext context, {double? height}) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final int adWidth = (screenWidth - 16).toInt();
    final int adHeight = height != null ? (screenHeight * 0.7).toInt() : screenHeight.toInt();

    return AdSize(width: adWidth, height: adHeight);
  }
}



