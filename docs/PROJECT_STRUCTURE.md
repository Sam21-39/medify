# Medify — project structure

Feature-based modular Clean Architecture. Cubit + GetIt + ObjectBox. No use-case layer.

```
lib/
├── main.dart                         # boot → initializeDependencies → MyApp
├── objectbox.g.dart                  # generated (gitignored)
├── app/
│   ├── my_app.dart                   # MaterialApp + MultiBlocProvider
│   └── main_navigation_page.dart     # tab shell
├── core/
│   ├── di/injection_container.dart   # composition root
│   ├── database/objectbox_service.dart
│   ├── notifications/
│   ├── preferences/
│   ├── permissions/
│   ├── navigation/
│   ├── system/
│   ├── theme/
│   ├── constants/
│   ├── utils/
│   └── widgets/
├── features/
│   ├── medicines/      # domain + data + presentation (CRUD)
│   ├── schedule/       # logs, daily/refill services, today UI
│   ├── history/
│   ├── statistics/
│   ├── settings/
│   ├── achievements/
│   ├── onboarding/
│   └── profiles/       # present; DI gated for upcoming release
├── gen/                              # flutter_gen
└── l10n/
```

## Conventions

- Per feature: `domain/` (entities, repo interfaces), `data/` (models, impls, feature services), `presentation/` (cubit, pages, widgets).
- Cross-feature imports of domain types are OK (e.g. statistics → schedule repos).
- Profile / CSV export / extra locales stay behind `COMMENTED OUT FOR UPCOMING RELEASE`.
- Quality gate: `./tool/check.sh` (format → codegen → analyze → test).
