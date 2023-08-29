import { StyleSheet } from "react-native";


const styles = StyleSheet.create({

container: {
    flex: 1,
    justifyContent: 'center',
    padding: 20,
    backgroundColor: 'blue'
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 20,
    textAlign: 'center',
  },

  input: {
    height: 50,
    borderColor: 'white',
    borderWidth: 1,
    marginBottom: 15,
    padding: 10,
    borderRadius: 5,
  },
 datePicker: {
    height: 50,
    borderColor: 'gray',
    borderWidth: 1,
    marginBottom: 15,
    padding: 10,
    borderRadius: 5,
    justifyContent: 'center',
 },
 contentContainer: {
  flexGrow: 1,
  justifyContent: 'center',
  paddingBottom: 50,
},
  button: {
    backgroundColor: '#4CAF50',
    padding: 15,
    borderRadius: 5,
    alignItems: 'center',
    marginBottom: 10,
  },
  buttonText: {
    color: 'white',
    fontWeight: 'bold',
  },
  divider: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 15,
  },
  disabledButton: {
    backgroundColor: '#9E9E9E',
  },  
  line: {
    flex: 1,
    height: 1,
    backgroundColor: 'gray',
    marginHorizontal: 10,
  },
  signupText: {
    textAlign: 'center',
    marginTop: 20,
  },
  linkText: {
    color: 'blue',
  },
  socialButtonsContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: 0,
  },
  socialButton: {
    width: 50,
    height: 50,
    borderRadius: 25,
    alignItems: 'center',
    justifyContent: 'center',
    marginHorizontal: 30,
  },
  facebookButton: {
    backgroundColor: '#1877F2',
  },
  googleButton: {
    backgroundColor: 'white',
    borderWidth: 1,
    borderColor: '#DB4437',
  },
  appleButton: {
    backgroundColor: '#000000',
  },
  errorText: {
    color: 'red',
    marginBottom: 10,
  },  
});

export default styles;
