#!/usr/bin/env bash
#
# self-update.sh — самообновление Mac Layout Switcher (таск 13, только macOS).
#
# Запускается ПРИЛОЖЕНИЕМ (Updater.swift) detached: приложение копирует этот
# скрипт из Contents/Resources своего бандла во временную папку и стартует
# КОПИЮ через nohup — потому что скрипт заменит сам бандл, и исполняемый файл
# не должен исчезнуть из-под bash посреди работы.
#
# Аргумент $1 — путь к текущему .app (Bundle.main.bundlePath), его и заменяем.
# Аргумент $2 (опционально) — временная папка Updater'а с КОПИЕЙ этого скрипта:
# удаляем её при завершении сами, больше некому.
#
# Порядок безопасен для существующей установки: скачиваем и СОБИРАЕМ во
# временной папке, старый .app трогаем ТОЛЬКО после успешной сборки. Любой
# сбой до замены (сеть, tar, build.sh) оставляет установленное приложение
# нетронутым — set -euo pipefail роняет скрипт до строки с rm -rf.
#
# Лог всего процесса: ~/Library/Logs/MacLayoutSwitcher-update.log

set -euo pipefail

LOG="$HOME/Library/Logs/MacLayoutSwitcher-update.log"
mkdir -p "$(dirname "$LOG")"
# Весь дальнейший вывод (свой и дочерних команд) — в лог; приложение уже
# вышло, показывать некому.
exec >>"$LOG" 2>&1

echo "=== $(date '+%Y-%m-%d %H:%M:%S') self-update: старт ==="

APP_PATH="${1:-}"
SCRIPT_TMP="${2:-}"
# Дальше по пути будет rm -rf, поэтому валидация жёсткая: путь обязан
# существовать И оканчиваться на «.app». Запуск вне бандла (голый бинарник,
# ~/bin, .build/release) обязан закончиться отказом, а не сносом каталога.
if [[ -z "$APP_PATH" || "$APP_PATH" != *.app || ! -d "$APP_PATH" ]]; then
    echo "!! Отказ: '$APP_PATH' не похож на путь к существующему .app-бандлу"
    exit 1
fi
echo "Обновляю: $APP_PATH"

# Временная папка на всё (архив, исходники, сборка); чистится при любом исходе.
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/mls-update.XXXXXX")"
cleanup() {
    rm -rf "$TMP_DIR"
    # Папка Updater'а с копией скрипта: удалить каталог, из которого bash
    # читает скрипт, безопасно — файл дочитывается из открытого дескриптора.
    if [[ -n "$SCRIPT_TMP" && -d "$SCRIPT_TMP" ]]; then
        rm -rf "$SCRIPT_TMP"
    fi
    # Спасение после сбоя на самом узком месте: старый .app уже снесён, а
    # новый ещё под временным именем — доставим его на место, не удалим.
    if [[ -n "${STAGED:-}" && -d "${STAGED:-}" ]]; then
        if [[ ! -d "$APP_PATH" ]]; then
            mv "$STAGED" "$APP_PATH" || true
        else
            rm -rf "$STAGED"
        fi
    fi
}
trap cleanup EXIT

# --- 1. Скачать и распаковать main ------------------------------------------
TARBALL_URL="https://github.com/alimp01/mac-layout-switcher/archive/refs/heads/main.tar.gz"
echo "==> curl $TARBALL_URL"
curl -fL --max-time 300 -o "$TMP_DIR/src.tar.gz" "$TARBALL_URL"
tar -xzf "$TMP_DIR/src.tar.gz" -C "$TMP_DIR"

SRC_DIR="$TMP_DIR/mac-layout-switcher-main"
if [[ ! -f "$SRC_DIR/build.sh" ]]; then
    echo "!! В архиве нет build.sh (ожидал $SRC_DIR/build.sh) — структура репо изменилась?"
    exit 1
fi

# --- 2. Собрать во временном ------------------------------------------------
echo "==> build.sh (в $SRC_DIR)"
( cd "$SRC_DIR" && bash ./build.sh )

NEW_APP="$SRC_DIR/dist/MacLayoutSwitcher.app"
if [[ ! -d "$NEW_APP" || ! -x "$NEW_APP/Contents/MacOS/MacLayoutSwitcher" ]]; then
    echo "!! Сборка отчиталась успехом, но $NEW_APP не похож на готовый бандл"
    exit 1
fi

# --- 3. Заменить установленный .app (только теперь!) ------------------------
# Сначала копируем новый бандл во временное имя РЯДОМ с целевым (тот же том):
# долгий cp с другого тома проходит заранее, а окно «приложения нет на месте»
# сжимается до rm + mv (mv в пределах тома — мгновенный rename).
STAGED="$(dirname "$APP_PATH")/.MacLayoutSwitcher.app.new.$$"
echo "==> Заменяю $APP_PATH (staging: $STAGED)"
rm -rf "$STAGED"
cp -R "$NEW_APP" "$STAGED"
rm -rf "$APP_PATH"
mv "$STAGED" "$APP_PATH"

# --- 4. Запустить новую версию ----------------------------------------------
# Замена по тому же пути с ad-hoc подписью сбрасывает TCC-доверие: при первом
# старте новая версия сама покажет онбординг разрешений — это ожидаемо.
echo "==> open $APP_PATH"
open "$APP_PATH"

echo "=== $(date '+%Y-%m-%d %H:%M:%S') self-update: готово ==="
