// วิธี mount routes สำหรับเซิร์ฟเวอร์หลัก
// ใส่ในไฟล์ app.js หรือ server.js ของเซิร์ฟเวอร์

const express = require('express');
const riderRoutes = require('./RiderSocketRoutes'); // เส้นทางไปยังไฟล์ routes

const app = express();

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Mount rider routes
app.use('/riders', riderRoutes);

// Health check
app.get('/health', (req, res) => {
    res.json({
        success: true,
        message: "Server is running",
        timestamp: new Date().toISOString()
    });
});

// 404 handler
app.use('*', (req, res) => {
    res.status(404).json({
        success: false,
        message: `Cannot ${req.method} ${req.originalUrl}`,
        available_routes: [
            'GET /health',
            'GET /riders/ping',
            'GET /riders/orders',
            'POST /riders/assign_rider',
            'PUT /riders/rider_update_status'
        ]
    });
});

const PORT = process.env.PORT || 4000;
app.listen(PORT, () => {
    console.log(`🚀 Server running on port ${PORT}`);
    console.log(`📍 Available routes:`);
    console.log(`   GET  /health`);
    console.log(`   GET  /riders/ping`);
    console.log(`   GET  /riders/orders`);
    console.log(`   POST /riders/assign_rider`);
    console.log(`   PUT  /riders/rider_update_status`);
});

module.exports = app;