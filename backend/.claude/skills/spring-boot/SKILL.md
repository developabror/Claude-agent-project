---
name: spring-boot
description: Spring Boot 3.x development - REST APIs, JPA, Security, Testing, and Cloud-native patterns. Use for building enterprise Java applications with Spring Boot.
metadata:
  version: "2.0.0"
  domain: backend
  triggers: Spring Boot, Spring Framework, Spring Security, Spring Data JPA, Java REST API, Microservices Java
  role: specialist
  scope: implementation
  output-format: code
---

# Spring Boot Skill

Enterprise Spring Boot 3.x development with focus on clean architecture and production-ready code.

## Core Workflow

1. **Analyze** - Understand requirements, identify service boundaries, APIs, data models
2. **Design** - Plan architecture, confirm design before coding
3. **Implement** - Build with constructor injection and layered architecture
4. **Secure** - Add Spring Security, OAuth2, method security; verify tests pass
5. **Test** - Write unit, integration tests; run `./gradlew test` and confirm all pass
6. **Deploy** - Configure health checks via Actuator; validate `/actuator/health` returns UP

## Quick Start Templates

### Entity
```java
@Entity
@Table(name = "products")
public class Product {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank
    private String name;

    @DecimalMin("0.0")
    private BigDecimal price;

    // Getters/Setters (no Lombok)
}
```

### Repository
```java
public interface ProductRepository extends JpaRepository<Product, Long> {
    List<Product> findByNameContainingIgnoreCase(String name);
}
```

### Service
```java
@Service
@Transactional(readOnly = true)
public class ProductService {
    private final ProductRepository repo;

    public ProductService(ProductRepository repo) {
        this.repo = repo;
    }

    public List<Product> search(String name) {
        return repo.findByNameContainingIgnoreCase(name);
    }

    @Transactional
    public Product create(ProductRequest request) {
        var product = new Product();
        product.setName(request.name());
        product.setPrice(request.price());
        return repo.save(product);
    }
}
```

### REST Controller
```java
@RestController
@RequestMapping("/api/v1/products")
@Validated
public class ProductController {
    private final ProductService service;

    public ProductController(ProductService service) {
        this.service = service;
    }

    // Return DTO records, NEVER the @Entity — map at the boundary.
    @GetMapping
    public List<ProductResponse> search(@RequestParam(defaultValue = "") String name) {
        return service.search(name).stream().map(ProductResponse::from).toList();
    }

    @PostMapping
    public ResponseEntity<ProductResponse> create(@Valid @RequestBody ProductRequest request) {
        var p = service.create(request);
        return ResponseEntity.created(URI.create("/api/v1/products/" + p.getId()))
                .body(ProductResponse.from(p));
    }
}
```

### DTOs (Records — separate from the entity)
```java
public record ProductRequest(
    @NotBlank String name,
    @DecimalMin("0.0") BigDecimal price
) {}

public record ProductResponse(Long id, String name, BigDecimal price) {
    static ProductResponse from(Product p) {
        return new ProductResponse(p.getId(), p.getName(), p.getPrice());
    }
}
```

### Global Exception Handler

> **Prefer RFC 9457 `ProblemDetail`** for the production error envelope — see the
> `rest-api-design` skill. The `Map`-based handler below is the minimal form; the
> `ProblemDetail` form (extend `ResponseEntityExceptionHandler`, return
> `application/problem+json` with a stable `errorCode` + `traceId`) is the standard for new code.

```java
@RestControllerAdvice
public class GlobalExceptionHandler {
    @ExceptionHandler(MethodArgumentNotValidException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public Map<String, String> handleValidation(MethodArgumentNotValidException ex) {
        return ex.getBindingResult().getFieldErrors().stream()
            .collect(Collectors.toMap(FieldError::getField,
                    error -> error.getDefaultMessage() != null ? error.getDefaultMessage() : "Invalid"));
    }

    @ExceptionHandler(EntityNotFoundException.class)
    @ResponseStatus(HttpStatus.NOT_FOUND)
    public Map<String, String> handleNotFound(EntityNotFoundException ex) {
        return Map.of("error", ex.getMessage());
    }
}
```

### Test Slice
```java
@WebMvcTest(ProductController.class)
class ProductControllerTest {
    @Autowired MockMvc mockMvc;
    @MockitoBean ProductService service;   // @MockBean is deprecated for removal in Boot 3.4 → use @MockitoBean

    @Test
    void createProduct_validRequest_returns201() throws Exception {
        var product = new Product();
        product.setName("Widget");
        when(service.create(any())).thenReturn(product);

        mockMvc.perform(post("/api/v1/products")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"name\":\"Widget\",\"price\":10.0}"))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.name").value("Widget"));
    }
}
```

## Canonical companion skills (load by domain)

This skill is the implementation quickstart. The authoritative rules for each domain live in
dedicated skills — read the matching one before going deep:

| Topic | Skill | When |
|-------|-------|------|
| REST contract / errors | `rest-api-design` | controllers, DTOs, status codes, RFC 9457 `ProblemDetail`, OpenAPI |
| Data access | `jpa-patterns` | entities, fetch strategy, N+1, transactions |
| Security | `spring-security` | `SecurityFilterChain`, OAuth2 resource server, method security |
| Testing | `backend-testing` | JUnit 5, slices, Testcontainers + `@ServiceConnection` |
| Migrations | `flyway-migrations` | versioned SQL, `ddl-auto=validate` |
| Observability | `observability` | Actuator, Micrometer/OTLP, structured logging |
| Build/package | `gradle-build` | multi-module, Docker, CI |

## Constraints

### MUST DO
- Constructor injection (no field injection)
- `@Valid` on all request bodies
- `@Transactional` for multi-step writes
- `@Transactional(readOnly = true)` for reads
- Type-safe config with `@ConfigurationProperties`
- Global exception handling with `@RestControllerAdvice`
- Externalize secrets (use env vars, not properties files)

### MUST NOT DO
- Field injection (`@Autowired` on fields)
- Skip input validation on endpoints
- Mix blocking and reactive code
- Store secrets in application.properties
- Use deprecated Spring Boot 2.x patterns
- Hardcode URLs, credentials, environment values

## Architecture Patterns

**Project Structure (Gradle multi-module — see `gradle-build` skill):**
```
backend/
├── api/        # web layer: @RestController, DTO records, OpenAPI — depends on service
├── service/    # use-cases / orchestration, @Transactional — depends on domain
├── domain/     # pure business model + ports (NO Spring, NO JPA)
├── infra/      # JPA adapters, Flyway, external clients — implements domain ports
└── common/     # shared errors/utils (ProblemDetail advice) — shared by all
```
Dependency direction: `api → service → domain ← infra`, `common` shared by all.
Base package: `com.example.app` (override per project). Single-module is fine
for small services — collapse to `src/main/java/<base-package>/{controller,service,repository,model,dto,config,exception}`.

**Layering:**
- Controller → Service → Repository
- Controller handles HTTP, validation
- Service handles business logic, transactions
- Repository handles data persistence

**Clean Architecture Principles:**
- Domain models independent of frameworks
- Use case driven design
- Dependency inversion (interfaces)
- Clear boundaries between layers

## Common Annotations

| Annotation | Purpose |
|------------|---------|
| `@RestController` | REST controller (combines @Controller + @ResponseBody) |
| `@Service` | Business logic component |
| `@Repository` | Data access component |
| `@Transactional` | Transaction management |
| `@Valid` | Trigger validation |
| `@ConfigurationProperties` | Bind properties to class |
| `@EnableMethodSecurity` | Enable method security |

## Spring Security (stateless resource server)

> Full security rules are in the `spring-security` skill. Minimal baseline:

```java
@Configuration
@EnableMethodSecurity
public class SecurityConfig {
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        return http
                .csrf(AbstractHttpConfigurer::disable)
                .sessionManagement(s -> s.sessionCreationPolicy(STATELESS))
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers("/actuator/health").permitAll()
                        .anyRequest().authenticated())
                .oauth2ResourceServer(oauth2 -> oauth2.jwt(Customizer.withDefaults()))
                .build();
    }
}
```

## Knowledge Base

Spring Boot 3.4, Java 21 (records, virtual threads), Spring MVC, Spring Data JPA, Spring Security 6, OAuth2/JWT, Hibernate, Flyway, Spring Cloud (optional), Resilience4j, Micrometer + OpenTelemetry, JUnit 5, Testcontainers, Mockito, Gradle. (Spring MVC, not WebFlux — this template is blocking + virtual threads.)
