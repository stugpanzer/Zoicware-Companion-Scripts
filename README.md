# Zoicware-Companion-Scripts

PostZoicwareCleanup

PostZoicware Windows 11 Cleanup is a companion script intended to run after RemoveWindowsAI. It does not remove AI packages or modify core Windows components. Instead, it focuses on cleaning up the remaining Windows 11 annoyances by disabling Widgets, lock-screen Spotlight promos, Start menu Recommended content, silent/promoted app installs, Settings suggestions, consumer experience nags, Advertising ID, and File Explorer sync-provider notifications. It helps create a cleaner and less promotional Windows experience after AI removal.

The script also applies a conservative set of Windows app privacy restrictions by blocking unnecessary access to items such as account info, camera, location, background app activity, calendar, messaging, phone, and related permissions. Microphone access is intentionally left user-controlled so apps like Discord, Zoom, Teams, OBS, and other voice applications continue working normally. The goal is to improve privacy and reduce clutter while keeping Windows stable and fully usable.


PostZoicwareAudit

PostZoicware Audit is a companion verification script intended to run after RemoveWindowsAI and the PostZoicware cleanup script. It does not make system changes. Instead, it checks whether the expected privacy, cleanup, and AI-related settings are actually in place. The script audits items such as Widgets being disabled, Spotlight promos being turned off, Start menu recommendations being hidden, Advertising ID being disabled, Explorer sync-provider promos being suppressed, and the configured Windows app privacy restrictions. It also checks likely Zoicware-related outcomes such as Copilot policy settings, Edge Copilot restrictions, Recall task removal, Recall folder removal, optional feature status, and the presence or absence of common AI-related packages and package keys.

The script then generates a local HTML report on the desktop that presents the results in an easy-to-read visual format. The report includes PASS, CHECK, and INFO statuses, summary counts at the top, and color-coded rows for quick review. Critical items, such as microphone access status, are highlighted more prominently so they are easy to spot right away. The HTML report gives the user a simple local audit dashboard showing what appears to be correctly applied, what may need review, and what was detected as informational only.
