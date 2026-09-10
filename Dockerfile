# ============================================================
# Stage 1: Builder — установка зависимостей
# ============================================================
FROM node:20-alpine AS builder

WORKDIR /app

# Копируем только package.json для кеширования слоя
COPY app/package*.json ./

# Устанавливаем только production-зависимости
RUN npm install --omit=dev

# ============================================================
# Stage 2: Runtime — финальный минимальный образ
# ============================================================
FROM node:20-alpine

# Метаданные
LABEL maintainer="michaelkochnev"
LABEL description="Terraform app with MySQL"

# Создаём непривилегированного пользователя
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Копируем node_modules из builder
COPY --from=builder /app/node_modules ./node_modules

# Копируем исходники приложения
COPY app/package.json ./
COPY app/server.js ./
COPY app/public ./public

# Меняем владельца
RUN chown -R appuser:appgroup /app

# Переключаемся на непривилегированного пользователя
USER appuser

# Открываем порт
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => process.exit(r.statusCode === 200 ? 0 : 1))"

# Запуск
CMD ["node", "server.js"]
