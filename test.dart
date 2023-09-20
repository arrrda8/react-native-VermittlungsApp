import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:linkmi/adData.dart';
import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class CompanyAdPage extends StatefulWidget {
  @override
  _companyAdPageState createState() => _companyAdPageState();
}

class _companyAdPageState extends State<CompanyAdPage> {
  final _formKey = GlobalKey<FormState>();

  String? userId;
  late CollectionReference ads;
  String? jobOfferSelectedCategory;
  String? jobOfferSelectedJob;
  String? jobOfferExperience;
  String? jobOfferEmploymentType;
  List<String> jobOfferSelectedDays = [];
  bool showWorkDays = false;
  TextEditingController jobOfferTitleController = TextEditingController();
  TextEditingController jobOfferDescriptionController = TextEditingController();
  DateTime jobOfferSelectedDate = DateTime.now();
  bool isIOS = Platform.isIOS;
  bool showJobOfferHourlyRate = false;
  bool isHourlyRateFieldActive = true;
  bool isMonthlyRateFieldActive = true;
  bool _suggestionChosen = false;
  TextEditingController jobOfferHourlyRateController = TextEditingController();
  TextEditingController jobOfferMonthlyRateController = TextEditingController();
  String _zipCode = '';
  final _zipCodeController = TextEditingController();
  List<String> _addressSuggestions = [];
  bool _isSuggestionSelected = false;

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser!.uid;
    ads = FirebaseFirestore.instance.collection('companyAds');

    jobOfferHourlyRateController.addListener(() {
      setState(() {
        if (jobOfferHourlyRateController.text.isNotEmpty) {
          isMonthlyRateFieldActive = false;
        } else {
          isMonthlyRateFieldActive = true;
        }
      });
    });

    jobOfferMonthlyRateController.addListener(() {
      setState(() {
        if (jobOfferMonthlyRateController.text.isNotEmpty) {
          isHourlyRateFieldActive = false;
        } else {
          isHourlyRateFieldActive = true;
        }
      });
    });
  }

  Future<Map<String, dynamic>> getCompanyInfo(String userId) async {
    DocumentSnapshot companyDoc = await FirebaseFirestore.instance.collection('users').doc(userId).collection('company').doc(userId).get();
    return companyDoc.data() as Map<String, dynamic>;
  }

  _onAddressChanged() {
    if (!_isSuggestionSelected && _zipCodeController.text.length > 3) {
      fetchSuggestions(_zipCodeController.text);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    if (Platform.isIOS) {
      showModalBottomSheet(
          context: context,
          builder: (BuildContext builder) {
            return Container(
              height: MediaQuery.of(context).copyWith().size.height / 3,
              color: Colors.white,
              child: Column(
                children: [
                  Container(
                    color: CupertinoColors.systemGrey5,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CupertinoButton(
                          child: Text('Abbrechen'),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        CupertinoButton(
                          child: Text('Fertig'),
                          onPressed: () {
                            Navigator.of(context).pop();
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.date,
                      initialDateTime: jobOfferSelectedDate,
                      onDateTimeChanged: (DateTime newDateTime) {
                        setState(() {
                          jobOfferSelectedDate = newDateTime;
                        });
                      },
                      dateOrder: DatePickerDateOrder.dmy,
                      maximumDate: DateTime.now().add(Duration(days: 365 * 10)), // Hier die Änderung
                      minimumDate: DateTime(1900, 1),
                    ),
                  ),
                ],
              ),
            );
          });
    } else {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: jobOfferSelectedDate,
        firstDate: DateTime(1900, 1),
        lastDate: DateTime.now().add(Duration(days: 365 * 10)), // Und hier die Änderung
      );
      if (picked != null && picked != jobOfferSelectedDate) {
        setState(() {
          jobOfferSelectedDate = picked;
        });
      }
    }
  }

  Widget _buildCardDropdown(String hint, List<String> items, String? selectedItem, Function(String?) onChanged) {
    if (isIOS) {
      return _buildCupertinoPicker(hint, items, selectedItem, onChanged);
    } else {
      return Card(
        child: ListTile(
          title: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: hint,
              border: InputBorder.none,
            ),
            value: selectedItem,
            items: [
              DropdownMenuItem<String>(
                value: null,
                child: Text('Bitte auswählen'),
              ),
              ...items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
            ],
            onChanged: hint == "Job" && jobOfferSelectedCategory == null ? null : onChanged,
          ),
        ),
      );
    }
  }

  void resetForm() {
    jobOfferTitleController.clear();
    jobOfferDescriptionController.clear();
    jobOfferHourlyRateController.clear();
    jobOfferMonthlyRateController.clear();
    jobOfferSelectedCategory = null;
    jobOfferSelectedJob = null;
    jobOfferExperience = null;
    jobOfferEmploymentType = null;
    jobOfferSelectedDays.clear();
    showWorkDays = false;
    showJobOfferHourlyRate = false;
    jobOfferSelectedDate = DateTime.now();
    setState(() {});
  }

  String? validateZipCode(String? value) {
    print("Validating zip code: $value");

    if (value == null || value.isEmpty) {
      return 'Bitte geben Sie eine PLZ ein';
    }

    if (!_suggestionChosen) {
      return 'Bitte wählen Sie einen Vorschlag aus der Liste';
    }

    return null;
  }

  Future<void> fetchSuggestions(String input) async {
    final request =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&types=(regions)&components=country:de&key=AIzaSyA5VmY2x0mZYYK6-5PPuU7Im1DEOBT8ju0';
    final response = await http.get(Uri.parse(request));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final predictions = jsonData['predictions'];

      setState(() {
        _addressSuggestions = predictions.map<String>((prediction) {
          return prediction['description']?.toString() ?? '';
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Stellenangebot erstellen')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            _buildCardDropdown('Wo?', jobCategories.keys.toList(), jobOfferSelectedCategory, (value) {
              setState(() {
                jobOfferSelectedCategory = value;
                jobOfferSelectedJob = null;
              });
            }),
            _buildCardDropdown('Job', jobOfferSelectedCategory != null ? jobCategories[jobOfferSelectedCategory]! : [], jobOfferSelectedJob, (value) {
              setState(() {
                jobOfferSelectedJob = value;
              });
            }),
            _buildCardDropdown('Berufserfahrung', experienceLevels, jobOfferExperience, (value) {
              setState(() {
                jobOfferExperience = value;
              });
            }),
            _buildCardDropdown('Beschäftigung', employmentTypes, jobOfferEmploymentType, (value) {
              setState(() {
                jobOfferEmploymentType = value;
              });
            }),
            Card(
              child: ListTile(
                title: Text('Beginn ab', style: TextStyle(fontSize: 16)),
                trailing: CupertinoButton(
                  child: Text('${jobOfferSelectedDate.day}.${jobOfferSelectedDate.month}.${jobOfferSelectedDate.year}'),
                  onPressed: () => _selectDate(context),
                ),
              ),
            ),
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: TextFormField(
                      controller: _zipCodeController,
                      decoration: InputDecoration(
                        labelText: 'PLZ',
                        border: InputBorder.none,  // Fügt einen Border hinzu
                      ),
                      validator: validateZipCode,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) => _onAddressChanged(),
                    ),
                  ),
                  ..._addressSuggestions.map((suggestion) => ListTile(
                    title: Text(suggestion),
                    onTap: () {
                      _isSuggestionSelected = true;
                      _zipCodeController.text = suggestion;
                      _zipCode = suggestion;
                      _suggestionChosen = true;
                      setState(() {
                        _addressSuggestions.clear();
                      });
                      _isSuggestionSelected = false;
                    },
                  )
                  ).toList(),
                ],
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 0),
                      title: Text('Arbeitstage', style: TextStyle(fontSize: 16)),
                      trailing: CupertinoSwitch(
                        value: showWorkDays,
                        onChanged: (bool value) {
                          setState(() {
                            showWorkDays = value;
                            if (!value) {
                              jobOfferSelectedDays.clear();
                            }
                          });
                        },
                      ),
                    ),
                    if (showWorkDays)
                      Wrap(
                        spacing: 8,
                        children: workDays.map((day) {
                          return FilterChip(
                            label: Text(day),
                            selected: jobOfferSelectedDays.contains(day),
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  jobOfferSelectedDays.add(day);
                                } else {
                                  jobOfferSelectedDays.remove(day);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 0),
                      title: Text('Lohn', style: TextStyle(fontSize: 16)),
                      trailing: CupertinoSwitch(
                        value: showJobOfferHourlyRate,
                        onChanged: (bool value) {
                          setState(() {
                            showJobOfferHourlyRate = value;
                            if (!value) {
                              jobOfferHourlyRateController.clear();
                              jobOfferMonthlyRateController.clear();
                            }
                          });
                        },
                      ),
                    ),
                    if (showJobOfferHourlyRate)
                      TextFormField(
                        controller: jobOfferHourlyRateController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        textAlign: TextAlign.right,
                        decoration: InputDecoration(
                          labelText: 'Stundenlohn',
                          suffixText: '€',
                          suffixStyle: TextStyle(fontSize: 16),
                        ),
                        enabled: isHourlyRateFieldActive,
                      ),

                    if (showJobOfferHourlyRate && jobOfferHourlyRateController.text.isEmpty)
                      TextFormField(
                        controller: jobOfferMonthlyRateController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        textAlign: TextAlign.right,
                        decoration: InputDecoration(
                          labelText: 'Monatslohn',
                          suffixText: '€',
                          suffixStyle: TextStyle(fontSize: 16),
                        ),
                        enabled: isMonthlyRateFieldActive,
                      ),

                  ],
                ),
              ),
            ),
            Card(
              child: ListTile(
                title: TextFormField(
                  controller: jobOfferTitleController,
                  decoration: InputDecoration(
                    labelText: 'Überschrift',
                    border: InputBorder.none,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Bitte ausfüllen';
                    }
                    return null;
                  },
                ),
              ),
            ),
            Card(
              child: ListTile(
                title: TextFormField(
                  controller: jobOfferDescriptionController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: 'Beschreibung',
                    border: InputBorder.none,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Bitte ausfüllen';
                    }
                    return null;
                  },
                ),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _saveToFirestore();
                }
              },
              child: Text('Speichern'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCupertinoPicker(String hint, List<String> items, String? selectedItem, Function(String?) onChanged) {
    int selectedIndex = items.indexOf(selectedItem ?? '');
    bool isButtonEnabled = !(hint == "Job" && jobOfferSelectedCategory == null);
    return Card(
      child: ListTile(
        title: Text(hint),
        trailing: CupertinoButton(
          child: Text(selectedItem ?? 'Bitte auswählen'),
          onPressed: isButtonEnabled ? () {
            showModalBottomSheet(
              context: context,
              builder: (BuildContext context) {
                return Container(
                  height: 200,
                  child: CupertinoPicker(
                    itemExtent: 32.0,
                    onSelectedItemChanged: (int index) {
                      onChanged(items[index]);
                    },
                    children: List<Widget>.generate(items.length, (int index) {
                      return Center(child: Text(items[index]));
                    }),
                    scrollController: FixedExtentScrollController(initialItem: selectedIndex >= 0 ? selectedIndex : 0),
                  ),
                );
              },
            );
          } : null, // Wenn isButtonEnabled false ist, wird onPressed auf null gesetzt, wodurch der Button deaktiviert wird.
        ),
      ),
    );
  }


  void _saveToFirestore() async {
    if (jobOfferSelectedCategory != null &&
        jobOfferSelectedJob != null &&
        jobOfferTitleController.text.isNotEmpty &&
        jobOfferDescriptionController.text.isNotEmpty) {

      // Datenstruktur für Firestore
      Map<String, dynamic> adData = {
        'at': jobOfferSelectedCategory,
        'job': jobOfferSelectedJob,
        'jobOfferExperienceInYears': jobOfferExperience,
        'jobOfferEmployment': jobOfferEmploymentType,
        'startWorkDate': jobOfferSelectedDate,
        'location': _zipCode,
        'jobOfferWorkingDays': jobOfferSelectedDays,
        'jobOfferHourWage': jobOfferHourlyRateController.text.isNotEmpty ? int.parse(jobOfferHourlyRateController.text) : null,
        'jobOfferMonthWage': jobOfferMonthlyRateController.text.isNotEmpty ? int.parse(jobOfferMonthlyRateController.text) : null,
        'jobOfferTopic': jobOfferTitleController.text,
        'jobOfferDescription': jobOfferDescriptionController.text,
        'jobOfferCreatedAt': Timestamp.now(), // Aktuelles Datum und Uhrzeit
        'userId': userId,
      };

      Map<String, dynamic> companyInfo = await getCompanyInfo(userId!);
      adData['companyName'] = companyInfo['companyName'];
      adData['companyProfileImage'] = companyInfo['companyProfileImage'];

      ads.add(adData).then((docRef) {
        print("Document written with ID: ${docRef.id}");

        // Aktualisieren Sie das Dokument mit seiner eigenen ID
        ads.doc(docRef.id).update({'companyAdId': docRef.id});

        // AlertDialog anzeigen
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Erfolg'),
              content: Text('Deine Anzeige ist online!'),
              actions: <Widget>[
                TextButton(
                  child: Text('Ok'),
                  onPressed: () {
                    Navigator.of(context).pop(); // Schließt den AlertDialog
                    resetForm(); // Setzt das Formular zurück
                    Navigator.of(context).pop(); // Navigiert zurück zur vorherigen Seite
                  },
                ),
              ],
            );
          },
        );
      }).catchError((error) {
        print("Error adding document: $error");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Speichern: $error')),
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bitte füllen Sie alle Felder aus.')),
      );
    }
  }
}


