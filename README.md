# Zoicware-RemoveWindowsAI-Companion-Scripts

PostZoicwareCleanup

PostZoicware Cleanup is a companion PowerShell script intended to run after Zoicware’s RemoveWindowsAI tool. It does not remove AI packages itself or alter core Windows system components. Instead, it focuses on cleaning up the remaining Windows 11 user-experience annoyances, promotional content, and privacy settings that many users still want addressed after AI removal. Its purpose is to leave the system cleaner, quieter, and more privacy-respecting while maintaining normal day-to-day usability.

The script disables Windows Widgets and related News and Interests policy entries, which removes the Widgets panel and reduces background content pulls for news, weather, and promoted cards. It disables Windows Spotlight promotional behavior on the lock screen, including rotating lock-screen content, overlays, and several hidden ContentDeliveryManager subscription entries tied to suggested or promotional material. This results in a simpler lock screen without Microsoft promos, rotating content, or “fun facts” style distractions.

It cleans up the Start menu by hiding the Recommended section and disabling several promoted-install and silent-install behaviors. This reduces Start menu clutter and helps prevent Microsoft or OEM app suggestions from reappearing after updates. It also disables a range of Windows suggestion systems tied to consumer experiences, including soft landing prompts, system pane suggestions, “finish setting up your device” nags, cloud-optimized suggested content, and Windows consumer feature promotions. Advertising ID is disabled at both user and policy level, reducing targeted advertising behavior inside Windows.

The script also reduces File Explorer promotional behavior by disabling sync-provider notifications, which are commonly associated with OneDrive or other cloud-service prompts inside Explorer. This helps create a cleaner file management experience with fewer popups and banners.

A major part of the script is privacy hardening for Windows apps. It uses Windows AppPrivacy policies to deny many categories of access for Store/UWP style apps. These include account information, location, camera, background app execution, radios, calendar, call history, email, messaging, and phone access. It also disables system location services. These changes are intended to reduce passive data access and unnecessary background activity from Windows apps.

One intentional exception is microphone access. Instead of force-disabling the microphone, the script leaves microphone permissions under normal user control. This means Discord, Zoom, Teams, OBS, voice chat, and other communication apps continue to function normally while still allowing the user to manage permissions themselves.

The script writes both machine-wide (HKLM) and current-user (HKCU) registry settings, meaning some changes apply to the entire PC while others apply only to the logged-in user who ran it. It is safe to rerun after Windows updates because it mainly reapplies policy and preference settings rather than deleting components.

In short, PostZoicware Cleanup is best described as a post-debloat refinement script. Zoicware removes the AI layer, while PostZoicware Cleanup removes much of the leftover clutter, advertising surfaces, suggestion systems, and privacy-invasive defaults that remain in Windows 11.


PostZoicwareAudit

PostZoicware Audit is a companion verification script intended to run after RemoveWindowsAI and the PostZoicware cleanup script. It does not make system changes. Instead, it checks whether the expected privacy, cleanup, and AI-related settings are actually in place. The script audits items such as Widgets being disabled, Spotlight promos being turned off, Start menu recommendations being hidden, Advertising ID being disabled, Explorer sync-provider promos being suppressed, and the configured Windows app privacy restrictions. It also checks likely Zoicware-related outcomes such as Copilot policy settings, Edge Copilot restrictions, Recall task removal, Recall folder removal, optional feature status, and the presence or absence of common AI-related packages and package keys.

The script then generates a local HTML report on the desktop that presents the results in an easy-to-read visual format. The report includes PASS, CHECK, and INFO statuses, summary counts at the top, and color-coded rows for quick review. Critical items, such as microphone access status, are highlighted more prominently so they are easy to spot right away. The HTML report gives the user a simple local audit dashboard showing what appears to be correctly applied, what may need review, and what was detected as informational only.
