# KIRO Spec Command Template

## Directory Structure
```
docs/kiro_specs/
├── 000_template.md (this file)
├── 001_<theme_name>/
│   ├── 001_requirements.md
│   ├── 002_design.md
│   ├── 003_tasks.md
│   └── 004_summary.md
├── 002_<theme_name>/
│   └── ...
└── 003_<theme_name>/
    └── ...
```

## Naming Convention
- Directory: `<3-digit-number>_<theme_name>` (e.g., `001_chat_persistence`)
- Files: `<3-digit-number>_<document_type>.md` (e.g., `001_requirements.md`)

## Document Types (in order)
1. `001_requirements.md` - Requirements analysis
2. `002_design.md` - Technical design
3. `003_tasks.md` - Implementation tasks
4. `004_summary.md` - Executive summary

## Helper Functions for Commands

```bash
# Function to get next directory number
get_next_kiro_dir() {
  local last_num=$(ls -1 docs/kiro_specs/ | grep -E '^[0-9]{3}_' | sort -n | tail -1 | cut -d'_' -f1)
  if [ -z "$last_num" ]; then
    echo "001"
  else
    # Remove leading zeros and increment
    local next=$((10#$last_num + 1))
    printf "%03d" $next
  fi
}

# Function to create KIRO spec directory
create_kiro_spec() {
  local theme_name=$1
  local dir_num=$(get_next_kiro_dir)
  local dir_path="docs/kiro_specs/${dir_num}_${theme_name}"
  
  mkdir -p "$dir_path"
  echo "$dir_path"
}

# Usage example in commands:
# SPEC_DIR=$(create_kiro_spec "chat_persistence")
# echo "# Requirements" > "$SPEC_DIR/001_requirements.md"
```

## Location Note
All KIRO specification documents are now stored permanently in `docs/kiro_specs/` instead of the temporary `.tmp/` directory.