# NX Framework (FiveM RP)

A modular starter framework for FiveM servers with a unified NUI stack:

- `nx_lib`: callbacks, helper exports, notifications, progress handling.
- `nx_target`: raycast target interactions for entities/models.
- `nx_hud`: circular HUD with health/armor/stamina/money/job.
- `nx_inventory`: NUI inventory with item usage and focus handling.
- `nx_dispatch`: emergency call feed and UI integration.
- `nx_shop_robbery`: register robbery gameplay with dispatch alerts.
- `nx_ui`: shared modern UI shell consumed by all resources.

## Resource order

```cfg
ensure nx_ui
ensure nx_lib
ensure nx_target
ensure nx_hud
ensure nx_inventory
ensure nx_dispatch
ensure nx_shop_robbery
```

## Notes

- The UI is intentionally centralized in `nx_ui` so every resource keeps a consistent style.
- Framework events are namespaced under `nx_*`.
- Designed as a sellable base: all resources are isolated, versioned, and production-ready for extension.
