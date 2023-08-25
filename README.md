# NewApp
Vermittlungsapp für Gastro, Kosmetik, etc...

Name;: ???

Bei Neustart werden folgende Codes benötigt:

<code>npx react-native start</code>

<code>npx react-native run-ios</code>

<code>npx react-native run-android</code>

Metro Server Cache löschen:

<code>npx react-native start --reset-cache</code>

Pods neu installieren:

<code>cd ios && pod install && cd ..</code>

Doctor 

<code>npx react-native doctor</code>

Neues Projekt:
<code>npx react-native@latest init MeinProjekt</code>

<<<<<<< HEAD

Firebase:
https://github.com/firebase/firebase-ios-sdk

## Packages

<code>npm install @react-navigation/native @react-navigation/stack @react-navigation/bottom-tabs @react-navigation/drawer</code>

<code>npm install react-native-screens</code>

<code>npm install react-native-safe-area-context</code>

<code>npm install @react-navigation/stack</code>

<code> npm install @react-native-community/datetimepicker</code>

<code>npm i react-native-modal-datetime-picker</code>

<code>npm install react-native-gesture-handler</code>

<code>npm install --save react-native-vector-icons</code>

<code>npm install @react-native-firebase/app</code>

<code>npm install @react-native-firebase/auth</code>


RUBY

<code>rvm install ruby-3.2.1 -C --with-openssl-dir=/opt/local/libexec/openssl11</code>

=======
>>>>>>> parent of f253b75 (v0.1)
# To-Do

- [ ] Name
- [ ] Frontend: Wo Benutzer ihre Informationen eingeben können.
- [ ] Backend: Ein Server, der die Registrierungsanfragen bearbeitet, Benutzerdaten speichert und Authentifizierungsdienste bereitstellt.
- [ ] Datenbank: Zum Speichern der Benutzerinformationen.
- [ ] Sicherheit: Sichere Passwortspeicherung, Datenverschlüsselung und Token-basierte Authentifizierung.


## Installation und Konfiguration
### 1. Node.js und npm (Node Package Manager)
React Native verwendet JavaScript, und Node.js ist die Plattform dafür. npm wird für die Paketverwaltung verwendet. Sie können Node.js von der offiziellen Website herunterladen und installieren: https://nodejs.org/
### 2. Watchman (optional, aber empfohlen auf macOS):
Ein Tool von Facebook für das Beobachten von Dateiänderungen. Es ist nützlich für Hot Reloading in React Native. Es kann über Homebrew auf macOS installiert werden: brew install watchman
### 3. React Native Command Line Interface (CLI):
Nachdem Sie Node.js installiert haben, können Sie den CLI über npm installieren:
<code>npm install -g react-native-cli</code>
### 4. Ein Code-Editor:
Obwohl Sie jeden gewünschten Texteditor verwenden können, ist Visual Studio Code (VS Code) aufgrund seiner Erweiterbarkeit und der breiten Unterstützung für React Native und JavaScript eine häufige Wahl.
### 5. Android Studio:
Für die Android-Entwicklung. Es enthält den notwendigen Android-Emulator und das Android SDK. Laden Sie es von der offiziellen Website herunter: https://developer.android.com/studio
Nach der Installation von Android Studio stellen Sie sicher, dass Sie das richtige SDK für React Native (normalerweise das neueste) und die Build-Tools installieren.
### 6. Xcode:
Für die iOS-Entwicklung. Dies ist nur auf macOS verfügbar und kann aus dem Mac App Store heruntergeladen werden. Stellen Sie sicher, dass Sie auch die notwendigen Komponenten wie die iOS-Simulatoren installieren.
### 7. Java Development Kit (JDK):
Benötigt für die Android-Entwicklung. Sie können die JDK von Oracle herunterladen oder eine Open-Source-Version wie AdoptOpenJDK verwenden.
### 8. Git (optional, aber sehr empfohlen):
Ein Versionskontrollsystem, das Ihnen und Ihrem Team hilft, Ihre Codeänderungen zu verwalten. Es kann von der offiziellen Website heruntergeladen werden: https://git-scm.com/

Nachdem Sie diese Tools eingerichtet haben, können Sie mit dem Befehl <code>react-native init MeinProjektName</code> ein neues React Native-Projekt erstellen und mit der Entwicklung beginnen!

## Projekt starten
### Öffnen Sie Ihr Projekt in VS Code:
Starten Sie VS Code.
Wählen Sie "Datei" > "Ordner öffnen" (oder "File" > "Open Folder" je nach Spracheinstellung) und navigieren Sie zu Ihrem Projektordner MeinProjektName.
Nun sollten Sie alle Dateien Ihres Projekts in VS Code sehen können.

### Installieren Sie nützliche Erweiterungen:
VS Code hat einen Marktplatz für Erweiterungen. Für React Native sind einige Erweiterungen besonders hilfreich:
React Native Tools: Bietet Debugging, IntelliSense und andere nützliche Funktionen.
ES7 React/Redux/GraphQL/React-Native snippets: Gibt Ihnen Code-Schnipsel für gängige React/React Native-Aufgaben.
Um diese zu installieren, klicken Sie auf das Quadrat-Symbol (Extensions) im linken Menü von VS Code und suchen Sie nach den oben genannten Erweiterungen.

### Starten Sie die App:
Öffnen Sie das Terminal in VS Code (Ansicht > Terminal).
Um die App im iOS-Simulator zu starten, geben Sie ein: react-native run-ios
Um die App im Android-Emulator zu starten, stellen Sie sicher, dass der Android-Emulator läuft und geben Sie dann ein: react-native run-android

## Visual Studio Code - Struktur der Dateien
### App.tsx: 
Dies ist die Hauptdatei, die Sie bearbeiten werden, um den Inhalt Ihrer App zu ändern. .tsx ist die Erweiterung für TypeScript-Dateien, die JSX (die Syntax, die in React zum Erstellen von Komponenten verwendet wird) enthalten. Sie können diese Datei so behandeln, wie Sie App.js in einem JavaScript-Projekt behandeln würden.
### App.json: 
Diese Datei enthält Konfigurationsinformationen für Ihre App, z. B. den Namen und das Anzeigeicon. Änderungen hier beeinflussen, wie Ihre App auf dem Gerät oder im Emulator dargestellt wird, aber nicht den eigentlichen Inhalt oder das Verhalten Ihrer App.
### index.js: 
Dies ist die Haupt-Einstiegsdatei für Ihre React Native-App. Sie importiert App.js und registriert die App mithilfe von AppRegistry. Normalerweise müssen Sie diese Datei nicht bearbeiten, es sei denn, Sie müssen eine spezielle Einrichtung oder Konfiguration vornehmen.
### android/: 
Dieser Ordner enthält alle Dateien und den Code, der spezifisch für die Android-Plattform ist. Hier finden Sie u.a. das Android-Manifest und Gradle-Konfigurationsdateien. Sie müssen in dieses Verzeichnis gehen, wenn Sie native Android-Module hinzufügen oder bestimmte Android-spezifische Einstellungen vornehmen möchten.
### ios/: 
Dieser Ordner enthält alle Dateien und den Code, der spezifisch für die iOS-Plattform ist, einschließlich des Xcode-Projekts. Wie beim android/-Verzeichnis gehen Sie hierher, wenn Sie native iOS-Module hinzufügen oder spezielle iOS-Einstellungen vornehmen möchten.
### node_modules/: 
Dieser Ordner enthält alle externen Abhängigkeiten und Bibliotheken, die Sie über npm oder yarn zu Ihrem Projekt hinzugefügt haben. Direkte Änderungen in diesem Ordner sind in der Regel nicht empfehlenswert, da sie überschrieben werden könnten, wenn Sie Pakete aktualisieren.
### package.json: 
Diese Datei listet alle Abhängigkeiten Ihres Projekts auf und enthält auch Skripte, Konfigurationen und Metadaten zu Ihrem Projekt.
