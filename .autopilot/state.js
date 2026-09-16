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
  "updatedAt": "2026-09-16T03:13:27.206206+00:00",
  "finishedAt": "2026-09-16T03:13:27.206206+00:00",
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
      "note": "5 тасков, ярус T2"
    },
    {
      "id": "build",
      "status": "done",
      "startedAt": "2026-08-29T03:52:30+00:00",
      "note": "17 тасков готовы; v1.3.0 локальная диктовка GigaAM v3",
      "finishedAt": "2026-09-16T03:13:27.206206+00:00"
    },
    {
      "id": "review",
      "status": "done",
      "startedAt": "2026-08-29T04:05:30+00:00",
      "note": "T16/T17: два независимых ревью, P2 исправлен и перепроверен",
      "finishedAt": "2026-09-16T03:13:27.206206+00:00"
    },
    {
      "id": "final",
      "status": "done",
      "startedAt": "2026-08-29T05:25:00+00:00",
      "finishedAt": "2026-09-16T03:13:27.206206+00:00",
      "note": "Mac .dmg проверен; 71 XCTest; ручная приёмка микрофона/вставки ожидается"
    }
  ],
  "requirements": {
    "total": 21,
    "done": 20,
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
    }
  ],
  "singlePass": null,
  "tests": {
    "passed": 71,
    "failed": 0,
    "note": "Linux Swift6.0.3 full final snapshot. Mac debug/release + offline real ASR + DMG signature verified; manual microphone/field acceptance pending."
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
    "2026-09-16: baseline swift build успешен на macOS15.6.1 arm64; swift test на Mac blocked: CLT без XCTest. Тесты выполнять на доступном claudebot-server (Swift6.0.3). v1.2.0 ручная приёмка ещё не выполнена."
  ],
  "reviewers": {
    "manifestSpec": "a3373fd28e916b546",
    "craft": "a9af146a77a904cc1",
    "G14": {
      "spec": "review_spec",
      "standards": "review_standards",
      "recheck": "P2 resolved, no remaining actionable findings"
    }
  },
  "blind": {
    "run": "Linux swift test71 passed; Mac swift build/release and DMG signature pass; real offline ASR incl speech after32s",
    "verdict": "G14 implemented; T16/T17 reviewed and committed",
    "note": "Microphone and external-field interaction not exercised; manual acceptance pending",
    "drift": []
  },
  "manualAcceptance": {
    "version": "1.3.0",
    "status": "pending",
    "checks": [
      "microphone consent and real hold/release dictation",
      "Esc/focus change/physical typing during insertion",
      "v1.2 Enter/Shift+Enter/fast typing regression acceptance"
    ]
  }
}
