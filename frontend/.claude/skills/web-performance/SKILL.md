---
name: web-performance
description: Use when working in frontend/ on performance — Core Web Vitals (LCP/INP/CLS), Vite bundle splitting, route-level code-splitting, lazy/Suspense, image/font strategy, memoization, and virtualization. Enforces measured optimization (analyze first), the CWV budgets, and surgical fixes.
---

# Web Performance (Core Web Vitals)

Optimize the **measured** bottleneck. Targets: **LCP < 2.5s · INP < 200ms · CLS < 0.1**.

## Measure first
- `npm run build` then analyze with `rollup-plugin-visualizer`; run Lighthouse on a production preview; track field data with the `web-vitals` library.
- Find the dominant cost before changing anything: oversized vendor chunk, unsplit routes, layout shift, long tasks, unoptimized media.

## Bundle / loading
- **Route-level `React.lazy` + `Suspense`** — don't ship the whole app to render one page.
- Vite `build.rollupOptions.output.manualChunks` to split `react`/`vendor`/UI libs so they cache independently.
- Tree-shakeable imports (named, not whole-namespace); drop unused deps; defer non-critical libs (charts, editors) behind interaction/idle.

## LCP (largest paint)
- Prioritize the hero image/text; `preconnect`/`preload` critical origins/assets; avoid render-blocking CSS/JS; serve modern image formats with explicit `width`/`height`.

## CLS (layout stability)
- Reserve space for images, embeds, and ads (`aspect-ratio` or explicit dimensions). `font-display: swap` with a metric-matched fallback to avoid reflow. Never insert content above existing content after load.

## INP (interaction responsiveness)
- Break long tasks (`startTransition`, chunked work, web workers for heavy compute); memoize genuinely hot paths (`useMemo`/`React.memo`) — but only proven ones; **virtualize** large lists/tables.

## Rules
- No speculative micro-optimization or blanket memoization — it adds complexity and can hurt. If the baseline meets the budgets, stop.
- Every change shows **before/after** numbers (bundle size or vitals). Keep edits surgical.
- Add a CI bundle-size check so regressions fail the build.
