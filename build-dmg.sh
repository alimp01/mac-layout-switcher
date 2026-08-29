#!/usr/bin/env bash
#
# build-dmg.sh — упаковка MacLayoutSwitcher.app в .dmg-дистрибутив одной командой.
#
# Запускать ТОЛЬКО на macOS 13+ (нужны `hdiutil` и `ln`, которых на Linux-машине
# сборки агента нет). На Linux скрипт не запускается — проверяется только
# шеллчеком: `bash -n build-dmg.sh`. Логику сборки .app держит build.sh, здесь —
# только упаковка в образ.
#
# Результат: dist/MacLayoutSwitcher.dmg. Пользователь монтирует его и
# перетаскивает MacLayoutSwitcher.app на ярлык «Программы» (симлинк /Applications
# внутри образа) — обычная установка macOS-приложения.
#
# Использование:
#   ./build-dmg.sh              собрать .app, если его нет в dist/, затем .dmg
#   ./build-dmg.sh --rebuild    пересобрать .app заново (вызвать build.sh) и .dmg

# -e: падать на первой ошибке; -u: необъявленная переменная — ошибка;
# -o pipefail: ошибка в любом звене пайпа валит весь пайп. Без этого можно
# «собрать» битый образ и отрапортовать успех.
set -euo pipefail

# Каталог скрипта = корень репозитория (build.sh и Package.swift рядом). Так
# build-dmg.sh работает из любого cwd.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# --- Константы образа ---------------------------------------------------------
APP_NAME="MacLayoutSwitcher"                 # = имя бандла, что делает build.sh
VOL_NAME="MacLayoutSwitcher"                 # имя тома при монтировании
DIST_DIR="$SCRIPT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
DMG_PATH="$DIST_DIR/$APP_NAME.dmg"

# --- Разбор аргументов --------------------------------------------------------
REBUILD=0
for arg in "$@"; do
    case "$arg" in
        --rebuild) REBUILD=1 ;;
        *) echo "!! Неизвестный аргумент: $arg (допустим только --rebuild)" >&2; exit 1 ;;
    esac
done

# --- Временная staging-папка + гарантированная чистка -------------------------
# Образ собирается из staging, а не напрямую из dist/, чтобы в .dmg попали
# ровно .app + симлинк на /Applications, без остального содержимого dist/.
# trap чистит staging при любом выходе (успех, ошибка, прерывание).
STAGING=""
cleanup() {
    if [[ -n "$STAGING" && -d "$STAGING" ]]; then
        rm -rf "$STAGING"
    fi
}
trap cleanup EXIT INT TERM

# --- 1. Гарантировать наличие .app --------------------------------------------
if [[ "$REBUILD" -eq 1 || ! -d "$APP_BUNDLE" ]]; then
    echo "==> Собираю $APP_NAME.app через ./build.sh"
    ./build.sh
fi
if [[ ! -d "$APP_BUNDLE" ]]; then
    echo "!! .app не найден после сборки: $APP_BUNDLE" >&2
    exit 1
fi

# --- 2. Staging: .app + симлинк на /Applications ------------------------------
STAGING="$(mktemp -d "${TMPDIR:-/tmp}/maclayoutswitcher-dmg.XXXXXX")"
echo "==> Готовлю staging $STAGING"
cp -R "$APP_BUNDLE" "$STAGING/$APP_NAME.app"
# Ярлык «Программы»: пользователь перетаскивает .app на него — установка.
ln -s /Applications "$STAGING/Applications"

# --- 3. Собрать сжатый образ --------------------------------------------------
# -ov: перезаписать существующий .dmg; -format UDZO: сжатый read-only образ
# (штатный формат дистрибутива). Пересобираем начисто, поэтому старый удаляем.
echo "==> hdiutil create $DMG_PATH"
rm -f "$DMG_PATH"
hdiutil create \
    -volname "$VOL_NAME" \
    -srcfolder "$STAGING" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

# staging уберёт trap на выходе.

# --- 4. Итог ------------------------------------------------------------------
cat <<DONE

Готово: $DMG_PATH

Установка:
  1. open "$DMG_PATH"
  2. Перетащить MacLayoutSwitcher.app на ярлык «Программы» (Applications).
  3. Первый запуск: в «Программах» правый клик по MacLayoutSwitcher →
     «Открыть» → подтвердить (ad-hoc подпись без нотаризации — Gatekeeper
     спросит один раз).
  4. Выдать разрешения: Системные настройки → Конфиденциальность и
     безопасность → Универсальный доступ + Мониторинг ввода.
DONE
