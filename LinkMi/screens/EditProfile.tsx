import React, { useState, useEffect } from 'react';
import { View, Text, TextInput, Button, StyleSheet } from 'react-native';
import { updateProfile, getProfile } from './firebaseFuntions';
import auth from '@react-native-firebase/auth';

interface ProfileData {
  firstName: string;
  lastName: string;
  email: string;
  birthDate: string;
  profilSlogan: string;
  currentJob: string;
  industry: string;
  zipCode: string;
  city: string;
}

const EditProfile = ({ navigation }) => {
  const [profileData, setProfileData] = useState<ProfileData | null>(null);
  const userId = auth().currentUser?.uid;

  useEffect(() => {
    if (!userId) {
      console.error("No user is logged in");
      return;
    }

    const fetchData = async () => {
      const data = await getProfile(userId);
      if (data) {
        setProfileData(data);
      } else {
        console.error("No profile data found for user: ", userId);
      }
    };

    fetchData();
  }, [userId]);

  const handleUpdateProfile = async () => {
    if (!userId) {
      console.error("No user is logged in");
      return;
    }

    const updatedData = {
      profilSlogan: profileData?.profilSlogan,
      currentJob: profileData?.currentJob,
      industry: profileData?.industry,
      zipCode: profileData?.zipCode,
      city: profileData?.city,
    };

    await updateProfile(userId, updatedData);
    console.log('Profile updated!');
    navigation.goBack();
  };

  if (!profileData) {
    return <Text>Loading...</Text>;
  }

  return (
    <View style={styles.container}>
      <Text style={styles.label}>Profil Slogan</Text>
      <TextInput
        style={styles.input}
        placeholder="Profil Slogan"
        value={profileData.profilSlogan}
        onChangeText={(text) => setProfileData({ ...profileData, profilSlogan: text })}
      />
      <Text style={styles.label}>Aktuelle Job Position</Text>
      <TextInput
        style={styles.input}
        placeholder="Aktuelle Job Position"
        value={profileData.currentJob}
        onChangeText={(text) => setProfileData({ ...profileData, currentJob: text })}
      />
      <Text style={styles.label}>Branche</Text>
      <TextInput
        style={styles.input}
        placeholder="Branche"
        value={profileData.industry}
        onChangeText={(text) => setProfileData({ ...profileData, industry: text })}
      />
      <Text style={styles.label}>Postleitzahl</Text>
      <TextInput
        style={styles.input}
        placeholder="Postleitzahl"
        value={profileData.zipCode}
        onChangeText={(text) => setProfileData({ ...profileData, zipCode: text })}
      />
      <Text style={styles.label}>Ort</Text>
      <TextInput
        style={styles.input}
        placeholder="Ort"
        value={profileData.city}
        onChangeText={(text) => setProfileData({ ...profileData, city: text })}
      />
      <Button title="Profil aktualisieren" onPress={handleUpdateProfile} />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 20,
  },
  label: {
    fontSize: 12,
    color: 'gray',
    marginBottom: 5,
  },
  input: {
    height: 50,
    borderColor: '#E5E7EB',
    borderWidth: 1,
    marginBottom: 20,
    paddingLeft: 10,
    borderRadius: 5,
    backgroundColor: '#F3F4F6',
  },
});

export default EditProfile;