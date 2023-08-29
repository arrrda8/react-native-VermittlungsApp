import firestore from '@react-native-firebase/firestore';

interface UpdatedData {
  // ... definieren Sie hier die Struktur Ihrer Daten
}

// Profil-Daten abrufen
export const getProfile = async (userId: string) => {
  try {
    const userDocument = await firestore().collection('users').doc(userId).get();
    const userData = userDocument.data();
    return userData;
  } catch (error) {
    console.error("Error getting user profile: ", error);
  }
}

// Profil-Daten aktualisieren
export const updateProfile = async (userId: string, updatedData: UpdatedData) => {
  try {
    await firestore().collection('users').doc(userId).update({
      ...updatedData,
      updatedAt: firestore.FieldValue.serverTimestamp(),
    });
  } catch (error) {
    console.error("Error updating user profile: ", error);
  }
}
