const { db } = require('./config');
const { Client } = require('@googlemaps/google-maps-services-js');
const googleMapsClient = new Client({});
const travelTimeCache = new Map();

async function getNextSequenceValue(sequenceName) {
    const counterRef = db.collection('counters').doc(sequenceName);
    return db.runTransaction(async (transaction) => {
        const counterDoc = await transaction.get(counterRef);
        const newCount = !counterDoc.exists ? 1 : counterDoc.data().count + 1;
        transaction.set(counterRef, { count: newCount });
        return newCount;
    });
}

function getDistanceFromLatLonInKm(lat1, lon1, lat2, lon2) {
    const R = 6371;
    const dLat = (lat2 - lat1) * (Math.PI / 180);
    const dLon = (lon2 - lon1) * (Math.PI / 180);
    const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) + Math.cos(lat1 * (Math.PI / 180)) * Math.cos(lat2 * (Math.PI / 180)) * Math.sin(dLon / 2) * Math.sin(dLon / 2);
    return R * (2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a)));
}

function decodePolyline(str, precision) {
    let index = 0, lat = 0, lng = 0, coordinates = [], shift = 0, result = 0, byte = null, lat_change, lng_change, factor = Math.pow(10, precision || 5);
    while (index < str.length) {
        byte = null; shift = 0; result = 0;
        do { byte = str.charCodeAt(index++) - 63; result |= (byte & 0x1f) << shift; shift += 5; } while (byte >= 0x20);
        lat_change = ((result & 1) ? ~(result >> 1) : (result >> 1)); shift = result = 0;
        do { byte = str.charCodeAt(index++) - 63; result |= (byte & 0x1f) << shift; shift += 5; } while (byte >= 0x20);
        lng_change = ((result & 1) ? ~(result >> 1) : (result >> 1)); lat += lat_change; lng += lng_change;
        coordinates.push([lat / factor, lng / factor]);
    }
    return coordinates;
}

async function geocodeAddress(address) {
    try {
        const res = await googleMapsClient.geocode({ params: { address, key: process.env.API_KEY } });
        const loc = res.data.results[0]?.geometry.location;
        if (!loc) throw new Error('No results');
        return { lat: loc.lat, lng: loc.lng };
    } catch (e) { throw new Error('Geocoding failed'); }
}

async function getTravelTime(origin, destination) {
    let originStr = typeof origin === 'string' ? origin : `${origin.lat},${origin.lng}`;
    let destStr = typeof destination === 'string' ? destination : `${destination.lat},${destination.lng}`;
    const cacheKey = `${originStr}|${destStr}`;
    if (travelTimeCache.has(cacheKey) && (Date.now() - travelTimeCache.get(cacheKey).timestamp < 86400000)) return travelTimeCache.get(cacheKey).duration;
    
    try {
        const res = await googleMapsClient.distancematrix({ params: { origins: [originStr], destinations: [destStr], key: process.env.API_KEY, departure_time: 'now' } });
        if (res.data?.rows[0]?.elements[0]?.status === 'OK') {
            const duration = res.data.rows[0].elements[0].duration.value;
            travelTimeCache.set(cacheKey, { duration, timestamp: Date.now() });
            return duration;
        }
        return 999999;
    } catch (e) { return 999999; }
}

module.exports = { getNextSequenceValue, getDistanceFromLatLonInKm, decodePolyline, geocodeAddress, getTravelTime, googleMapsClient };