---
name: backend-testing
description: Use when writing or running backend tests — JUnit 5 + Mockito unit tests, @WebMvcTest/@DataJpaTest slices, and @SpringBootTest integration tests with Testcontainers + @ServiceConnection against real Postgres/Redis/Kafka. Enforces real-infra integration tests (no H2 fakery), positive+negative coverage, deterministic isolation, and a coverage gate.
---

# Backend Testing (JUnit 5 · Mockito · Testcontainers)

Behavior is not done until it is proven. Pick the **cheapest level that proves the behavior**.

## The test pyramid (choose the right level)

| Level | Use for | Annotation |
|---|---|---|
| **Unit** (Mockito) | pure business logic, no Spring context | plain JUnit 5 + `@ExtendWith(MockitoExtension.class)` |
| **Web slice** | controller mapping, validation, `ProblemDetail` | `@WebMvcTest(Controller.class)` + `MockMvc` + `@MockitoBean` |
| **Data slice** | repository queries, mappings, N+1 | `@DataJpaTest` (+ Testcontainers Postgres, not H2) |
| **Integration** | cross-layer, security, real DB | `@SpringBootTest` + Testcontainers + `@ServiceConnection` |

## Integration tests run against REAL infrastructure

Spring Boot 3.1+ `@ServiceConnection` auto-wires the JDBC URL/credentials — no `@DynamicPropertySource`.

```java
@SpringBootTest(webEnvironment = WebEnvironment.RANDOM_PORT)
@Testcontainers
class OrderApiIntegrationTest {

  @Container @ServiceConnection
  static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16-alpine");

  @Autowired TestRestTemplate http;

  @Test
  void createOrder_valid_returns201WithLocation() { /* happy path */ }

  @Test
  void createOrder_blankName_returns400ProblemDetail() {  // NEGATIVE path is mandatory
    var res = http.postForEntity("/api/v1/orders", new CreateOrderRequest("", customerId), ProblemDetail.class);
    assertThat(res.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
    assertThat(res.getBody().getProperties()).containsKey("violations");
  }
}
```

Provide a reusable `TestcontainersConfiguration` + a `bootTestRun` task so devs run the app against
containers locally; enable `.withReuse(true)` locally to keep it fast.

## Hard rules
- **Never H2 as a Postgres substitute** — dialect drift hides real bugs. Use Testcontainers.
- **Cover both paths**: every feature gets a happy-path test *and* failure tests (validation 400, conflict 409 with message, auth 401/403). Project convention requires positive **and** negative cases.
- **Deterministic & isolated**: `@Transactional` rollback or explicit cleanup; no shared mutable state; no order dependence; no real network/clock — inject `Clock`.
- **Arrange-Act-Assert**, one behavior per test, names like `method_condition_expectedResult`.
- Assert on **behavior and the response contract** (status + `ProblemDetail` shape), not implementation details.

## Coverage & running
- `./gradlew test` for unit+slice; `./gradlew integrationTest` (or tagged `@Tag("integration")`) for container tests.
- Gate coverage (JaCoCo) on changed code; report **only failures** + the summary to keep context lean.
- Reproduce reported bugs with a failing test **first**, then fix.

## Property / invariant tests (catch what example tests miss)
For rules that must hold for *all* inputs (ordering, idempotency, no-overlap, totals), add
**property-based tests** (jqwik): generate many inputs and assert the invariant, instead of a few
hand-picked cases. Pair every DB constraint (see `jpa-patterns`) with a test that the violating case is
**rejected** — that's how "it should never happen" stops happening.

## Provider contract verification (Pact)
Run **Pact provider verification** (see `contract-testing`) in the suite: replay the frontend's consumer
contract against the running app (states seeded via Testcontainers) so a change that breaks a *consumed*
endpoint fails the **backend** build — before it reaches the frontend. Codegen checks shape; Pact checks behavior.
