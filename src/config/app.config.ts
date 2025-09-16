import { registerAs } from '@nestjs/config';

export default registerAs('app', () => ({
  // Application Configuration
  nodeEnv: process.env.NODE_ENV || 'development',
  port: parseInt(process.env.APP_PORT || '3000', 10),
  host: process.env.APP_HOST || 'localhost',
  name: process.env.APP_NAME || 'backend-nestjs-boilerplate',

  // Database Configuration
  database: {
    host: process.env.DATABASE_HOST || 'localhost',
    port: parseInt(process.env.DATABASE_PORT || '5432', 10),
    name: process.env.DATABASE_NAME || 'nestjs_db',
    user: process.env.DATABASE_USER || 'postgres',
    password: process.env.DATABASE_PASSWORD || 'postgres',
    url:
      process.env.DATABASE_URL ||
      'postgresql://postgres:postgres@localhost:5432/nestjs_db',
  },

  // Test Database Configuration
  testDatabase: {
    host: process.env.TEST_DATABASE_HOST || 'localhost',
    port: parseInt(process.env.TEST_DATABASE_PORT || '5433', 10),
    name: process.env.TEST_DATABASE_NAME || 'nestjs_test_db',
    user: process.env.TEST_DATABASE_USER || 'test',
    password: process.env.TEST_DATABASE_PASSWORD || 'test',
    url:
      process.env.TEST_DATABASE_URL ||
      'postgresql://test:test@localhost:5433/nestjs_test_db',
  },

  // Security Configuration
  security: {
    jwtSecret: process.env.JWT_SECRET || 'dev-secret-key-change-in-production',
    jwtExpiry: parseInt(process.env.JWT_EXPIRY || '3600', 10),
    apiKey: process.env.API_KEY || 'dev-api-key',
  },

  // Logging Configuration
  logging: {
    level: process.env.LOG_LEVEL || 'info',
    format: process.env.LOG_FORMAT || 'json',
  },

  // Testing Configuration
  testing: {
    timeout: parseInt(process.env.TEST_TIMEOUT || '30000', 10),
    batsTimeout: parseInt(process.env.BATS_TEST_TIMEOUT || '120', 10),
    smartTestingEnabled: process.env.SMART_TESTING_ENABLED === 'true',
  },
}));
