# vmenu_esx_vehicle_admin

ESX admin resource za FiveM, ki doda hitre ukaze za vozila (podobno kot vehicle možnosti v vMenu):

- boost
- vehicle god mode (toggle)
- repair
- clean
- flip
- max upgrade

## Zahteve

- `es_extended`
- FiveM server

## Namestitev

1. Mapo resource-a daj v `resources/[admin]/vmenu_esx_vehicle_admin`
2. V `server.cfg` dodaj:
   ```cfg
   ensure vmenu_esx_vehicle_admin
   ```
3. Po potrebi prilagodi `config.lua`:
   - `AllowedGroups`
   - imena ukazov
   - moč boosta

## Privzeti ukazi

- `/vboost`
- `/vgodcar`
- `/vfixcar`
- `/vcleancar`
- `/vflipcar`
- `/vmaxcar`

Ukaze lahko uporabljajo samo skupine iz `Config.AllowedGroups`.
