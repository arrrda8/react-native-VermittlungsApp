import React, { useEffect, useState } from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createStackNavigator } from '@react-navigation/stack';
import auth from '@react-native-firebase/auth';
import DrawerNavigator from './DrawerNavigator';
import AuthStack from './AuthStack';
import EditProfile from '../screens/EditProfile';

const RootStack = createStackNavigator();

const AppNavigator = () => {
  const [isAuthenticated, setIsAuthenticated] = useState(false);

  useEffect(() => {
    const unsubscribe = auth().onAuthStateChanged(user => {
      setIsAuthenticated(!!user && user.emailVerified);
    });

    return unsubscribe;
  }, []);

  return (
    <NavigationContainer>
      <RootStack.Navigator screenOptions={{ headerShown: false }}>
        <RootStack.Screen name="AuthStack" component={AuthStack} />
        <RootStack.Screen name="DrawerNavigator" component={DrawerNavigator} />
        <RootStack.Screen name="EditProfile" component={EditProfile} />
      </RootStack.Navigator>
    </NavigationContainer>
  );
};

export default AppNavigator;
