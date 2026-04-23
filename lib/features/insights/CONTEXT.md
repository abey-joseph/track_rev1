# insights — CONTEXT

AI-generated observations (trends, correlations, suggestions, warnings) about the user's habits and spending. **Currently skeleton-only** — pages are placeholders, no repository/BLoC wired up yet.

## Key files

### Domain
- `entities/insight_entity.dart` — `InsightEntity { id, userId, title, body, type, confidenceScore (0..1), isRead, isDismissed, generatedAt, createdAt, metadata? (raw JSON), expiresAt? }` and `enum InsightType { correlation, trend, suggestion, warning }`.

### Data
- `mappers/insight_mapper.dart` — Drift ↔ entity extensions for the `insights` table.
- **No datasource, no repository impl yet** — data reads go straight through `InsightsDao` (in `core/database/daos/`) where needed.

### Presentation
- `pages/insights_page.dart` — `@RoutePage()` placeholder with an icon and "AI-powered insights will appear here" copy. No BLoC.
- `pages/insight_detail_page.dart` — `@RoutePage(path: '/insight/:id')` detail page.
- `pages/analysis_page.dart` — `@RoutePage()` analysis view.

## Public surface
None exposed yet. Seeded data from `DatabaseSeeder._seedInsights` populates the `insights` table in mock mode but no domain repository reads it.

## Gotchas
- Before adding a real repository, create `domain/repositories/insights_repository.dart` + impl with `Either<Failure, T>` return types and register via `@LazySingleton(as: InsightsRepository)`.
- `metadata` is a raw JSON string — decode in the presentation layer (per feature), never expose decoded dynamic maps through the domain.
- `insights` table is owned by `core/database/` (schema v7); `InsightsDao` lives there too.
- `DashboardPage.AiInsightCard` currently uses hard-coded text; wiring real insights means creating `WatchInsights` / `GetTopInsight` use cases and reading them from home or creating a shared bloc.
