# Expected Behavior

## Triggering prompts

- The skill asks 1-3 high-leverage clarification questions unless the user asked to skip questions.
- The skill classifies the project as S/M/L or asks one sizing question if unclear.
- The skill never asks more than two interview rounds before producing a draft.
- The draft includes success metrics, In/Out scope, decision owner, milestones/gates, risks, and TBD items.
- If the user asks for PR/FAQ or working backwards, the output starts from customer value and includes FAQ.
- If the project is AI/model/data related, the output includes eval, staged rollout, and failure/safety analysis.

## Non-triggering prompts

- Weekly task planning should be handled as normal planning, not a kickoff packet.
- Bug fixing should use normal engineering workflow, not project charter templates.
- Copywriting and meeting summary prompts should not invoke this skill unless the user explicitly asks to launch a project.

## Boundary prompts

- For "我想做一个 AI 产品", ask about target user, problem, success metric, and constraints.
- For urgent but incomplete information, output assumptions plus `TBD（负责人 / 截止日）` instead of pretending the information is complete.
