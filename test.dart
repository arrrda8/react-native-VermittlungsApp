import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:linkmi/main.dart';
import 'package:linkmi/platform_widgets.dart';
import 'package:linkmi/serviceProvider/editServiceProviderProfile_page.dart';
import 'package:zoom_pinch_overlay/zoom_pinch_overlay.dart';
import 'package:linkmi/serviceProvider/addServices_page.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:linkmi/serviceProvider/editServices_page.dart';
import 'package:flutter_reorderable_list/flutter_reorderable_list.dart';


class ServiceProviderProfilePage extends StatefulWidget {
  @override
  _ServiceProviderProfilePageState createState() => _ServiceProviderProfilePageState();
}

int _currentIndex = 0;

class _ServiceProviderProfilePageState extends State<ServiceProviderProfilePage> {
  User? user;
  Map<String, dynamic>? profileData;
  int selectedTabIndex = 0;
  List<Map<String, dynamic>> servicesList = [];
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    fetchServices();
  }

  Future<Map<String, dynamic>?> fetchData() async {
    if (user != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users')
            .doc(user!.uid)
            .collection('company')
            .doc(user!.uid)
            .get();
        return doc.data() as Map<String, dynamic>?;
      } catch (e) {
        print(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ein Fehler ist aufgetreten. Bitte versuchen Sie es erneut.'),
          ),
        );
        return null;
      }
    }
    return null;
  }

  void navigateToEditServiceProviderProfilePage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditServiceProviderProfilePage()),
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
    final url = 'https://maps.googleapis.com/maps/api/geocode/json?address=$address&key=AIzaSyA5VmY2x0mZYYK6-5PPuU7Im1DEOBT8ju0';
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
      final address = '${profileData!['zipCode']} ${profileData!['city']}';
      return await getCoordinatesFromAddress(address);
    }
    return null;
  }

  Future<Map<String, dynamic>?> fetchPrivateProfileData() async {
    if (user != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
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
      await FirebaseStorage.instance.ref('images/${user!.uid}/$imageType').putFile(file);
      final String url = await FirebaseStorage.instance.ref('images/${user!.uid}/$imageType').getDownloadURL();

      // Aktualisieren Sie die richtige Firestore-Sammlung basierend auf dem Bildtyp
      if (imageType == 'companyProfileImage' || imageType == 'companyBackgroundImage') {
        await FirebaseFirestore.instance.collection('users')
            .doc(user!.uid)
            .collection('company')
            .doc(user!.uid)
            .update({imageType: url});
      } else {
        await FirebaseFirestore.instance.collection('users')
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
          content: Text('Ein Fehler ist aufgetreten. Bitte versuchen Sie es erneut.'),
        ),
      );
    }
  }


  Future<void> deleteImage(String imageType) async {
    try {
      // Bild aus Firebase Storage löschen
      await FirebaseStorage.instance.ref('images/${user!.uid}/$imageType').delete();

      // Bild-URL aus Firestore löschen
      if (imageType == 'companyProfileImage' || imageType == 'companyBackgroundImage') {
        await FirebaseFirestore.instance.collection('users')
            .doc(user!.uid)
            .collection('company')
            .doc(user!.uid)
            .update({imageType: FieldValue.delete()});
      } else {
        await FirebaseFirestore.instance.collection('users')
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
          content: Text('Ein Fehler ist aufgetreten. Bitte versuchen Sie es erneut.'),
        ),
      );
    }
  }

  void _showImageOptions(String imageType) async {
    final bool isProfileImage = imageType == 'companyProfileImage';
    final bool imageExists = profileData![imageType] != null && profileData![imageType]!.isNotEmpty;

    void handleImageSelection() async {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final File originalFile = File(pickedFile.path);
        final CroppedFile? croppedFile = await _cropImage(originalFile);
        if (croppedFile != null) {
          final File croppedFinalFile = File(croppedFile.path); // Konvertieren Sie CroppedFile in File
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
              child: Text(imageExists ? (isProfileImage ? 'Profilbild wechseln' : 'Hintergrundbild wechseln') : (isProfileImage ? 'Profilbild hinzufügen' : 'Hintergrundbild hinzufügen')),
              onPressed: () {
                Navigator.pop(context);
                handleImageSelection();
              },
            ),
            if (imageExists)
              CupertinoActionSheetAction(
                child: Text(isProfileImage ? 'Profilbild löschen' : 'Hintergrundbild löschen'),
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
          children: <Widget> [
            ListTile(
              title: Text(imageExists ? (isProfileImage ? 'Profilbild wechseln' : 'Hintergrundbild wechseln') : (isProfileImage ? 'Profilbild hinzufügen' : 'Hintergrundbild hinzufügen')),
              onTap: () {
                Navigator.pop(context);
                handleImageSelection();
              },
            ),
            if (imageExists)
              ListTile(
                title: Text(isProfileImage ? 'Profilbild löschen' : 'Hintergrundbild löschen'),
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
        content: Text('Möchten Sie dieses Unternehmen wirklich löschen? Dieser Vorgang kann nicht rückgängig gemacht werden.'),
        actions: [
          CupertinoDialogAction(
            child: Text('Abbrechen'),
            onPressed: () {
              Navigator.of(context).pop(false); // Gibt 'false' zurück, um das Löschen abzubrechen
            },
          ),
          CupertinoDialogAction(
            child: Text('Löschen'),
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(context).pop(true); // Gibt 'true' zurück, um das Löschen fortzusetzen
            },
          ),
        ],
      ),
    );

    // Wenn der Benutzer die Löschung bestätigt hat
    if (shouldDelete == true) {
      try {
        // Löschen Sie alle Dokumente aus der 'company' Sammlung
        QuerySnapshot companyDocs = await FirebaseFirestore.instance.collection('users')
            .doc(user!.uid)
            .collection('company')
            .get();
        for (DocumentSnapshot doc in companyDocs.docs) {
          await doc.reference.delete();
        }

        // Löschen Sie alle Dokumente aus der 'media' Sammlung
        QuerySnapshot mediaDocs = await FirebaseFirestore.instance.collection('users')
            .doc(user!.uid)
            .collection('media')
            .get();
        for (DocumentSnapshot doc in mediaDocs.docs) {
          await doc.reference.delete();
        }

        // Überprüfen Sie, ob companyProfileImage existiert, bevor Sie versuchen, es zu löschen
        Reference companyProfileImageRef = FirebaseStorage.instance.ref('images/${user!.uid}/companyProfileImage');
        if ((await companyProfileImageRef.getMetadata()).updated != null) {
          await companyProfileImageRef.delete();
        }

        // Überprüfen Sie, ob companyBackgroundImage existiert, bevor Sie versuchen, es zu löschen
        Reference companyBackgroundImageRef = FirebaseStorage.instance.ref('images/${user!.uid}/companyBackgroundImage');
        if ((await companyBackgroundImageRef.getMetadata()).updated != null) {
          await companyBackgroundImageRef.delete();
        }

        // Löschen Sie alle Dateien im 'medien' Ordner
        ListResult medienFiles = await FirebaseStorage.instance.ref('images/${user!.uid}/medien').listAll();
        for (Reference file in medienFiles.items) {
          await file.delete();
        }
      } catch (e) {
        print(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ein Fehler ist aufgetreten. Bitte versuchen Sie es erneut.'),
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
              navigateToEditServiceProviderProfilePage();
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
            lockAspectRatio: false
        ),
        IOSUiSettings(
          title: 'Bild zuschneiden',
        ),
      ],
    );
    return croppedFile;
  }

  Future<void> fetchServices() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('company')
          .where(FieldPath.documentId, isNotEqualTo: user!.uid)
          .get();

      setState(() {
        servicesList = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      });
      refreshNotifier.value++;
    } catch (error) {
      print(error);
    }
  }

  bool _onReorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = servicesList.removeAt(oldIndex);
    servicesList.insert(newIndex, item);
    setState(() {});
    return true;
  }

  final refreshNotifier = ValueNotifier<int>(0);


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users')
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
              ImageProvider backgroundImage = AssetImage('lib/assets/hintergrund.jpg');
              ImageProvider profileImage = AssetImage('lib/assets/standardprofilbild.jpg');

              // Überprüfen, ob companyBackgroundImage vorhanden ist und es verwenden, wenn es vorhanden ist
              if (profileData!['companyBackgroundImage'] != null && profileData!['companyBackgroundImage']!.isNotEmpty) {
                backgroundImage = NetworkImage("${profileData!['companyBackgroundImage']}?v=${DateTime.now().millisecondsSinceEpoch}");
              }

              // Überprüfen, ob companyProfileImage vorhanden ist und es verwenden, wenn es vorhanden ist
              if (profileData!['companyProfileImage'] != null && profileData!['companyProfileImage']!.isNotEmpty) {
                profileImage = NetworkImage("${profileData!['companyProfileImage']}?v=${DateTime.now().millisecondsSinceEpoch}");
              }
              return DefaultTabController(
                  length: 3, // Anzahl der Tabs
                  child: Scaffold(
                      key: _scaffoldMessengerKey,
                      body: CustomScrollView(
                          slivers: [
                            SliverList(
                                delegate: SliverChildListDelegate(
                                    [
                                      Container(
                                        height: 240,
                                        child: Stack(
                                          children: <Widget> [
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
                                              left: (MediaQuery.of(context).size.width - 160) / 2,
                                              child: Stack(
                                                children: <Widget>[
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
                                                      onPressed: () => _showImageOptions('companyProfileImage'),
                                                    ),
                                                  ),
                                                  // Hier wird das private Profilbild hinzugefügt
                                                  InkWell(
                                                    onTap: navigateToPrivateProfile,
                                                    child: FutureBuilder<Map<String, dynamic>?>(
                                                      future: fetchPrivateProfileData(),
                                                      builder: (context, snapshot) {
                                                        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                                                          String? privateProfileImageUrl = snapshot.data!['profileImage'];
                                                          if (privateProfileImageUrl != null && privateProfileImageUrl.isNotEmpty) {
                                                            return CircleAvatar(
                                                              radius: 25,
                                                              backgroundImage: NetworkImage(privateProfileImageUrl),
                                                            );
                                                          }
                                                        }
                                                        return CircleAvatar(
                                                          radius: 25,
                                                          backgroundImage: AssetImage('lib/assets/standardprofilbild.jpg'),
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
                                                onPressed: () => _showImageOptions('companyBackgroundImage'),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: <Widget> [
                                            Container(
                                              width: 48, // Dies sollte der ungefähren Breite des IconButton entsprechen
                                            ),
                                            Expanded(
                                              child: Text(
                                                '${profileData!['companyName'] ?? ''}',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 5.0),
                                        child: Text(
                                          '${profileData!['description'] ?? ''}',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                        ),
                                      ),
                                    ]
                                )
                            ),

                            SliverStickyHeader(
                              header: Container(
                                color: Colors.white,
                                child: TabBar(
                                  labelColor: Colors.blue,
                                  unselectedLabelColor: Colors.black,
                                  tabs: [
                                    Tab(text: 'Über mich'),
                                    Tab(text: 'Medien'),
                                    Tab(text: 'Anzeigen'),
                                  ],
                                ),
                              ),
                              sliver: SliverFillRemaining(
                                child: TabBarView(
                                  children: <Widget>[
                                    SingleChildScrollView(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,  // Dies sorgt für den Abstand zwischen Text und Icon
                                              children: [
                                                Text(
                                                  'Dienstleistungen',
                                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                                ),
                                                IconButton(
                                                  icon: Icon(Icons.add),
                                                  onPressed: () async {
                                                    final result = await Navigator.push(
                                                      context,
                                                      MaterialPageRoute(builder: (context) => AddServicesPage()),
                                                    );

                                                    if (result == true) {
                                                      fetchServices();  //
                                                    }
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),

                                          Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: SingleChildScrollView(
                                                reverse: true,
                                                child: Column(
                                                  children: [
                                                    if (servicesList.isEmpty)
                                                      Center(child: Text('Keine Dienstleistungen im Angebot'))
                                                    else
                                                      ValueListenableBuilder<int>(
                                                        valueListenable: refreshNotifier,
                                                        builder: (context, value, child) {
                                                          return ListView.builder(
                                                            key: UniqueKey(),
                                                            // physics: NeverScrollableScrollPhysics(), // Verhindert das Scrollen der inneren ListView
                                                            shrinkWrap: true, // Damit die ListView ihre Größe an den Inhalt anpasst
                                                            itemCount: servicesList.length,
                                                            itemBuilder: (context, index) {
                                                              final serviceData = servicesList[index];
                                                              final Color cardColor = Color(int.parse(serviceData['color'], radix: 16));
                                                              final Color textColor = Color(int.parse(serviceData['textColor'], radix: 16));
                                                              final List services = serviceData['services'];

                                                              return Slidable(
                                                                  endActionPane: ActionPane(
                                                                    motion: const BehindMotion(),
                                                                    children: [
                                                                      SlidableAction(
                                                                        label: 'Bearbeiten',
                                                                        backgroundColor: Colors.blue,
                                                                        icon: Icons.edit,
                                                                        onPressed: (context) {
                                                                          Navigator.push(
                                                                            context,
                                                                            MaterialPageRoute(
                                                                              builder: (context) => EditServicesPage(serviceData: serviceData),
                                                                            ),
                                                                          );
                                                                        },
                                                                      ),
                                                                      SlidableAction(
                                                                        label: 'Löschen',
                                                                        backgroundColor: Colors.red,
                                                                        icon: Icons.delete,
                                                                        onPressed: (context) async {
                                                                          final shouldDelete = await showDeleteConfirmation(context);
                                                                          if (shouldDelete == true) {
                                                                            // Firestore Dokument löschen
                                                                            await FirebaseFirestore.instance
                                                                                .collection('users')
                                                                                .doc(user!.uid)
                                                                                .collection('company')
                                                                                .doc(serviceData['servicesId']) // Verwenden Sie serviceData['servicesId'] als Dokument-ID
                                                                                .delete();

                                                                            // Bild aus Firebase Storage löschen
                                                                            final ref = FirebaseStorage.instance
                                                                                .ref('images/${user!.uid}/${serviceData['servicesId']}');

                                                                            try {
                                                                              // Versuchen Sie, die Download-URL zu erhalten
                                                                              final url = await ref.getDownloadURL();

                                                                              // Wenn die obige Zeile erfolgreich ist, existiert das Bild und kann gelöscht werden
                                                                              await ref.delete();
                                                                              print("Bild erfolgreich gelöscht");
                                                                            } catch (e) {
                                                                              if (e is FirebaseException && e.code == 'object-not-found') {
                                                                                // Das Bild existiert nicht, also tun Sie nichts
                                                                                print("Bild existiert nicht, nichts zu löschen");
                                                                              } else {
                                                                                // Ein anderer Fehler ist aufgetreten
                                                                                print("Ein Fehler ist aufgetreten: $e");
                                                                              }
                                                                            }

                                                                            // Optional: Aktualisieren Sie den UI-Status oder zeigen Sie eine Benachrichtigung an, dass das Löschen erfolgreich war
                                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                                              SnackBar(content: Text('Erfolgreich gelöscht!')),
                                                                            );
                                                                          }
                                                                        },
                                                                      ),

                                                                    ],
                                                                  ),
                                                                  child: Card(
                                                                    color: cardColor,
                                                                    child: Column(
                                                                      children: <Widget>[
                                                                        if (serviceData['imageUrl'] != null)
                                                                          Image.network(serviceData['imageUrl'], fit: BoxFit.cover, height: 100, width: double.infinity),
                                                                        ExpansionTile(
                                                                          title: Text(serviceData['category'], style: TextStyle(color: textColor)),
                                                                          trailing: Icon(Icons.arrow_drop_down, color: textColor),
                                                                          children: services.map<Widget>((s) {
                                                                            return ListTile(
                                                                              title: Text(s['service'], style: TextStyle(color: textColor)),
                                                                              trailing: Text(s['price'] == null || s['price'].isEmpty ? "auf Anfrage" : '${s['price']} €', style: TextStyle(color: textColor)),
                                                                            );
                                                                          }).toList(),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ));
                                                            },
                                                          );},)
                                                  ],
                                                ),)
                                          ),
                                          SizedBox(height: 20.0),
                                          Padding(
                                            padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,  // Dies sorgt für den Abstand zwischen Text und Icon
                                              children: [
                                                Text(
                                                  'Standort',
                                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(height: 0.0),
                                          Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Container(
                                              height: 200.0,
                                              child: FutureBuilder<LatLng?>(
                                                future: fetchCoordinates(),
                                                builder: (context, snapshot) {
                                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                                    return Center(child: CircularProgressIndicator());
                                                  } else if (snapshot.hasError) {
                                                    return Center(child: Text('Fehler beim Abrufen der Koordinaten.'));
                                                  } else if (snapshot.data != null) {
                                                    return GoogleMap(
                                                      initialCameraPosition: CameraPosition(
                                                        target: snapshot.data!,
                                                        zoom: 14.0,
                                                      ),
                                                      markers: {
                                                        Marker(
                                                          markerId: MarkerId('companyLocation'),
                                                          position: snapshot.data!,
                                                          infoWindow: InfoWindow(title: 'Unternehmen'),
                                                        ),
                                                      },
                                                    );
                                                  } else {
                                                    return Center(child: Text('Adresse nicht gefunden.'));
                                                  }
                                                },
                                              ),),),
                                        ],
                                      ),
                                    ),
                                    SingleChildScrollView(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Flexible(
                                            child: StreamBuilder<QuerySnapshot>(
                                              stream: FirebaseFirestore.instance.collection('users')
                                                  .doc(user!.uid)
                                                  .collection('media')
                                                  .orderBy('timestamp', descending: true) // Neueste Bilder zuerst
                                                  .snapshots(),
                                              builder: (context, snapshot) {
                                                if (snapshot.connectionState == ConnectionState.waiting) {
                                                  return Center(child: CircularProgressIndicator());
                                                } else if (snapshot.hasError) {
                                                  return Center(child: Text('Fehler beim Abrufen der Medien.'));
                                                } else if (snapshot.hasData) {
                                                  final mediaData = snapshot.data!.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
                                                  return GridView.builder(
                                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
                                                              builder: (context) => CupertinoActionSheet(
                                                                actions: [
                                                                  CupertinoActionSheetAction(
                                                                    child: Text('Löschen'),
                                                                    isDestructiveAction: true,
                                                                    onPressed: () {
                                                                      // Hier den Code zum Löschen des Bildes hinzufügen
                                                                      FirebaseFirestore.instance.collection('users')
                                                                          .doc(user!.uid)
                                                                          .collection('media')
                                                                          .doc(snapshot.data!.docs[index].id)
                                                                          .delete();

                                                                      Navigator.pop(context);
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
                                                            // Für Android-Geräte
                                                            showModalBottomSheet(
                                                              context: context,
                                                              builder: (context) => Column(
                                                                mainAxisSize: MainAxisSize.min,
                                                                children: <Widget>[
                                                                  ListTile(
                                                                    leading: Icon(Icons.delete),
                                                                    title: Text('Löschen'),
                                                                    onTap: () {
                                                                      // Hier den Code zum Löschen des Bildes hinzufügen
                                                                      FirebaseFirestore.instance.collection('users')
                                                                          .doc(user!.uid)
                                                                          .collection('media')
                                                                          .doc(snapshot.data!.docs[index].id)
                                                                          .delete();

                                                                      Navigator.pop(context);
                                                                    },
                                                                  ),
                                                                ],
                                                              ),
                                                            );
                                                          }
                                                        },
                                                        child: ZoomOverlay(
                                                          maxScale: 2.5, // Maximale Zoomstufe
                                                          minScale: 1.0, // Minimale Zoomstufe
                                                          child: Image.network(mediaData[index]['imageUrl'], fit: BoxFit.cover),
                                                        ),
                                                      );
                                                    },
                                                  );
                                                } else {
                                                  return Center(child: Text('Keine Medien gefunden.'));
                                                }
                                              },
                                            ),
                                          ),
                                          ElevatedButton(
                                            child: Icon(Icons.add),
                                            onPressed: () async {
                                              final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
                                              if (pickedFile != null) {
                                                final File originalFile = File(pickedFile.path);
                                                final CroppedFile? cropped = await _cropImage(originalFile);
                                                if (cropped != null) {
                                                  final File croppedFile = File(cropped.path); // Konvertieren von CroppedFile zu File
                                                  final ref = FirebaseStorage.instance.ref('images/${user!.uid}/medien/${DateTime.now().toIso8601String()}.jpg');
                                                  await ref.putFile(croppedFile);
                                                  final imageUrl = await ref.getDownloadURL();
                                                  await FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('media').add({'imageUrl': imageUrl,'timestamp': FieldValue.serverTimestamp()});
                                                }
                                              }
                                            },
                                          ),

                                          SizedBox(height: 20) // Ein bisschen Abstand zum unteren Rand
                                        ],
                                      ),
                                    ),
                                    SingleChildScrollView(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                        Padding(
                                        padding: const EdgeInsets.only(left: 16.0),
                                          child: Text(
                                          'Anzeige',
                                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ]),
                                    )
                                    )
                                  ],
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
      ),
    );
  }}

