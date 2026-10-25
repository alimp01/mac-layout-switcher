# G27 evidence25.10
User screenshot proves physical1.4.9 FAIL in Codex: AXFrontmost=ok,
SystemFocus=-25212; AppFocus=-25212. Current focus routes return noValue.
SDK kAXErrorNoValue=-25212, apiDisabled=-25211. This is not a timeout.
No actual deeper system/app tree read performed; prior CUA denials respected.

## Source evidence

Read only installed bundle metadata: /Applications/ChatGPT.app has bundle ID
com.openai.codex and version 26.1016.62342. Its Codex Framework.framework reports
Chromium version 155.0.8059.80. This identifies the implementation family; it
does not prove any live AX setter result in Codex.

Exact primary source:
https://chromium.googlesource.com/chromium/src/+/155.0.8059.80/chrome/browser/chrome_browser_application_mac.mm
Local evidence copy: /tmp/mls-g27-chrome-browser-application.mm.
- AXEnhancedUserInterface schedules screen-reader accessibility after a two-second
  debounce. Repeating the setter resets that timer.
- The side effect happens before the superclass setter result, so an error return
  is not sufficient evidence that activation did not happen.
- This class has no AXManualAccessibility handling. Electron documents that
  different bootstrap attribute in its own accessibility tutorial:
  https://github.com/electron/electron/blob/main/docs/tutorial/accessibility.md
- Reading AXRole is another documented activation path, but its target mode
  differs; the candidate does not require a speculative extra activation path.

Inference: the current Electron-only bootstrap and 160 ms capture retries can
leave this Chromium implementation without a focused field. A controlled raw
AX fixture is necessary to validate the compatibility change. Only the user's
physical test can confirm this is the remaining cause on the installed app.

Known third-party reports of latency/phantom input when repeatedly enabling
enhanced accessibility and walking trees motivate once-per-process gating and
the prohibition on a broad tree walker; they are not evidence of this failure:
https://github.com/screenpipe/screenpipe/issues/3884
https://github.com/screenpipe/screenpipe/issues/3789

## Candidate 1.4.10

The exact final raw fixture fails 13 checks on literal 1.4.9 and passes all 77
checks on the candidate. Both independent reviewers repeated this boundary and
approved the final product; their process-replacement counterexamples changed
from RED to GREEN. Reports and source hashes are in audit/no-value-focus.

Final reviewed source manifest SHA256:
bf30a557698b2af3fd0eeec39f60aa92bedb517cb16ed9b91eac64b6f1a231cc.
The unchanged Core/Tests/Package inputs match all 27 hashes from the Linux 95-test
pass. Root independently passed the full Engine/navigation suite and dictation
completion tests on the first candidate. The later process-identity correction
was tested by final raw focus/keyboard/dictation adapters and both reviewers;
the unchanged mocked Engine path was not rerun gratuitously.

Full speech release build, deep/strict signature, mounted DMG version/helper,
Applications symlink and binary hashes passed on the final product. Installed
1.4.10 has one new process, PID 23883; previous PID 19475 stopped. Previous 1.4.9
was preserved as outputs/MacLayoutSwitcher-1.4.9-before-G27-backup.zip and
/Applications/.MacLayoutSwitcher-G27-3un9rxng/previous.app. No model/config reset.

Actual physical acceptance is PENDING. User was asked to test ghbdtn+Option and
separate ghbdtn+Space in Codex after the candidate starts. No denied-app UI/AX
probe, TCC change, microphone, global typing or clipboard access was performed.
Code commit 72c48b6af12d85e0da244fc55285e00d3fe446f7 pushed and archived. Raw GitHub VERSION1.4.10,
public HTTPS archive SHA a52a092cecc890744f548ab00ab4cc9caad44d214d958ef91c06956499dd0cbf and
embedded commit match; all 87 frozen release inputs and all 332 tracked files
match Git blobs. Final metadata archive receipt is in outputs.
