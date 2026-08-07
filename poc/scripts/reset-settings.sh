#!/usr/bin/env bash
set -euo pipefail

KEYS=(
  "ContextDiscovery.SelectedOllamaModel"
  "ContextDiscovery.SelectedProvider"
  "ContextDiscovery.SelectedCodexModel"
  "ContextDiscovery.SelectedOpenRouterModel"
  "ContextDiscovery.MyLanguage"
  "ContextDiscovery.TheirLanguage"
  "ContextDiscovery.ShowsMenuBarItem"
  "ContextDiscovery.Shortcut.KeyCode"
  "ContextDiscovery.Shortcut.Modifiers"
  "ContextDiscovery.FirstLaunchCompleted"
  "ContextDiscovery.OpenRouter.HasAPIKey"
  "ContextDiscovery.BubblePanel.size"
  "ContextDiscovery.ExplainTextPaneWidth"
  "NSWindow Frame ContextDiscovery.AssistantPanel"
)

DOMAINS=(
  "ContextTranslatePOC"
  "context-translate-poc"
  "ContextTranslateDiscovery"
  "context-translate-discovery"
)

for domain in "${DOMAINS[@]}"; do
  for key in "${KEYS[@]}"; do
    defaults delete "$domain" "$key" >/dev/null 2>&1 || true
  done
done

security delete-generic-password \
  -s "ContextTranslateDiscovery.OpenRouter" \
  -a "apiKey" \
  >/dev/null 2>&1 || true

echo "POC settings reset. Quit and relaunch the POC to see the first-launch state."
