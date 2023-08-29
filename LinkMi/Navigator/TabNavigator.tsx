import React from 'react';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import Ionicons from 'react-native-vector-icons/Ionicons';
import AnzeigeErstellen from '../screens/AnzeigeErstellen';
import Favoriten from '../screens/Favoriten';
import Nachrichten from '../screens/Nachrichten';
import Profil from '../screens/Profil';
import Suche from '../screens/Suche';
import EditProfile from '../screens/EditProfile';

const Tab = createBottomTabNavigator();

const TabNavigator = () => (
  <Tab.Navigator
    screenOptions={({ route }) => ({
      headerShown: false,
      tabBarIcon: ({ focused, color, size }) => {
        let iconName;

        if (route.name === 'Suche') {
          iconName = focused ? 'search' : 'search-outline';
        } else if (route.name === 'Favoriten') {
          iconName = focused ? 'heart' : 'heart-outline';
        } else if (route.name === 'AnzeigeErstellen') {
          iconName = focused ? 'add-circle' : 'add-circle-outline';
        } else if (route.name === 'Nachrichten') {
          iconName = focused ? 'chatbubbles' : 'chatbubbles-outline';
        } else if (route.name === 'Profil') {
          iconName = focused ? 'person' : 'person-outline';
        }

        return <Ionicons name={iconName} size={size} color={color} />;
      },
      tabBarActiveTintColor: 'tomato',
      tabBarInactiveTintColor: 'gray',
    })}
  >
    <Tab.Screen name="Suche" component={Suche} />
    <Tab.Screen name="Favoriten" component={Favoriten} />
    <Tab.Screen name="AnzeigeErstellen" component={AnzeigeErstellen} />
    <Tab.Screen name="Nachrichten" component={Nachrichten} />
    <Tab.Screen name="Profil" component={Profil} />
  </Tab.Navigator>
);

export default TabNavigator;
