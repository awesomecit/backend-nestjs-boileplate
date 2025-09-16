// Load environment variables from .env file
require('dotenv').config();

// Test environment setup
process.env.NODE_ENV = 'test';
process.env.DATABASE_URL =
  process.env.TEST_DATABASE_URL ||
  'postgresql://test:test@localhost:5432/test_db';
process.env.APP_PORT = process.env.APP_PORT || '3001'; // Use different port for tests
process.env.REDIS_HOST = 'localhost';
process.env.REDIS_PORT = '6379';
process.env.JWT_SECRET = 'test-jwt-secret';
