# aws-skills

Claude Code skills for working with AWS serverless infrastructure. Each skill is a self-contained `SKILL.md` that Claude reads on demand to apply consistent, least-privilege, cost-aware patterns.

## Skills

| Skill | When to load |
|-------|-------------|
| [`serverless-scanner`](./serverless-scanner/SKILL.md) | Analyzing existing products to identify high-ROI serverless migration opportunities |
| [`sam-deploy`](./sam-deploy/SKILL.md) | Building and deploying stacks with AWS SAM CLI — `samconfig.toml`, build/deploy pipeline, response streaming, common errors |
| [`lambda-patterns`](./lambda-patterns/SKILL.md) | Writing Lambda handlers — arm64, memory sizing, cold starts, ESM, Python, CloudWatch logs, error handling |
| [`iam-least-privilege`](./iam-least-privilege/SKILL.md) | Creating IAM users/roles/policies — deploy-user pattern, execution roles, policy templates, setup scripts |
| [`cost-optimizer`](./cost-optimizer/SKILL.md) | Keeping AWS costs minimal — free tier, arm64, log retention, billing alarms, cost traps |

## Usage in CLAUDE.md

```md
## AWS Skills

Before writing any AWS infrastructure, SAM template, Lambda handler, or IAM policy:
- Deployments: read `~/projects/aws-skills/sam-deploy/SKILL.md`
- Lambda code: read `~/projects/aws-skills/lambda-patterns/SKILL.md`
- IAM policies: read `~/projects/aws-skills/iam-least-privilege/SKILL.md`
- Cost review: read `~/projects/aws-skills/cost-optimizer/SKILL.md`
- Migration analysis: read `~/projects/aws-skills/serverless-scanner/SKILL.md`
```

## Setup on a new machine

```bash
git clone https://github.com/LorenGrz/aws-skills ~/projects/aws-skills
```

Then update `~/.claude/CLAUDE.md` to reference the paths above.
