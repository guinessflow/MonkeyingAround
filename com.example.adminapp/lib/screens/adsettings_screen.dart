import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdsSettings extends StatefulWidget {
  final Function backButton;

  const AdsSettings({super.key, required this.backButton});

  @override
  _AdsSettingsState createState() => _AdsSettingsState();
}

class _AdsSettingsState extends State<AdsSettings> {
  final _formKey = GlobalKey<FormState>();
  String _selectedAdUnit = ''; // Default selected ad unit
  final List<String> _adUnits = []; // List of ad units

  Map<String, dynamic>? _adUnitData; // Selected ad unit data

  @override
  void initState() {
    super.initState();
    _fetchFirstAdUnit();
  }

  void _fetchFirstAdUnit() {
    FirebaseFirestore.instance
        .collection('ads')
        .doc('adSettings')
        .collection('units')
        .orderBy(FieldPath.documentId)
        .limit(1)
        .get()
        .then((QuerySnapshot snapshot) {
      if (snapshot.docs.isNotEmpty) {
        String firstAdUnit = snapshot.docs.first.id;
        setState(() {
          _selectedAdUnit = firstAdUnit;
        });
      } else {
        print("No ad units found in Firestore");
      }
      _fetchAdUnitData();
    })
        .catchError((error) => print("Failed to fetch ad units: $error"));
  }

  void _fetchAdUnitData() {
    FirebaseFirestore.instance
        .collection('ads')
        .doc('adSettings')
        .collection('units')
        .doc(_selectedAdUnit)
        .get()
        .then((DocumentSnapshot<Map<String, dynamic>> snapshot) {
      if (snapshot.exists) {
        setState(() {
          _adUnitData = snapshot.data();
        });
      } else {
        setState(() {
          _adUnitData = null;
        });
      }
    }).catchError((error) {
      setState(() {
        _adUnitData = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ads Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            widget.backButton();
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('ads')
            .doc('adSettings')
            .collection('units')
            .snapshots(),
        builder: (BuildContext context,
            AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final adUnits = snapshot.data?.docs.map((doc) => doc.id)
              .toSet()
              .toList();

          if (adUnits != null && adUnits.isNotEmpty) {
            _selectedAdUnit = _selectedAdUnit.isNotEmpty
                ? _selectedAdUnit
                : adUnits[0]; // Preserve previous selection if available

            return SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Ad Unit:',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: DropdownButton<String>(
                        key: Key(_selectedAdUnit),
                        value: _selectedAdUnit,
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedAdUnit = newValue!;
                            _fetchAdUnitData(); // Fetch ad unit data for the selected ad unit
                          });
                        },
                        items: adUnits.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  if (_adUnitData != null)
                ...[
            Expanded(
            child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Card(
          child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
          child: Form(
          key: _formKey,
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          const Text('Ad Format'),
          DropdownButtonFormField<String>(
          value: _adUnitData!['adFormat'],
          items: const [
          DropdownMenuItem<String>(
          value: 'banner',
          child: Text('Banner'),
          ),
          DropdownMenuItem<String>(
          value: 'mediumRectangle',
          child: Text('Medium Rectangle'),
          ),
          DropdownMenuItem<String>(
          value: 'largeBanner',
          child: Text('Large Banner'),
          ),
          DropdownMenuItem<String>(
          value: 'interstitial',
          child: Text('Interstitial'),
          ),
          DropdownMenuItem<String>(
          value: 'adaptiveBanner',
          child: Text('Adaptive Banner'),
          ),
          ],
          onChanged: (String? value) {
          setState(() {
          _adUnitData!['adFormat'] = value!;
          });
          },
          ),
          const SizedBox(height: 16),
          const Text('Ad Provider'),
          DropdownButtonFormField<String>(
          value: _adUnitData!['adProvider'],
          items: const [
          DropdownMenuItem<String>(
          value: 'admob',
          child: Text('AdMob'),
          ),
          DropdownMenuItem<String>(
          value: 'custom',
          child: Text('Custom'),
          ),
          ],
          onChanged: (String? value) {
          setState(() {
          _adUnitData!['adProvider'] = value!;
          });
          },
          ),
          const SizedBox(height: 16),
          const Text('Ad Unit ID'),
          TextFormField(
          initialValue: _adUnitData!['adUnitId'],
          onSaved: (value) {
          _adUnitData!['adUnitId'] = value!;
          },
          ),
          const SizedBox(height: 16),
          const Text('Custom Ad Code'),
          TextFormField(
          initialValue: _adUnitData!['customAdCode'],
          maxLines: null,
          onSaved: (value) {
          _adUnitData!['customAdCode'] = value!;
          },
          ),
          const SizedBox(height: 16),
          const Text('Enabled'),
          DropdownButtonFormField<bool>(
          value: _adUnitData!['enabled'],
          items: const [
          DropdownMenuItem<bool>(
          value: true,
          child: Text('Enabled'),
          ),
          DropdownMenuItem<bool>(
          value: false,
          child: Text('Disabled'),
          ),
          ],
          onChanged: (bool? value) {
          setState(() {
          _adUnitData!['enabled'] = value ?? false;
          });
          },
          ),
          const SizedBox(height: 16),
          const Text('Position'),
          DropdownButtonFormField<String>(
          value: _adUnitData!['position'],
          items: const [
          DropdownMenuItem<String>(
          value: 'default',
          child: Text('Default'),
          ),
          DropdownMenuItem<String>(
          value: 'top',
          child: Text('Top'),
          ),
          DropdownMenuItem<String>(
          value: 'bottom',
          child: Text('Bottom'),
          ),
          DropdownMenuItem<String>(
          value: 'inline',
          child: Text('Inline'),
          ),
          DropdownMenuItem<String>(
          value: 'carousel',
          child: Text('Carousel'),
          ),
          ],
          onChanged: (String? value) {
          setState(() {
          _adUnitData!['position'] = value ?? 'default';
          });
          },
          ),
          const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Update data in Firestore
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    FirebaseFirestore.instance
                        .collection('ads')
                        .doc('adSettings')
                        .collection('units')
                        .doc(_selectedAdUnit)
                        .update(_adUnitData!)
                        .then((value) {
                      print("Data saved successfully");
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Success'),
                            content: const Text('Ad settings updated successfully.'),
                            actions: <Widget>[
                              TextButton(
                                child: const Text('OK'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  setState(() {
                                    _selectedAdUnit = _selectedAdUnit;
                                    _adUnitData = _adUnitData;
                                  });

                                },
                              ),
                            ],
                          );
                        },
                      );
                    })
                        .catchError((error) => print("Failed to save data: $error"));
                  }
                },
                child: const Text('Save'),
              ),
            ),
          ],
          ),
          ),
          ),
          ),
          ),
          ),
            ),
          ],


          ],
                ),
              ),
            );
          } else {
            return const Text('No ad units available.');
          }
        },
      ),
    );
  }

}




