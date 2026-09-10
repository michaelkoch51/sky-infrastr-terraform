const express = require('express');
const mysql = require('mysql2/promise');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// Параметры БД из переменных окружения
const dbConfig = {
  host: process.env.DB_HOST,
  port: process.env.DB_PORT || 3306,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
};

// Раздача статики
app.use(express.static(path.join(__dirname, 'public')));

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

// API: проверка связи с БД
app.get('/api/db', async (req, res) => {
  try {
    const connection = await mysql.createConnection(dbConfig);
    const [rows] = await connection.execute('SELECT VERSION() as version, NOW() as now');
    const [tables] = await connection.execute('SHOW TABLES');
    await connection.end();

    res.json({
      status: 'connected',
      mysql_version: rows[0].version,
      server_time: rows[0].now,
      tables_count: tables.length,
      tables: tables.map(t => Object.values(t)[0]),
    });
  } catch (err) {
    res.status(500).json({
      status: 'error',
      message: err.message,
    });
  }
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
});
