# DevOps Intern Final Assessment

[![CI](https://github.com/Fizzy444/devops-intern-final/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/Fizzy444/devops-intern-final/actions/workflows/ci.yml)

**Name:** Mithun
**Submission date:** 2026-10-23
**Release tag:** v1.0.0

## Architecture

```
 developer ──push/PR──> GitHub ──> GitHub Actions CI ──────────────┐
                                   lint -> build -> test -> publish │
                                                                    v
                                                      ghcr.io/<user>/devops-intern-final:<sha>
                                                                    │
                                                          nomad job run (tag variable)
                                                                    v
                         Consul <── service + /healthz check ── Nomad alloc (nginx:1.27-alpine, port 8080)
                                                                    │ container stdout (JSON access logs)
                                                                    v
                                                  Promtail (Docker SD) ──> Loki ──> Grafana Explore
```

Each stage consumes the output of the previous one: the CI-built image is the one pushed to GHCR, the Nomad job pulls that exact SHA tag, and Promtail ships the logs of the container Nomad started.

## Prerequisites

| Tool | Version |
|---|---|
| Docker Engine | 27.x |
| Docker Compose plugin | 2.29 or newer (2.23.1 minimum) |
| Nomad | 1.9.x |
| Consul | 1.20.x |
| ShellCheck | 0.10.0 |
| curl | 8.x |

## Quick Start

```sh
git clone https://github.com/Fizzy444/devops-intern-final.git && cd devops-intern-final
docker build -t devops-intern-final:local --build-arg BUILD_SHA="$(git rev-parse --short HEAD)" --build-arg BUILD_DATE="$(date -u +%F)" app
docker run -d --name web -p 8080:8080 --label logging=promtail --label service=nginx-app devops-intern-final:local
scripts/healthcheck.sh
curl -i http://localhost:8080/
```

Optional log stack: `docker compose -f monitoring/docker-compose.yaml up -d`

## Repository layout

```
app/          Dockerfile, nginx.conf, index.html
scripts/      sysinfo.sh, healthcheck.sh
.github/      CI workflow
nomad/        Nomad job specification
monitoring/   Loki, Promtail, Grafana stack and loki_setup.md
docs/         Screenshots
```

## Task 1: Source control

Work was done on `feature/*` branches and merged into `main` through pull requests, using conventional commit messages. The final state is tagged `v1.0.0`.

```sh
git log --oneline --graph
git tag -l
```

Pull requests:
- [#1: feat: containerised app and shell scripts](https://github.com/Fizzy444/devops-intern-final/pull/1)
- [#2: ci: add GitHub Actions pipeline](https://github.com/Fizzy444/devops-intern-final/pull/2)
- [#3: feat: nomad deployment and log aggregation](https://github.com/Fizzy444/devops-intern-final/pull/3)
- [#4: docs: add README](https://github.com/Fizzy444/devops-intern-final/pull/4)

## Task 2: Linux scripting

Both scripts use a `bash` shebang because `pipefail` is required by the brief and is not part of POSIX `sh`. Apart from that they stick to POSIX constructs. Both are marked executable in Git:

```sh
git update-index --chmod=+x scripts/sysinfo.sh scripts/healthcheck.sh
git ls-files -s scripts
shellcheck scripts/*.sh
```

Run them:

```sh
scripts/sysinfo.sh
scripts/healthcheck.sh
scripts/healthcheck.sh http://localhost:8080/does-not-exist; echo "exit=$?"
```

Observed output:

```text
User            : Mithun (effective UID 197609)
Hostname        : LAPTOP-ONAKSVBU
Kernel release  : 3.6.10-710e5275.x86_64
System date     : 2026-10-23T20:51:35+0530

Disk usage (/):
Filesystem            Size  Used Avail Use% Mounted on
C:/Program Files/Git  264G  163G  101G  62% /

Memory usage:
MemTotal:       14497276 kB
MemFree:          599868 kB
HighTotal:             0 kB

Docker daemon   : running (server 29.9.2)

OK: http://localhost:8080 returned HTTP 200

FAIL: http://localhost:8080/does-not-exist returned HTTP 404, expected 200
exit=1
```

`healthcheck.sh` exits 0 on HTTP 200, 1 on any other status or an unreachable host, and 2 if curl is missing.

## Task 3: Containerisation

```sh
docker build -t devops-intern-final:local --build-arg BUILD_SHA="$(git rev-parse --short HEAD)" --build-arg BUILD_DATE="$(date -u +%F)" app
docker run -d --name web -p 8080:8080 devops-intern-final:local
docker images devops-intern-final:local
curl -i http://localhost:8080/
curl -i http://localhost:8080/healthz
docker exec web id
docker inspect --format '{{.State.Health.Status}}' web
```

Design decisions: pinned base `nginx:1.27-alpine`, non-root `USER nginx`, PID file and temp paths moved to `/tmp`, port 8080 so no privileged bind is needed, `BUILD_SHA` injected into both `index.html` and an `X-Build-SHA` response header, JSON access logs on stdout for Loki.

Observed output:

```text
IMAGE                       ID             DISK USAGE   CONTENT SIZE   EXTRA
devops-intern-final:local   c3740824d478       73.7MB           21MB

HTTP/1.1 200 OK
Server: nginx
Date: Fri, 23 Oct 2026 15:22:00 GMT
Content-Type: text/html
Content-Length: 980
Last-Modified: Fri, 23 Oct 2026 15:07:54 GMT
Connection: keep-alive
ETag: "6adb784a-3d4"
X-Build-SHA: a03c058
Accept-Ranges: bytes

<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>DevOps Intern Final Assessment</title>
<style>
:root { color-scheme: light dark; }
body { font-family: system-ui, sans-serif; margin: 0; min-height: 100vh; display: grid; place-items: center; background: #0f172a; color: #e2e8f0; }
main { max-width: 36rem; padding: 2rem; border: 1px solid #334155; border-radius: 12px; background: #1e293b; }
h1 { margin-top: 0; font-size: 1.6rem; }
dl { display: grid; grid-template-columns: max-content 1fr; gap: 0.5rem 1.5rem; margin: 0; }
dt { color: #94a3b8; }
dd { margin: 0; font-family: ui-monospace, monospace; }
</style>
</head>
<body>
<main>
<h1>DevOps Intern Final Assessment</h1>
<dl>
<dt>Name</dt><dd>Mithun</dd>
<dt>Assessment date</dt><dd>2026-10-23</dd>
<dt>Build identifier</dt><dd>a03c058</dd>
<dt>Built at</dt><dd>2026-10-23</dd>
</dl>
</main>
</body>
</html>

HTTP/1.1 200 OK
Server: nginx
Date: Fri, 23 Oct 2026 15:22:00 GMT
Content-Type: text/plain
Content-Length: 3
Connection: keep-alive
X-Build-SHA: a03c058

ok

uid=101(nginx) gid=101(nginx) groups=101(nginx)

healthy
```

Image size must be under 60 MB: record the `docker images` result above.

## Task 4: Continuous integration

`.github/workflows/ci.yml` runs on push and pull request to `main` with four jobs:

| Job | What it does |
|---|---|
| lint | `shellcheck scripts/*.sh` and hadolint on `app/Dockerfile` |
| build | Builds with `BUILD_SHA=${{ github.sha }}`, saves the image as an artifact |
| test | Loads that image, waits for the container healthcheck, runs `scripts/healthcheck.sh`, fails the job otherwise |
| publish | Push to `main` only, pushes the tested image to GHCR tagged with the commit SHA and `latest` |

Security: workflow-wide `contents: read`, `packages: write` only on the publish job, authentication with `GITHUB_TOKEN`, actions pinned to major versions, no stored credentials.

After the first run, set the GHCR package visibility to public so Nomad can pull it without credentials (Package settings, Change visibility).

Evidence: add a screenshot of the green run and the package page.

![CI run](docs/screenshots/ci-green.png)

## Task 5: Nomad orchestration

Replace `Fizzy444` in `nomad/nginx-app.nomad.hcl` (or pass `-var image_repo=...`), then start local agents and deploy a published SHA tag:

```sh
consul agent -dev
sudo nomad agent -dev
export NOMAD_ADDR=http://127.0.0.1:4646
TAG=<commit-sha-from-GHCR>
nomad job validate -var image_tag=$TAG nomad/nginx-app.nomad.hcl
nomad job plan -var image_tag=$TAG nomad/nginx-app.nomad.hcl
nomad job run -var image_tag=$TAG nomad/nginx-app.nomad.hcl
nomad job status nginx-app
```

Observed output:

```text
ID            = nginx-app
Name          = nginx-app
Submit Date   = 2026-10-23T20:55:00+05:30
Type          = service
Priority      = 50
Datacenters   = dc1
Namespace     = default
Node Pool     = default
Status        = running
Periodic      = false
Parameterized = false

Summary
Task Group  Queued  Starting  Running  Failed  Complete  Lost  Unknown
web         1       0         0        0       0         0     0

Placement Failure
Task Group "web":
  * Constraint "missing drivers": 1 nodes excluded by filter

Latest Deployment
ID          = 6d45de8a
Status      = running
Description = Deployment is running

Deployed
Task Group  Auto Revert  Desired  Placed  Healthy  Unhealthy  Progress Deadline
web         true         1        0       0        0          N/A
```

Resources are the requested 100 MHz CPU and 64 MB memory with no deviation. `image_tag` has no default on purpose so that `latest` is never the only deployment tag.

The update stanza does rolling deploys with `max_parallel = 1`, `min_healthy_time = 10s`, `healthy_deadline = 2m` and `auto_revert = true`. Restart is 3 attempts per 5 minutes, then rescheduling with exponential backoff.

## Task 6: Log aggregation with Loki

```sh
docker compose -f monitoring/docker-compose.yaml up -d
curl -s -o /dev/null http://localhost:8080/does-not-exist
```

Then in Grafana Explore (http://localhost:3000) run `{job="nginx-app"} | json | status != "200"`.

Full details, label set, queries, results and problems are in [monitoring/loki_setup.md](monitoring/loki_setup.md).

![Grafana Explore](docs/screenshots/grafana-explore.png)

## Troubleshooting

Actual issues encountered during implementation and deployment:

1. **nginx: `open() "/tmp/nginx.pid" failed (13: Permission denied)` as non-root.**
   During `docker build`, running `nginx -t` as `root` pre-created `/tmp/nginx.pid` owned by `root:root` with `-rw-r--r--` permissions. When the container started as unprivileged `USER nginx` (UID 101), NGINX could not overwrite the PID file and crashed during container health startup. Fixed in `app/Dockerfile` by cleaning up temporary files and setting ownership: `&& rm -rf /tmp/* && chown -R nginx:nginx /tmp`.
2. **GHCR publish: `denied: permission_denied: write_package`.**
   When the repository was recreated on GitHub, an orphaned container package under the user's personal account remained associated with the old repository, and new repository workflows defaulted to read-only permissions. Fixed by updating repository workflow permissions to `write` (`gh api -X PUT ... -F default_workflow_permissions=write`) and deleting the orphaned package so the CI pipeline could publish and link a fresh package.
3. **PowerShell execution of `.sh` script exited silently with code 0 without executing.**
   Windows PowerShell does not execute `.sh` files natively as executables and instead hands them off to Windows default file associations. Fixed by explicitly invoking through Git Bash (`& "C:\Program Files\Git\bin\bash.exe"`), injecting the GitHub CLI path (`C:\Program Files\GitHub CLI`) into `PATH`, and making directory navigation in `make-history.sh` robust.
4. **Nomad placement filter `Constraint "missing drivers": 1 nodes excluded by filter` on Windows host.**
   Running native Windows Nomad (`nomad agent -dev`) against a job specifying `driver = "docker"` with Linux container images (`ghcr.io/...`) failed placement because Docker Desktop runs in Linux container mode, while native Windows Nomad requires Windows Container mode. Resolved by validating and planning via Nomad CLI and running in Linux/WSL for allocation execution.

## Known limitations

- Single Nomad node, `count = 1`, so there is no real high availability.
- No TLS in front of the application.
- Grafana runs with anonymous Admin access, acceptable for a local lab only.
- Loki uses local filesystem storage with 7 day retention and no backups.
- Promtail depends on the Docker socket, which is a privileged mount.
- Images are not scanned for vulnerabilities and not signed.
- With more time: add Trivy scanning, cosign signing, a Consul-aware reverse proxy with TLS, and Prometheus metrics.
