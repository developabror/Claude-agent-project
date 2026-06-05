---
name: spring-security
description: Use when writing or reviewing Spring Boot security — SecurityFilterChain, stateless OAuth2 Resource Server (JWT validation), method security (@PreAuthorize), CORS, CSRF posture, password hashing, auth error responses, and rate limiting. Enforces deny-by-default, stateless sessions, allow-list CORS, ProblemDetail auth errors, and secrets hygiene. Spring Security 6 (no WebSecurityConfigurerAdapter).
---

# Spring Security (Spring Boot 3 / Security 6)

Security is **default-on, not an afterthought**. Every endpoint is authenticated unless explicitly public.
Every input is untrusted. Read this before touching anything auth-related.

## The baseline filter chain (stateless, JWT resource server)

```java
@Configuration
@EnableMethodSecurity
class SecurityConfig {

  @Bean
  SecurityFilterChain api(HttpSecurity http) throws Exception {
    return http
      .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
      .csrf(AbstractHttpConfigurer::disable)              // stateless token API → no CSRF cookie
      .cors(Customizer.withDefaults())                    // see allow-list bean below
      .authorizeHttpRequests(auth -> auth
        .requestMatchers("/actuator/health/**", "/v3/api-docs/**").permitAll()
        .requestMatchers(HttpMethod.POST, "/api/v1/auth/**").permitAll()
        .anyRequest().authenticated())                    // deny-by-default
      .oauth2ResourceServer(o -> o.jwt(jwt -> jwt.jwtAuthenticationConverter(rolesConverter())))
      .exceptionHandling(e -> e
        .authenticationEntryPoint(problemDetailEntryPoint())   // 401 → ProblemDetail
        .accessDeniedHandler(problemDetailAccessDenied()))      // 403 → ProblemDetail
      .build();
  }

  @Bean
  CorsConfigurationSource corsConfigurationSource() {
    var cfg = new CorsConfiguration();
    cfg.setAllowedOrigins(List.of("https://app.example.com")); // ALLOW-LIST — never "*" with credentials
    cfg.setAllowedMethods(List.of("GET","POST","PUT","PATCH","DELETE"));
    cfg.setAllowedHeaders(List.of("Authorization","Content-Type","Idempotency-Key"));
    cfg.setAllowCredentials(true);
    var src = new UrlBasedCorsConfigurationSource();
    src.registerCorsConfiguration("/api/**", cfg);
    return src;
  }
}
```

`application.yml` points validation at the IdP — the service **validates**, it does not mint tokens
(unless it is the auth service):
```yaml
spring:
  security:
    oauth2:
      resourceserver:
        jwt:
          issuer-uri: ${OIDC_ISSUER_URI}   # e.g. Keycloak/Auth0/Okta — never a secret in source
```

## Non-negotiables

- **Stateless**: `SessionCreationPolicy.STATELESS`, explicit `SecurityFilterChain` bean. No `WebSecurityConfigurerAdapter` (removed in Security 6).
- **Deny-by-default**: `anyRequest().authenticated()`; public endpoints opt in by explicit matcher.
- **Method security**: `@EnableMethodSecurity` + `@PreAuthorize("hasRole('ADMIN')")` / `@PostAuthorize` for object-level checks (prevent IDOR).
- **CORS allow-list**, never `*` with `allowCredentials(true)`.
- **Auth errors are `ProblemDetail`** (401/403) with generic messages — details only in server logs.
- **Passwords**: BCrypt (`BCryptPasswordEncoder`), never plaintext, never reversible.
- **Tokens**: short-lived access + rotated refresh; if browser-facing, prefer **HttpOnly + Secure + SameSite cookies** over `localStorage`. Never log tokens.
- **Rate-limit** auth endpoints (Bucket4j / gateway). **Secrets** via env/Vault, never in source, images, or logs.

## Custom token → authorities
Map JWT scopes/claims to Spring authorities with a `JwtAuthenticationConverter` so `@PreAuthorize` works.

## Non-JWT / opaque-token auth
If some clients authenticate with an opaque token (e.g. an `X-Api-Key` / `X-Service-Token` header
rather than a JWT), add a dedicated `OncePerRequestFilter` + a second `SecurityFilterChain` (`@Order`)
scoped by request matcher — do **not** weaken the JWT chain to accommodate it.

## Review checklist (the auditor runs this)
- [ ] deny-by-default; every public route is intentional
- [ ] no broken object-level authorization (IDOR) — ownership checked
- [ ] parameterized queries only; safe deserialization
- [ ] CORS allow-list; CSRF posture matches the auth model
- [ ] no secrets/tokens/PII in source, logs, or error bodies
- [ ] dependency CVE scan clean (`./gradlew dependencyCheckAnalyze`)
