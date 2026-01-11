#!/bin/bash
# Read CTO Be Growth plugin settings from .claude/cto-begrowth.local.md
# Usage: source read-settings.sh
#        if [[ "$CTO_ENABLED" != "true" ]]; then exit 0; fi

STATE_FILE=".claude/cto-begrowth.local.md"

# Default values
CTO_ENABLED="true"
CTO_POST_WRITE_VALIDATION="true"
CTO_STOP_CONSISTENCY_CHECK="true"
CTO_SESSION_START_CHECK="true"
CTO_DEFAULT_EMPRESA="holding"
CTO_USE_BOXES="true"
CTO_SHOW_ALERTS="true"
CTO_VERBOSE="false"
CTO_NOTIFICATION_LEVEL="info"
CTO_AUTO_INDEX_UPDATE="true"
CTO_LANGUAGE="pt-BR"

# If settings file exists, parse it
if [[ -f "$STATE_FILE" ]]; then
  FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$STATE_FILE")

  # Parse enabled
  VALUE=$(echo "$FRONTMATTER" | grep '^enabled:' | sed 's/enabled: *//')
  [[ -n "$VALUE" ]] && CTO_ENABLED="$VALUE"

  # Parse hooks settings
  VALUE=$(echo "$FRONTMATTER" | grep 'post_write_validation:' | sed 's/.*post_write_validation: *//')
  [[ -n "$VALUE" ]] && CTO_POST_WRITE_VALIDATION="$VALUE"

  VALUE=$(echo "$FRONTMATTER" | grep 'stop_consistency_check:' | sed 's/.*stop_consistency_check: *//')
  [[ -n "$VALUE" ]] && CTO_STOP_CONSISTENCY_CHECK="$VALUE"

  VALUE=$(echo "$FRONTMATTER" | grep 'session_start_check:' | sed 's/.*session_start_check: *//')
  [[ -n "$VALUE" ]] && CTO_SESSION_START_CHECK="$VALUE"

  # Parse default empresa
  VALUE=$(echo "$FRONTMATTER" | grep '^default_empresa:' | sed 's/default_empresa: *//')
  [[ -n "$VALUE" ]] && CTO_DEFAULT_EMPRESA="$VALUE"

  # Parse output settings
  VALUE=$(echo "$FRONTMATTER" | grep 'use_boxes:' | sed 's/.*use_boxes: *//')
  [[ -n "$VALUE" ]] && CTO_USE_BOXES="$VALUE"

  VALUE=$(echo "$FRONTMATTER" | grep 'show_alerts:' | sed 's/.*show_alerts: *//')
  [[ -n "$VALUE" ]] && CTO_SHOW_ALERTS="$VALUE"

  VALUE=$(echo "$FRONTMATTER" | grep 'verbose:' | sed 's/.*verbose: *//')
  [[ -n "$VALUE" ]] && CTO_VERBOSE="$VALUE"

  # Parse notification level
  VALUE=$(echo "$FRONTMATTER" | grep '^notification_level:' | sed 's/notification_level: *//')
  [[ -n "$VALUE" ]] && CTO_NOTIFICATION_LEVEL="$VALUE"

  # Parse auto index update
  VALUE=$(echo "$FRONTMATTER" | grep '^auto_index_update:' | sed 's/auto_index_update: *//')
  [[ -n "$VALUE" ]] && CTO_AUTO_INDEX_UPDATE="$VALUE"

  # Parse language
  VALUE=$(echo "$FRONTMATTER" | grep '^language:' | sed 's/language: *//')
  [[ -n "$VALUE" ]] && CTO_LANGUAGE="$VALUE"

  # Extract body (context notes)
  CTO_CONTEXT=$(awk '/^---$/{i++; next} i>=2' "$STATE_FILE")
fi

# Export all variables
export CTO_ENABLED CTO_POST_WRITE_VALIDATION CTO_STOP_CONSISTENCY_CHECK CTO_SESSION_START_CHECK
export CTO_DEFAULT_EMPRESA CTO_USE_BOXES CTO_SHOW_ALERTS CTO_VERBOSE
export CTO_NOTIFICATION_LEVEL CTO_AUTO_INDEX_UPDATE CTO_LANGUAGE CTO_CONTEXT
