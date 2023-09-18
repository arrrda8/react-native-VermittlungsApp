import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'adData.dart';
import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

bool isIOS = Platform.isIOS;
bool showHourlyRate = false;
TextEditingController hourlyRateController = TextEditingController();
TextEditingController monthlyRateController = TextEditingController();

class AdPage extends StatefulWidget {
  @override
  _AdPageState createState() => _AdPageState();
}

class _AdPageState extends State<AdPage> {
  final _formKey = GlobalKey<FormState>();

  String? userId;
  late CollectionReference ads;

  String? selectedCategory;
  String? selectedJob;
  String? experience;
  String? employmentType;
  List<String> selectedDays = [];
  bool showWorkDays = false;
  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  bool showHourlyRate = false;
  TextEditingController hourlyRateController = TextEditingController();
  TextEditingController monthlyRateController = TextEditingController();
  String _zipCode = '';
  final _zipCodeController = TextEditingController();
  List<String> _addressSuggestions = [];
  bool _isSuggestionSelected = false;


  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser!.uid;
    ads = FirebaseFirestore.instance.collection('privateAds');
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
                      initialDateTime: selectedDate,
                      onDateTimeChanged: (DateTime newDateTime) {
                        setState(() {
                          selectedDate = newDateTime;
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
        initialDate: selectedDate,
        firstDate: DateTime(1900, 1),
        lastDate: DateTime.now().add(Duration(days: 365 * 10)), // Und hier die Änderung
      );
      if (picked != null && picked != selectedDate) {
        setState(() {
          selectedDate = picked;
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
            onChanged: hint == "Job" && selectedCategory == null ? null : onChanged,
          ),
        ),
      );
    }
  }

  void resetForm() {
    titleController.clear();
    descriptionController.clear();
    hourlyRateController.clear();
    monthlyRateController.clear();
    selectedCategory = null;
    selectedJob = null;
    experience = null;
    employmentType = null;
    selectedDays.clear();
    showWorkDays = false;
    showHourlyRate = false;
    selectedDate = DateTime.now();
    _zipCodeController.clear();
    _addressSuggestions.clear();
    _isSuggestionSelected = false;
    setState(() {});
  }

  String? validateZipCode(String? value) {
    print("Validating zip code: $value");

    if (value == null || value.isEmpty) {
      return 'Bitte geben Sie eine PLZ ein';
    }

    // Überprüfen, ob der Text eine gültige PLZ ist (z.B. "12345")
    bool isValidZipCode = RegExp(r'^\d{5}$').hasMatch(value);

    if (!isValidZipCode) {
      return 'Bitte geben Sie eine gültige PLZ ein';
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
      appBar: AppBar(title: Text('Anzeige erstellen')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            _buildCardDropdown('Wo?', jobCategories.keys.toList(), selectedCategory, (value) {
              setState(() {
                selectedCategory = value;
                selectedJob = null;
              });
            }),
            _buildCardDropdown('Job', selectedCategory != null ? jobCategories[selectedCategory]! : [], selectedJob, (value) {
              setState(() {
                selectedJob = value;
              });
            }),
            _buildCardDropdown('Berufserfahrung', experienceLevels, experience, (value) {
              setState(() {
                experience = value;
              });
            }),
            _buildCardDropdown('Beschäftigung', employmentTypes, employmentType, (value) {
              setState(() {
                employmentType = value;
              });
            }),
            Card(
              child: ListTile(
                title: Text('Beginn ab', style: TextStyle(fontSize: 16)),
                trailing: CupertinoButton(
                  child: Text('${selectedDate.day}.${selectedDate.month}.${selectedDate.year}'),
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
                      // Extrahieren Sie nur den PLZ-Teil des Vorschlags
                      final extractedZip = suggestion.split(' ')[0];
                      _zipCodeController.text = extractedZip;
                      _zipCode = extractedZip;
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
                              selectedDays.clear();
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
                            selected: selectedDays.contains(day),
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  selectedDays.add(day);
                                } else {
                                  selectedDays.remove(day);
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
                        value: showHourlyRate,
                        onChanged: (bool value) {
                          setState(() {
                            showHourlyRate = value;
                            if (!value) {
                              hourlyRateController.clear();
                              monthlyRateController.clear();
                            }
                          });
                        },
                      ),
                    ),
                    if (showHourlyRate)
                      ValueListenableBuilder(
                        valueListenable: monthlyRateController,
                        builder: (context, value, child) {
                          return TextFormField(
                            controller: hourlyRateController,
                            enabled: monthlyRateController.text.isEmpty,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            textAlign: TextAlign.right,
                            decoration: InputDecoration(
                              labelText: 'Stundenlohn',
                              suffixText: '€',
                              suffixStyle: TextStyle(fontSize: 16),
                            ),
                          );
                        },
                      ),
                    if (showHourlyRate)
                      ValueListenableBuilder(
                        valueListenable: hourlyRateController,
                        builder: (context, value, child) {
                          return TextFormField(
                            controller: monthlyRateController,
                            enabled: hourlyRateController.text.isEmpty,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            textAlign: TextAlign.right,
                            decoration: InputDecoration(
                              labelText: 'Monatslohn',
                              suffixText: '€',
                              suffixStyle: TextStyle(fontSize: 16),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),


            Card(
              child: ListTile(
                title: TextFormField(
                  controller: titleController,
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
                  controller: descriptionController,
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
    bool isButtonEnabled = !(hint == "Job" && selectedCategory == null);
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


  void _saveToFirestore() {
    if (selectedCategory != null &&
        selectedJob != null &&
        titleController.text.isNotEmpty &&
        descriptionController.text.isNotEmpty) {

      // Datenstruktur für Firestore
      Map<String, dynamic> adData = {
        'at': selectedCategory,
        'job': selectedJob,
        'experienceInYears': experience,
        'employment': employmentType,
        'startWorkDate': selectedDate,
        'workingDays': selectedDays,
        'location': _zipCode,
        'hourWage': hourlyRateController.text.isNotEmpty ? int.parse(hourlyRateController.text) : null,
        'monthWage': monthlyRateController.text.isNotEmpty ? int.parse(monthlyRateController.text) : null,
        'topic': titleController.text,
        'jobApplicationDescription': descriptionController.text,
        'createdAt': Timestamp.now(), // Aktuelles Datum und Uhrzeit
        'userId': userId,
      };

      final privateAds = FirebaseFirestore.instance.collection('privateAds');

      privateAds.add(adData).then((docRef) {
        print("Document written with ID: ${docRef.id}");
        privateAds.doc(docRef.id).update({'privateAdId': docRef.id});

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
