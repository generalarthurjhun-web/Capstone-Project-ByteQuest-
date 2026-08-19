# ByteQuest Dashboard Override

This project is an authenticated TESDA-aligned EdTech operations product, not a landing page or Smart Home dashboard. The established ByteQuest visual world in `ByteQuest Web Dashboard/src/app/globals.css` takes precedence over the generated generic page pattern.

## Preserve

- Plus Jakarta Sans from the existing application shell.
- Existing HSL design tokens: electric blue primary, slate foreground, white cards, soft slate borders, semantic success/warning/destructive colors.
- Existing 240px desktop navigation and mobile Sheet pattern.
- 12â€“16px surface radii, restrained 1px borders, and offset soft shadows only where elevation is required.

## Dashboard composition

- Use a compact page heading and one sentence of operational context.
- Use real counts and states only; never synthesize charts, trends, scores, names, or percentage changes.
- Prefer a small metric strip followed by task-oriented tables/lists and explicit empty states.
- Keep Admin governance and Instructor teaching actions in separate navigation trees and pages.
- Present `PENDING_TESDA_VALIDATION` as a blocking governance state, not as a warning that can be ignored.
- Tables must remain readable at 375px through stacked rows or deliberate horizontal overflow with a visible affordance.

## Interaction and accessibility

- Minimum 44px touch targets for primary actions on narrow screens.
- Visible labels, inline validation, disabled/loading states, and recovery-oriented errors.
- Never rely on color alone; pair status colors with text and Lucide icons.
- Keep keyboard focus visible and respect reduced motion.
- No decorative animations; use only subtle state transitions in the 150â€“250ms range.


