# G28 evidence — 26.10.2026

User screenshot: SystemFocus/AppFocus=-25212, Bootstrap=manual:-25205.
Current isChromium includes six framework names and omits Yandex Framework.
Only application/framework Info.plist metadata read; no live UI/AX probe.
Yandex26.8.3.1016 identifies Chromium150.0.7871.250 explicitly in its framework.
Installed MLS1.4.10. Current Codex app has updated to Chromium156; its previously
accepted Option/Space behavior is not rescinded by a separate browser failure.
User confirmed actual target is native Bitrix24.app; Yandex is only a related finding. No screenshot/private form data published.

Primary matching Chromium150 branch7871 source verified read-only:
https://chromium.googlesource.com/chromium/src/+/refs/branch-heads/7871/chrome/browser/chrome_browser_application_mac.mm
Local copy /tmp/mls-g28-chromium-7871.mm, SHA256
83fe534883220804de925904534b10115c5f78332e20ee1cf17a29d7779371d0.
It has the same AXEnhancedUserInterface setter and two-second debounce, no
AXManualAccessibility hook. This supports the existing compatibility path for
Yandex's declared upstream family; it does not establish live fork behavior.

## Confirmed actual app: Bitrix24
User reply: «Приложение Битрикс24».
Static Info.plist: com.bitrixsoft.bitrix24desktop, NSPrincipalClass BrowserCrApplication,
SCMRevision0928d8283580e875808233327daaf5e8e09d4fed-refs/branch-heads/7727@{#4055}.
Framework Bitrix24 Framework.framework exports static strings BrowserCrApplication,
AXEnhancedUserInterface, enableScreenReaderCompleteModeAfterDelay:. Independent
Standards scan found Chromium147.0.7727.144. These are static shipped code/metadata,
not private runtime fields; no live AX/UI, cache, account or login inspection.

Matching Bitrix upstream source:
https://chromium.googlesource.com/chromium/src/+/refs/branch-heads/7727/chrome/browser/chrome_browser_application_mac.mm
Local /tmp/mls-g28-chromium-7727.mm SHA256
a3bbf7d2878019bbb555779859d8699bb3728e8dd57de8227b42d593100d059d.
BrowserCrApplication has the same enhanced setter and two-second debounce; its
manual hook is absent. Combined with the installed principal class and binary
selectors this justifies an exact Bitrix24 framework identity, not a name guess.

## Final candidate 1.4.11

The product changes only two exact framework names in the shared classifier.
Same final raw fixture: literal d82a674 baseline RED24 → candidate GREEN147.
Both independent reviewers ran the final fixture and approved with zero findings.
All 87 release-input hashes match manifest
 e0635fa95231c2118c297077d29ffc29f49e88cd1f6ef2be61b25cfb73c1f7b3.
Keyboard/dictation adapters pass. Linux95 reused by exact 27 Core/Tests/Package
input hashes. Full speech release, deep/strict signatures, mounted DMG version,
helper, Applications link and main/helper binary hashes passed.

Installed exact 1.4.11; old PID53896 stopped, one new PID85982 confirmed twice.
Previous 1.4.10 retained in outputs/MacLayoutSwitcher-1.4.10-before-G28-backup.zip
and /Applications/.MacLayoutSwitcher-G28-k7tdtkiq/previous.app. User asked to repeat
зщкефд+Option in the actual Bitrix24 field after preparation. Physical acceptance
PENDING; Codex1.4.10 accepted Option/Space history remains intact.
No private UI/AX, TCC, microphone, clipboard or form submission during tests.
Code 77e96bec6ce1a54f4d8c624b202fa0bfeb670621 pushed and archived. Public HTTPS archive SHA
a88a2696e563ffbfb88fa1af383da8509f508479ae241705aeeb6be07f56ce40 and PAX commit match; raw
GitHub VERSION1.4.11 and all355 tracked Git blobs verified from release server.
Final metadata receipt is in outputs; physical Bitrix24 result remains pending.
