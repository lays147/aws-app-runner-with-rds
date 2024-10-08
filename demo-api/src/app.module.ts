import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { HealthModule } from './health/health.module';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TerminusModule } from '@nestjs/terminus';

@Module({
  imports: [
    ConfigModule.forRoot(),
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: (configService: ConfigService) => ({
        type: 'postgres',
        host: configService.get('POSTGRES_HOST'),
        port: +configService.get('POSTGRES_PORT', 5432),
        username: configService.get('POSTGRES_USERNAME'),
        password: () => {
          const secret = JSON.parse(configService.get('POSTGRES_SECRET'));
          return secret['password'];
        },
        database: configService.get('POSTGRES_DATABASE'),
        entities: [],
        synchronize: true,
        ssl: configService.get('NODE_ENV') === 'production' ? true : false,
        extra: {
          ssl:
            configService.get('NODE_ENV') === 'production'
              ? { rejectUnauthorized: false }
              : null,
        },
      }),
      inject: [ConfigService],
    }),
    TerminusModule,
    HealthModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
