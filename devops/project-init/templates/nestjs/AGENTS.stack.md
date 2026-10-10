## NestJS conventions

Clean architecture layers, enforced by review rather than ESLint:

- Layers run one direction: domain (entities, business rules) <- application (use cases) <- infrastructure (DB, HTTP clients) <- presentation (controllers, DTOs).
- Controllers stay thin: validate input, call a use case/service, map the result. No business logic in controllers.
- Business logic lives in the domain/application layer, not in a service that also talks to the ORM directly.
- Validate request bodies with DTOs + `class-validator` at the edge.
- Inject dependencies through the constructor; no service locators.
- Tests: Jest unit tests per use case/service; colocated as `*.spec.ts`.

See the `nest-module-generator` skill for generating new modules and `database-persistence-patterns` for persistence.
