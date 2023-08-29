import React from 'react';
import { View, Alert } from 'react-native';
import auth from '@react-native-firebase/auth';
import { useNavigation } from '@react-navigation/native';


const Logout = () => {
  const navigation = useNavigation();

  const handleLogout = () => {
    auth()
      .signOut()
      .then(() => {
        console.log('Benutzer abgemeldet');
        navigation.reset({
          index: 0,
          routes: [{ name: 'AuthStack' }],
        });
      })
      .catch(error => console.error('Fehler beim Abmelden: ', error));
  };

  Alert.alert(
    'Abmelden',
    'Sind Sie sicher, dass Sie sich abmelden möchten?',
    [
      {
        text: 'Abbrechen',
        onPress: () => navigation.goBack(),
        style: 'cancel',
      },
      { text: 'OK', onPress: handleLogout },
    ],
    { cancelable: false }
  );

  return <View />;
};

export default Logout;
