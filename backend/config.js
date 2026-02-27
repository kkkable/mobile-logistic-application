const admin = require('firebase-admin');
const { BlobServiceClient } = require('@azure/storage-blob');
const path = require('path');
require('dotenv').config();

// Firebase
const keyPath = process.env.FIREBASE_KEY_PATH || './serviceAccountKey.json';
const absoluteKeyPath = path.resolve(__dirname, keyPath);
const serviceAccount = require(absoluteKeyPath);

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

// Azure
const AZURE_CONNECTION_STRING = process.env.AZURE_STORAGE_CONNECTION_STRING;
let containerClient;
if (AZURE_CONNECTION_STRING) {
    try {
        const blobServiceClient = BlobServiceClient.fromConnectionString(AZURE_CONNECTION_STRING);
        containerClient = blobServiceClient.getContainerClient('pod');
        containerClient.createIfNotExists({ access: 'blob' }).catch(e => {});
    } catch (e) {
        console.error("Azure Init Failed:", e.message);
    }
}

module.exports = { admin, db, containerClient };