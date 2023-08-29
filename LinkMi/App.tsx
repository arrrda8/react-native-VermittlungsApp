import React from 'react';
import AppNavigator from './Navigator/AppNavigator';
import { enableScreens } from 'react-native-screens';
import firebase from '@react-native-firebase/app';
import auth from '@react-native-firebase/auth';

enableScreens();

function App() {
  return <AppNavigator />;
}

export default App;