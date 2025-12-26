import * as admin from "firebase-admin";
import { vectorize } from "./vectorize";

// Initialize Firebase Admin
admin.initializeApp();

// Export Cloud Functions
export { vectorize };
