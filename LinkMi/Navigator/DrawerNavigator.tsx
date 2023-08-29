import React from 'react';
import { createDrawerNavigator } from '@react-navigation/drawer';
import AppTabs from './TabNavigator';
import Logout from '../screens/Logout';
import EditProfile from '../screens/EditProfile';

const Drawer = createDrawerNavigator();

const DrawerNavigator = () => (
  <Drawer.Navigator
    initialRouteName="AppTabs"
    screenOptions={{
      drawerStyle: {
        width: 180, // Setzen Sie die Breite des Drawers
      },
    }}
  >
    <Drawer.Screen name="AppTabs" component={AppTabs} options={{ title: 'LinkMi' }} />
    <Drawer.Screen name="Logout" component={Logout} />
    
  </Drawer.Navigator>
);

export default DrawerNavigator;
