import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { createStackNavigator } from '@react-navigation/stack';

import AnzeigeErstellen from './screens/AnzeigeErstellen';
import Favoriten from './screens/Favoriten';
import Nachrichten from './screens/Nachrichten';
import Profil from './screens/Profil';
import Suche from './screens/Suche';

import Login from './screens/Login';
import Signup from './screens/Signup';

const Tab = createBottomTabNavigator();
const Stack = createStackNavigator();

const AuthStack = () => (
  <Stack.Navigator initialRouteName="Login">
    <Stack.Screen name="Login" component={Login} />
    <Stack.Screen name="Signup" component={Signup} />
  </Stack.Navigator>
);

const AppTabs = () => (
  <Tab.Navigator>
    <Tab.Screen name="Suche" component={Suche} />
    <Tab.Screen name="Favoriten" component={Favoriten} />
    <Tab.Screen name="AnzeigeErstellen" component={AnzeigeErstellen} />
    <Tab.Screen name="Nachrichten" component={Nachrichten} />
    <Tab.Screen name="Profil" component={Profil} />
  </Tab.Navigator>
);

function AppNavigator() {
  
  return (
    <NavigationContainer>
      <AuthStack />
    </NavigationContainer>
  );
}

export default AppNavigator;
