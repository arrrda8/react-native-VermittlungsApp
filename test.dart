import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:linkmi/editAboutMe_page.dart';
import 'package:linkmi/addWorkingExperience_page.dart';
import 'package:linkmi/editWorkingExperience_page.dart';
import 'package:linkmi/company/createCompanyProfile_page.dart';
import 'package:linkmi/company/companyNavigator.dart';
import 'package:linkmi/serviceProvider/createServiceProviderProfile_page.dart';
import 'package:linkmi/serviceProvider/serviceProviderNavigator.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? user;
  Map<String, dynamic>? profileData;
  List<String> skills = [];
  TextEditingController skillController = TextEditingController();

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
  }

  Future<Map<String, dynamic>> fetchCompanyData() async {
    if (user != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('company')
            .doc(user!.uid)
            .get();
        return doc.data() as Map<String, dynamic>? ?? {};
      } catch (e) {
        print(e);
        return {};
      }
    }
    return {};
  }

  Future<Map<String, dynamic>?> fetchData() async {
    if (user != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();
        if (doc.exists) {
          return doc.data() as Map<String, dynamic>?;
        } else {
          return null;
        }
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

  Future<void> uploadImage(ImageSource source, String imageType) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      final File file = File(pickedFile.path);
      try {
        await FirebaseStorage.instance
            .ref('images/${user!.uid}/$imageType')
            .putFile(file);
        final String url = await FirebaseStorage.instance
            .ref('images/${user!.uid}/$imageType')
            .getDownloadURL();
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .update({imageType: url});
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kein Bild ausgewählt.'),
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
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({imageType: FieldValue.delete()});

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

  void _showImageOptions(String imageType) {
    final bool isProfileImage = imageType == 'profileImage';
    final bool imageExists =
        profileData![imageType] != null && profileData![imageType]!.isNotEmpty;

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
                uploadImage(ImageSource.gallery, imageType);
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
                uploadImage(ImageSource.gallery, imageType);
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

  void _showCompanyOptions() {
    if (Platform.isIOS) {
      showCupertinoModalPopup(
        context: context,
        builder: (context) => CupertinoActionSheet(
          title: Text('Unternehmensseite erstellen'),
          actions: [
            CupertinoActionSheetAction(
              child: Text('Ich besitze ein Betrieb'),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateCompanyProfilePage(),
                  ),
                );
              },
            ),
            CupertinoActionSheetAction(
              child: Text('Ich biete Dienstleistungen an'),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateServiceProviderProfilePage(),
                  ),
                );
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
              title: Text('Ich besitze ein Betrieb'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateCompanyProfilePage(),
                  ),
                );
              },
            ),
            ListTile(
              title: Text('Ich biete Dienstleistungen an'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateServiceProviderProfilePage(),
                  ),
                );
              },
            ),
          ],
        ),
      );
    }
  }

  String generateJobText(String? currentJob, String? industry, String? city) {
    if (currentJob != null && currentJob.isNotEmpty) {
      if (industry != null && industry.isNotEmpty) {
        if (city != null && city.isNotEmpty) {
          return '$currentJob @ $industry in $city';
        } else {
          return '$currentJob @ $industry';
        }
      } else if (city != null && city.isNotEmpty) {
        return '$currentJob in $city';
      } else {
        return currentJob;
      }
    } else if (industry != null && industry.isNotEmpty) {
      if (city != null && city.isNotEmpty) {
        return '$industry in $city';
      } else {
        return industry;
      }
    } else if (city != null && city.isNotEmpty) {
      return city;
    } else {
      return '';
    }
  }

  int calculateAge(DateTime birthday) {
    final currentDate = DateTime.now();
    int age = currentDate.year - birthday.year;
    if (currentDate.month < birthday.month ||
        (currentDate.month == birthday.month &&
            currentDate.day < birthday.day)) {
      age--;
    }
    return age;
  }

  Future<void> updateSkillsInFirestore() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({'skills': skills});
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
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
          profileData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          skills = List<String>.from(profileData!['skills'] ?? []);

          ImageProvider backgroundImage =
          AssetImage('lib/assets/hintergrund.jpg');
          ImageProvider profileImage =
          AssetImage('lib/assets/standardprofilbild.jpg');
          final ImageProvider defaultCompanyImage =
          AssetImage('lib/assets/standardprofilbild.jpg');

          if (profileData!['backgroundImage'] != null &&
              profileData!['backgroundImage']!.isNotEmpty) {
            backgroundImage = NetworkImage(profileData!['backgroundImage']!);
          }

          if (profileData!['profileImage'] != null &&
              profileData!['profileImage']!.isNotEmpty) {
            profileImage = NetworkImage(profileData!['profileImage']!);
          }

          final birthdayString = profileData!['birthday'];
          DateTime? birthday;
          if (birthdayString != null && birthdayString.isNotEmpty) {
            final List<String> dateParts = birthdayString.split('.');
            if (dateParts.length == 3) {
              birthday = DateTime.parse(dateParts.reversed.join('-'));
            }
          }

          List<Map<String, dynamic>> workingExperience =
          List<Map<String, dynamic>>.from(
              profileData!['workingExperience'] ?? []);
          workingExperience.sort((a, b) {
            final aFrom = int.parse(a['from'].split('/').reversed.join());
            final bFrom = int.parse(b['from'].split('/').reversed.join());
            return bFrom.compareTo(aFrom);
          });

          return Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    height:
                    240, // Dies ist die kombinierte Höhe des Hintergrundbildes und des Profilbildes
                    child: Stack(
                      children: [
                        Stack(
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
                              top:
                              80, // 200 ist die Höhe des Hintergrundbildes und 104 ist die Größe des Profilbilds (einschließlich des Rahmens)
                              left: (MediaQuery.of(context).size.width - 160) /
                                  2, // Hiermit wird das Profilbild horizontal zentriert
                              child: Stack(
                                children: [
                                  Container(
                                    width:
                                    160, // Durchmesser des CircleAvatar + 2 * Breite des Rahmens
                                    height:
                                    160, // Durchmesser des CircleAvatar + 2 * Breite des Rahmens
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.grey, // Farbe des Rahmens
                                        width: 2.0, // Breite des Rahmens
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
                                      onPressed: () =>
                                          _showImageOptions('profileImage'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              bottom: 35,
                              right: 0,
                              child: IconButton(
                                icon: Icon(Icons.add_a_photo),
                                color: Colors.white,
                                onPressed: () =>
                                    _showImageOptions('backgroundImage'),
                              ),
                            ),
                            Positioned(
                              top: 180,
                              left: 290,
                              child: FutureBuilder<Map<String, dynamic>>(
                                future: fetchCompanyData(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.done) {
                                    if (snapshot.hasData &&
                                        snapshot.data!.isNotEmpty) {
                                      ImageProvider imageProvider;
                                      if (snapshot
                                          .data!['companyProfileImage'] !=
                                          null) {
                                        imageProvider = NetworkImage(snapshot
                                            .data!['companyProfileImage']);
                                      } else {
                                        imageProvider =
                                            defaultCompanyImage; // Stellen Sie sicher, dass Sie eine Standardbildvariable haben
                                      }

                                      return GestureDetector(
                                        onTap: () {
                                          if (snapshot.data!['type'] ==
                                              'Betrieb') {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    CompanyNavigator(
                                                        initialIndex: 4),
                                              ),
                                            );
                                          } else if (snapshot.data!['type'] ==
                                              'Service Provider') {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ServiceProviderNavigator(),
                                              ),
                                            );
                                          }
                                        },
                                        child: CircleAvatar(
                                          backgroundImage: imageProvider,
                                          radius: 20,
                                        ),
                                      );
                                    } else {
                                      return GestureDetector(
                                        onTap: _showCompanyOptions,
                                        child: CircleAvatar(
                                          radius: 20,
                                          backgroundColor: Colors.blue,
                                          child: Icon(Icons.add,
                                              color: Colors.white),
                                        ),
                                      );
                                    }
                                  } else {
                                    return Container();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                birthday != null
                                    ? '${profileData!['firstName'] ?? ''} ${profileData!['lastName'] ?? ''}, ${calculateAge(birthday)}'
                                    : '${profileData!['firstName'] ?? ''} ${profileData!['lastName'] ?? ''}',
                                style: TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditAboutMePage(
                                        profileData: profileData ?? {}),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        Text(
                            generateJobText(profileData!['currentJob'],
                                profileData!['industry'], profileData!['city']),
                            style: TextStyle(color: Colors.grey)),
                        if (profileData!['profileSlogan'] != null &&
                            profileData!['profileSlogan']!.isNotEmpty)
                          Text(profileData!['profileSlogan']!,
                              style: TextStyle(fontStyle: FontStyle.italic)),
                        Divider(),
                        Container(
                          height: 50,
                          child: Stack(
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text('Berufserfahrung',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                              ),
                              Positioned(
                                right: 0,
                                child: IconButton(
                                  icon: Icon(Icons.add),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              AddWorkingExperiencePage()),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        workingExperience.isNotEmpty
                            ? Column(
                          children:
                          List<Widget>.from(workingExperience.map(
                                (e) => e != null
                                ? Slidable(
                              key: Key(
                                  e['workingExperienceId'] ?? ''),
                              endActionPane: ActionPane(
                                motion: const BehindMotion(),
                                children: [
                                  SlidableAction(
                                    onPressed: (context) {
                                      // Bearbeiten
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              EditWorkingExperiencePage(
                                                  workingExperience:
                                                  e),
                                        ),
                                      ).then(
                                              (updatedWorkingExperience) {
                                            if (updatedWorkingExperience !=
                                                null) {
                                              setState(() {
                                                final index =
                                                workingExperience
                                                    .indexOf(e);
                                                workingExperience[
                                                index] =
                                                    updatedWorkingExperience;
                                              });
                                              FirebaseFirestore.instance
                                                  .collection('users')
                                                  .doc(user!.uid)
                                                  .update({
                                                'workingExperience':
                                                workingExperience
                                              });
                                            }
                                          });
                                    },
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    icon: Icons.edit,
                                    label: 'Bearbeiten',
                                  ),
                                  SlidableAction(
                                    onPressed: (context) {
                                      // Löschen
                                      setState(() {
                                        workingExperience.remove(e);
                                      });
                                      FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(user!.uid)
                                          .update({
                                        'workingExperience':
                                        workingExperience
                                      });
                                    },
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    icon: Icons.delete,
                                    label: 'Löschen',
                                  ),
                                ],
                              ),
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(10),
                                margin: EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  border: null,
                                  borderRadius:
                                  BorderRadius.circular(5),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text('${e['company'] ?? ''}',
                                        style: TextStyle(
                                            fontWeight:
                                            FontWeight.bold,
                                            fontSize: 20)),
                                    Text(
                                        '${e['from'] ?? ''} - ${e['to'] ?? ''}'),
                                    Text('${e['job'] ?? ''}'),
                                    Text(
                                        '${e['activities'] ?? ''}'),
                                  ],
                                ),
                              ),
                            )
                                : Container(),
                          )),
                        )
                            : Text('- Keine Berufserfahrung -',
                            style: TextStyle(color: Colors.grey[400])),
                        Divider(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment
                              .start, // Dies sorgt dafür, dass die Überschrift linksbündig ist
                          children: [
                            Container(
                              height: 50,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text('Kenntnisse',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                            ...skills
                                .map((skill) => ListTile(
                              title: Row(
                                children: [
                                  Text(
                                      '•  '), // Bullet Point hinzugefügt
                                  Expanded(child: Text(skill)),
                                ],
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () {
                                  setState(() {
                                    skills.remove(skill);
                                  });
                                  updateSkillsInFirestore();
                                },
                              ),
                            ))
                                .toList(),
                            TextField(
                              controller: skillController,
                              decoration: InputDecoration(
                                hintText: 'Fügen Sie eine neue Kenntnis hinzu',
                                suffixIcon: IconButton(
                                  icon: Icon(Icons.add),
                                  onPressed: () {
                                    if (skillController.text.isNotEmpty) {
                                      setState(() {
                                        skills.add(skillController.text);
                                        skillController.clear();
                                      });
                                      updateSkillsInFirestore();
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}
