---
name: trigger-api-contract-design
tags: [triggers]
max_turns: 4
allowed_tools: [Read, Glob, Grep, Skill]
---
I need to add an optional `nickname` field to the `POST /users` response and rename `fullName` to `name` without breaking the existing React Native client. How should I shape the DTOs, validation and error responses between our NestJS API and the clients?
