# vmenu_adminpanel (ESX FiveM)

All-in-one in-game admin panel for ESX with command `/ap`.

## Features

- Modern NUI panel with tabs: dashboard, players, reports, community services, logs
- Moderation actions: kick, ban (session drop), warn, freeze, goto, bring, revive, heal, slay
- Global announcement sender
- Report system (`/report`) with claim/close flow
- Community service assignment + timer tracking
- Centralized admin action logs with live updates
- Permission checks via ESX group or ACE (`vmenu.adminpanel`)

## Installation

1. Place this resource into your server resources folder.
2. Ensure dependencies:
   - `es_extended`
   - `oxmysql` (optional now but declared in manifest)
3. Add in `server.cfg`:

```cfg
ensure vmenu
```

## Config

Edit `shared/config.lua`:

- `Config.Command` admin command (default `ap`)
- `Config.RequiredGroups` groups allowed to open panel
- `Config.UseAcePermission` to allow ACE permission based access
- Limits for reasons, reports, announcements, services, and warning threshold

## Commands

- `/ap` open admin panel
- `/report <message>` create a player report

## Notes

- This is a ready baseline with many tools for admins.
- For production ban persistence, integrate your ban database inside `server/main.lua` under `action == 'ban'`.
