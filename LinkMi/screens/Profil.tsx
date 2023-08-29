import React, { useState, useEffect } from 'react';
import { View, Text, Button, Image, StyleSheet, ScrollView } from 'react-native';
import { getProfile, updateProfile } from './firebaseFuntions';
import auth from '@react-native-firebase/auth';
import storage from '@react-native-firebase/storage';
import ImagePicker from 'react-native-image-crop-picker';
import { NavigationProp } from '@react-navigation/native';

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
  profileImage: string;
  backgroundImage: string;
}

interface ProfileProps {
  navigation: NavigationProp<any>;
}

const Profile: React.FC<ProfileProps> = ({ navigation }) => {
  const [profileData, setProfileData] = useState<ProfileData | null>(null);
  const userId = auth().currentUser?.uid;

  const fetchData = async () => {
    if (!userId) {
      console.error("No user is logged in");
      return;
    }

    const data = await getProfile(userId);
    if (data) {
      setProfileData(data as ProfileData);
    } else {
      console.error("No profile data found for user: ", userId);
    }
  };

  useEffect(() => {
    fetchData();
  }, [userId]);

  useEffect(() => {
    const unsubscribe = navigation.addListener('focus', () => {
      fetchData();
    });

    return unsubscribe;
  }, [navigation]);

  const handleEditProfile = () => {
    navigation.navigate('EditProfile');
  };

  const uploadImage = async (imagePath: string, userId: string, imageType: string) => {
    try {
      const response = await fetch(imagePath);
      const blob = await response.blob();
      const ref = storage().ref(`images/${userId}/${imageType}`);
      await ref.put(blob);
      const url = await ref.getDownloadURL();
      console.log('Image uploaded to: ', url);
      return url;
    } catch (error) {
      console.error("Error uploading image: ", error);
    }
  };

  const handleSelectProfileImage = () => {
    ImagePicker.openPicker({
      width: 300,
      height: 300,
      cropping: true,
    }).then(async image => {
      console.log(image);
      if (image.path && userId) {
        const imageUrl = await uploadImage(image.path, userId, 'profileImage');
        await updateProfile(userId, { profileImage: imageUrl });
        fetchData();
      }
    });
  };

  const handleSelectBackgroundImage = () => {
    ImagePicker.openPicker({
      width: 300,
      height: 300,
      cropping: true,
    }).then(async image => {
      console.log(image);
      if (image.path && userId) {
        const imageUrl = await uploadImage(image.path, userId, 'backgroundImage');
        await updateProfile(userId, { backgroundImage: imageUrl });
        fetchData();
      }
    });
  };

  if (!profileData) {
    return <Text>Loading...</Text>;
  }

  return (
    <ScrollView style={styles.container}>
      <View style={styles.header}>
        <Image source={{ uri: profileData.backgroundImage }} style={styles.backgroundImage} />
        <Image source={{ uri: profileData.profileImage }} style={styles.profileImage} />
        <Text style={styles.name}>{profileData.firstName} {profileData.lastName}</Text>
        <Text style={styles.jobTitle}>{profileData.currentJob} @ {profileData.industry} in {profileData.city}</Text>
        {profileData.profilSlogan ? <Text style={styles.profilSlogan}>{profileData.profilSlogan}</Text> : null}
      </View>
      <View style={styles.divider} />
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Berufserfahrung</Text>
        {/* ... Berufserfahrung anzeigen ... */}
      </View>
      <View style={styles.divider} />
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Kenntnisse</Text>
        {/* ... Kenntnisse anzeigen ... */}
      </View>
      <Button title="Profilbild auswählen" onPress={handleSelectProfileImage} />
      <Button title="Hintergrundbild auswählen" onPress={handleSelectBackgroundImage} />
      <Button title="Profil bearbeiten" onPress={handleEditProfile} />
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
  profilSlogan: {
    fontStyle: 'italic',
  },
  section: {
    padding: 20,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 10,
  },
  divider: {
    height: 1,
    backgroundColor: 'gray',
    marginHorizontal: 20,
  },
});

export default Profile;
