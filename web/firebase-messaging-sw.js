importScripts('https://www.gstatic.com/firebasejs/9.6.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.6.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyCsA7j4ekgqRITTxLkkkcUSV-8ws4jw4fM',
  authDomain: 'resume-master-61af6.firebaseapp.com',
  projectId: 'resume-master-61af6',
  storageBucket: 'resume-master-61af6.firebasestorage.app',
  messagingSenderId: '541168145892',
  appId: '1:541168145892:web:024bd92ffcbf48f600e3f1',
  measurementId: 'G-V74QTBWY0N'
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('Received background message ', payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/firebase-logo.png'
  };
  return self.registration.showNotification(notificationTitle, notificationOptions);
}); 