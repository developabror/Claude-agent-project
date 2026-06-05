---
name: observability
description: Use when instrumenting a Spring Boot backend for production — Micrometer Observation metrics, OpenTelemetry (OTLP) tracing, structured JSON logging with traceId/spanId correlation, Actuator health/liveness/readiness probes, and SLI/SLO definition. Enforces OTLP-as-protocol, correlated logs↔traces, restricted Actuator exposure, and a separate management port.
---

# Observability (Micrometer · OpenTelemetry · Actuator)

Three correlated pillars: **metrics, traces, logs**. If a 2am pager can't explain a request from these, it isn't instrumented.

## The stance
- **Micrometer Observation is the single abstraction.** Instrument once; export over **OTLP** to any backend (Grafana LGTM, Tempo, etc.). The protocol matters, not the vendor library.
- Auto-instrumentation covers web/JDBC/clients; add `@Observed` (or `ObservationRegistry`) on custom critical paths.

## Dependencies (Boot 3.4)
`spring-boot-starter-actuator`, `micrometer-registry-otlp` (metrics), `micrometer-tracing-bridge-otel` + `opentelemetry-exporter-otlp` (traces). (Boot 4 ships `spring-boot-starter-opentelemetry`.)

## Actuator config
```yaml
management:
  server.port: 9090                       # separate management port
  endpoints.web.exposure.include: health,info,prometheus
  endpoint.health.probes.enabled: true    # liveness/readiness groups for k8s
  endpoint.health.show-details: when_authorized
  tracing.sampling.probability: 1.0       # tune down in prod
  otlp:
    metrics.export.url: ${OTLP_ENDPOINT}/v1/metrics
    tracing.endpoint: ${OTLP_ENDPOINT}/v1/traces
```
- `/actuator/health/liveness` and `/actuator/health/readiness` back the orchestrator probes.

## Structured logging with trace correlation (Boot 3.4 native)
```yaml
logging:
  structured.format.console: ecs          # or logstash / gelf — JSON to stdout
  pattern.correlation: "[%X{traceId:-},%X{spanId:-}] "
```
Micrometer Tracing injects `traceId`/`spanId` into MDC, so every JSON log line correlates to its
trace. Ship logs via **stdout** to the platform collector. **Never log secrets or PII.**

## SLIs / SLOs
- For each critical path define an SLI (latency p95, error rate, availability), an SLO target, and an
  alert threshold. Record them next to the code (`docs/SLO.md`) so they're reviewed with the change.

## Definition of done
- `/actuator/health` UP with liveness/readiness groups; a request produces a trace with correlated
  JSON logs and at least one metric. Show a sample log line containing a non-empty `traceId`.

## MUST NOT
- Expose `env`/`heapdump`/`threaddump` publicly; log tokens/PII; instrument hot loops into a perf
  regression; couple code to a specific observability vendor (keep it OTLP).

## End-to-end trace correlation (FE → BE → logs)
The point of tracing is to turn "a user saw an error" into one query.
- **Continue the incoming trace:** read the `traceparent` header (Micrometer Tracing / OTel context propagation continues it; start a fresh trace if absent). `traceId`/`spanId` land in MDC automatically → every JSON log line carries them.
- **Echo `traceId` to the client:** include it in `ProblemDetail` (non-prod) and a response header (`X-Request-Id`/`traceresponse`) so the frontend can show "ref: &lt;traceId&gt;" on errors.
- Result: one `traceId` ties the UI action, the HTTP request, every log line, the DB span, and any emitted event (`realtime-contract`) together — a user report becomes a single grep, not a hunt.
