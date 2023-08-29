import React, { useState, useEffect } from 'react';
import { View, Text, TextInput, Button, ScrollView, StyleSheet, Modal, Alert, Image, ActionSheetIOSOptions } from 'react-native';
import database from '@react-native-firebase/database';
import firebase from '@react-native-firebase/app';
// import { launchImageLibrary } from 'react-native-image-picker';
import { useNavigation } from '@react-navigation/native';
import DateTimePickerModal from "react-native-modal-datetime-picker";

const CreateProfile: React.FC = () => {
  const navigation = useNavigation();
  const [modalVisible, setModalVisible] = useState(false);
  const [profileImage, setProfileImage] = useState('https://via.placeholder.com/150');
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [birthDate, setBirthDate] = useState('');
  const [profession, setProfession] = useState('');
  const [personalInformation, setPersonalInformation] = useState('');
  const [workExperience, setWorkExperience] = useState({ company: '', profession: '', from: '', to: '', activities: '' });
  const [isSaveButtonDisabled, setIsSaveButtonDisabled] = useState(true);
  const [isDatePickerVisible, setDatePickerVisibility] = useState(false);
  const [dateType, setDateType] = useState('');
  const [fromDate, setFromDate] = useState('');
  const [toDate, setToDate] = useState('');

  const showFromDatePicker = () => {
    setDatePickerVisibility(true);
    setDateType('from');
  };

  const showToDatePicker = () => {
    setDatePickerVisibility(true);
    setDateType('to');
  };

  const hideDatePicker = () => {
    setDatePickerVisibility(false);
  };

  const handleConfirm = (date: Date) => {
    const formattedDate = `${date.getMonth() + 1}/${date.getFullYear()}`;
    if (dateType === 'from') {
      setFromDate(formattedDate);
      setWorkExperience({ ...workExperience, from: formattedDate });
    } else {
      setToDate(formattedDate);
      setWorkExperience({ ...workExperience, to: formattedDate });
    }
    hideDatePicker();
  };

  useEffect(() => {
    const currentUser = firebase.auth().currentUser;
    const userId = currentUser ? currentUser.uid : null;

    if (userId) {
      database().ref(`/users/${userId}`).once('value')
        .then(snapshot => {
          const userData = snapshot.val();
          setFirstName(userData.firstName);
          setLastName(userData.lastName);
          setBirthDate(userData.birthDate);
        });
    }
  }, []);

  useEffect(() => {
    const { company, profession, from, to, activities } = workExperience;
    if (company && profession && from && to && activities) {
      setIsSaveButtonDisabled(false);
    } else {
      setIsSaveButtonDisabled(true);
    }
  }, [workExperience]);

  const handleChoosePhoto = () => {
    const options = {
      mediaType: 'photo',
      noData: true,
    };
    launchImageLibrary(options, response => {
      if (response.assets && response.assets[0].uri) {
        setProfileImage(response.assets[0].uri);
      }
    });
  };

  const options: ActionSheetIOSOptions = {
    title: 'Berufserfahrung hinzufügen',
  };

  const saveWorkExperience = () => {
    const currentUser = firebase.auth().currentUser;
    const userId = currentUser ? currentUser.uid : null;

    if (userId) {
      database().ref(`/users/${userId}/workExperience`).push(workExperience);
    }

    closeWorkExperienceModal();
  };

  const openWorkExperienceModal = () => {
    setModalVisible(true);
  };

  const closeWorkExperienceModal = () => {
    setModalVisible(false);
  };

  const handleSubmit = () => {
    const currentUser = firebase.auth().currentUser;
    const userId = currentUser ? currentUser.uid : null;

    if (userId) {
      const userData = {
        firstName,
        lastName,
        birthDate,
        profession,
        personalInformation,
        profileImage,
      };
      database().ref(`/users/${userId}`).update(userData);
      navigation.navigate('Suche');
    } else {
      // Handle the case where there is no logged in user
      // Zum Beispiel, eine Fehlermeldung anzeigen oder den Benutzer zur Anmeldeseite umleiten
    }
  };

  return (
    <ScrollView style={styles.container}>
      <View style={styles.profileImageContainer}>
        <Image source={{ uri: profileImage }} style={styles.profileImage} />
        <View style={styles.uploadButtonContainer}>
          <Button title="Foto hochladen" onPress={handleChoosePhoto} color="#fff" />
        </View>
      </View>
      <View style={styles.infoContainer}>
        <Text style={styles.label}>{firstName} {lastName}</Text>
        <Text style={styles.info}>{birthDate}</Text>
      </View>
      <TextInput
        style={styles.input}
        placeholder="Persönliche Informationen"
        value={personalInformation}
        onChangeText={setPersonalInformation}
        multiline
      />
      <TextInput
        style={styles.input}
        placeholder="Beruf"
        value={profession}
        onChangeText={setProfession}
      />
      <Button title="Berufserfahrung hinzufügen" onPress={openWorkExperienceModal} />
      <Modal
        animationType="slide"
        transparent={true}
        visible={modalVisible}
        onRequestClose={() => {
          Alert.alert("Modal has been closed.");
          setModalVisible(!modalVisible);
        }}
      >
        <View style={styles.centeredView}>
          <View style={styles.modalView}>
            <Text style={styles.modalText}>Berufserfahrung hinzufügen</Text>
            <TextInput
              style={{ ...styles.input, height: 40 }}
              placeholder="Betrieb"
              value={workExperience.company}
              onChangeText={company => setWorkExperience({ ...workExperience, company })}
            />
            <TextInput
              style={styles.input}
              placeholder="Beruf"
              value={workExperience.profession}
              onChangeText={profession => setWorkExperience({ ...workExperience, profession })}
            />
            <TextInput
              style={styles.input}
              placeholder="Von"
              value={fromDate}
              onTouchStart={showFromDatePicker}
              editable={false}
            />
            <TextInput
              style={styles.input}
              placeholder="Bis"
              value={toDate}
              onTouchStart={showToDatePicker}
              editable={false}
            />
            <TextInput
              style={styles.input}
              placeholder="Tätigkeiten"
              value={workExperience.activities}
              onChangeText={activities => setWorkExperience({ ...workExperience, activities })}
            />
            <Button title="Speichern" onPress={saveWorkExperience} disabled={isSaveButtonDisabled} />
            <Button title="Schließen" onPress={closeWorkExperienceModal} />
          </View>
        </View>
      </Modal>
      {/* ... rest of your code */}
      <View style={styles.saveButtonContainer}>
        <Button title="Speichern" onPress={handleSubmit} color="#fff" />
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    padding: 20,
  },
  profileImageContainer: {
    alignItems: 'center',
    marginBottom: 20,
  },
  profileImage: {
    width: 150,
    height: 150,
    borderRadius: 75,
    marginBottom: 10,
  },
  uploadButtonContainer: {
    backgroundColor: '#000',
    padding: 10,
    borderRadius: 5,
  },
  infoContainer: {
    alignItems: 'center',
    marginBottom: 20,
  },
  label: {
    fontSize: 18,
    fontWeight: 'bold',
    textAlign: 'center',
  },
  info: {
    fontSize: 16,
    marginBottom: 10,
    textAlign: 'center',
  },
  input: {
    height: 40,
    borderWidth: 1,
    borderColor: '#ccc',
    padding: 10,
    marginBottom: 10,
    borderRadius: 5,
  },
  saveButtonContainer: {
    backgroundColor: '#000',
    padding: 10,
    borderRadius: 5,
  },
  centeredView: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    marginTop: 22,
  },
  modalView: {
    margin: 20,
    backgroundColor: 'white',
    borderRadius: 20,
    padding: 35,
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: {
      width: 0,
      height: 2,
    },
    shadowOpacity: 0.25,
    shadowRadius: 4,
    elevation: 5,
  },
  modalText: {
    marginBottom: 15,
    textAlign: 'center',
    fontWeight: 'bold',
    fontSize: 18,
  },
});

export default CreateProfile;
