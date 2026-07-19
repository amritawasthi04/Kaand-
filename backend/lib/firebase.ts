import { initializeApp, cert, getApps } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

let dbInstance: any = null;

try {
  const projectId = process.env.FIREBASE_PROJECT_ID;
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  const privateKey = process.env.FIREBASE_PRIVATE_KEY;

  if (projectId && clientEmail && privateKey) {
    if (getApps().length === 0) {
      initializeApp({
        credential: cert({
          projectId,
          clientEmail,
          privateKey: privateKey.replace(/\\n/g, '\n').replace(/"/g, ''),
        }),
      });
      console.log('Firebase Admin SDK initialized successfully.');
    }
    dbInstance = getFirestore();
  } else {
    console.warn('Firebase credentials not complete. Firebase Admin SDK not initialized.');
  }
} catch (error) {
  console.error('Firebase Admin initialization error:', error);
}

export const db = dbInstance;
