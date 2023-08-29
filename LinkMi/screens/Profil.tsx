import React, { useState, useEffect } from 'react';
import { View, Text, Button, Image, StyleSheet, ScrollView } from 'react-native';
import { getProfile, updateProfile } from './firebaseFuntions';
import auth from '@react-native-firebase/auth';

interface ProfileData {
  firstName: string;
  lastName: string;
  email: string;
  birthdate: string;
  // ... andere Profil-Daten
}

const Profile = () => {
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
      // ... hier die aktualisierten Daten einfügen
    };
    await updateProfile(userId, updatedData);
  };

  if (!profileData) {
    return <Text>Loading...</Text>;
  }

  return (
    <ScrollView style={styles.container}>
      <View style={styles.header}>
        <Image source={require('./path/to/your/background/image.jpg')} style={styles.backgroundImage} />
        <Image source={require('./path/to/your/profile/image.jpg')} style={styles.profileImage} />
        <Text style={styles.name}>{profileData.firstName} {profileData.lastName}</Text>
        <Text style={styles.jobTitle}>Job Title</Text>
      </View>
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Über mich</Text>
        <Text>{profileData.email}</Text>
        <Text>{profileData.birthdate}</Text>
        {/* ... andere Profil-Daten anzeigen ... */}
      </View>
      {/* ... andere Abschnitte hinzufügen ... */}
      <Button title="Profil bearbeiten" onPress={handleUpdateProfile} />
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  header: {
    alignItems: 'center',
    padding: 20,
  },
  backgroundImage: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    height: 200,
    resizeMode: 'cover',
  },
  profileImage: {
    width: 100,
    height: 100,
    borderRadius: 50,
    marginTop: 100,
  },
  name: {
    fontSize: 24,
    fontWeight: 'bold',
    marginTop: 10,
  },
  jobTitle: {
    color: 'gray',
  },
  section: {
    padding: 20,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 10,
  },
});

export default Profile;
