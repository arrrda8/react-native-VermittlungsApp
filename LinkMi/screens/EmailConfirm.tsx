import React from 'react';
import { View, Text, StyleSheet, Button, Alert } from 'react-native';
import auth from '@react-native-firebase/auth';

const Bestätigungsseite: React.FC<{ navigation: any }> = ({ navigation }) => {

  const checkEmailVerified = async () => {
    const user = auth().currentUser;
    if (user) {
      await user.reload();
      if (user.emailVerified) {
        navigation.reset({
          index: 0,
          routes: [{ name: 'AppTabs' }],
        });
      } else {
        Alert.alert('Fehler', 'Bitte bestätigen Sie Ihre E-Mail-Adresse.');
      }
    }
  };

  return (
    <View style={styles.container}>
      <Text style={styles.text}>Eine Bestätigungs-E-Mail wurde gesendet. Bitte überprüfen Sie Ihr E-Mail-Postfach und klicken Sie auf den Link in der E-Mail, um Ihre E-Mail-Adresse zu bestätigen.</Text>
      <Button title="Ich habe meine E-Mail-Adresse bestätigt" onPress={checkEmailVerified} />
      <Button title="Zurück zum Login" onPress={() => navigation.navigate('Login')} />
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
  },
});

export default Bestätigungsseite;
