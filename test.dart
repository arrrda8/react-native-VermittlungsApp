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

class EditAdPage extends StatefulWidget {
  final String privateAdId; //

  EditAdPage({required this.privateAdId});

  @override
  _EditAdPageState createState() => _EditAdPageState();
}

class _EditAdPageState extends State<EditAdPage> {
  final _formKey = GlobalKey<FormState>();

  String? userId;
  late CollectionReference ads;
  bool isIOS = Platform.isIOS;
  bool showHourlyRate = false;
  bool _suggestionChosen = false;
  String? selectedCategory;
  String? selectedJob;
  String? experience;
  String? employmentType;
  List<String> selectedDays = [];
  bool showWorkDays = false;
  TextEditingController titleController = TextEditingController();
  TextEditingController jobApplicationDescriptionController = TextEditingController();
  DateTime selectedDate = DateTime.now();
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
    _loadAdData();
    hourlyRateController.addListener(() {
      if (hourlyRateController.text.isNotEmpty) {
        monthlyRateController.clear();
      }
    });

    monthlyRateController.addListener(() {
      if (monthlyRateController.text.isNotEmpty) {
        hourlyRateController.clear();
      }
    });
  }

  _loadAdData() async {
    DocumentSnapshot adSnapshot = await ads.doc(widget.privateAdId).get();

    if (adSnapshot.data() != null) {
      Map<String, dynamic> adData = adSnapshot.data() as Map<String, dynamic>;

      // Setzen Sie die Formularfelder mit den Daten des Stellenangebots
      selectedCategory = adData['at'];
      selectedJob = adData['job'];
      experience = adData['experienceInYears'];
      employmentType = adData['employment'];
      selectedDays = List<String>.from(adData['workingDays'] ?? []);
      selectedDate = (adData['startWorkDate'] as Timestamp).toDate();
      titleController.text = adData['topic'];
      jobApplicationDescriptionController.text = adData['jobApplicationDescription']?.toString() ?? '';
      hourlyRateController.text = adData['hourWage']?.toString() ?? '';
      monthlyRateController.text = adData['monthWage']?.toString() ?? '';
      showWorkDays = selectedDays.isNotEmpty;
      showHourlyRate = hourlyRateController.text.isNotEmpty ||
          monthlyRateController.text.isNotEmpty;

      setState(() {});
    } else {
      // Hier können Sie eine Fehlermeldung anzeigen oder eine andere Aktion ausführen, wenn die Daten null sind.
    }
  }


  Future<void> _selectDate(BuildContext context) async {
    if (Platform.isIOS) {
      showModalBottomSheet(
          context: context,
          builder: (BuildContext builder) {
            return Container(
              height: MediaQuery
                  .of(context)
                  .copyWith()
                  .size
                  .height / 3,
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
                      maximumDate: DateTime.now().add(Duration(days: 365 * 10)),
                      // Hier die Änderung
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
        lastDate: DateTime.now().add(
            Duration(days: 365 * 10)), // Und hier die Änderung
      );
      if (picked != null && picked != selectedDate) {
        setState(() {
          selectedDate = picked;
        });
      }
    }
  }

  Widget _buildCardDropdown(String hint, List<String> items,
      String? selectedItem, Function(String?) onChanged) {
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
            onChanged: hint == "Job" && selectedCategory == null
                ? null
                : onChanged,
          ),
        ),
      );
    }
  }

  Widget _buildCupertinoPicker(String hint, List<String> items,
      String? selectedItem, Function(String?) onChanged) {
    int selectedIndex = items.indexOf(selectedItem ?? '');
    bool isButtonEnabled = !(hint == "Job" && selectedCategory == null);
    return Card(
      child: ListTile(
        title: Text(hint),
        trailing: CupertinoButton(
          child: Text(selectedItem ?? 'Bitte auswählen'),
          onPressed: isButtonEnabled
              ? () {
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
                    scrollController: FixedExtentScrollController(
                        initialItem: selectedIndex >= 0 ? selectedIndex : 0),
                  ),
                );
              },
            );
          }
              : null, // Wenn isButtonEnabled false ist, wird onPressed auf null gesetzt, wodurch der Button deaktiviert wird.
        ),
      ),
    );
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
          return prediction['jobApplicationDescription']?.toString() ?? '';
        }).toList();
      });
    }
  }

  _onAddressChanged() {
    if (!_isSuggestionSelected && _zipCodeController.text.length > 3) {
      fetchSuggestions(_zipCodeController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Stellenangebot bearbeiten')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            _buildCardDropdown(
                'Wo?', jobCategories.keys.toList(), selectedCategory, (
                value) {
              setState(() {
                selectedCategory = value;
                selectedJob = null;
              });
            }),
            _buildCardDropdown('Job', selectedCategory != null
                ? jobCategories[selectedCategory]!
                : [], selectedJob, (value) {
              setState(() {
                selectedJob = value;
              });
            }),
            _buildCardDropdown(
                'Berufserfahrung', experienceLevels, experience, (
                value) {
              setState(() {
                experience = value;
              });
            }),
            _buildCardDropdown(
                'Beschäftigung', employmentTypes, employmentType, (
                value) {
              setState(() {
                employmentType = value;
              });
            }),
            Card(
              child: ListTile(
                title: Text('Beginn ab', style: TextStyle(fontSize: 16)),
                trailing: CupertinoButton(
                  child: Text(
                      '${selectedDate.day}.${selectedDate
                          .month}.${selectedDate.year}'),
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
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 0),
                      title: Text(
                          'Arbeitstage', style: TextStyle(fontSize: 16)),
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
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 0),
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
                      TextFormField(
                        controller: hourlyRateController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        textAlign: TextAlign.right,
                        enabled: monthlyRateController.text.isEmpty,
                        decoration: InputDecoration(
                          labelText: 'Stundenlohn',
                          suffixText: '€',
                          suffixStyle: TextStyle(fontSize: 16),
                        ),
                      ),
                    if (showHourlyRate)
                      TextFormField(
                        controller: monthlyRateController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        textAlign: TextAlign.right,
                        enabled: hourlyRateController.text.isEmpty,
                        decoration: InputDecoration(
                          labelText: 'Monatslohn',
                          suffixText: '€',
                          suffixStyle: TextStyle(fontSize: 16),
                        ),
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
                  controller: jobApplicationDescriptionController,
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
              child: Text('Aktualisieren'),
            ),
          ],
        ),
      ),
    );
  }

  void _saveToFirestore() {
    // Überprüfen, ob die Eingaben gültig sind
    if (_formKey.currentState!.validate()) {
      // Hier prüfen wir, ob Stunden- oder Monatslohn gesetzt ist, und setzen entsprechend den Wert oder null.
      double? hourWage;
      double? monthWage;
      if (hourlyRateController.text.isNotEmpty) {
        hourWage = double.parse(hourlyRateController.text);
      }
      if (monthlyRateController.text.isNotEmpty) {
        monthWage = double.parse(monthlyRateController.text);
      }

      // Datenstruktur für Firestore erstellen
      Map<String, dynamic> adData = {
        'at': selectedCategory,
        'job': selectedJob,
        'experienceInYears': experience,
        'employment': employmentType,
        'workingDays': selectedDays,
        'location': _zipCode,
        'startWorkDate': Timestamp.fromDate(selectedDate),
        'topic': titleController.text,
        'jobApplicationDescription': jobApplicationDescriptionController.text,
        'hourWage': hourWage,
        'monthWage': monthWage
      };

      // Nicht benötigte Daten entfernen
      adData.removeWhere((key, value) => value == null);

      // Aktualisieren Sie den bestehenden Eintrag in Firestore
      ads.doc(widget.privateAdId).update(adData).then((_) {
        // Erfolgsmeldung zeigen
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Stellenangebot erfolgreich aktualisiert!'))
        );

        // Zurück zur vorherigen Seite gehen
        Navigator.pop(context);
      }).catchError((error) {
        // Fehlerbehandlung
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ein Fehler ist aufgetreten: $error'))
        );
      });
    }
  }
}
