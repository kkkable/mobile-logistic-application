const express = require('express');
const router = express.Router();
const { verifyToken, verifyAdminToken, upload } = require('./middlewares');

const auth = require('./controllers/authController');
const orders = require('./controllers/orderController');
const drivers = require('./controllers/driverController');
const admin = require('./controllers/adminController');

// Auth and Users
router.post('/register', auth.register);
router.post('/login', auth.login);
router.get('/users/:id', verifyToken, auth.getUser);

// Orders
router.post('/orders', verifyToken, (req, res) => res.redirect(307, '/api/orders/distribute'));
router.post('/orders/distribute', verifyToken, orders.createOrder);
router.get('/orders', verifyToken, orders.getOrders);
router.get('/orders/check/:id', verifyToken, orders.checkRating);
router.get('/orders/:id/estimated_time', verifyToken, orders.getEstimatedTime);
router.post('/ratings', verifyToken, orders.submitRating);
router.post('/orders/:id/finish', verifyToken, upload.single('photo'), orders.finishOrder);
router.get('/orders/driver/:id', verifyToken, orders.getDriverOrders);
router.post('/places/find', verifyToken, orders.findPlaces);
router.post('/geocode', verifyToken, orders.geocodeAddressAPI);

// Drivers
router.get('/drivers/:id', verifyToken, drivers.getDriverBasic);
router.get('/drivers/:id/details', verifyToken, drivers.getDriverDetails);
router.get('/drivers/:id/average_rating', verifyToken, drivers.getDriverRating);
router.post('/drivers/location', verifyToken, drivers.updateLocation);
router.get('/drivers/:id/location', verifyToken, drivers.getLocation);
router.get('/drivers/:id/route', verifyToken, drivers.getRoute);
router.post('/drivers/arrive_node', verifyToken, drivers.arriveNode);
router.post('/routes', verifyToken, drivers.getGoogleRoute);

// Admin Web
router.get('/web/dashboard/stats', verifyAdminToken, admin.getDashboardStats);
router.get('/web/admin/preferences', verifyAdminToken, admin.getPreferences);
router.post('/web/admin/preferences', verifyAdminToken, admin.savePreferences);
router.get('/config/maps-key', verifyAdminToken, admin.getMapsKey);
router.get('/web/master-map/drivers', verifyAdminToken, admin.getMasterMapDrivers);
router.get('/web/:table', verifyAdminToken, admin.getAllRecords);
router.get('/web/:table/:id', verifyAdminToken, admin.getRecordById);
router.post('/web/:table', verifyAdminToken, admin.createRecord);
router.put('/web/:table/:id', verifyAdminToken, admin.updateRecord);
router.delete('/web/:table/:id', verifyAdminToken, admin.deleteRecord);

module.exports = router;