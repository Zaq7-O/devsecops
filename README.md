# Three-Tier AWS Architecture (Terraform + ECS + RDS)

## Overview

This repository contains a secure, scalable, three-tier AWS architecture implemented with Terraform. The architecture includes:

- VPC with multiple subnets (public, private, isolated) across two Availability Zones
- Application tier: ECS Fargate running the provided Next.js application
- Presentation tier: Internet-facing Application Load Balancer (ALB)
- Data tier: Multi-AZ PostgreSQL RDS deployment in isolated subnets

All infrastructure is validated locally—no real AWS resources are provisioned, ensuring zero cost. Docker Compose is used to demonstrate local proof-of-life.

## Architecture Decisions and Trade-offs

- **Three-tier architecture:** Segregates presentation, application, and data tiers to enforce security boundaries.
- **ALB in public subnets:** Handles all incoming internet traffic. This is intentional to allow public access to the app.
- **ECS Fargate for application tier:** Serverless container deployment for reduced operational overhead and automatic scaling.
- **RDS in isolated subnets:** Ensures no direct internet access; multi-AZ deployment provides high availability.

**Trade-offs:**
- NAT Gateways deployed per public subnet for redundancy; increases cost slightly but ensures high availability.
- ECS Fargate chosen for simplicity and scalability, though EC2 self-managed containers may be slightly more cost-efficient.

## Security Considerations

### Network security
- Public subnets host ALB only.
- Private subnets host ECS tasks; outbound internet via NAT Gateway.
- Isolated subnets host RDS; no internet access.
- ALB exposure: ALB is intentionally internet-facing to serve application traffic.

### RDS security
- `publicly_accessible = false`
- Storage encryption enabled
- Security group allows inbound PostgreSQL traffic only from ECS tasks

### ECS security
- Security group allows inbound traffic on port 3000 from ALB only
- Outbound traffic restricted to RDS (port 5432) and HTTPS endpoints
- DNS resolution enabled

### Secrets management
- Database credentials stored in AWS Secrets Manager, never hardcoded.

### Container security
- Dockerfile linted with hadolint
- Container scanned with Trivy; base image pinned to specific versions

### CI/CD security
- GitHub Actions workflows use pinned versions
- GHCR authentication via GITHUB_TOKEN
- gitleaks ensures no secrets committed

## Scanner Findings Skipped

**Public ALB (aws-elb-alb-not-public):**
- The Application Load Balancer is intentionally public to serve internet-facing traffic for the application tier.
- Documented in the ALB module with a `# tfsec:ignore` comment and justification.

All other tfsec, checkov, and Trivy scans passed with no critical or high findings. Any remaining low or medium findings have been reviewed and addressed.

## Local Proof-of-Life (Docker Compose)

The application has been validated locally using Docker Compose.

### Verification

After running:

```sh
docker compose up
curl http://localhost:3000/api/db-check
```

Expected output (replace with your screenshot/terminal output):

```
Database connection successful!
```
![alt text](<Screenshot 2026-02-21 at 9.08.23 AM.png>)

## CI/CD

### PR workflow
- Terraform checks (fmt, init -backend=false, validate, tflint, checkov/tfsec)
- Dockerfile linting with hadolint
- Docker image build and Trivy scan
- Application security audit (npm audit or trivy fs)
- Secret detection via gitleaks
- Docker Compose test of db-check endpoint

### Merge workflow
- Includes all PR checks
- Builds and pushes Docker image to GitHub Container Registry (GHCR) with SHA and latest tag

## Notes / Justification

- All infrastructure code is validated locally—no terraform apply has been executed.
- Public ALB is the only intentional exception to tfsec rules; documented inline.

## Workflow Compatibility Note

**gitleaks-action@v2 usage:**

The GitHub Actions workflows use `gitleaks-action@v2` for secret scanning. As of early 2026, the correct input for specifying files or directories to scan is `scan-paths` (not `scan-args`).

If you update or troubleshoot the workflow, ensure the gitleaks step uses:

```yaml
      - uses: gitleaks/gitleaks-action@v2
        with:
          scan-paths: .
          github-token: ${{ secrets.GITHUB_TOKEN }}
```

See [gitleaks-action documentation](https://github.com/gitleaks/gitleaks-action) for details.
