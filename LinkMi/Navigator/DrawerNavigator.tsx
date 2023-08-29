import React from 'react';
import { createDrawerNavigator } from '@react-navigation/drawer';
import AppTabs from './TabNavigator';
import Login from '../screens/Login';
import Logout from '../screens/Logout';

const Drawer = createDrawerNavigator();

const DrawerNavigator = () => (
  <Drawer.Navigator initialRouteName="AppTabs">
    <Drawer.Screen name="AppTabs" component={AppTabs} options={{ title: 'LinkMi' }} />
    <Drawer.Screen name="Logout" component={Logout} />
  </Drawer.Navigator>
);

export default DrawerNavigator;
