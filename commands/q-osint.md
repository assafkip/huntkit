Run targeted OSINT collection on a specific platform.

Read `skills/osint/SKILL.md` for actor IDs and tool usage, then execute the platform-specific steps.

Supported platforms: `linkedin`, `instagram`, `facebook`, `reddit`, `x`, `tiktok`, `youtube`, `domain`, `email`, `telegram`, `username`, `sweep`

Additional tools beyond the OSINT skill scripts (install separately if needed):
- Telegram: `tgspyder <target> --members --chats` (https://github.com/Darksight-Analytics/tgspyder)
- Username search: `maigret <username> --json investigations/<case>/evidence/maigret-<username>.json`
- Google/email: `ghunt email <address> --json investigations/<case>/evidence/ghunt-<address>.json`

All results must be saved to `investigations/<case>/evidence/` and relevant target profiles updated.
Tag source reliability using the A-F scale from `skills/osint/SKILL.md`.

Argument: $ARGUMENTS (required: platform and target, e.g. "linkedin https://linkedin.com/in/someone")
