import { NestFactory } from '@nestjs/core';
import { ConfigService } from '@nestjs/config';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  const configService = app.get(ConfigService);
  const port = configService.get<number>('app.port', 3000);
  const host = configService.get<string>('app.host', 'localhost');

  console.log(`🚀 Application starting on ${host}:${port}`);
  console.log(`📊 Environment: ${configService.get<string>('app.nodeEnv')}`);

  await app.listen(port, host);
}
bootstrap();
