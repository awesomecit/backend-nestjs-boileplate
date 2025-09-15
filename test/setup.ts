// Global test setup
import 'reflect-metadata';

// Aumenta il timeout per i test
jest.setTimeout(60000);

// Mock console per ridurre il noise nei test
global.console = {
  ...console,
  log: jest.fn(),
  debug: jest.fn(),
  info: jest.fn(),
  warn: jest.fn(),
  error: jest.fn(),
};
