# G26 evidence — 2026-10-25
User actual1.4.8 FAIL ghbdtn/Option: unavailableField. Exact installedbinary
f9104e4df9032ef13c2c3ab80e98378461fe38de1ca846683d5b5075ddeb9e71.
One running PID1462 at initial metadata check. Prior G25 stale-cached-field
repair remains valid but did NOT fix user complaint. G25 acceptance nowFAILED.
Fresh audit of systemfocus boundary + keyboard + speech/lifecycle begins.

## Proven defects and evidence
T29 raw AX RPC matrix baseline23PASS/24FAIL → candidate50PASS. Resolver itself
is production, not mocked. AXFrontmost unavailable no longer vetoes an exact
system focus; positive foreign system owner never falls back to stale app focus.
Missing PID and raw focus failure stages now distinguished, no typed text logged.
T30 production EventTap/KeyTranslator/Engine navigation160 cases baselineRED
→GREEN; tap interruption stale shortcut ownership baselineRED→GREEN. Ordinary
click preserves still-held shortcut ownership. Held speech is cancelled after
interruption; already released speech retains recovery.
T31 updater offline/badarchive/buildfail, recorder focus-loss, failed resume
proved separately and implementation in progress. Details audit/reliability.

Independent Spec/Standards reviews and final integrated checks pending.
Native T29 adapter/Engine-selection/WebKit/dictation15groups + debug buildPASS.
These controlled fixtures do not prove the installed user's AX failure cause.

## Live test boundary
Root-created TextEdit field contained literal ghbdtn, then separate tests had
срфе and тест срфе before Space; CUA-generated Space left the words unchanged.
CUA cannot send modifier-only Option (keyPressIncludedNoNonModifierKeys), and
its events are not established as physical EventTap input, so no hardware result
is claimed. Own fixture saved /private/tmp/MLS-G26-Option-Test.rtf and closed.
No private composer/microphone/TCC was accessed; earlier Codex/MLS CUA denials
were not bypassed. Candidate physical acceptance remains UNKNOWN.

## Integrated candidate 1.4.9
Root full Linux suite95/95 PASS in isolated /tmp/mls-g26-linux.LQl0C8. Final
27 Core/Tests/Package inputs exactly match tested bytes. Mac fullspeech release
built38.53s with pinnedGigaSTT; helper bundled; deepstrict signaturePASS.
Mounted DMG version1.4.9/helper/mainbinary/Applications symlink all verified.
DMG SHA dad44e98b9e1833821502af02364e037e13403cac21ffd18563fda8fe80de093.
Root final rejected/resumed start lifecycle PASS, including stopped focus sampler.
T31 final update15cases, actual hidden NSWindow focus-loss, resume/initial-start
RED→GREEN and full dictation15groups PASS. Integrated Engine final27groups PASS at /tmp/mls-keyboard-engine.bxONiY.
Spec and Standards independent final approved0findings; both verify exact99 hashes.
Exact99 reviewed inputs frozen in audit/reliability/reviewed-files.json.
Installed1.4.8 backed up to outputs/MacLayoutSwitcher-1.4.8-before-G26-backup.zip
without modifying currentinstallation. Installed exact1.4.9 binary and helper; codesign deepstrictPASS, oldPID1462 stopped, newPID14682 confirmed. Publication pending.

Actual user acceptance remains pending. Root asked only a new physical1.4.9
ghbdtn+Space and separate ghbdtn+Option check after permissions if prompted.
This cannot be replaced by CUA modifier-only input (unsupported), and denied
app access was not bypassed. Resolved controlled defects are not claimed as
the installed user's proven root cause.
