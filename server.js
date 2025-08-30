// server.js
const express = require('express');
const cors = require('cors');
const app = express();
const port = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json());

// Example route
app.get('/', (req, res) => {
  res.send('Hello, world!');
});

// Start server
app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});
