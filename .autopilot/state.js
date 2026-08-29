window.STATE =
{
  "slug": "mac-layout-switcher",
  "dir": "2026-08-29-mac-layout-switcher--wip",
  "title": "Свой аналог Punto/Caramba Switcher для Mac",
  "mode": "semi",
  "depth": "normal",
  "polish": null,
  "tier": "T2",
  "briefFile": "2026-08-29-brief.md",
  "memoryFile": "CLAUDE.md",
  "skillDir": "/home/claudebot/.claude/skills/autopilot",
  "startedAt": "2026-08-29T03:22:57+00:00",
  "updatedAt": "2026-08-29T04:24:00+00:00",
  "finishedAt": null,
  "stages": [
    { "id": "preflight", "status": "done", "startedAt": "2026-08-29T03:22:57+00:00", "finishedAt": "2026-08-29T03:24:41+00:00" },
    { "id": "manifest",  "status": "done", "startedAt": "2026-08-29T03:24:41+00:00", "finishedAt": "2026-08-29T03:27:10+00:00" },
    { "id": "briefing",  "status": "done", "startedAt": "2026-08-29T03:27:10+00:00", "finishedAt": "2026-08-29T03:34:30+00:00" },
    { "id": "spec",      "status": "done", "startedAt": "2026-08-29T03:34:30+00:00", "finishedAt": "2026-08-29T03:44:20+00:00" },
    { "id": "plan",      "status": "done", "startedAt": "2026-08-29T03:44:20+00:00", "finishedAt": "2026-08-29T03:52:30+00:00", "note": "5 тасков, ярус T2" },
    { "id": "build",     "status": "active", "startedAt": "2026-08-29T03:52:30+00:00", "note": "1 из 5 тасков готов" },
    { "id": "review",    "status": "active", "startedAt": "2026-08-29T04:05:30+00:00", "note": "проверено 1 из 5" },
    { "id": "final",     "status": "pending" }
  ],
  "requirements": {
    "total": 9, "done": 0, "inTicket": 9, "inSpec": 0,
    "placeholder": 0, "deferred": 0, "dropped": 0
  },
  "tickets": [
    { "id": "01", "title": "Каркас SwiftPM + ядро: KeyMap, WordBuffer, SnippetStore", "requirements": ["R02", "R03", "R07i", "G01"], "blockedBy": [], "wave": 1, "zone": ["Package.swift", "Sources/SwitcherCore/", "Tests/"], "status": "done", "startedAt": "2026-08-29T03:56:00+00:00", "finishedAt": "2026-08-29T04:12:40+00:00", "tests": { "passed": 12, "failed": 0 }, "commit": "8ee81d5", "retries": 0, "repairs": 0, "handoffs": 0 },
    { "id": "02", "title": "Детектор неправильной раскладки", "requirements": ["R04i"], "blockedBy": ["01"], "wave": 2, "zone": ["Sources/SwitcherCore/Detector"], "status": "in-progress", "startedAt": "2026-08-29T04:13:20+00:00", "retries": 0, "repairs": 0, "handoffs": 0 },
    { "id": "03", "title": "Системный слой macOS: перехват, перепечатка, раскладка", "requirements": ["R06i", "R03"], "blockedBy": ["01"], "wave": 2, "zone": ["Sources/MacLayoutSwitcher/System/"], "status": "review", "startedAt": "2026-08-29T04:13:20+00:00", "retries": 0, "repairs": 0, "handoffs": 0 },
    { "id": "04", "title": "Engine: автоисправление, Option, откат, автозамена, автопауза", "requirements": ["R04i", "R05i", "G01", "A01"], "blockedBy": ["02", "03"], "wave": 3, "zone": ["Sources/MacLayoutSwitcher/Engine", "Sources/MacLayoutSwitcher/Config"], "status": "pending", "retries": 0, "repairs": 0, "handoffs": 0 },
    { "id": "05", "title": "Меню-бар, звуки, сборка .app, README", "requirements": ["R06i", "G02", "R07i", "R01"], "blockedBy": ["04"], "wave": 4, "zone": ["Sources/MacLayoutSwitcher/UI/", "build.sh", "README.md"], "status": "pending", "retries": 0, "repairs": 0, "handoffs": 0 }
  ],
  "singlePass": null,
  "tests": { "passed": 12, "failed": 0 },
  "debt": { "placeholders": [], "assumptions": [], "emptyEnv": [] },
  "additions": [],
  "coverage": { "findings": 0, "note": "G2: пропусков нет, полупокрытий нет; 8 позиций «сверх брифа» = R##.n-проработка и A01 с родителем — оставлены" },
  "concerns": ["Tests/SwitcherCoreTests/*:2 — @testable import SwitcherCore, хотя ассерты ходят через публичный шов; условие: обычный import", "T04 обязан закрыть долг: EventTap только .listenOnly, для подавления Option-события нужен active-tap или доработка (spec-missing из ревью 03)", "Typist.swift:50,68 — отказ создания CGEvent молча съедает событие, частичная замена портит текст; условие: прерывать весь replaceLastWord", "Typist.swift:27 — 5000 мкс на событие ≈0.2 с на слово; условие: обосновать или уменьшить"],
  "reviewers": { "manifestSpec": "a3373fd28e916b546", "craft": "a22e174c56de678a4" },
  "blind": null
}
