import { check } from "k6";
import http from "k6/http";
import { Trend, Rate } from "k6/metrics";

// Endpoints
const ENDPOINTS = [
  "https://golfindev.tech/",
  "https://www.golfindev.tech/",
  "https://marketplace.golfindev.tech/",
  "https://cdn.golfindev.tech/banner-golfin-v1.png",
  "https://gamedevapi.golfindev.tech/",
  "https://marketplace-newfeature.golfindev.tech/",
  "https://gamecdn.golfindev.tech/banner-golfin-v1.png",
  "https://golfin-stage.com/",
  "https://www.golfin-stage.com/",
  "https://gamecdn.golfin-stage.com/banner-golfin-v1.png",
  "https://golfinsrv.com/",
  "https://www.golfinsrv.com/",
  "https://cdn.golfinsrv.com/banner-golfin-v1.png",
  "https://gamecdn.golfinsrv.com/banner-golfin-v1.png",
  "https://maintenance.golfindev.tech/health",
];

// SLOs used only for status labeling in the table (no k6 thresholds)
const SLO = {
  p95_ms: 1000,
  p99_ms: 2000,
  error_rate: 0.05,
};

// Helpers (no URL class in k6)
function hostFromUrl(u) {
  const m = String(u).match(/^https?:\/\/([^\/?#]+)/i);
  return m ? m[1] : String(u);
}
function sanitizeName(s) {
  return String(s).replace(/[^a-zA-Z0-9_]/g, "_");
}

// Build scenarios: one per endpoint with constant arrival rate
const scenarios = {};
const PER_ENDPOINT_RPS = 2;
const DURATION = "5s";
const PRE_ALLOCATED_VUS = 10;
const MAX_VUS = 50;

for (const url of ENDPOINTS) {
  const scName = sanitizeName(hostFromUrl(url));
  const reqName = hostFromUrl(url);
  scenarios[scName] = {
    executor: "constant-arrival-rate",
    rate: PER_ENDPOINT_RPS,
    timeUnit: "1s",
    duration: DURATION,
    preAllocatedVUs: PRE_ALLOCATED_VUS,
    maxVUs: MAX_VUS,
    exec: "endpointTest",
    env: { TARGET_URL: url, REQ_NAME: reqName, METRIC_KEY: sanitizeName(reqName) },
  };
}

// Per-endpoint custom metrics
const latencyTrends = {};
const errorRates = {};
for (const url of ENDPOINTS) {
  const key = sanitizeName(hostFromUrl(url));
  latencyTrends[key] = new Trend(`latency_${key}`, true);
  errorRates[key] = new Rate(`errors_${key}`);
}

export const options = {
  scenarios,
  discardResponseBodies: true,
  summaryTrendStats: ["avg", "min", "med", "p(95)", "p(99)", "max"],
};

// Scenario exec
export function endpointTest() {
  const url = __ENV.TARGET_URL;
  const name = __ENV.REQ_NAME;
  const key = __ENV.METRIC_KEY;

  const res = http.get(url, { tags: { name }, timeout: "5s" });

  latencyTrends[key].add(res.timings.duration);
  errorRates[key].add(!(res.status >= 200 && res.status < 400));

  check(res, {
    "status is 2xx/3xx": (r) => r.status >= 200 && r.status < 400,
  });
}

export function handleSummary(data) {
  const C = {
    r: "\x1b[31m",
    g: "\x1b[32m",
    y: "\x1b[33m",
    c: "\x1b[36m",
    b: "\x1b[1m",
    dim: "\x1b[2m",
    reset: "\x1b[0m",
  };
  const lines = [];
  const pct = (v) => `${(v * 100).toFixed(2)}%`;
  const ms = (v) => `${Math.round(v)} ms`;

  // Title
  lines.push(`${C.b}${C.c}Infra Smoke Summary (parallel)${C.reset}`);
  lines.push(
    `${C.dim}Duration: ${DURATION}  |  Rate per endpoint: ${PER_ENDPOINT_RPS} req/s  |  Endpoints: ${ENDPOINTS.length}${C.reset}\n`,
  );

  // Per-endpoint table
  lines.push(`${C.b}Endpoint${C.reset}                                 p95 (ms)   p99 (ms)   Err%    Status`);
  lines.push(`${C.dim}${"-".repeat(80)}${C.reset}`);
  for (const url of ENDPOINTS) {
    const host = hostFromUrl(url);
    const key = sanitizeName(host);
    const lt = data.metrics[`latency_${key}`];
    const er = data.metrics[`errors_${key}`];

    const p95 = lt ? lt.values["p(95)"] : 0;
    const p99 = lt ? lt.values["p(99)"] : 0;
    const cnt = lt ? lt.values["count"] : 0;
    const errRate = er ? er.values["rate"] || 0 : 0;

    let status = `${C.g}OK${C.reset}`;
    if (errRate >= SLO.error_rate) status = `${C.r}ERRORS${C.reset}`;
    else if (p95 > SLO.p95_ms) status = `${C.y}SLOW${C.reset}`;

    const hostCol = host.padEnd(37, " ");
    const p95Col = String(Math.round(p95 || 0) || "-").padStart(8, " ");
    const p99Col = String(Math.round(p99 || 0) || "-").padStart(10, " ");
    const errCol = `${(errRate * 100).toFixed(2)}%`.padStart(7, " ");

    lines.push(`${hostCol} ${p95Col}   ${p99Col}   ${errCol}   ${status}`);
  }

  // Global summary (informational)
  const total = data.metrics.http_reqs?.values?.count || 0;
  const failRate = data.metrics.http_req_failed?.values?.rate || 0;
  const globP95 = data.metrics.http_req_duration?.values?.["p(95)"] || 0;
  const globP99 = data.metrics.http_req_duration?.values?.["p(99)"] || 0;

  lines.push(
    `\n${C.b}Global${C.reset}   reqs: ${total}   p95: ${ms(globP95)}   p99: ${ms(
      globP99,
    )}   errors: ${pct(failRate)}`,
  );

  return { stdout: lines.join("\n") + "\n" };
}


export function infraSmokeTests() {
  // Run a single pass over all endpoints (sequential) so it can be called from main.js
  for (const url of ENDPOINTS) {
    const name = hostFromUrl(url);
    const key = sanitizeName(name);

    const res = http.get(url, { tags: { name }, timeout: "5s" });

    latencyTrends[key].add(res.timings.duration);
    errorRates[key].add(!(res.status >= 200 && res.status < 400));

    check(res, {
      "status is 2xx/3xx": (r) => r.status >= 200 && r.status < 400,
    });
  }

}
