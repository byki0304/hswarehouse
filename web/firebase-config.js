// Firebase web SDK config for hswarehouse
// Mirrors Firebase Console snippet — Flutter uses lib/firebase_options.dart.
// Kept here as the canonical JS reference for this project.

import { initializeApp } from "https://www.gstatic.com/firebasejs/11.0.0/firebase-app.js";
import { getAnalytics } from "https://www.gstatic.com/firebasejs/11.0.0/firebase-analytics.js";

export const firebaseConfig = {
  apiKey: "AIzaSyA82mdwO9wIuZGhgy12_vLnqgXSB9fFtG8",
  authDomain: "hswarehouse.firebaseapp.com",
  projectId: "hswarehouse",
  storageBucket: "hswarehouse.firebasestorage.app",
  messagingSenderId: "584793321765",
  appId: "1:584793321765:web:1abb60d10b26f7b9feeacc",
  measurementId: "G-YZDQYCTQYZ",
};

export const app = initializeApp(firebaseConfig);
export const analytics = getAnalytics(app);
