// jest.config.js

module.exports = {
  displayName: 'Unit Tests',
  testEnvironment: 'node',

  // CRITICO: Forza l'esecuzione sequenziale per evitare conflitti
  maxWorkers: 1,
  runInBand: true,

  // Timeout generosi per operazioni database e container
  testTimeout: 60000,

  // Rileva handle aperti (connessioni database non chiuse)
  detectOpenHandles: true,
  forceExit: true,

  // Pattern dei file di test
  testMatch: ['<rootDir>/src/**/*.spec.ts', '<rootDir>/src/**/*.test.ts'],

  // Moduli da trasformare con TypeScript
  preset: 'ts-jest',

  // Setup per ogni test file
  setupFilesAfterEnv: ['<rootDir>/test/setup.ts'],

  // Mapping dei moduli per import relativi
  moduleNameMapping: {
    '^@/(.*)$': '<rootDir>/src/$1',
    '^@test/(.*)$': '<rootDir>/test/$1',
  },

  // Coverage configuration
  collectCoverage: false, // Disabilitato per i test per performance
  collectCoverageFrom: [
    'src/**/*.ts',
    '!src/**/*.spec.ts',
    '!src/**/*.test.ts',
    '!src/main.ts',
  ],

  // Ignora i moduli node_modules tranne alcuni specifici se necessario
  transformIgnorePatterns: ['node_modules/(?!(testcontainers)/)'],

  // Variables d'environment per i test
  setupFiles: ['<rootDir>/test/env.setup.js'],
};
