import React, { useEffect, useState } from 'react';
import { View, Text, TextInput, TouchableOpacity, StyleSheet } from 'react-native';
import DateTimePickerModal from 'react-native-modal-datetime-picker';
import Icon from 'react-native-vector-icons/FontAwesome';
import { ScrollView } from 'react-native';
import auth from '@react-native-firebase/auth';


const Signup: React.FC<{ navigation: any }> = ({ navigation }) => {
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [birthDate, setBirthDate] = useState(new Date());
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [isDatePickerVisible, setDatePickerVisibility] = useState(false);
  const [emailError, setEmailError] = useState('');
  const [passwordError, setPasswordError] = useState('');

  useEffect(() => {
    if (email && !email.includes('@')) {
      setEmailError('Bitte E-Mail Adresse eingeben');
    } else {
      setEmailError('');
    }

    if (password && confirmPassword && password !== confirmPassword) {
      setPasswordError('Passwörter stimmen nicht überein');
    } else {
      setPasswordError('');
    }
  }, [email, password, confirmPassword]);

  const handleSignup = () => {
    auth()
      .createUserWithEmailAndPassword(email, password)
      .then(() => {
        console.log('Benutzer registriert!');
        // Hier können Sie den Benutzer z.B. zur Hauptseite weiterleiten
      })
      .catch(error => {
        console.error('Fehler bei der Registrierung: ', error);
        // Hier können Sie Fehlermeldungen anzeigen, z.B. "E-Mail bereits verwendet"
      });
  };

  const showDatePicker = () => {
    setDatePickerVisibility(true);
  };

  const hideDatePicker = () => {
    setDatePickerVisibility(false);
  };

  const handleConfirm = (date: Date) => {
    setBirthDate(date);
    hideDatePicker();
  };

  const isFormValid = () => {
    return firstName && lastName && email && email.includes('@') && password && password === confirmPassword;
  };

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.contentContainer}>
      <Text style={styles.title}>Registrieren</Text>
      <TextInput
        style={styles.input}
        placeholder="Vorname"
        onChangeText={setFirstName}
        value={firstName}
      />
      <TextInput
        style={styles.input}
        placeholder="Nachname"
        onChangeText={setLastName}
        value={lastName}
      />
      <TouchableOpacity onPress={showDatePicker} style={styles.datePicker}>
        <Text>{birthDate.toDateString()}</Text>
      </TouchableOpacity>
      <DateTimePickerModal
        isVisible={isDatePickerVisible}
        mode="date"
        maximumDate={new Date()}
        onConfirm={handleConfirm}
        onCancel={hideDatePicker}
      />
      <TextInput
        style={styles.input}
        placeholder="E-Mail"
        onChangeText={(text) => setEmail(text.toLowerCase())}
        value={email}
        autoCorrect={false}
        keyboardType="email-address"
      />
      {emailError ? <Text style={styles.errorText}>{emailError}</Text> : null}
      <TextInput
        style={styles.input}
        placeholder="Passwort"
        secureTextEntry
        onChangeText={setPassword}
        value={password}
        passwordRules={null}
      />
      <TextInput
        style={styles.input}
        placeholder="Passwort bestätigen"
        secureTextEntry
        onChangeText={setConfirmPassword}
        value={confirmPassword}
      />
      {passwordError ? <Text style={styles.errorText}>{passwordError}</Text> : null}
      <TouchableOpacity style={[styles.button, !isFormValid() && styles.disabledButton]} onPress={handleSignup} disabled={!isFormValid()}>
        <Text style={styles.buttonText}>Registrieren</Text>
      </TouchableOpacity>

      <View style={styles.divider}>
        <View style={styles.line} />
        <Text>ODER</Text>
        <View style={styles.line} />
      </View>

      <View style={styles.socialButtonsContainer}>
        <TouchableOpacity style={[styles.socialButton, styles.facebookButton]} onPress={() => { /* Facebook Login Logik */ }}>
          <Icon name="facebook" size={30} color="white" />
        </TouchableOpacity>
        <TouchableOpacity style={[styles.socialButton, styles.googleButton]} onPress={() => { /* Google Login Logik */ }}>
          <Icon name="google" size={30} color="#DB4437" />
        </TouchableOpacity>
        <TouchableOpacity style={[styles.socialButton, styles.appleButton]} onPress={() => { /* Apple Login Logik */ }}>
          <Icon name="apple" size={30} color="white" />
        </TouchableOpacity>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 20,
    paddingBottom: 50,
  },
  contentContainer: {
    flexGrow: 1,
    justifyContent: 'center',
    paddingBottom: 50,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 20,
    textAlign: 'center',
  },
  input: {
    height: 50,
    borderColor: 'gray',
    borderWidth: 1,
    marginBottom: 15,
    padding: 10,
    borderRadius: 5,
  },
  datePicker: {
    height: 50,
    borderColor: 'gray',
    borderWidth: 1,
    marginBottom: 15,
    padding: 10,
    borderRadius: 5,
    justifyContent: 'center',
  },
  button: {
    backgroundColor: '#4CAF50',
    padding: 15,
    borderRadius: 5,
    alignItems: 'center',
    marginBottom: 10,
  },
  buttonText: {
    color: 'white',
    fontWeight: 'bold',
  },
  divider: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 15,
  },
  line: {
    flex: 1,
    height: 1,
    backgroundColor: 'gray',
    marginHorizontal: 10,
  },
  errorText: {
    color: 'red',
    marginBottom: 10,
  },
  disabledButton: {
    backgroundColor: '#9E9E9E',
  },
  socialButtonsContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: 0,
  },
  socialButton: {
    width: 50,
    height: 50,
    borderRadius: 25, // Dies macht den Button rund
    alignItems: 'center',
    justifyContent: 'center',
    marginHorizontal: 30, // Abstand zwischen den Buttons
  },
  facebookButton: {
    backgroundColor: '#1877F2',
  },
  googleButton: {
    backgroundColor: 'white',
    borderWidth: 1,
    borderColor: '#DB4437',
  },
  appleButton: {
    backgroundColor: '#000000',
  },
});

export default Signup;
