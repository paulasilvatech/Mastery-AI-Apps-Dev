# 📁 Content Directory Guide

This directory should contain all the original module content files that need to be restored.

## Expected File Structure

Place your original files here following this naming pattern:

```
content/
├── module-01-README.md                   # Main module overview
├── module-01-prerequisites.md            # Prerequisites
├── module-01-best-practices.md           # Best practices
├── module-01-troubleshooting.md          # Troubleshooting guide
├── module-01-exercise1-part1.md          # Exercise 1 instructions (part 1)
├── module-01-exercise1-part2.md          # Exercise 1 instructions (part 2)
├── module-01-exercise1-part3.md          # Exercise 1 instructions (part 3)
├── module-01-exercise1-solution.py       # Exercise 1 solution
├── module-01-exercise1-starter.py        # Exercise 1 starter code
├── module-01-exercise2-part1.md          # Exercise 2 instructions (part 1)
├── module-01-exercise2-part2.md          # Exercise 2 instructions (part 2)
├── module-01-exercise2-part3.md          # Exercise 2 instructions (part 3)
├── module-01-exercise2-solution.py       # Exercise 2 solution
├── module-01-exercise3-part1.md          # Exercise 3 instructions (part 1)
├── module-01-exercise3-part2.md          # Exercise 3 instructions (part 2)
├── module-01-exercise3-part3.md          # Exercise 3 instructions (part 3)
├── module-01-common-patterns.md          # Common patterns reference
├── module-01-prompt-templates.md         # AI prompt templates
├── module-01-utils.py                    # Utility functions
├── module-01-setup-script.sh             # Setup script
├── module-02-README.md                   # Module 2 files...
└── ... (continue for all 30 modules)
```

## File Naming Convention

**IMPORTANT**: Files must follow this naming pattern:
- `module-XX-` prefix (where XX is 01-30)
- Descriptive name
- Appropriate extension (.md, .py, .sh, etc.)

## Automatic Mapping

The restoration scripts will automatically map files to the correct locations:

| File Pattern | Destination |
|--------------|-------------|
| `module-XX-README.md` | `modules/module-XX/README.md` |
| `module-XX-exercise1-part1.md` | `modules/module-XX/exercises/exercise1-easy/instructions/part1.md` |
| `module-XX-exercise1-solution.py` | `modules/module-XX/exercises/exercise1-easy/solution/solution.py` |
| `module-XX-best-practices.md` | `modules/module-XX/best-practices.md` |
| `module-XX-utils.py` | `modules/module-XX/resources/utils.py` |

## Quick Setup

1. Copy all your original module files into this directory
2. Ensure they follow the naming convention
3. Run the restoration script from the repository root:
   ```bash
   cd ..
   ./ONE_COMMAND_FIX.sh
   ```

## Troubleshooting

If files aren't being restored correctly:
1. Check the file naming follows the pattern exactly
2. Ensure no spaces in filenames (use hyphens)
3. Module numbers must be two digits (01, not 1)
4. Check the restoration reports for details

## Need Help?

Run the smart restore script for detailed mapping info:
```bash
python3 ../scripts/smart-restore.py
```

This will generate a detailed report showing where each file was placed.
