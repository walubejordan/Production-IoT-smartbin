/* eslint-disable no-undef */

// Use a stable version known to work with Firebase Messaging on web.
importScripts('https://www.gstatic.com/firebasejs/9.23.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.23.0/firebase-messaging-compat.js');

try {
  firebase.initializeApp({
    apiKey: "AIzaSyC_lVjVMJ-kp4pPwT0CD_TfLsixZdEGmr8",
    authDomain: "smartbin-4397f.firebaseapp.com",
    projectId: "smartbin-4397f",
    storageBucket: "smartbin-4397f.firebasestorage.app",
    messagingSenderId: "633268717315",
    appId: "1:633268717315:web:85713be5eec1c17e7a4b36",
  });

  const messaging = firebase.messaging();

  messaging.onBackgroundMessage((payload) => {
    console.log('[firebase-messaging-sw.js] Received background message ', payload);
    const title = payload?.notification?.title || 'SmartBin Alert';
    const options = {
      body: payload?.notification?.body,
      icon: '/icons/Icon-192.png', // Ensure this icon exists in your web/icons folder
    };

    self.registration.showNotification(title, options);
  });
} catch (error) {
  console.error('[firebase-messaging-sw.js] initialization error:', error);
}