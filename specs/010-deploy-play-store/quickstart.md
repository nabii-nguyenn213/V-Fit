# Quickstart: Google Play Store Release Guide

Follow these steps to sign, compile, and publish the V-FIT Android application to Google Play.

## Phase 1: Local Signing Configuration

### Step 1: Generate a Release Keystore
Run this command in a terminal to generate a secure keystore file:
```bash
keytool -genkey -v -keystore VFIT_Fontend/android/upload-keystore.jks -keepclassattachments -alias upload -keyalg RSA -keysize 2048 -validity 10000
```
*Note: Save the password securely. Do not commit `upload-keystore.jks` to git.*

### Step 2: Configure `key.properties`
Create a file at `VFIT_Fontend/android/key.properties` with the following content:
```properties
storePassword=<YOUR_STORE_PASSWORD>
keyPassword=<YOUR_KEY_PASSWORD>
keyAlias=upload
storeFile=upload-keystore.jks
```
*Make sure `key.properties` is listed in `VFIT_Fontend/android/.gitignore`.*

### Step 3: Configure `android/app/build.gradle`
Open `VFIT_Fontend/android/app/build.gradle` and update the signing configuration:
```groovy
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    ...
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            ...
        }
    }
}
```

---

## Phase 2: Build the Android App Bundle (AAB)

Run the following command inside `VFIT_Fontend` directory:
```bash
flutter clean
flutter pub get
flutter build appbundle --release
```
The compiled bundle will be located at:
`VFIT_Fontend/build/app/outputs/bundle/release/app-release.aab`

---

## Phase 3: Play Console & OAuth Integration

### Step 1: Retrieve and Link Production Fingerprint
1. Upload `app-release.aab` to Google Play Console (e.g. in **Internal Testing** track).
2. Go to **Setup > App Integrity** in Play Console.
3. Locate the **App Signing key certificate** and copy the **SHA-1 certificate fingerprint**.
4. Open [Google Cloud Console](https://console.cloud.google.com/).
5. Navigate to **APIs & Services > Credentials**.
6. Create an **OAuth 2.0 Client ID** for Android:
   - Name: `V-Fit Android Production`
   - Package name: `com.vfit.vfit_frontend`
   - SHA-1 fingerprint: *Paste the SHA-1 copied from Google Play App Integrity*.
7. Save. (Google Sign-In will now authenticate successfully on Play Store versions).

### Step 2: Set up Privacy Policy
Create a simple HTML page at `privacy-policy.html` and place it in the backend's static directory.
URL format to enter in Play Console Content Declarations:
`https://trungtranvfit.id.vn/privacy-policy.html`
