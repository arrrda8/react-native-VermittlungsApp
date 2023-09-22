import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:linkmi/main.dart';
import 'package:linkmi/company/editCompanyProfile_page.dart';
import 'package:zoom_pinch_overlay/zoom_pinch_overlay.dart';
import 'package:linkmi/AdCard.dart';
import 'companyAdDetail_page.dart';
import 'editCompanyAd_page.dart';

class CompanyProfilePage extends StatefulWidget {
  @override
  _CompanyProfilePageState createState() => _CompanyProfilePageState();
}

int _currentIndex = 0;

class _CompanyProfilePageState extends State<CompanyProfilePage> {
  User? user;
  Map<String, dynamic>? profileData;
  int selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
  }

  Future<Map<String, dynamic>?> fetchData() async {
    if (user != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('company')
            .doc(user!.uid)
            .get();
        return doc.data() as Map<String, dynamic>?;
      } catch (e) {
        print(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Ein Fehler ist aufgetreten. Bitte versuchen Sie es erneut.'),
          ),
        );
        return null;
      }
    }
    return null;
  }

  void navigateToEditCompanyProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditCompanyProfilePage()),
    );
  }

  void navigateToPrivateProfile() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomePage(initialIndex: 4),
      ),
    );
  }

  Future<LatLng?> getCoordinatesFromAddress(String address) async {
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?address=$address&key=AIzaSyA5VmY2x0mZYYK6-5PPuU7Im1DEOBT8ju0';
    final response = await http.get(Uri.parse(url));
    final jsonData = json.decode(response.body);

    if (jsonData['status'] == 'OK') {
      final lat = jsonData['results'][0]['geometry']['location']['lat'];
      final lng = jsonData['results'][0]['geometry']['location']['lng'];
      return LatLng(lat, lng);
    } else {
      print('Error geocoding address: ${jsonData['status']}');
      return null;
    }
  }

  Future<LatLng?> fetchCoordinates() async {
    if (profileData != null) {
      final address =
          '${profileData!['street']} ${profileData!['houseNumber']}, ${profileData!['zipCode']} ${profileData!['city']}';
      return await getCoordinatesFromAddress(address);
    }
    return null;
  }

  Future<Map<String, dynamic>?> fetchPrivateProfileData() async {
    if (user != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();
        return doc.data() as Map<String, dynamic>?;
      } catch (e) {
        print(e);
        return null;
      }
    }
    return null;
  }

  Future<void> uploadImage(File file, String imageType) async {
    try {
      // Speichern Sie das Bild im richtigen Ordner
      await FirebaseStorage.instance
          .ref('images/${user!.uid}/$imageType')
          .putFile(file);
      final String url = await FirebaseStorage.instance
          .ref('images/${user!.uid}/$imageType')
          .getDownloadURL();

      // Aktualisieren Sie die richtige Firestore-Sammlung basierend auf dem Bildtyp
      if (imageType == 'companyProfileImage' ||
          imageType == 'companyBackgroundImage') {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('company')
            .doc(user!.uid)
            .update({imageType: url});
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .update({imageType: url});
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bild erfolgreich hochgeladen.'),
        ),
      );
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Ein Fehler ist aufgetreten. Bitte versuchen Sie es erneut.'),
        ),
      );
    }
  }

  Future<void> deleteImage(String imageType) async {
    try {
      // Bild aus Firebase Storage löschen
      await FirebaseStorage.instance
          .ref('images/${user!.uid}/$imageType')
          .delete();

      // Bild-URL aus Firestore löschen
      if (imageType == 'companyProfileImage' ||
          imageType == 'companyBackgroundImage') {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('company')
            .doc(user!.uid)
            .update({imageType: FieldValue.delete()});
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .update({imageType: FieldValue.delete()});
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bild erfolgreich gelöscht.'),
        ),
      );
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Ein Fehler ist aufgetreten. Bitte versuchen Sie es erneut.'),
        ),
      );
    }
  }

  void _showImageOptions(String imageType) async {
    final bool isProfileImage = imageType == 'companyProfileImage';
    final bool imageExists =
        profileData![imageType] != null && profileData![imageType]!.isNotEmpty;

    void handleImageSelection() async {
      final pickedFile =
      await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final File originalFile = File(pickedFile.path);
        final CroppedFile? croppedFile = await _cropImage(originalFile);
        if (croppedFile != null) {
          final File croppedFinalFile =
          File(croppedFile.path); // Konvertieren Sie CroppedFile in File
          await uploadImage(croppedFinalFile, imageType);
        }
      }
    }

    if (Platform.isIOS) {
      showCupertinoModalPopup(
        context: context,
        builder: (context) => CupertinoActionSheet(
          title: Text(isProfileImage ? 'Profilbild' : 'Hintergrundbild'),
          actions: [
            CupertinoActionSheetAction(
              child: Text(imageExists
                  ? (isProfileImage
                  ? 'Profilbild wechseln'
                  : 'Hintergrundbild wechseln')
                  : (isProfileImage
                  ? 'Profilbild hinzufügen'
                  : 'Hintergrundbild hinzufügen')),
              onPressed: () {
                Navigator.pop(context);
                handleImageSelection();
              },
            ),
            if (imageExists)
              CupertinoActionSheetAction(
                child: Text(isProfileImage
                    ? 'Profilbild löschen'
                    : 'Hintergrundbild löschen'),
                isDestructiveAction: true,
                onPressed: () {
                  Navigator.pop(context);
                  deleteImage(imageType);
                },
              ),
          ],
          cancelButton: CupertinoActionSheetAction(
            child: Text('Abbrechen'),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        builder: (context) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(imageExists
                  ? (isProfileImage
                  ? 'Profilbild wechseln'
                  : 'Hintergrundbild wechseln')
                  : (isProfileImage
                  ? 'Profilbild hinzufügen'
                  : 'Hintergrundbild hinzufügen')),
              onTap: () {
                Navigator.pop(context);
                handleImageSelection();
              },
            ),
            if (imageExists)
              ListTile(
                title: Text(isProfileImage
                    ? 'Profilbild löschen'
                    : 'Hintergrundbild löschen'),
                leading: Icon(Icons.delete, color: Colors.red),
                onTap: () {
                  Navigator.pop(context);
                  deleteImage(imageType);
                },
              ),
          ],
        ),
      );
    }
  }

  Future<void> _deleteCompany() async {
    // Zeigen Sie einen Bestätigungsdialog an
    bool? shouldDelete = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Unternehmen löschen'),
        content: Text(
            'Möchten Sie dieses Unternehmen wirklich löschen? Dieser Vorgang kann nicht rückgängig gemacht werden.'),
        actions: [
          CupertinoDialogAction(
            child: Text('Abbrechen'),
            onPressed: () {
              Navigator.of(context).pop(
                  false); // Gibt 'false' zurück, um das Löschen abzubrechen
            },
          ),
          CupertinoDialogAction(
            child: Text('Löschen'),
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(context)
                  .pop(true); // Gibt 'true' zurück, um das Löschen fortzusetzen
            },
          ),
        ],
      ),
    );

    // Wenn der Benutzer die Löschung bestätigt hat
    if (shouldDelete == true) {
      try {
        // Löschen Sie alle Dokumente aus der 'company' Sammlung
        QuerySnapshot companyDocs = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('company')
            .get();
        for (DocumentSnapshot doc in companyDocs.docs) {
          await doc.reference.delete();
        }

        // Löschen Sie alle Dokumente aus der 'media' Sammlung
        QuerySnapshot mediaDocs = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('media')
            .get();
        for (DocumentSnapshot doc in mediaDocs.docs) {
          await doc.reference.delete();
        }

        // Überprüfen Sie, ob companyProfileImage existiert, bevor Sie versuchen, es zu löschen
        Reference companyProfileImageRef = FirebaseStorage.instance
            .ref('images/${user!.uid}/companyProfileImage');
        if ((await companyProfileImageRef.getMetadata()).updated != null) {
          await companyProfileImageRef.delete();
        }

        // Überprüfen Sie, ob companyBackgroundImage existiert, bevor Sie versuchen, es zu löschen
        Reference companyBackgroundImageRef = FirebaseStorage.instance
            .ref('images/${user!.uid}/companyBackgroundImage');
        if ((await companyBackgroundImageRef.getMetadata()).updated != null) {
          await companyBackgroundImageRef.delete();
        }

        // Löschen Sie alle Dateien im 'medien' Ordner
        ListResult medienFiles = await FirebaseStorage.instance
            .ref('images/${user!.uid}/medien')
            .listAll();
        for (Reference file in medienFiles.items) {
          await file.delete();
        }
      } catch (e) {
        print(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Ein Fehler ist aufgetreten. Bitte versuchen Sie es erneut.'),
          ),
        );
      } finally {
        // Weiterleitung zur profilePage.dart
        navigateToPrivateProfile();
      }
    }
  }

  void _showMenuOptions() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text('${profileData!['companyName'] ?? ''}'),
        actions: [
          CupertinoActionSheetAction(
            child: Text('Bearbeiten'),
            onPressed: () {
              Navigator.pop(context);
              navigateToEditCompanyProfile();
            },
          ),
          CupertinoActionSheetAction(
            child: Text('Löschen'),
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(context);
              await _deleteCompany();
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: Text('Abbrechen'),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Future<CroppedFile?> _cropImage(File imageFile) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 100,
      uiSettings: [
        AndroidUiSettings(
            toolbarTitle: 'Bild zuschneiden',
            toolbarColor: Colors.blue,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false),
        IOSUiSettings(
          title: 'Bild zuschneiden',
        ),
      ],
    );
    return croppedFile;
  }

  final userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    print("Aktuelle User ID: $userId");
    return WillPopScope(
        onWillPop: () async {
          return false;
        },
        child: StreamBuilder<DocumentSnapshot>(
          // stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('company').doc(user!.uid).snapshots(),
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .collection('company')
              .doc(user!.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            } else if (snapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Text('Fehler: ${snapshot.error}'),
                ),
              );
            } else {
              if (snapshot.data != null && snapshot.data!.exists) {
                profileData = snapshot.data!.data() as Map<String, dynamic>;

                // Standardbilder definieren
                ImageProvider backgroundImage =
                AssetImage('lib/assets/hintergrund.jpg');
                ImageProvider profileImage =
                AssetImage('lib/assets/standardprofilbild.jpg');

                // Überprüfen, ob companyBackgroundImage vorhanden ist und es verwenden, wenn es vorhanden ist
                if (profileData!['companyBackgroundImage'] != null &&
                    profileData!['companyBackgroundImage']!.isNotEmpty) {
                  backgroundImage = NetworkImage(
                      "${profileData!['companyBackgroundImage']}?v=${DateTime.now().millisecondsSinceEpoch}");
                }

                // Überprüfen, ob companyProfileImage vorhanden ist und es verwenden, wenn es vorhanden ist
                if (profileData!['companyProfileImage'] != null &&
                    profileData!['companyProfileImage']!.isNotEmpty) {
                  profileImage = NetworkImage(
                      "${profileData!['companyProfileImage']}?v=${DateTime.now().millisecondsSinceEpoch}");
                }

                List<Map<String, dynamic>> openingHours =
                List<Map<String, dynamic>>.from(
                    profileData!['openingHours'] ?? []);
                Map<String, Map<String, dynamic>> openingHoursMap = {};
                for (var entry in openingHours) {
                  openingHoursMap[entry['day']] = entry;
                }
                return DefaultTabController(
                  length: 3, // Anzahl der Tabs
                  child: Scaffold(
                    body: SingleChildScrollView(
                      child: Column(
                        children: [
                          Container(
                            height: 240,
                            child: Stack(
                              children: [
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  right: 0,
                                  child: Image(
                                    image: backgroundImage,
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 80,
                                  left: (MediaQuery.of(context).size.width -
                                      160) /
                                      2,
                                  child: Stack(
                                    children: [
                                      Container(
                                        width: 160,
                                        height: 160,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.grey,
                                            width: 2.0,
                                          ),
                                        ),
                                        child: CircleAvatar(
                                          radius: 50,
                                          backgroundImage: profileImage,
                                        ),
                                      ),
                                      Positioned(
                                        right: 55,
                                        bottom: 0,
                                        child: IconButton(
                                          icon: Icon(Icons.add_a_photo),
                                          color: Colors.white,
                                          onPressed: () => _showImageOptions(
                                              'companyProfileImage'),
                                        ),
                                      ),
                                      // Hier wird das private Profilbild hinzugefügt
                                      InkWell(
                                        onTap: navigateToPrivateProfile,
                                        child: FutureBuilder<
                                            Map<String, dynamic>?>(
                                          future: fetchPrivateProfileData(),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState ==
                                                ConnectionState.done &&
                                                snapshot.hasData) {
                                              String? privateProfileImageUrl =
                                              snapshot
                                                  .data!['profileImage'];
                                              if (privateProfileImageUrl !=
                                                  null &&
                                                  privateProfileImageUrl
                                                      .isNotEmpty) {
                                                return CircleAvatar(
                                                  radius: 25,
                                                  backgroundImage: NetworkImage(
                                                      privateProfileImageUrl),
                                                );
                                              }
                                            }
                                            return CircleAvatar(
                                              radius: 25,
                                              backgroundImage: AssetImage(
                                                  'lib/assets/standardprofilbild.jpg'),
                                            );
                                          },
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                Positioned(
                                  bottom: 35,
                                  right: 0,
                                  child: IconButton(
                                    icon: Icon(Icons.add_a_photo),
                                    color: Colors.white,
                                    onPressed: () => _showImageOptions(
                                        'companyBackgroundImage'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  width:
                                  48, // Dies sollte der ungefähren Breite des IconButton entsprechen
                                ),
                                Expanded(
                                  child: Text(
                                    '${profileData!['companyName'] ?? ''}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: _showMenuOptions,
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5.0),
                            child: Text(
                              '${profileData!['industry'] ?? ''}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 18, color: Colors.grey[600]),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5.0),
                            child: Text(
                              '${profileData!['description'] ?? ''}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600]),
                            ),
                          ),
                          TabBar(
                            labelColor: Colors.blue, //<-- selected text color
                            unselectedLabelColor:
                            Colors.black, //<-- Unselected text color
                            tabs: [
                              Tab(
                                text: 'Über Uns',
                              ),
                              Tab(text: 'Medien'),
                              Tab(text: 'Anzeigen'),
                            ],
                          ),
                          SizedBox(height: 20.0),
                          Container(
                            height: 500,
                            child: TabBarView(
                              children: [
                                Column(
                                  children: [
                                    Text(
                                      'Öffnungszeiten',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 10.0),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal:
                                          16.0), // Setzen Sie hier den gewünschten horizontalen Abstand
                                      child: Table(
                                        defaultVerticalAlignment:
                                        TableCellVerticalAlignment.middle,
                                        border: TableBorder.symmetric(
                                          inside: BorderSide(
                                              color: Colors.grey[300]!,
                                              width: 0.5),
                                          outside: BorderSide(
                                              color: Colors.grey[400]!,
                                              width: 1),
                                        ),
                                        children: [
                                          TableRow(
                                            children: [
                                              for (var day in [
                                                'Mo',
                                                'Di',
                                                'Mi',
                                                'Do',
                                                'Fr',
                                                'Sa',
                                                'So'
                                              ])
                                                Center(
                                                    child: Text(day,
                                                        style: TextStyle(
                                                            fontWeight:
                                                            FontWeight
                                                                .bold)))
                                            ],
                                          ),
                                          TableRow(
                                            children: [
                                              for (var fullDay in [
                                                'Montag',
                                                'Dienstag',
                                                'Mittwoch',
                                                'Donnerstag',
                                                'Freitag',
                                                'Samstag',
                                                'Sonntag'
                                              ])
                                                Center(
                                                    child: Text(openingHoursMap[
                                                    fullDay]
                                                    ?['startTime'] ??
                                                        '-'))
                                            ],
                                          ),
                                          TableRow(
                                            children: [
                                              for (var fullDay in [
                                                'Montag',
                                                'Dienstag',
                                                'Mittwoch',
                                                'Donnerstag',
                                                'Freitag',
                                                'Samstag',
                                                'Sonntag'
                                              ])
                                                Center(
                                                    child: openingHoursMap[
                                                    fullDay] !=
                                                        null
                                                        ? Text('-')
                                                        : Text('-'))
                                            ],
                                          ),
                                          TableRow(
                                            children: [
                                              for (var fullDay in [
                                                'Montag',
                                                'Dienstag',
                                                'Mittwoch',
                                                'Donnerstag',
                                                'Freitag',
                                                'Samstag',
                                                'Sonntag'
                                              ])
                                                Center(
                                                    child: Text(
                                                        openingHoursMap[fullDay]
                                                        ?['endTime'] ??
                                                            '-'))
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 20.0),
                                    Text(
                                      'Standort',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 0.0),
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Container(
                                        height: 200.0,
                                        child: FutureBuilder<LatLng?>(
                                          future: fetchCoordinates(),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return Center(
                                                  child:
                                                  CircularProgressIndicator());
                                            } else if (snapshot.hasError) {
                                              return Center(
                                                  child: Text(
                                                      'Fehler beim Abrufen der Koordinaten.'));
                                            } else if (snapshot.data != null) {
                                              return GoogleMap(
                                                initialCameraPosition:
                                                CameraPosition(
                                                  target: snapshot.data!,
                                                  zoom: 14.0,
                                                ),
                                                markers: {
                                                  Marker(
                                                    markerId: MarkerId(
                                                        'companyLocation'),
                                                    position: snapshot.data!,
                                                    infoWindow: InfoWindow(
                                                        title: 'Unternehmen'),
                                                  ),
                                                },
                                              );
                                            } else {
                                              return Center(
                                                  child: Text(
                                                      'Adresse nicht gefunden.'));
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: StreamBuilder<QuerySnapshot>(
                                          stream: FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(user!.uid)
                                              .collection('media')
                                              .orderBy('timestamp',
                                              descending:
                                              true) // Neueste Bilder zuerst
                                              .snapshots(),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return Center(
                                                  child:
                                                  CircularProgressIndicator());
                                            } else if (snapshot.hasError) {
                                              return Center(
                                                  child: Text(
                                                      'Fehler beim Abrufen der Medien.'));
                                            } else if (snapshot.hasData) {
                                              final mediaData = snapshot
                                                  .data!.docs
                                                  .map((doc) => doc.data()
                                              as Map<String, dynamic>)
                                                  .toList();
                                              return GridView.builder(
                                                gridDelegate:
                                                SliverGridDelegateWithFixedCrossAxisCount(
                                                  crossAxisCount: 3,
                                                  crossAxisSpacing: 2.0,
                                                  mainAxisSpacing: 2.0,
                                                ),
                                                itemCount: mediaData.length,
                                                itemBuilder: (context, index) {
                                                  return GestureDetector(
                                                    onLongPress: () {
                                                      if (Platform.isIOS) {
                                                        showCupertinoModalPopup(
                                                          context: context,
                                                          builder: (context) =>
                                                              CupertinoActionSheet(
                                                                actions: [
                                                                  CupertinoActionSheetAction(
                                                                    child: Text(
                                                                        'Löschen'),
                                                                    isDestructiveAction:
                                                                    true,
                                                                    onPressed: () {
                                                                      // Hier den Code zum Löschen des Bildes hinzufügen
                                                                      FirebaseFirestore
                                                                          .instance
                                                                          .collection(
                                                                          'users')
                                                                          .doc(user!
                                                                          .uid)
                                                                          .collection(
                                                                          'media')
                                                                          .doc(snapshot
                                                                          .data!
                                                                          .docs[
                                                                      index]
                                                                          .id)
                                                                          .delete();

                                                                      Navigator.pop(
                                                                          context);
                                                                    },
                                                                  ),
                                                                ],
                                                                cancelButton:
                                                                CupertinoActionSheetAction(
                                                                  child: Text(
                                                                      'Abbrechen'),
                                                                  onPressed: () {
                                                                    Navigator.pop(
                                                                        context);
                                                                  },
                                                                ),
                                                              ),
                                                        );
                                                      } else {
                                                        // Für Android-Geräte
                                                        showModalBottomSheet(
                                                          context: context,
                                                          builder: (context) =>
                                                              Column(
                                                                mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                                children: [
                                                                  ListTile(
                                                                    leading: Icon(
                                                                        Icons
                                                                            .delete),
                                                                    title: Text(
                                                                        'Löschen'),
                                                                    onTap: () {
                                                                      // Hier den Code zum Löschen des Bildes hinzufügen
                                                                      FirebaseFirestore
                                                                          .instance
                                                                          .collection(
                                                                          'users')
                                                                          .doc(user!
                                                                          .uid)
                                                                          .collection(
                                                                          'media')
                                                                          .doc(snapshot
                                                                          .data!
                                                                          .docs[
                                                                      index]
                                                                          .id)
                                                                          .delete();

                                                                      Navigator.pop(
                                                                          context);
                                                                    },
                                                                  ),
                                                                ],
                                                              ),
                                                        );
                                                      }
                                                    },
                                                    child: ZoomOverlay(
                                                      maxScale:
                                                      2.5, // Maximale Zoomstufe
                                                      minScale:
                                                      1.0, // Minimale Zoomstufe
                                                      child: Image.network(
                                                          mediaData[index]
                                                          ['imageUrl'],
                                                          fit: BoxFit.cover),
                                                    ),
                                                  );
                                                },
                                              );
                                            } else {
                                              return Center(
                                                  child: Text(
                                                      'Keine Medien gefunden.'));
                                            }
                                          },
                                        ),
                                      ),
                                      SizedBox(
                                          height:
                                          20) // Ein bisschen Abstand zum unteren Rand
                                    ],
                                  ),
                                ),
                                // Für den Tab "Anzeigen"
                                StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('ads')
                                        .where('userId', isEqualTo: userId)
                                        .where('adType', isEqualTo: 'companyAd')
                                        .snapshots(),
                                    builder: (BuildContext context,
                                        AsyncSnapshot<QuerySnapshot> snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return CircularProgressIndicator();
                                      }

                                      if (snapshot.hasError) {
                                        return Text("Fehler: ${snapshot.error}");
                                      }

                                      List<DocumentSnapshot> servicesListAds =
                                          snapshot.data!.docs;

                                      return SingleChildScrollView(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 16.0, right: 16.0),
                                              child: Column(
                                                children:
                                                servicesListAds.map((data) {
                                                  return FutureBuilder<
                                                      DocumentSnapshot>(
                                                    future: FirebaseFirestore
                                                        .instance
                                                        .collection('users')
                                                        .doc(data['userId'])
                                                        .collection('company')
                                                        .doc(data['userId'])
                                                        .get(),
                                                    builder: (BuildContext
                                                    context,
                                                        AsyncSnapshot<
                                                            DocumentSnapshot>
                                                        snapshot) {
                                                      if (snapshot
                                                          .connectionState ==
                                                          ConnectionState.done) {
                                                        if (snapshot.hasError) {
                                                          return Text(
                                                              "Fehler: ${snapshot.error}");
                                                        }

                                                        Map<String, dynamic>?
                                                        userData =
                                                        snapshot.data?.data()
                                                        as Map<String,
                                                            dynamic>?;
                                                        String?
                                                        companyProfileImageUrl =
                                                        userData?[
                                                        'companyProfileImage'];

                                                        return Slidable(
                                                          key: ValueKey(
                                                              data['userId']),
                                                          endActionPane:
                                                          ActionPane(
                                                            motion:
                                                            const ScrollMotion(),
                                                            children: [
                                                              SlidableAction(
                                                                onPressed: (context) {
                                                                  Navigator.push(
                                                                    context,
                                                                    MaterialPageRoute(
                                                                      builder: (context) => EditCompanyAdPage(companyAdId: data.id),
                                                                    ),
                                                                  );
                                                                },
                                                                backgroundColor: Colors.blue,
                                                                foregroundColor: Colors.white,
                                                                icon: Icons.edit,
                                                                label: 'Bearbeiten',
                                                              ),

                                                              SlidableAction(
                                                                onPressed:
                                                                    (context) {
                                                                  showDialog(
                                                                    context:
                                                                    context,
                                                                    builder:
                                                                        (BuildContext
                                                                    context) {
                                                                      if (Theme.of(context)
                                                                          .platform ==
                                                                          TargetPlatform
                                                                              .iOS) {
                                                                        return CupertinoAlertDialog(
                                                                          title: Text(
                                                                              'Löschen bestätigen'),
                                                                          content:
                                                                          Text('Möchten Sie dieses Stellenangebot wirklich löschen?'),
                                                                          actions: <Widget>[
                                                                            CupertinoDialogAction(
                                                                              child:
                                                                              Text('Abbrechen'),
                                                                              onPressed:
                                                                                  () {
                                                                                Navigator.of(context).pop();
                                                                              },
                                                                            ),
                                                                            CupertinoDialogAction(
                                                                              child:
                                                                              Text('Löschen'),
                                                                              isDestructiveAction:
                                                                              true,
                                                                              onPressed:
                                                                                  () {
                                                                                FirebaseFirestore.instance.collection('companyAds').doc(data.id).delete().then((_) {
                                                                                  Navigator.of(context).pop();
                                                                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CompanyAd erfolgreich gelöscht!')));
                                                                                }).catchError((error) {
                                                                                  Navigator.of(context).pop();
                                                                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler beim Löschen: $error')));
                                                                                });
                                                                              },
                                                                            ),
                                                                          ],
                                                                        );
                                                                      } else {
                                                                        return AlertDialog(
                                                                          title: Text(
                                                                              'Löschen bestätigen'),
                                                                          content:
                                                                          Text('Möchten Sie dieses Stellenangebot wirklich löschen?'),
                                                                          actions: <Widget>[
                                                                            TextButton(
                                                                              child:
                                                                              Text('Abbrechen'),
                                                                              onPressed:
                                                                                  () {
                                                                                Navigator.of(context).pop();
                                                                              },
                                                                            ),
                                                                            TextButton(
                                                                              child:
                                                                              Text('Löschen'),
                                                                              onPressed:
                                                                                  () {
                                                                                FirebaseFirestore.instance.collection('companyAds').doc(data.id).delete().then((_) {
                                                                                  Navigator.of(context).pop();
                                                                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CompanyAd erfolgreich gelöscht!')));
                                                                                }).catchError((error) {
                                                                                  Navigator.of(context).pop();
                                                                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler beim Löschen: $error')));
                                                                                });
                                                                              },
                                                                            ),
                                                                          ],
                                                                        );
                                                                      }
                                                                    },
                                                                  );
                                                                },
                                                                backgroundColor:
                                                                Colors.red,
                                                                foregroundColor:
                                                                Colors.white,
                                                                icon:
                                                                Icons.delete,
                                                                label: 'Löschen',
                                                              ),
                                                            ],
                                                          ),
                                                          child: GestureDetector(
                                                            onTap: () {
                                                              Navigator.push(
                                                                context,
                                                                MaterialPageRoute(
                                                                  builder: (context) => CompanyAdDetailPage(
                                                                      data: data
                                                                          .data()
                                                                      as Map<
                                                                          String,
                                                                          dynamic>,
                                                                      companyProfileImageUrl:
                                                                      companyProfileImageUrl ??
                                                                          '',
                                                                      companyName:
                                                                      userData?['companyName'] ??
                                                                          ''),
                                                                ),
                                                              );
                                                            },
                                                            child: Container(
                                                              width: MediaQuery.of(
                                                                  context)
                                                                  .size
                                                                  .width *
                                                                  0.9,
                                                              child: Card(
                                                                child: Padding(
                                                                  padding:
                                                                  const EdgeInsets
                                                                      .all(
                                                                      8.0),
                                                                  child: Row(
                                                                    children: [
                                                                      CircleAvatar(
                                                                        backgroundImage:
                                                                        NetworkImage(companyProfileImageUrl ??
                                                                            ''),
                                                                        radius:
                                                                        30.0,
                                                                      ),
                                                                      SizedBox(
                                                                          width:
                                                                          10),
                                                                      Expanded(
                                                                        child:
                                                                        Column(
                                                                          crossAxisAlignment:
                                                                          CrossAxisAlignment.start,
                                                                          children: [
                                                                            Row(
                                                                              mainAxisAlignment:
                                                                              MainAxisAlignment.spaceBetween,
                                                                              children: [
                                                                                Text(userData?['companyName'] ?? '', style: TextStyle(fontSize: 14)),
                                                                                Text(DateFormat('dd.MM.yyyy').format(DateTime.fromMillisecondsSinceEpoch(data['createdAt'].seconds * 1000)), style: TextStyle(fontSize: 14)),
                                                                              ],
                                                                            ),
                                                                            Text(
                                                                                data['jobOfferTopic'],
                                                                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                                                            Row(
                                                                              mainAxisAlignment:
                                                                              MainAxisAlignment.spaceBetween,
                                                                              children: [
                                                                                Text(data['at'], style: TextStyle(fontSize: 14)),
                                                                              ],
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        );
                                                      } else {
                                                        return CircularProgressIndicator();
                                                      }
                                                    },
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    })
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              } else {
                return Scaffold(
                  body: Center(
                    child: Text('Unternehmensprofil gelöscht.'),
                  ),
                );
              }
            }
          },
        ));
  }
}
