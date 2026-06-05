---
name: rest-api-design
description: Use when designing or implementing REST endpoints, controllers, request/response DTOs, route paths, status codes, pagination, error envelopes, API versioning, idempotency keys, or springdoc/OpenAPI annotations in Spring Boot. Enforces plural-noun resources under /api/v1/, the RFC 9457 ProblemDetail error envelope, capped pagination, DTO/entity separation, and correct status codes — the FE↔BE contract.
---

# REST API Design (Spring Boot)

A REST API is a contract with the frontend. Make it **predictable, versioned, documented, and stable**.
Read this before adding or changing any endpoint.

## Non-negotiables

1. **Resources are plural nouns under `/api/v1/`.** No verbs in paths. Version everything.
   `GET /api/v1/orders`, `POST /api/v1/orders`, `GET /api/v1/orders/{id}/items`.
2. **DTOs are records, separate from entities, always.** Never serialize a JPA entity. Map at the boundary.
3. **`@Valid` every inbound body.** Validation lives on the DTO via Jakarta Bean Validation annotations.
4. **One error envelope: RFC 9457 `ProblemDetail`** (`application/problem+json`). Never a bespoke wrapper, never an empty body, always a human-readable `message`.
5. **Pagination is capped.** Default `size=20`, hard max `100`. List responses carry paging metadata.

## Status codes (use exactly these)

| Situation | Status | Notes |
|---|---|---|
| Read OK | 200 | |
| Create OK | 201 | + `Location` header to the new resource |
| Update OK (full state returned) | 200 | use 204 if no body |
| Delete OK | 204 | empty body |
| Validation / malformed | 400 | `ProblemDetail` with field violations |
| Unauthenticated | 401 | from the security entry point |
| Authenticated but forbidden | 403 | |
| Not found | 404 | |
| Conflict (duplicate, version, state) | 409 | **always include a message explaining the conflict** |
| Unprocessable (semantic) | 422 | optional, when 400 is too coarse |
| Rate limited | 429 | + `Retry-After` |

## The error envelope (RFC 9457)

One `@RestControllerAdvice` extending `ResponseEntityExceptionHandler`. Add a stable `errorCode`
and (non-prod) `traceId` as ProblemDetail properties; map domain exceptions to statuses.

```java
@RestControllerAdvice
class ApiExceptionHandler extends ResponseEntityExceptionHandler {

  @ExceptionHandler(ResourceNotFoundException.class)
  ProblemDetail handleNotFound(ResourceNotFoundException ex) {
    var pd = ProblemDetail.forStatusAndDetail(HttpStatus.NOT_FOUND, ex.getMessage());
    pd.setProperty("errorCode", "RESOURCE_NOT_FOUND");
    return pd;
  }

  @ExceptionHandler(ResourceConflictException.class)
  ProblemDetail handleConflict(ResourceConflictException ex) {
    var pd = ProblemDetail.forStatusAndDetail(HttpStatus.CONFLICT, ex.getMessage()); // message is mandatory
    pd.setProperty("errorCode", "RESOURCE_CONFLICT");
    pd.setProperty("conflicts", ex.conflicts());
    return pd;
  }

  @Override
  protected ResponseEntity<Object> handleMethodArgumentNotValid(
      MethodArgumentNotValidException ex, HttpHeaders h, HttpStatusCode s, WebRequest r) {
    var pd = ProblemDetail.forStatusAndDetail(HttpStatus.BAD_REQUEST, "Validation failed");
    pd.setProperty("errorCode", "VALIDATION_ERROR");
    pd.setProperty("violations", ex.getBindingResult().getFieldErrors().stream()
        .map(f -> Map.of("field", f.getField(), "message",
            Optional.ofNullable(f.getDefaultMessage()).orElse("invalid"))).toList());
    return ResponseEntity.badRequest().body(pd);
  }
}
```

> **Contract rule (learned the hard way):** a 409 (or any 4xx) **must** carry a message the
> frontend can show. A frontend that suppresses error toasts will silently drop a message-less
> error — so the body is the contract, not the status alone. Note every contract change for
> `/contract-sync`.

## DTO + controller shape

```java
public record CreateOrderRequest(@NotBlank String name, @NotNull UUID customerId) {}
public record OrderResponse(UUID id, String name, UUID customerId, Instant createdAt) {}

@RestController
@RequestMapping("/api/v1/orders")
class OrderController {
  private final OrderService service;
  OrderController(OrderService service) { this.service = service; }

  @PostMapping
  ResponseEntity<OrderResponse> create(@Valid @RequestBody CreateOrderRequest req) {
    var d = service.create(req);
    return ResponseEntity.created(URI.create("/api/v1/orders/" + d.id())).body(d);
  }

  @GetMapping
  PagedResponse<OrderResponse> list(@RequestParam(defaultValue = "0") int page,
                                     @RequestParam(defaultValue = "20") int size) {
    return service.list(PageRequest.of(page, Math.min(size, 100)));
  }
}
```

## Pagination & idempotency
- List endpoints return `{ content, page, size, totalElements, totalPages }` (a `PagedResponse` record), never a bare array (so you can add metadata without breaking clients).
- Unsafe operations that may be retried accept an `Idempotency-Key` header; store the key→result to make retries safe.

## OpenAPI
- Add `springdoc-openapi-starter-webmvc-ui`; annotate controllers/DTOs so `/v3/api-docs` is accurate.
- Declare a JWT bearer `securityScheme` in an `@Bean OpenAPI`. **Disable or auth-gate Swagger UI in prod.**
- The generated `/v3/api-docs` is the **source of truth** the frontend's typed client is generated from (`/contract-sync`).

## MUST NOT
- Return entities, expose internal IDs/stack traces, break a published `/api/v1` shape without versioning, or return an error without a message.
