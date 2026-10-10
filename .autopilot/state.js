window.STATE =
{
  "slug": "mac-layout-switcher",
  "dir": "2026-08-29-mac-layout-switcher",
  "title": "Свой аналог Punto/Caramba Switcher для Mac",
  "mode": "semi",
  "depth": "normal",
  "polish": null,
  "tier": "T2",
  "briefFile": "2026-08-29-brief.md",
  "memoryFile": "CLAUDE.md",
  "skillDir": "/home/claudebot/.claude/skills/autopilot",
  "startedAt": "2026-08-29T03:22:57+00:00",
  "updatedAt": "2026-10-10T17:27:38.248052+00:00",
  "stages": [
    {
      "id": "preflight",
      "status": "done",
      "startedAt": "2026-08-29T03:22:57+00:00",
      "finishedAt": "2026-08-29T03:24:41+00:00"
    },
    {
      "id": "manifest",
      "status": "done",
      "startedAt": "2026-08-29T03:24:41+00:00",
      "finishedAt": "2026-08-29T03:27:10+00:00"
    },
    {
      "id": "briefing",
      "status": "done",
      "startedAt": "2026-08-29T03:27:10+00:00",
      "finishedAt": "2026-08-29T03:34:30+00:00"
    },
    {
      "id": "spec",
      "status": "done",
      "startedAt": "2026-08-29T03:34:30+00:00",
      "finishedAt": "2026-08-29T03:44:20+00:00"
    },
    {
      "id": "plan",
      "status": "done",
      "startedAt": "2026-08-29T03:44:20+00:00",
      "finishedAt": "2026-08-29T03:52:30+00:00",
      "note": "23 тикета; дополнение G20 2026-10-08"
    },
    {
      "id": "build",
      "status": "done",
      "startedAt": "2026-08-29T03:52:30+00:00",
      "note": "G23 frozen4 approved0findings byboth; root15groups/Engine/delay/nativefullspeech/mountedDMG and Linux95exactreuse PASS",
      "finishedAt": "2026-10-10T17:17:49.980263+00:00"
    },
    {
      "id": "review",
      "status": "done",
      "startedAt": "2026-10-08T04:45:11.080956+00:00",
      "note": "G23 frozen4 approved0findings byboth; root15groups/Engine/delay/nativefullspeech/mountedDMG and Linux95exactreuse PASS",
      "finishedAt": "2026-10-10T17:17:49.980263+00:00"
    },
    {
      "id": "final",
      "status": "done",
      "startedAt": "2026-08-29T05:25:00+00:00",
      "note": "1.4.6 codecommit/rawVERSION/publicarchiveSHA/PAX64frozenfiles verified; actualspeech manualhandoff pending",
      "finishedAt": "2026-10-10T17:27:38.248052+00:00"
    }
  ],
  "requirements": {
    "total": 30,
    "done": 29,
    "inTicket": 0,
    "droppedNote": "G07 отменён пользователем в пользу G08",
    "inSpec": 0,
    "placeholder": 0,
    "deferred": 0,
    "dropped": 1
  },
  "tickets": [
    {
      "id": "01",
      "title": "Каркас SwiftPM + ядро: KeyMap, WordBuffer, SnippetStore",
      "requirements": [
        "R02",
        "R03",
        "R07i",
        "G01"
      ],
      "blockedBy": [],
      "wave": 1,
      "zone": [
        "Package.swift",
        "Sources/SwitcherCore/",
        "Tests/"
      ],
      "status": "done",
      "startedAt": "2026-08-29T03:56:00+00:00",
      "finishedAt": "2026-08-29T04:12:40+00:00",
      "tests": {
        "passed": 12,
        "failed": 0
      },
      "commit": "8ee81d5",
      "retries": 0,
      "repairs": 0,
      "handoffs": 0
    },
    {
      "id": "02",
      "title": "Детектор неправильной раскладки",
      "requirements": [
        "R04i"
      ],
      "blockedBy": [
        "01"
      ],
      "wave": 2,
      "zone": [
        "Sources/SwitcherCore/Detector"
      ],
      "status": "done",
      "startedAt": "2026-08-29T04:13:20+00:00",
      "finishedAt": "2026-08-29T04:42:00+00:00",
      "tests": {
        "passed": 17,
        "failed": 0
      },
      "commit": "59f0216",
      "retries": 0,
      "repairs": 0,
      "handoffs": 0
    },
    {
      "id": "03",
      "title": "Системный слой macOS: перехват, перепечатка, раскладка",
      "requirements": [
        "R06i",
        "R03"
      ],
      "blockedBy": [
        "01"
      ],
      "wave": 2,
      "zone": [
        "Sources/MacLayoutSwitcher/System/"
      ],
      "status": "done",
      "startedAt": "2026-08-29T04:13:20+00:00",
      "finishedAt": "2026-08-29T04:32:10+00:00",
      "tests": {
        "passed": 12,
        "failed": 0
      },
      "commit": "54da5e2",
      "retries": 0,
      "repairs": 0,
      "handoffs": 0
    },
    {
      "id": "04",
      "title": "Engine: автоисправление, Option, откат, автозамена, автопауза",
      "requirements": [
        "R04i",
        "R05i",
        "G01",
        "A01"
      ],
      "blockedBy": [
        "02",
        "03"
      ],
      "wave": 3,
      "zone": [
        "Sources/MacLayoutSwitcher/Engine",
        "Sources/MacLayoutSwitcher/Config"
      ],
      "status": "done",
      "startedAt": "2026-08-29T04:42:30+00:00",
      "finishedAt": "2026-08-29T04:53:00+00:00",
      "tests": {
        "passed": 28,
        "failed": 0
      },
      "commit": "2a2f260",
      "retries": 0,
      "repairs": 0,
      "handoffs": 0
    },
    {
      "id": "05",
      "title": "Меню-бар, звуки, сборка .app, README",
      "requirements": [
        "R06i",
        "G02",
        "R07i",
        "R01"
      ],
      "blockedBy": [
        "04"
      ],
      "wave": 4,
      "zone": [
        "Sources/MacLayoutSwitcher/UI/",
        "build.sh",
        "README.md"
      ],
      "status": "done",
      "startedAt": "2026-08-29T04:53:30+00:00",
      "finishedAt": "2026-08-29T05:24:00+00:00",
      "tests": {
        "passed": 28,
        "failed": 0
      },
      "commit": "272742e",
      "retries": 0,
      "repairs": 1,
      "repairFindings": [
        "звук клика играл в secure input/паузе — нарушение A01 «молчать полностью»"
      ],
      "handoffs": 0
    },
    {
      "id": "06",
      "title": "Порог отмен перед авто-исключением",
      "requirements": [
        "G03"
      ],
      "blockedBy": [
        "04"
      ],
      "wave": 5,
      "zone": [
        "Sources/SwitcherCore/EngineCore",
        "Sources/MacLayoutSwitcher/Config",
        "Sources/MacLayoutSwitcher/Engine"
      ],
      "status": "done",
      "startedAt": "2026-08-29T06:50:00+00:00",
      "finishedAt": "2026-08-29T07:05:00+00:00",
      "tests": {
        "passed": 31,
        "failed": 0
      },
      "commit": "6df8775",
      "retries": 0,
      "repairs": 0,
      "handoffs": 0
    },
    {
      "id": "07",
      "title": "Упаковка в .dmg-дистрибутив",
      "requirements": [
        "G04"
      ],
      "blockedBy": [
        "05"
      ],
      "wave": 5,
      "zone": [
        "build-dmg.sh",
        "build.sh",
        "README.md"
      ],
      "status": "done",
      "startedAt": "2026-08-29T06:58:00+00:00",
      "finishedAt": "2026-08-29T07:20:00+00:00",
      "tests": {
        "passed": 31,
        "failed": 0
      },
      "commit": "5f5ebc1",
      "retries": 0,
      "repairs": 0,
      "handoffs": 0
    },
    {
      "id": "08",
      "title": "Настройка горячих клавиш",
      "requirements": [
        "G05"
      ],
      "blockedBy": [
        "04",
        "06"
      ],
      "wave": 6,
      "zone": [
        "Sources/SwitcherCore/Hotkey",
        "Sources/SwitcherCore/EngineCore",
        "Sources/MacLayoutSwitcher/Config",
        "Sources/MacLayoutSwitcher/Engine",
        "Sources/MacLayoutSwitcher/UI/"
      ],
      "status": "done",
      "startedAt": "2026-08-29T07:12:00+00:00",
      "finishedAt": "2026-08-29T07:35:00+00:00",
      "tests": {
        "passed": 43,
        "failed": 0
      },
      "commit": "9754eb0",
      "retries": 0,
      "repairs": 0,
      "handoffs": 0
    },
    {
      "id": "09",
      "title": "Автозапуск при входе (launch at login)",
      "requirements": [
        "G06"
      ],
      "blockedBy": [
        "05",
        "08"
      ],
      "wave": 7,
      "zone": [
        "Sources/MacLayoutSwitcher/System/LoginItem",
        "Sources/MacLayoutSwitcher/Config",
        "Sources/MacLayoutSwitcher/UI/StatusBarUI",
        "Sources/MacLayoutSwitcher/main.swift"
      ],
      "status": "done",
      "startedAt": "2026-08-31T09:00:00+00:00",
      "finishedAt": "2026-08-31T09:20:00+00:00",
      "tests": {
        "passed": 43,
        "failed": 0
      },
      "commit": "21f8a6b",
      "retries": 0,
      "repairs": 1,
      "repairFindings": [
        "register→.requiresApproval снимал галочку без подсказки — пользователь видит «не работает»"
      ],
      "handoffs": 0
    },
    {
      "id": "10",
      "title": "Инфраструктура иконки (.icns в бандле)",
      "requirements": [
        "G08"
      ],
      "blockedBy": [
        "05",
        "07"
      ],
      "wave": 8,
      "zone": [
        "Resources/",
        "tools/make-icns.py",
        "build.sh"
      ],
      "status": "done",
      "startedAt": "2026-08-31T10:10:00+00:00",
      "finishedAt": "2026-08-31T10:40:00+00:00",
      "tests": {
        "passed": 43,
        "failed": 0
      },
      "commit": "f4a2248",
      "retries": 0,
      "repairs": 0,
      "handoffs": 0
    },
    {
      "id": "11",
      "title": "Утка-иконка + индикация раскладки в трее",
      "requirements": [
        "G08",
        "G09"
      ],
      "blockedBy": [
        "10"
      ],
      "wave": 9,
      "zone": [
        "Resources/AppIcon.icns",
        "Sources/MacLayoutSwitcher/UI/",
        "Sources/MacLayoutSwitcher/main.swift"
      ],
      "status": "done",
      "startedAt": "2026-08-31T10:40:00+00:00",
      "finishedAt": "2026-08-31T11:30:00+00:00",
      "tests": {
        "passed": 43,
        "failed": 0
      },
      "commit": "6fdee31",
      "retries": 0,
      "repairs": 0,
      "handoffs": 0
    },
    {
      "id": "12",
      "title": "Звук только на исправление",
      "requirements": [
        "G10"
      ],
      "blockedBy": [
        "11"
      ],
      "wave": 10,
      "zone": [
        "Sources/MacLayoutSwitcher/Engine.swift",
        "Sources/MacLayoutSwitcher/UI/Sounds.swift"
      ],
      "status": "done",
      "startedAt": "2026-08-31T12:05:00+00:00",
      "finishedAt": "2026-08-31T12:25:00+00:00",
      "tests": {
        "passed": 43,
        "failed": 0
      },
      "commit": "30b02db",
      "retries": 0,
      "repairs": 0,
      "handoffs": 0
    },
    {
      "id": "13",
      "title": "Автообновление через GitHub",
      "requirements": [
        "G11"
      ],
      "blockedBy": [
        "11"
      ],
      "wave": 11,
      "zone": [
        "VERSION",
        "Sources/MacLayoutSwitcher/System/Updater",
        "tools/self-update.sh",
        "build.sh"
      ],
      "status": "done",
      "startedAt": "2026-08-31T12:50:00+00:00",
      "finishedAt": "2026-08-31T13:40:00+00:00",
      "tests": {
        "passed": 49,
        "failed": 0
      },
      "commit": "e73a751",
      "retries": 0,
      "repairs": 1,
      "repairFindings": [
        "rm -rf без гарда .app + предложение обновления вне бандла = снос произвольного каталога; interactive-офлайн молчит; замена не атомарна"
      ],
      "handoffs": 0
    },
    {
      "id": "14",
      "title": "Исправление ДО доставки разделителя (активный EventTap)",
      "requirements": [
        "G12"
      ],
      "blockedBy": [
        "13"
      ],
      "wave": 12,
      "zone": [
        "Sources/SwitcherCore/EngineCore",
        "Sources/MacLayoutSwitcher/System/EventTap",
        "Sources/MacLayoutSwitcher/System/Typist",
        "Sources/MacLayoutSwitcher/Engine"
      ],
      "status": "done",
      "startedAt": "2026-09-15T12:20:00+00:00",
      "finishedAt": "2026-09-15T15:10:00+00:00",
      "tests": {
        "passed": 58,
        "failed": 0
      },
      "commit": "3b51c43",
      "retries": 0,
      "repairs": 1,
      "repairFindings": [
        "typeKey молча терял подавленный Enter; гонка ввода во время перепечатки; файловый I/O в колбэке активного tap'а; мёртвый then:"
      ],
      "handoffs": 0
    },
    {
      "id": "15",
      "title": "Короткие частотные слова: «Как», «ты», «и»",
      "requirements": [
        "G13"
      ],
      "blockedBy": [
        "02"
      ],
      "wave": 12,
      "zone": [
        "Sources/SwitcherCore/Detector",
        "Sources/SwitcherCore/ShortWords"
      ],
      "status": "done",
      "startedAt": "2026-09-15T13:10:00+00:00",
      "finishedAt": "2026-09-15T15:10:00+00:00",
      "tests": {
        "passed": 58,
        "failed": 0
      },
      "commit": "3b51c43",
      "retries": 0,
      "repairs": 0,
      "handoffs": 0
    },
    {
      "id": "16",
      "title": "Локальная расшифровка WAV через GigaAM v3",
      "requirements": [
        "G14"
      ],
      "blockedBy": [],
      "wave": 13,
      "status": "done",
      "commit": "9a83348",
      "retries": 0,
      "repairs": 0,
      "handoffs": 0,
      "finishedAt": "2026-09-16T03:13:27.206206+00:00",
      "tests": {
        "passed": 71,
        "failed": 0
      }
    },
    {
      "id": "17",
      "title": "Диктовка по удержанию горячей клавиши и вставка в поле",
      "requirements": [
        "G14"
      ],
      "blockedBy": [
        "16"
      ],
      "wave": 14,
      "status": "done",
      "commit": "0b378f3",
      "retries": 0,
      "repairs": 1,
      "handoffs": 0,
      "finishedAt": "2026-09-16T03:13:27.206206+00:00",
      "tests": {
        "passed": 71,
        "failed": 0
      },
      "repairFindings": [
        "P2: потерянный keyUp после паузы/записи хоткея мог съесть первый Space; полный reset жеста и подавленных клавиш, 2 регрессионных теста"
      ]
    },
    {
      "id": "18",
      "title": "Целостность ввода и одиночные и/я",
      "requirements": [
        "G15"
      ],
      "blockedBy": [],
      "status": "done",
      "wave": 15,
      "commit": "321eba8",
      "validation": "36 focused Linux tests passed; Mac build passed; both reviewers approved after repairs",
      "repairs": 1
    },
    {
      "id": "19",
      "title": "Автоматическая подготовка модели",
      "requirements": [
        "G16"
      ],
      "blockedBy": [],
      "status": "done",
      "wave": 15,
      "commit": "2bb8f1f",
      "validation": "Native real model cache/restarts/download/cancel/offline PASS; Spec+Standards no findings"
    },
    {
      "id": "20",
      "title": "Конвертация выделенного текста",
      "requirements": [
        "G17"
      ],
      "blockedBy": [
        "18"
      ],
      "status": "done",
      "wave": 16,
      "commit": "12cc6de",
      "tests": {
        "passed": 85,
        "failed": 0
      },
      "validation": "Native debug + integrated Spec/Standards approved; live AX acceptance pending"
    },
    {
      "id": "21",
      "title": "Системная полнота исправлений и защита правильных слов",
      "requirements": [
        "G18"
      ],
      "blockedBy": [],
      "status": "done",
      "wave": 17,
      "commit": "fec1515",
      "finishedAt": "2026-10-07T07:44:01.810778+00:00",
      "tests": {
        "passed": 95,
        "failed": 0
      },
      "validation": "49 targeted tests;95 fullLinux; two independent approvals; frozen audit; native release/DMG verification"
    },
    {
      "id": "22",
      "title": "Вставка диктовки и видимый результат",
      "requirements": [
        "G19"
      ],
      "blockedBy": [],
      "wave": 18,
      "status": "done",
      "commit": "e857996",
      "finishedAt": "2026-10-08T04:32:25.996828+00:00",
      "tests": {
        "passed": 95,
        "failed": 0
      },
      "validation": "Native panel red/green and adapter pass independently; actual Codex routing metadata; fullLinux95; both reviews approved; release/DMG verified",
      "repairs": 1
    },
    {
      "id": "23",
      "title": "Восстановить Option и автоматическую замену",
      "requirements": [
        "G20"
      ],
      "status": "done",
      "blockedBy": [],
      "wave": 19,
      "zone": [
        "Sources/MacLayoutSwitcher",
        "Tests",
        "tools"
      ],
      "retries": 0,
      "repairs": 0,
      "handoffs": 0,
      "startedAt": "2026-10-08T04:39:46.121007+00:00",
      "finishedAt": "2026-10-08T05:54:58.892222+00:00",
      "commit": "d7b003d",
      "tests": {
        "passed": 95,
        "failed": 0
      },
      "review": {
        "spec": "approved",
        "standards": "approved"
      }
    },
    {
      "id": "24",
      "title": "Исправить удаление вместо замены",
      "requirements": [
        "G21"
      ],
      "status": "done",
      "startedAt": "2026-10-10T09:26:43.132471+00:00",
      "blockedBy": [],
      "wave": 20,
      "zone": [
        "Sources/MacLayoutSwitcher",
        "tools"
      ],
      "retries": 0,
      "repairs": 0,
      "handoffs": 1,
      "partialCommit": "c57e700f9f44f62dd79d2576e88300d994932ccb",
      "validation": "Frozen160 checksum exact; same finalrunner baselineRED finalGREEN; root+2independentreviewers engine/native/G19PASS; rootfullspeech+Linux95PASS",
      "tests": {
        "passed": 95,
        "failed": 0
      },
      "review": {
        "spec": "approved",
        "standards": "approved",
        "scope": "Concrete autorepeat race; physicaluser/crossprocess delivery unverified"
      },
      "note": "Allapps autoSpace/Enter trigger known; scoped fix approved; manual acceptance pending",
      "finishedAt": "2026-10-10T14:37:25.105000+00:00"
    },
    {
      "id": "25",
      "title": "Исправить реальное удаление после1.4.4",
      "requirements": [
        "G22"
      ],
      "status": "done",
      "startedAt": "2026-10-10T15:15:18.569320+00:00",
      "blockedBy": [],
      "zone": [
        "Sources/MacLayoutSwitcher",
        "tools"
      ],
      "wave": 21,
      "validation": "Concrete delayedACK baselineRED/finalGREEN; root nativeEngine+delay/G19/fullspeech/Linux95; Spec+Standards finalapproved; installedphysicalSpace GREEN bothownedCodexfields",
      "candidateCodeCommit": "2163e0a3e7fa7f388ba551ef97b69d9a6f0a3126",
      "reviews": "Both finalapproved0blockers",
      "finishedAt": "2026-10-10T16:23:10.954219+00:00",
      "commit": "2163e0a3e7fa7f388ba551ef97b69d9a6f0a3126"
    },
    {
      "id": "26",
      "title": "Полная вставка диктовки после1.4.5",
      "requirements": [
        "G23"
      ],
      "status": "done",
      "startedAt": "2026-10-10T16:32:38.436837+00:00",
      "blockedBy": [],
      "zone": [
        "Sources/MacLayoutSwitcher/Speech",
        "tools"
      ],
      "wave": 22,
      "validation": "LiteralbaselineRED16; concurrentforeign/multiOwn/capacitywait RED→GREEN; rootfinal15groups/Engine/delay/nativefullspeech/mountedDMG; exact27file Linux95reuse; actualspeech pending",
      "repairs": 3,
      "review": {
        "spec": "approved",
        "standards": "approved",
        "sourceSHA256": "cf3d4d6e29672b1c9601e0cd4234c9253ee94d3214d45f428a65f9429d351c41",
        "findings": 0
      },
      "tests": {
        "passed": 95,
        "failed": 0,
        "nativeCompletionGroups": 15
      },
      "commit": "f96f920104b538201d12c51bf7d8d8018eaf5b71",
      "finishedAt": "2026-10-10T17:27:38.248052+00:00"
    }
  ],
  "singlePass": null,
  "tests": {
    "passed": 95,
    "failed": 0,
    "note": "G22 rootLinux95/95; frozen finalEngine/delayedselection/fullspeech/deepstrict/mountedDMG; reviewerskeyboard/notice/G19 PASS. PhysicalSpace GREEN bothownedCodexIAB fields; privatecomposer/allapps/manualEnterShift pending."
  },
  "debt": {
    "placeholders": [],
    "assumptions": [],
    "emptyEnv": []
  },
  "additions": [
    {
      "id": "G14",
      "title": "Локальная диктовка по удержанию хоткея, GigaAM v3",
      "status": "done",
      "tickets": [
        "16",
        "17"
      ]
    },
    {
      "id": "G15",
      "title": "Целостность ввода и одиночные и/я",
      "status": "done",
      "tickets": [
        "18"
      ]
    },
    {
      "id": "G16",
      "title": "Автоматическая подготовка модели",
      "status": "done",
      "tickets": [
        "19"
      ]
    },
    {
      "id": "G17",
      "title": "Конвертация выделенного текста",
      "status": "done",
      "tickets": [
        "20"
      ]
    },
    {
      "id": "G18",
      "title": "Системный аудит замен",
      "status": "done",
      "tickets": [
        "21"
      ]
    },
    {
      "id": "G19",
      "title": "Исправить вставку диктовки",
      "status": "done",
      "tickets": [
        "22"
      ]
    }
  ],
  "coverage": {
    "findings": 0,
    "note": "G2: пропусков нет, полупокрытий нет; 8 позиций «сверх брифа» = R##.n-проработка и A01 с родителем — оставлены"
  },
  "concerns": [
    "Tests/SwitcherCoreTests/*:2 — @testable import SwitcherCore, хотя ассерты ходят через публичный шов; условие: обычный import",
    "РЕШЕНО в T04: EventTap оставлен .listenOnly осознанно — исправление стирает слово вместе с уже напечатанным разделителем и перепечатывает; подавлять нечего. Плата: Enter-как-submit в chat-полях может перепечататься (задокументировано в Engine.swift). Ревью 04 признало переигровкой, не блок.",
    "Typist.swift:50,68 — отказ создания CGEvent молча съедает событие, частичная замена портит текст; условие: прерывать весь replaceLastWord",
    "Typist.swift:27 — 5000 мкс на событие ≈0.2 с на слово; условие: обосновать или уменьшить",
    "DetectorTests.swift:90,102 — ambiguousShort все <3 символов, дублируют testShortMixed; условие: спорные короткие ≥3 либо убрать метку",
    "Detector.swift:167 — save глотает ошибку записи через try? молча; условие: не выглядеть успехом при отказе или задокументировать",
    "Config.swift:100 — при тихом провале move битого config следующий save() затрёт оригинал дефолтами, .broken-бэкап не останется; условие: бэкап копией до записи либо не затирать при неудаче",
    "EngineCore.swift:237 — cyrillicSet дублирует алфавит из Detector/KeyMap (3-е место); условие: единый источник, если появится публичный шов классификатора",
    "EngineCoreTests.swift:3 — @testable import избыточен (ассерты через публичный шов); условие: обычный import",
    "main.swift:83,162 — openInEditor и relaunch глотают отказ через try? молча; условие: отказ не должен выглядеть успехом",
    "T10 make-icns.py:104 — self-check делит константу CHUNK_TYPES со сборщиком (самоподтверждение в миниатюре); условие: эталон типов отдельным литералом",
    "T11 main.swift:134 — имя TIS-уведомления захардкожено строкой при доступной Carbon-константе; условие: kTISNotifySelectedKeyboardInputSourceChanged as String",
    "T11 main.swift:29+StatusBarUI:56 — факт ручной паузы дублирован (manualPaused и state.paused, OR прячет рассинхрон); условие: единый источник",
    "T06 EngineCore/Engine — при пороге счётчик пишется key=0, а не удаляется; undo-counts.json монотонно пухнет мёртвыми записями; условие: удалять сброшенный ключ",
    "T06 EngineCore — дефолт undoThreshold=3 нигде не проверяется тестом без явной передачи порога; условие: тест на конструктор без порога",
    "T14 Engine.swift:383 / Typist.keyCode(forSeparator:) — запасной путь по символу недостижим (stroke==nil только у хоткеев); условие: убрать или сделать stroke обязательным для boundary",
    "T14 Detector.save(to:) — приложением больше не используется (персист через Config.saveExclusions), жив только в тестах; условие: одна точка записи exclusions.json",
    "T14 Engine.swift:172 — isBusy = «очередь пуста», а не «события доставлены»: микроокно после последней синтетики; условие: зафиксировать как известную плату",
    "T14 EventTap mask — реальный keyUp разделителя не подавляется (mask keyDown+flagsChanged): приложение видит одиночный keyUp после синтетической пары; для текстовых полей безвредно; условие: зафиксировать как известную плату / подавлять парный keyUp",
    "T14 Typist.replaceLastWord(then:) добавлен, Engine не использует (порядок через typeKey в той же очереди); условие: убрать неиспользуемый параметр",
    "T09 StatusBarUI:23 — State.launchAtLogin имеет дефолт =false, прочие поля нет; условие: убрать дефолт или задать всем",
    "T09: CLAUDE.md не упоминает launchAtLogin/LoginItem.swift; условие: дописать при финале памяти",
    "CLAUDE.md устарел: «28 тестов» (стало 43) + раздел Архитектура упоминает InputEvent.optionTap (переименован в .hotkey(.convert)); условие: обновить память при финале",
    "T08 Hotkey.swift — rightCommand/rightOption/... в модели, но не порождаются (Engine и рекордер схлопывают лево/право); speculative generality; условие: либо различать, либо убрать кейсы",
    "T08 HotkeyRecorderWindow — рекордер записывает голый печатный keyDown (напр. «K»), который под .listenOnly и сработает, и напечатается; условие: отклонять/предупреждать голый печатный keyCode",
    "T08 HotkeyTests/HotkeyEngineTests — @testable import избыточен; условие: обычный import",
    "2026-09-16: baseline swift build успешен на macOS15.6.1 arm64; swift test на Mac blocked: CLT без XCTest. Тесты выполнять на доступном claudebot-server (Swift6.0.3). v1.2.0 ручная приёмка ещё не выполнена.",
    "G21 historical:1.4.4 actualuserdeletion FAILED; ownTextEdit fixture closed; continuedG22.",
    "G22:1.4.5 actualownedCodexSpaceGREEN bothfields, matching concrete delayedACK fix; privatecomposer/allapps/manualEnterShift untested, not universal compatibilityclaim.",
    "G23:1.4.5 actualdictation partialprefix with fullrecognized recovery; first16UTF16 clue only, previousadapter checks insufficient foractualCodexdelivery."
  ],
  "reviewers": {
    "manifestSpec": "a3373fd28e916b546",
    "craft": "a9af146a77a904cc1",
    "G14": {
      "spec": "review_spec",
      "standards": "review_standards",
      "recheck": "P2 resolved, no remaining actionable findings"
    },
    "G15-G17": {
      "spec": "review_repairs_spec",
      "standards": "review_repairs_standards",
      "result": "Both approved integrated code; last cancellation fix rechecked"
    },
    "G18": {
      "spec": "review_word_spec",
      "standards": "review_word_standards",
      "result": "Both approved finaldiff with zero actionable findings"
    },
    "G19": {
      "spec": "review_dictation_spec",
      "standards": "review_dictation_standards",
      "result": "Both final approved, no blocking findings; liveAX/CG and notification-window limitations documented"
    },
    "G21": {
      "spec": "review_autorepeat_spec",
      "standards": "review_autorepeat_standards",
      "result": "Both finalapproved;0blockers; frozen baselineRED/finalGREEN; hardware/userexactcause boundary documented"
    },
    "G22": {
      "spec": "review_live_selection_spec",
      "standards": "review_live_selection_standards",
      "result": "Both finalapproved0blockers; supplemental tools also rechecked bySpec+Standards"
    },
    "G23": {
      "spec": "review_dictation_completion_spec",
      "standards": "review_dictation_completion_standards",
      "result": "Both frozen4 finalapproved0findings; all64hashes stable; actualspeech unproven"
    }
  },
  "blind": {
    "run": "G23 root15groups/Engine/delayedselection/fullspeech/mountedDMG PASS; exact27fileLinux95reuse",
    "verdict": "Concrete own-notification completion + capacitywaitguards reviewed and published1.4.6",
    "note": "ActualCodexspeech/WindowServer pending usermanualtest; no universaloratomicPASS",
    "drift": []
  },
  "manualAcceptance": {
    "version": "1.4.6",
    "status": "pending",
    "checks": [
      "ozon после смены поля; b/B/z/Z и plan b",
      "Option по выделению с переносами и без выделения",
      "Enter/Shift+Enter и быстрый ghbdtn+Tab+abc",
      "диктовка после перезапуска без скачивания; новый hold после подготовки",
      "f/d/r/j/c/e одиночные + Englishlabels; ни/буду/могу/люблю; rfr?/ghbdtn!/(yt)",
      "Диктовка в Codex: удержание/отпускание вставляет один раз без Enter",
      "Во время распознавания сменить поле/ввести символ: видимый результат, причина отказа, явное копирование",
      "Длинная фраза и выделение, поздние уведомления; непроверенная доставка сохраняет весь результат с предупреждением",
      "Option: выделение/слово после reset/пустое поле → RU/EN",
      "ghbdtn+Space/Enter, Shift+Enter, быстрый ввод в native и Codex",
      "При неподтверждённой записи Enter остановлен, удержанный ввод сохраняется до явного Close"
    ],
    "note": "Userasked to update via menu and dictate literalphrase in own Codex chat. G23 no actualspeechPASS yet. PriorG22 physicalSpace1.4.5 GREEN ownIABfields; Enter/Shift/allapps remain untested."
  },
  "release": {
    "version": "1.4.6",
    "artifact": "MacLayoutSwitcher-1.4.6.dmg",
    "sha256": "0571ae808a108550662b10decc38600b9df0519e81b383b79be19abaaa40e326",
    "bytes": 10966502,
    "binarySHA256": "cff40179237f82900269144880096325e4f71bf5147b9bb0c6465b60d8ca655f",
    "mountedVerification": "version/helper/deepstrict/Applications symlink/main binary exact PASS",
    "speechAcceptance": "manual Codex pending",
    "publication": "verified",
    "verifiedPublicationHead": "f96f920104b538201d12c51bf7d8d8018eaf5b71",
    "publicArchiveSHA256": "532c606d13f4bb45a665d8fcef5acd9124a0f37d8e598f419f0eefe9f7c33d59",
    "frozenProductFilesVerified": 64,
    "verification": "GitHub raw VERSION / server HEAD / HTTPS archive SHA / PAX commit / all64approved hashes exact",
    "manualSpeech": "pending; no actual Codex/WindowServer acceptance claimed",
    "codeCommit": "f96f920104b538201d12c51bf7d8d8018eaf5b71",
    "verifiedAt": "2026-10-10T17:27:38.248052+00:00",
    "physicalAcceptance": "G23 speechpending; priorG22 physicalSpace1.4.5 ownCodexfields GREEN",
    "publicationNote": "Verification receipt covers exact published codecommit; root metadata follows, finalarchive externally reverified"
  },
  "wordCoverageAudit": {
    "independentRU": 459,
    "independentEN": 692,
    "frozenInputRows": 2934,
    "verdicts": 8802,
    "newUndeclaredValidCorrections": 0,
    "newWrongDirections": 0,
    "intentionalNewContextualCollisionRows": 9,
    "note": "Curated diagnostics, not statistical accuracy; see word-coverage-qa.md"
  },
  "dictationInsertionAudit": {
    "panelCause": "ProductionNSTextView/textContainer width0, nonempty recognizedtext clipped",
    "nativePanel": "red→green + root/2reviewers reruns",
    "nativeAdapter": "productioncapture/insert with injectedAX/nativeNSTextView; actualCodex frameworkrouting metadata PASS",
    "liveCodex": "not exercised; diagnostic process AXIsProcessTrusted=false",
    "privacy": "No microphone, privateeditor typing, TCC forcing or automaticclipboard mutation duringdiagnostics"
  },
  "keyboardRuntimeAudit": {
    "codeCommit": "d7b003d",
    "review": "Spec+Standards approved",
    "native": "Production Target/Typist + mock AX/CG and owned NSTextView; recovery NSPanel headless",
    "scope": "Lazy capture, same-snapshot source, readback, selection RPC uncertainty, fastinput retention, Option fallback",
    "live": "Prior TextEdit/Chrome PASS withdrawn: no pre-separator source snapshot, RussianWin already active; live automatic replacement unproved",
    "coldLimit": "First separator before any AX capture passes without late correction; explicit Option may recover word"
  },
  "deletionRepairAudit": {
    "partialCommit": "c57e700f9f44f62dd79d2576e88300d994932ccb",
    "snapshot": "/tmp/mls-g21-autorepeat-final.v8tpedvg",
    "files": 160,
    "linux": "/tmp/mls-g21-tests.fKQES6",
    "cause": "RED: busy separator autorepeat reaches early reset before replay, invalidates permit and native key replaces temporary source selection",
    "transport": "Unchanged productionpostToPid; realCG/NSEvent harness injects finalpost, notWindowServerproof",
    "recovery": "Original+completeplannedreplacement+heldinput preserveduntilClose",
    "review": "Both fresh reviewers final approved, no blockers",
    "release": "1.4.4 published and installed; recording reproduces deletion; G22/T25 continues investigation",
    "currentExecutor": "implement_deletion_system",
    "manualFixture": "Owned TextEdit /tmp/MLS-Option-Test.rtf saved and closed; auto replacement not triggered by CUA, inconclusive; Mac now locked",
    "engineIntegration": {
      "snapshot": "/tmp/mls-g21-engine.wvh4ck3e",
      "result": "Executor+root independentPASS directAX+productionCGlocalUnicode Enginehandle/selection/undo/cancellation",
      "boundary": "Finalpost/frontPID/AX injected; EventTapregistration andTISstub, no physicalWindowServer proof",
      "provenance": "29sources identicalbase57f54d3; README/source-provenance/seams.patch/SHA256SUMS/run.log/root-run.log"
    },
    "autorepeatRed": {
      "snapshot": "/tmp/mls-g21-repeat.3xn__0zm",
      "result": "4/4 RED Space+Enter directAX/productionCGlocalNSEvent; source руддщ before separator",
      "boundary": "Real production EventTap.process/KeyTranslator/Engine; own NSTextView, not physical WindowServer proof"
    },
    "engineSHA256": "5a91543b9a2a92dfc0e473d6949792890b92170944a8362926cc6cd461b8c7b3",
    "productionChecks": "/tmp/mls-g21-final.8ijwtyc9",
    "finalRunner": "baselineRED/finalGREEN same savedrunner; root+2reviewers independentlyPASS"
  },
  "liveInsertionAudit": {
    "recording": "/Users/ilyaalimpiev/Desktop/Запись экрана 2026-10-10 в 17.57.37.mov",
    "evidence": "srfe→empty twice at4.6/9.6secs, nochat; installed1.4.4 freshsingleprocess",
    "cause": "ACK-before-apply selection readback returns stale caret; old untouched replays separator against late source selection. Contract baselineRED plus matching actualownedCodexevent trace.",
    "ticket": "25",
    "liveProbe": "Native human srfe→chat PASS; ownedCodexIAB physical srfe→space deletionRED, valid V2log27events",
    "blocker": "none for completed scopedG22 release; supplementalmanualEnter/Shift question pending",
    "productChange": "Candidate1.4.5 bounded selectionconfirmation + unconfirmedSelection queue hold/recovery; public remains1.4.4",
    "qa": ".autopilot/2026-08-29-mac-layout-switcher/live-insertion-qa.md",
    "candidateScratch": "/var/folders/s7/blf5jdcs7q7bfjjxbt621w500000gn/T/mls-g22-candidate.zaw8onaw",
    "linux": "/tmp/mls-g22-linux.HdVgbk/run.log",
    "rootSelectionDelay": "/tmp/mls-keyboard-selection-delay.2TBufd/run.log",
    "hardwareExcerptSHA256": "81cdbbf9e097e62fb25ffd9b2e08b79c4616b199d49f958372adb5f473c39542",
    "rootEngine": "/tmp/mls-keyboard-engine.KPSkna/run.log",
    "dmgCandidate": {
      "version": "1.4.5",
      "sha256": "58e067a3d42eed8ba5db44c29202f8becf6d7f249b7fac6cc945f6609c9641b7",
      "verified": "mounted version/deepstrict/helper/symlink/binarymatches PASS"
    },
    "durableAudit": "audit/live-insertion",
    "candidateCodeCommit": "2163e0a3e7fa7f388ba551ef97b69d9a6f0a3126",
    "publication": "1.4.5 pushed/rawVERSION/publicarchiveSHA/embeddedcommit/all55SourcesTools verified",
    "installedBackup": "/var/folders/s7/blf5jdcs7q7bfjjxbt621w500000gn/T/mls-g22-candidate.zaw8onaw/installed-1.4.4-backup.app",
    "installedVersion": "1.4.5",
    "installedBinarySHA256": "c0d8f234e223623cda80149e3c43eec6a8b520798e09a63c2ffb06633b81dfe9",
    "installedPID": 49664,
    "physicalSpace": "Sourceсрфе caret4 → selected0/4 → nativeUnicode datachatspace → finalchatspace caret5 in bothownedCodexfields; user confirmed chat",
    "permissions": "User repliedready after panels/restart; actual candidate auto insertion works. No root grantTCC.",
    "physicalScope": "Owned CodexIAB contenteditable+textarea physicalSpaceGREEN; mainprivatecomposer/allapps/manualEnterShift notdeclaredpassed"
  },
  "dictationCompletionAudit": {
    "ticket": "26",
    "evidence": "User screenshot fullrecognizedphrase + visibleprefix actualCodexcomposer; unconfirmed recovery",
    "cause": "Concrete production RED: one ACK per notification cancels after duplicate own selection after first16UTF16; actualCodex callback pattern unproven. Independent stale value/caret RED also covered.",
    "privacy": "No publishedscreenshot/privatecomposerautomation/microphone activation",
    "qa": "dictation-completion-qa.md",
    "baseline": "audit/dictation-completion/root-baseline-red.log",
    "candidate": "1.4.6 published/verified; actualCodexspeech manualhandoff pending",
    "initialFrozenSourceSHA": "506f8f646524805c7c09927a2354e1e7485ed09b4cc98b10d516ffe7c009e88a",
    "sourceSHA256": "cf3d4d6e29672b1c9601e0cd4234c9253ee94d3214d45f428a65f9429d351c41",
    "nativeCompletionGroups": 15,
    "manualSpeech": "Requested user update via menu then samephrase in Codex; awaiting response",
    "linux95Reuse": "27identicalCore/Tests/Package hashes",
    "durableAudit": "audit/dictation-completion",
    "codeCommit": "f96f920104b538201d12c51bf7d8d8018eaf5b71",
    "publication": "GitHub VERSION1.4.6 / HTTPSarchiveSHA / PAXcommit / all64approved files exact"
  },
  "finishedAt": "2026-10-10T17:27:38.248052+00:00",
  "previousRelease": {
    "version": "1.4.5",
    "codeCommit": "2163e0a3e7fa7f388ba551ef97b69d9a6f0a3126",
    "artifact": "MacLayoutSwitcher-1.4.5.dmg",
    "sha256": "58e067a3d42eed8ba5db44c29202f8becf6d7f249b7fac6cc945f6609c9641b7",
    "bytes": 10958211,
    "publication": "verified",
    "physicalAcceptance": "Space correctin bothownedCodexfields; manualEnter/Shift and allapps not declaredpassed",
    "verifiedAt": "2026-10-10T16:25:53.568774+00:00",
    "verifiedPublicationHead": "5f6606fd1972229067d17be8c74e2726b1f97261",
    "publicArchiveSHA256": "cfc49ec37a0b1558a805431cfd9205d44c8c030139b2d493b7419e0b83ae0aa2"
  }
}
