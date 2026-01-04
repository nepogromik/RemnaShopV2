#!/bin/bash

# Интерактивный скрипт установки Remna Shop Bot
# Поддержка Remnawave API v2.2.4

set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║       🚀 Remna Shop Bot - Интерактивная установка         ║"
echo "║              Remnawave API v2.2.4                          ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для вывода с цветом
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Функция для запроса ввода с валидацией
ask_input() {
    local prompt="$1"
    local var_name="$2"
    local default="$3"
    local required="$4"
    
    while true; do
        if [ -n "$default" ]; then
            read -p "$(echo -e ${BLUE}$prompt [по умолчанию: $default]: ${NC})" input
            input="${input:-$default}"
        else
            read -p "$(echo -e ${BLUE}$prompt: ${NC})" input
        fi
        
        if [ "$required" = "true" ] && [ -z "$input" ]; then
            print_error "Это поле обязательно для заполнения!"
            continue
        fi
        
        eval "$var_name='$input'"
        break
    done
}

# Проверка прав root
if [ "$EUID" -ne 0 ]; then 
    print_warning "Скрипт требует права root для установки systemd service"
    print_info "Запустите: sudo ./install.sh"
    exit 1
fi

echo ""
print_info "Проверка зависимостей..."

# Проверка Docker
if ! command -v docker &> /dev/null; then
    print_warning "Docker не найден. Устанавливаем..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    print_success "Docker установлен"
else
    print_success "Docker найден"
fi

# Проверка Docker Compose
if ! docker compose version &> /dev/null; then
    print_error "Docker Compose не найден!"
    print_info "Установите Docker Desktop или обновите Docker"
    exit 1
fi
print_success "Docker Compose найден"

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║              📝 Настройка конфигурации                     ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Проверяем существующий .env
if [ -f ".env" ]; then
    print_warning "Найден существующий файл .env"
    read -p "$(echo -e ${YELLOW}Хотите использовать существующие настройки? [y/N]: ${NC})" use_existing
    if [[ "$use_existing" =~ ^[Yy]$ ]]; then
        print_success "Используем существующий .env"
        SKIP_CONFIG=true
    else
        print_info "Создаем новую конфигурацию..."
        SKIP_CONFIG=false
    fi
else
    SKIP_CONFIG=false
fi

if [ "$SKIP_CONFIG" = false ]; then
    echo ""
    print_info "═══ Telegram Bot ═══"
    ask_input "Telegram Bot Token (от @BotFather)" TELEGRAM_BOT_TOKEN "" "true"
    ask_input "Telegram Bot Username (без @)" TELEGRAM_BOT_USERNAME "" "true"
    ask_input "Admin Telegram ID (ваш ID)" ADMIN_TELEGRAM_ID "" "true"
    
    echo ""
    print_info "═══ Remnawave API v2.2.4 ═══"
    ask_input "URL панели Remnawave (https://panel.example.com)" REMNA_BASE_URL "" "true"
    ask_input "API Token (из Settings → API Tokens)" REMNA_API_TOKEN "" "true"
    ask_input "Inbound ID (номер ноды)" REMNA_INBOUND_ID "1" "true"
    ask_input "Лимит трафика (ГБ)" REMNA_DATA_LIMIT_GB "500" "false"
    ask_input "Дней по умолчанию" REMNA_DEFAULT_DAYS "30" "false"
    
    echo ""
    print_info "═══ Платежные системы ═══"
    
    # Telegram Stars
    read -p "$(echo -e ${BLUE}Включить Telegram Stars? [Y/n]: ${NC})" enable_stars
    if [[ ! "$enable_stars" =~ ^[Nn]$ ]]; then
        STARS_ENABLED="true"
        ask_input "Курс Stars (звезд за 1 RUB)" STARS_RATE "1.5" "false"
    else
        STARS_ENABLED="false"
        STARS_RATE="1.5"
    fi
    
    # YooKassa
    read -p "$(echo -e ${BLUE}Настроить YooKassa? [y/N]: ${NC})" setup_yookassa
    if [[ "$setup_yookassa" =~ ^[Yy]$ ]]; then
        ask_input "YooKassa Shop ID" YOOKASSA_SHOP_ID "" "false"
        ask_input "YooKassa Secret Key" YOOKASSA_SECRET_KEY "" "false"
    else
        YOOKASSA_SHOP_ID=""
        YOOKASSA_SECRET_KEY=""
    fi
    
    # Crypto
    read -p "$(echo -e ${BLUE}Настроить Crypto платежи? [y/N]: ${NC})" setup_crypto
    if [[ "$setup_crypto" =~ ^[Yy]$ ]]; then
        ask_input "Crypto API Key" CRYPTO_API_KEY "" "false"
        ask_input "Crypto Merchant ID" CRYPTO_MERCHANT_ID "" "false"
        ask_input "Crypto Webhook URL" CRYPTO_WEBHOOK_URL "" "false"
    else
        CRYPTO_API_KEY=""
        CRYPTO_MERCHANT_ID=""
        CRYPTO_WEBHOOK_URL=""
    fi
    
    echo ""
    print_info "Создаем файл .env..."
    
    # Создаем .env файл
    cat > .env << EOF
# ═══════════════════════════════════════════════════════════
#                    TELEGRAM BOT
# ═══════════════════════════════════════════════════════════
TELEGRAM_BOT_TOKEN=${TELEGRAM_BOT_TOKEN}
TELEGRAM_BOT_USERNAME=${TELEGRAM_BOT_USERNAME}
ADMIN_TELEGRAM_ID=${ADMIN_TELEGRAM_ID}

# ═══════════════════════════════════════════════════════════
#                 REMNAWAVE API v2.2.4
# ═══════════════════════════════════════════════════════════
REMNA_BASE_URL=${REMNA_BASE_URL}
REMNA_API_TOKEN=${REMNA_API_TOKEN}
REMNA_INBOUND_ID=${REMNA_INBOUND_ID}
REMNA_DATA_LIMIT_GB=${REMNA_DATA_LIMIT_GB}
REMNA_DEFAULT_DAYS=${REMNA_DEFAULT_DAYS}

# ═══════════════════════════════════════════════════════════
#                   TELEGRAM STARS
# ═══════════════════════════════════════════════════════════
STARS_ENABLED=${STARS_ENABLED}
STARS_RATE=${STARS_RATE}

# ═══════════════════════════════════════════════════════════
#                      YOOKASSA
# ═══════════════════════════════════════════════════════════
YOOKASSA_SHOP_ID=${YOOKASSA_SHOP_ID}
YOOKASSA_SECRET_KEY=${YOOKASSA_SECRET_KEY}

# ═══════════════════════════════════════════════════════════
#                   CRYPTO PAYMENTS
# ═══════════════════════════════════════════════════════════
CRYPTO_API_KEY=${CRYPTO_API_KEY}
CRYPTO_MERCHANT_ID=${CRYPTO_MERCHANT_ID}
CRYPTO_WEBHOOK_URL=${CRYPTO_WEBHOOK_URL}
EOF
    
    chmod 600 .env
    print_success "Файл .env создан"
fi

echo ""
print_info "Создаем необходимые директории..."
mkdir -p data logs backups
print_success "Директории созданы"

echo ""
print_info "Собираем Docker образ..."
docker compose build

echo ""
print_info "Настраиваем systemd service..."
if [ -f "remna-shop-bot.service" ]; then
    cp remna-shop-bot.service /etc/systemd/system/
    systemctl daemon-reload
    systemctl enable remna-shop-bot
    print_success "Systemd service настроен"
else
    print_warning "Файл remna-shop-bot.service не найден, пропускаем"
fi

echo ""
print_info "Запускаем бота..."
docker compose up -d

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║              ✅ Установка завершена!                       ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
print_success "Бот успешно запущен!"
echo ""
echo "📊 Управление:"
echo "   Логи:      docker compose logs -f"
echo "   Статус:    docker compose ps"
echo "   Остановка: docker compose down"
echo "   Рестарт:   docker compose restart"
echo ""
echo "📁 Файлы:"
echo "   Конфиг:    .env"
echo "   База:      data/shop_bot.db"
echo "   Логи:      logs/"
echo "   Бэкапы:    backups/"
echo ""
echo "🔧 Настройка бота:"
echo "   1. Откройте бота в Telegram: @${TELEGRAM_BOT_USERNAME}"
echo "   2. Используйте админ-панель для настройки текстов"
echo "   3. Настройте тарифы в src/shop_bot/config.py"
echo ""
print_info "Проверьте логи: docker compose logs -f"
