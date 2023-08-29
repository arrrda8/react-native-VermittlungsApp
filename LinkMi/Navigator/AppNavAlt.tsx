import React, { useEffect, useState, FC } from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { createStackNavigator } from '@react-navigation/stack';
import { createDrawerNavigator } from '@react-navigation/drawer';
import auth from '@react-native-firebase/auth';
import { View, ActivityIndicator, Alert } from 'react-native';

import AnzeigeErstellen from '../screens/AnzeigeErstellen';
import Favoriten from '../screens/Favoriten';
import Nachrichten from '../screens/Nachrichten';
import Profil from '../screens/Profil';
import Suche from '../screens/Suche';

import Login from '../screens/Login';
import Signup from '../screens/Signup';
import EmailConfirm from '../screens/EmailConfirm';

const Tab = createBottomTabNavigator();
const Stack = createStackNavigator();
const Drawer = createDrawerNavigator();
const RootStack = createStackNavigator();
const MainStack = createStackNavigator();

const AuthStack = () => (
  <Stack.Navigator initialRouteName="Login">
    <Stack.Screen name="Login" component={Login} />
    <Stack.Screen name="Signup" component={Signup} />
    <Stack.Screen name="EmailConfirm" component={EmailConfirm} />
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

const LogoutScreen: React.FC<{ navigation: any }> = ({ navigation }) => {
  useEffect(() => {
    const unsubscribe = navigation.addListener('focus', () => {
      Alert.alert(
        'Ausloggen',
        'Möchten Sie sich wirklich ausloggen?',
        [
          {
            text: 'Abbrechen',
            onPress: () => navigation.goBack(),
            style: 'cancel',
          },
          {
            text: 'Ausloggen',
            onPress: () => {
              auth()
                .signOut()
                .then(() => {
                  navigation.reset({
                    index: 0,
                    routes: [{ name: 'AppDrawer' }],
                  });
                });
            },
          },
        ],
        { cancelable: false }
      );
    });

    return unsubscribe;
  }, [navigation]);

  return (
    <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}>
      <ActivityIndicator size="large" />
    </View>
  );
};

const AppDrawer = () => (
  <Drawer.Navigator initialRouteName="AppTabs">
    <Drawer.Screen name="AppTabs" component={AppTabs} options={{ title: 'Home' }} />
    <Drawer.Screen name="Logout" component={LogoutScreen} />
  </Drawer.Navigator>
);

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
      <MainStack.Navigator>
        {isAuthenticated ? (
          <MainStack.Screen name="AppDrawer" component={AppDrawer} />
        ) : (
          <MainStack.Screen name="Auth" component={AuthStack} />
        )}
      </MainStack.Navigator>
    </NavigationContainer>
  );
  
};

export default AppNavigator;