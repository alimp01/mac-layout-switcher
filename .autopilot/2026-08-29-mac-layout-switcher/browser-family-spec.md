# G28 — поддержка пропущенного Chromium-браузера

## Evidence and intent
Actual screenshot on 26.10: source remains in the native Bitrix24.app address field;
AXFrontmost=ok, SystemFocus/AppFocus=-25212, Bootstrap=manual:-25205. No enhanced
metadata means the current candidate did not enter the enhanced path. In current
code, manual attributeUnsupported (-25205) is accepted, so an unrecognized browser
family is a concrete explanation. User explicitly confirmed «Приложение Битрикс24»; Yandex is a related omission,
not the application shown in the screenshot. This is separate from accepted Codex Option/Space G27.
Installed MLS is 1.4.10. Installed Yandex.app has bundle ru.yandex.desktop.yandex-browser,
Yandex Framework.framework / ru.yandex.desktop.yandex-browser.framework, and explicit
CFBundleChromiumShortVersionString=150.0.7871.250. This framework is omitted by
SystemDictationAccessibility.isChromium. Bitrix24 is the actual target: com.bitrixsoft.bitrix24desktop, version23.0.32,
Bitrix24 Framework.framework / com.bitrixsoft.bitrix24desktop.framework.
Its app declares NSPrincipalClass=BrowserCrApplication; static binary has
AXEnhancedUserInterface and enableScreenReaderCompleteModeAfterDelay:.
SCMRevision points to Chromium branch7727, binary version147.0.7727.144.
Verify the matching upstream enhanced implementation; no live app probe needed.
Both Bitrix24 and Yandex must have literal raw metadata fixtures; former Bitrix
unknown-negative fixture is superseded by genuinely unknown/native/lookalikes.

## Contract
- Recognize the confirmed missing Chromium family from positive on-disk metadata
  or a narrowly justified framework identity. Do not enable enhanced access for
  every app or match arbitrary names containing browser/Chromium.
- Use the same family decision for preparation AND choosing the existing verified
  Unicode path before text mutation. Native/Safari and existing supported families
  must retain their behavior. A renamed .app directory must not break detection.
- Preserve G27 bounded once-per-process activation, exact PID+launch identity,
  process-change rejection, cancellable/off-main waits, fresh operation after
  absent initial field, and all existing source/range/readback/write-once guards.
- No dictionary changes, clipboard, tree walker, whole-value writes, write retries,
  live private UI/AX, TCC or mic access. Prior CUA denials for Codex/MLS remain;
  do not bypass via shell/CDP/AX/helper. Own hidden fixtures only.
- Show the cause in fixed-code diagnostic metadata if needed for unsupported
  families; do not log user text or broad installed application metadata.

## Validation/release
Same raw boundary fixture baseline d82a6748ec1c8b523c77c119bbaed3c6fd4637a4 RED to
candidate GREEN for literal Bitrix24 (main target) and Yandex frameworks, unsupported manual/noValue,
fresh subsequent Option and automatic separators. Include literal зщкефд→portal
for the Bitrix word case from the screenshot; no submission of authorization forms. Verify Unicode routing before
mutation and native/lookalike negative controls, process replacement and cancel.
Use existing raw harness and targeted adapters, not another lengthy unrelated
full audit. Existing Core/Tests/Package unchanged hash evidence may reuse Linux95.
Fresh executor, two independent Spec/Standards reviews, full speech release and
mounted signed DMG. Root owns git/install/publish; VERSION1.4.11 only after root
signal. Actual target-browser physical acceptance remains separate from fixtures.
