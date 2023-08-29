import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, Alert } from 'react-native';
import auth from '@react-native-firebase/auth';

const EmailConfirm: React.FC<{ navigation: any }> = ({ navigation }) => {
  const [lastEmailSent, setLastEmailSent] = useState(0);
  const [error, setError] = useState('');
  const [countdown, setCountdown] = useState(0);

  const checkEmailVerified = async () => {
    const user = auth().currentUser;
    if (user) {
      await user.reload();
      if (user.emailVerified) {
        console.log('E-Mail bestätigt!');
        navigation.reset({
          index: 0,
          routes: [{ name: 'DrawerNavigator' }],
        });             
      } else {
        Alert.alert('Fehler', 'Bitte bestätigen Sie Ihre E-Mail.');
      }
    }
  };

  useEffect(() => {
    let timer: NodeJS.Timeout;
    if (countdown > 0) {
      timer = setTimeout(() => {
        setCountdown(countdown - 1);
        setError(`Bitte warten Sie ${countdown - 1} Sekunden, bevor Sie eine neue E-Mail anfordern.`);
      }, 1000);
    } else {
      setError('');
    }
    return () => clearTimeout(timer);
  }, [countdown]);

  const handleResendEmail = () => {
    const currentTime = Date.now();
    if (currentTime - lastEmailSent < 60000) {
      const remainingTime = Math.ceil((60000 - (currentTime - lastEmailSent)) / 1000);
      setCountdown(remainingTime);
      setError(`Bitte warten Sie ${remainingTime} Sekunden, bevor Sie einen neuen Bestätigungslink anfordern.`);
      return;
    }

    const user = auth().currentUser;
    if (user) {
      user.sendEmailVerification()
        .then(() => {
          Alert.alert(
            'E-Mail gesendet',
            'Eine neuer Bestätigungslink wurde an Ihre E-Mail gesendet',
            [{ text: 'OK' }],
            { cancelable: false }
          );
          setLastEmailSent(currentTime);
          setError('');
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
    }
  };

  return (
    <View style={styles.container}>
      <Text style={styles.text}>Bitte bestätigen Sie ihre E-Mail über den Link in Ihrem Postfach.</Text>
      <TouchableOpacity style={styles.button} onPress={checkEmailVerified}>
        <Text style={styles.buttonText}>E-Mail bestätigt</Text>
      </TouchableOpacity>
      <TouchableOpacity style={[styles.button, styles.buttonOutline]} onPress={handleResendEmail}>
        <Text style={styles.buttonOutlineText}>Bestätigungsmail nochmal anfordern</Text>
      </TouchableOpacity>
      {countdown > 0 ? <Text style={styles.errorText}>{error}</Text> : null}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    padding: 20,
  },
  text: {
    textAlign: 'center',
    marginBottom: 20,
    fontSize: 16,
  },
  button: {
    backgroundColor: '#1E90FF',
    padding: 15,
    borderRadius: 5,
    marginBottom: 10,
  },
  buttonText: {
    color: 'white',
    textAlign: 'center',
    fontWeight: 'bold',
  },
  buttonOutline: {
    backgroundColor: 'transparent',
    borderColor: '#1E90FF',
    textAlign: 'center',
    borderWidth: 1,
  },
  buttonOutlineText: {
    color: '#1E90FF',
    textAlign: 'center',
  },
  errorText: {
    color: 'red',
    textAlign: 'center',
    marginTop: 10,
  },
});

export default EmailConfirm;
