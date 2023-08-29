import React from 'react';
import { createStackNavigator } from '@react-navigation/stack';
import Login from '../screens/Login';
import Signup from '../screens/Signup';
import EmailConfirm from '../screens/EmailConfirm';

const Stack = createStackNavigator();

const AuthStack = () => (
  <Stack.Navigator initialRouteName="Login">
    <Stack.Screen name="Login" component={Login} />
    <Stack.Screen name="Signup" component={Signup} />
    <Stack.Screen name="EmailConfirm" component={EmailConfirm} />
  </Stack.Navigator>
);

export default AuthStack;
