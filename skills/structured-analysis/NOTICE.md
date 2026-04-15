# Structured Analysis Skill -- Attribution & Modifications

**Original:** https://github.com/Blevene/structured-analysis-skill
**License:** Apache 2.0 (see LICENSE)
**Integrated:** 2026-04-03

## Modifications from upstream

1. **Output path override** -- All `analyses/{{ANALYSIS_ID}}/` paths replaced with `{{ANALYSIS_DIR}}` variable, resolved to active Q investigation case folder
2. **Skill directory variable** -- Added `{{SKILL_DIR}}` resolution for subagent path access
3. **Firecrawl removed** -- All Firecrawl MCP references replaced with WebSearch + WebFetch (we use Apify/Exa/Jina for deep OSINT via separate Q skill)
4. **Tool naming** -- "Task tool" / "Task subagent" replaced with "Agent tool" / "Agent subagent" to match Claude Code tool names
5. **Subagent substitution lists** -- Made explicit in all prompt templates (evidence-collector, report-generator, orchestrator)
6. **Library relocated** -- `docs/library/` copied to `library/` within skill directory; internal references updated
7. **Q investigation integration** -- Added to SKILL.md: output path override, Tier 2 evidence integration with case directories, feedback loop (Step 8 in report-generator)
8. **Active case tracking** -- Path resolution reads from `./.active-case`
9. **Evidence collector Tier 2** -- Added explicit Q case directory search paths
10. **Meta template** -- "Firecrawl Available" field replaced with "Collection Method"
