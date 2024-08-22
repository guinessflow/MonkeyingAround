import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '/models/database_helper.dart';
import 'ad_containers.dart';
import 'dart:convert';

enum AdFormat { banner, mediumRectangle, largeBanner, adaptiveBanner }

class UniversalAdWidget extends StatefulWidget {
  final String adUnitId;
  final AdFormat adFormat;
  final BuildContext context;
  final String adProvider;
  final String customAdCode;
  final double? adHeight;

  const UniversalAdWidget({
    Key? key,
    required this.adUnitId,
    required this.adFormat,
    required this.context,
    required this.adProvider,
    required this.customAdCode,
    this.adHeight,
  }) : super(key: key);

  @override
  _UniversalAdWidgetState createState() => _UniversalAdWidgetState();
}

class _UniversalAdWidgetState extends State<UniversalAdWidget> {
  BannerAd? ad;
  bool _isAdLoaded = false;
  late Future<Map<String, dynamic>> _adSettingsFuture;
  final dbHelper = DatabaseHelper.instance;
  late WebViewController _controller;

  BannerAdListener? adListener;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.dataFromString(widget.customAdCode, mimeType: 'text/html'));

    _adSettingsFuture = dbHelper.fetchAdSettings();

    adListener = BannerAdListener(
      onAdLoaded: (Ad ad) async {
        //print('Ad loaded');
        setState(() {
          _isAdLoaded = true;
        });

        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setBool('_isAdLoaded', _isAdLoaded);
      },
      onAdFailedToLoad: (Ad ad, LoadAdError error) async {
       // print('Ad failed to load: $error');
        ad.dispose();
        setState(() {
          _isAdLoaded = false;
        });

        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setBool('_isAdLoaded', _isAdLoaded);
      },
      onAdOpened: (Ad ad) {},
      onAdClosed: (Ad ad) {},
    );

    _initAd(widget.adFormat);
  }

  Future<void> _initAd(AdFormat adFormat) async {
    final adSettings = await _adSettingsFuture;
    final bool adEnabled = adSettings['enabled'] ?? false;

    //if (!adEnabled) return;

    AdSize adSize;
    switch (adFormat) {
      case AdFormat.banner:
        adSize = AdSize.banner;
        break;
      case AdFormat.mediumRectangle:
        adSize = AdSize.mediumRectangle;
        break;
      case AdFormat.largeBanner:
        adSize = AdSize.largeBanner;
        break;
      case AdFormat.adaptiveBanner: // Add this case for adaptive banner
        //adSize = AdContainers.getAdaptiveBannerAdSize(context);
        adSize = AdContainers.getAdaptiveBannerAdSize(context, height: MediaQuery.of(context).size.height * 0.7);
       // adSize = AdContainers.getAdaptiveBannerAdSize(context, height: widget.adHeight ?? MediaQuery.of(context).size.height);
        break;
      default:
        return;
    }

    ad = BannerAd(
      adUnitId: widget.adUnitId,
      request: const AdRequest(),
      size: adSize,
      listener: adListener!,
    );

    ad?.load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 0),
        Expanded(
          child: widget.adProvider == 'admob'
              ? _buildAdMobAd(context)
              : _buildCustomAd(context),
        ),
      ],
    );
  }

  Widget _buildAdMobAd(BuildContext context) {
    if (_isAdLoaded && ad != null) {
      return AdWidget(ad: ad!);
    } else {
      return Container(
        color: Colors.transparent,
        width: 0,
        height: 0,
      );
      // Alternatively, you can use SizedBox with zero dimensions
      // return SizedBox(width: 0, height: 0);
    }
  }



  Widget _buildCustomAd(BuildContext context) {
    String adText;
    switch (widget.adFormat) {
      case AdFormat.banner:
        adText = ''; // Test Custom Banner Ad
        break;
      case AdFormat.mediumRectangle:
        adText = '';
        break;
      case AdFormat.largeBanner:
        adText = '';
        break;
      case AdFormat.adaptiveBanner: // Add this case for adaptive banner
        adText = '';
        break;
      default:
        adText = '';
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
            color: Theme.of(context).colorScheme.background,
              child: Column(
                children: [
                  Text(adText),  // Your adText
                  Expanded(  // Add this
                    child: CustomWebViewWidget(
                      height: widget.adHeight ?? MediaQuery.of(context).size.height,
                      htmlData: widget.customAdCode,
                    ),
                  ),
                ],
              )
          ),
        ),
      ),
    );
  }


  @override
  void dispose() {
    ad?.dispose(); // Updated to handle nullability
    super.dispose();
  }
}

class CustomWebViewWidget extends StatefulWidget {
  final double height;
  final String htmlData;

  const CustomWebViewWidget({
    Key? key,
    required this.height,
    required this.htmlData,
  }) : super(key: key);

  @override
  _CustomWebViewWidgetState createState() => _CustomWebViewWidgetState();
}

class _CustomWebViewWidgetState extends State<CustomWebViewWidget> {
  late WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.dataFromString(
        widget.htmlData,
        mimeType: 'text/html',
        encoding: utf8,
      ));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: WebViewWidget(controller: _controller),
    );
  }
}
