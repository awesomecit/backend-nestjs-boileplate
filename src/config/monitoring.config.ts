import { registerAs } from '@nestjs/config';

export default registerAs('monitoring', () => ({
  // Prometheus Configuration
  prometheus: {
    port: parseInt(process.env.PROMETHEUS_PORT || '9090', 10),
    host: process.env.PROMETHEUS_HOST || 'localhost',
    url: `http://${process.env.PROMETHEUS_HOST || 'localhost'}:${process.env.PROMETHEUS_PORT || '9090'}`,
  },

  // Grafana Configuration
  grafana: {
    port: parseInt(process.env.GRAFANA_PORT || '3000', 10),
    host: process.env.GRAFANA_HOST || 'localhost',
    url: `http://${process.env.GRAFANA_HOST || 'localhost'}:${process.env.GRAFANA_PORT || '3000'}`,
    adminUser: process.env.GRAFANA_ADMIN_USER || 'admin',
    adminPassword: process.env.GRAFANA_ADMIN_PASSWORD || 'admin123',
  },

  // Node Exporter Configuration
  nodeExporter: {
    port: parseInt(process.env.NODE_EXPORTER_PORT || '9100', 10),
    host: process.env.NODE_EXPORTER_HOST || 'localhost',
    url: `http://${process.env.NODE_EXPORTER_HOST || 'localhost'}:${process.env.NODE_EXPORTER_PORT || '9100'}`,
  },

  // NGINX Exporter Configuration
  nginxExporter: {
    port: parseInt(process.env.NGINX_EXPORTER_PORT || '9113', 10),
    host: process.env.NGINX_EXPORTER_HOST || 'localhost',
    url: `http://${process.env.NGINX_EXPORTER_HOST || 'localhost'}:${process.env.NGINX_EXPORTER_PORT || '9113'}`,
  },

  // Portainer Configuration (optional)
  portainer: {
    port: parseInt(process.env.PORTAINER_PORT || '9000', 10),
    host: process.env.PORTAINER_HOST || 'localhost',
    url: `http://${process.env.PORTAINER_HOST || 'localhost'}:${process.env.PORTAINER_PORT || '9000'}`,
    enabled: process.env.PORTAINER_ENABLED === 'true',
  },

  // NGINX Configuration
  nginx: {
    port: parseInt(process.env.NGINX_PORT || '80', 10),
    host: process.env.NGINX_HOST || 'localhost',
    url: `http://${process.env.NGINX_HOST || 'localhost'}:${process.env.NGINX_PORT || '80'}`,
  },

  // Docker Configuration
  docker: {
    stackName: process.env.DOCKER_STACK_NAME || 'monitoring',
    composeProjectName: process.env.COMPOSE_PROJECT_NAME || 'backend-nestjs',
  },
}));
