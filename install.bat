@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: Интерактивный скрипт установки Remna Shop Bot для Windows
:: Поддержка Remnawave API v2.2.4

echo ╔════════════════════════════════════════════════════════════╗
echo ║       🚀 Remna Shop Bot - Интерактивная установка         ║
echo ║              Remnawave API v2.2.4                          ║
echo ╚════════════════════════════════════════════════════════════╝
echo.

:: Проверка Docker
echo ℹ️  Проверка зависимостей...
docker --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker не найден!
    echo ℹ️  Установите Docker Desktop: https://www.docker.com/products/docker-desktop
    pause
    exit /b 1
)
echo ✅ Docker найден

docker compose version >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker Compose не найден!
    echo ℹ️  Обновите Docker Desktop
    pause
    exit /b 1
)
echo ✅ Docker Compose найден

echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║              📝 Настройка конфигурации                     ║
echo ╚════════════════════════════════════════════════════════════╝
echo.

:: Проверка существующего .env
if exist .env (
    echo ⚠️  Найден существующий файл .env
    set /p "use_existing=Использовать существующие настройки? [y/N]: "
    if /i "!use_existing!"=="y" (
        echo ✅ Используем существующий .env
        goto :skip_config
    )
)

echo.
echo ═══ Telegram Bot ═══
set /p "TELEGRAM_BOT_TOKEN=Telegram Bot Token (от @BotFather): "
set /p "TELEGRAM_BOT_USERNAME=Telegram Bot Username (без @): "
set /p "ADMIN_TELEGRAM_ID=Admin Telegram ID (ваш ID): "

echo.
echo ═══ Remnawave API v2.2.4 ═══
set /p "REMNA_BASE_URL=URL панели Remnawave (https://panel.example.com): "
set /p "REMNA_API_TOKEN=API Token (из Settings → API Tokens): "
set /p "REMNA_INBOUND_ID=Inbound ID (номер ноды) [1]: "
if "!REMNA_INBOUND_ID!"=="" set "REMNA_INBOUND_ID=1"
set /p "REMNA_DATA_LIMIT_GB=Лимит трафика (ГБ) [500]: "
if "!REMNA_DATA_LIMIT_GB!"=="" set "REMNA_DATA_LIMIT_GB=500"
set /p "REMNA_DEFAULT_DAYS=Дней по умолчанию [30]: "
if "!REMNA_DEFAULT_DAYS!"=="" set "REMNA_DEFAULT_DAYS=30"

echo.
echo ═══ Платежные системы ═══

set /p "enable_stars=Включить Telegram Stars? [Y/n]: "
if /i "!enable_stars!"=="n" (
    set "STARS_ENABLED=false"
    set "STARS_RATE=1.5"
) else (
    set "STARS_ENABLED=true"
    set /p "STARS_RATE=Курс Stars (звезд за 1 RUB) [1.5]: "
    if "!STARS_RATE!"=="" set "STARS_RATE=1.5"
)

set /p "setup_yookassa=Настроить YooKassa? [y/N]: "
if /i "!setup_yookassa!"=="y" (
    set /p "YOOKASSA_SHOP_ID=YooKassa Shop ID: "
    set /p "YOOKASSA_SECRET_KEY=YooKassa Secret Key: "
) else (
    set "YOOKASSA_SHOP_ID="
    set "YOOKASSA_SECRET_KEY="
)

set /p "setup_crypto=Настроить Crypto платежи? [y/N]: "
if /i "!setup_crypto!"=="y" (
    set /p "CRYPTO_API_KEY=Crypto API Key: "
    set /p "CRYPTO_MERCHANT_ID=Crypto Merchant ID: "
    set /p "CRYPTO_WEBHOOK_URL=Crypto Webhook URL: "
) else (
    set "CRYPTO_API_KEY="
    set "CRYPTO_MERCHANT_ID="
    set "CRYPTO_WEBHOOK_URL="
)

echo.
echo ℹ️  Создаем файл .env...

(
echo # ═══════════════════════════════════════════════════════════
echo #                    TELEGRAM BOT
echo # ═══════════════════════════════════════════════════════════
echo TELEGRAM_BOT_TOKEN=!TELEGRAM_BOT_TOKEN!
echo TELEGRAM_BOT_USERNAME=!TELEGRAM_BOT_USERNAME!
echo ADMIN_TELEGRAM_ID=!ADMIN_TELEGRAM_ID!
echo.
echo # ═══════════════════════════════════════════════════════════
echo #                 REMNAWAVE API v2.2.4
echo # ═══════════════════════════════════════════════════════════
echo REMNA_BASE_URL=!REMNA_BASE_URL!
echo REMNA_API_TOKEN=!REMNA_API_TOKEN!
echo REMNA_INBOUND_ID=!REMNA_INBOUND_ID!
echo REMNA_DATA_LIMIT_GB=!REMNA_DATA_LIMIT_GB!
echo REMNA_DEFAULT_DAYS=!REMNA_DEFAULT_DAYS!
echo.
echo # ═══════════════════════════════════════════════════════════
echo #                   TELEGRAM STARS
echo # ═══════════════════════════════════════════════════════════
echo STARS_ENABLED=!STARS_ENABLED!
echo STARS_RATE=!STARS_RATE!
echo.
echo # ═══════════════════════════════════════════════════════════
echo #                      YOOKASSA
echo # ═══════════════════════════════════════════════════════════
echo YOOKASSA_SHOP_ID=!YOOKASSA_SHOP_ID!
echo YOOKASSA_SECRET_KEY=!YOOKASSA_SECRET_KEY!
echo.
echo # ═══════════════════════════════════════════════════════════
echo #                   CRYPTO PAYMENTS
echo # ═══════════════════════════════════════════════════════════
echo CRYPTO_API_KEY=!CRYPTO_API_KEY!
echo CRYPTO_MERCHANT_ID=!CRYPTO_MERCHANT_ID!
echo CRYPTO_WEBHOOK_URL=!CRYPTO_WEBHOOK_URL!
) > .env

echo ✅ Файл .env создан

:skip_config

echo.
echo ℹ️  Создаем необходимые директории...
if not exist data mkdir data
if not exist logs mkdir logs
if not exist backups mkdir backups
echo ✅ Директории созданы

echo.
echo ℹ️  Собираем Docker образ...
docker compose build

echo.
echo ℹ️  Запускаем бота...
docker compose up -d

echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║              ✅ Установка завершена!                       ║
echo ╚════════════════════════════════════════════════════════════╝
echo.
echo ✅ Бот успешно запущен!
echo.
echo 📊 Управление:
echo    Логи:      docker compose logs -f
echo    Статус:    docker compose ps
echo    Остановка: docker compose down
echo    Рестарт:   docker compose restart
echo.
echo 📁 Файлы:
echo    Конфиг:    .env
echo    База:      data\shop_bot.db
echo    Логи:      logs\
echo    Бэкапы:    backups\
echo.
echo 🔧 Настройка бота:
echo    1. Откройте бота в Telegram: @!TELEGRAM_BOT_USERNAME!
echo    2. Используйте админ-панель для настройки текстов
echo    3. Настройте тарифы в src\shop_bot\config.py
echo.
echo ℹ️  Проверьте логи: docker compose logs -f
echo.
pause
