---
name: trigger-iam-least-privilege
tags: [triggers]
max_turns: 4
allowed_tools: [Read, Glob, Grep, Skill]
---
I need an IAM role for a Lambda that only reads from one S3 bucket and writes to one DynamoDB table. Write the policy so it has the minimum permissions.
