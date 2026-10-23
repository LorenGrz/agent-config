---
name: trigger-debug-assistant
tags: [triggers]
max_turns: 4
allowed_tools: [Read, Glob, Grep, Skill]
---
I'm getting this when I hit the checkout endpoint: `TypeError: Cannot read properties of undefined (reading 'items')` at `CartService.total (cart.service.ts:42)`. The line is `return cart.items.reduce((s, i) => s + i.price, 0)`. Why does it fail and what's the smallest fix?
