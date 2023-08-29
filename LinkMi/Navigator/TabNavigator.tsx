import React from 'react';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import AnzeigeErstellen from '../screens/AnzeigeErstellen';
import Favoriten from '../screens/Favoriten';
import Nachrichten from '../screens/Nachrichten';
import Profil from '../screens/Profil';
import Suche from '../screens/Suche';

const Tab = createBottomTabNavigator();

const TabNavigator = () => (
  <Tab.Navigator>
    <Tab.Screen name="Suche" component={Suche} />
    <Tab.Screen name="Favoriten" component={Favoriten} />
    <Tab.Screen name="AnzeigeErstellen" component={AnzeigeErstellen} />
    <Tab.Screen name="Nachrichten" component={Nachrichten} />
    <Tab.Screen name="Profil" component={Profil} />
  </Tab.Navigator>
);

export default TabNavigator;
