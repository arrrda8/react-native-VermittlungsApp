import React, { useEffect, useState } from 'react';
import { View, Text, TextInput, TouchableOpacity, StyleSheet, Alert } from 'react-native';
import Icon from 'react-native-vector-icons/FontAwesome';
import auth from '@react-native-firebase/auth';
import mystyles from '../myStyles'
import DrawerNavigator from '../Navigator/DrawerNavigator';
import TabNavigator from '../Navigator/TabNavigator';

const Login: React.FC<{ navigation: any }> = ({navigation}) => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [emailError, setEmailError] = useState('');
  const navigateToSignup = () => {
    navigation.navigate('Signup');
  };
  
  useEffect(() => {
    if (email && !email.includes('@')) {
      setEmailError('Bitte E-Mail Adresse eingeben');
    } else {
      setEmailError('');
    }
  }, [email]);

  const isFormValid = () => {
    return email.includes('@') && password.length > 0;
  };
  
  const handleLogin = () => {
    auth()
      .signInWithEmailAndPassword(email, password)
      .then((userCredential) => {
        const user = userCredential.user;
        if (user.emailVerified) {
          console.log('Benutzer angemeldet!');
          navigation.navigate('DrawerNavigator', {
            screen: 'AppTabs',
            params: { screen: 'Suche' },
          });
          
        } else {
          console.log('E-Mail nicht bestätigt');
          navigation.reset({
            index: 0,
            routes: [{ name: 'EmailConfirm' }],
          });
        }
      })
      .catch(error => {
        console.error('Fehler bei der Anmeldung: ', error);
        Alert.alert(
          'Fehler',
          'Login-Daten falsch! Bitte nochmal versuchen',
          [{ text: 'OK' }],
          { cancelable: false }
        );
      });
  };
  
  
  

  const handlePasswordReset = () => {
    if (!email) {
      Alert.alert(
        'Fehler',
        'Bitte geben Sie Ihre E-Mail-Adresse ein',
        [{ text: 'OK' }],
        { cancelable: false }
      );
      return;
    }

    auth()
      .sendPasswordResetEmail(email)
      .then(() => {
        Alert.alert(
          'E-Mail gesendet',
          'Eine E-Mail zum Zurücksetzen des Passworts wurde an Ihre E-Mail-Adresse gesendet',
          [{ text: 'OK' }],
          { cancelable: false }
        );
      })
      .catch(error => {
        console.error('Fehler beim Senden der E-Mail: ', error);
        Alert.alert(
          'Fehler',
          'Fehler beim Senden der E-Mail. Bitte versuchen Sie es später erneut',
          [{ text: 'OK' }],
          { cancelable: false }
        );
      });
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Einloggen</Text>
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
      />
      <TouchableOpacity 
        style={[styles.button, !isFormValid() && styles.disabledButton]} 
        onPress={handleLogin} 
        disabled={!isFormValid()}
        >
        <Text style={styles.buttonText}>Einloggen</Text>
      </TouchableOpacity>
      <TouchableOpacity 
        onPress={handlePasswordReset}
        >
        <Text style={styles.forgotPasswordText}>Passwort vergessen?</Text>
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

      <Text style={styles.signupText}>Noch kein Konto? <Text style={styles.linkText} onPress={navigateToSignup}>Registrieren</Text></Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    padding: 20,
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
  disabledButton: {
    backgroundColor: '#9E9E9E',
  },  
  line: {
    flex: 1,
    height: 1,
    backgroundColor: 'gray',
    marginHorizontal: 10,
  },
  signupText: {
    textAlign: 'center',
    marginTop: 20,
  },
  linkText: {
    color: 'blue',
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
  errorText: {
    color: 'red',
    marginBottom: 10,
  },  
  forgotPasswordText: {
    textAlign: 'center',
    marginTop: 5,
    marginBottom: 10,
    fontSize: 12,
    color: 'blue',
  },
});

export default Login;