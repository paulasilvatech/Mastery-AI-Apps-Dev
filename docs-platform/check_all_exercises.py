#!/usr/bin/env python3
"""
Check if all modules have all 3 exercises with all parts
"""

from pathlib import Path
import json

def check_module_completeness():
    """Check if all modules have complete exercise structure"""
    
    base_path = Path("/Users/paulasilva/Documents/paulasilvatech/GH-Repos/Mastery-AI-Apps-Dev/docs-platform/docs/modules")
    
    # Expected files for each module
    expected_files = [
        "index.md",
        "prerequisites.md",
        "best-practices.md",
        # Exercise 1
        "exercise1-overview.md",
        "exercise1-part1.md", 
        "exercise1-part2.md",
        "exercise1-part3.md",
        # Exercise 2
        "exercise2-overview.md",
        "exercise2-part1.md",
        "exercise2-part2.md", 
        "exercise2-part3.md",
        # Exercise 3
        "exercise3-overview.md",
        "exercise3-part1.md",
        "exercise3-part2.md",
        "exercise3-part3.md"
    ]
    
    results = {}
    all_complete = True
    
    # Check each module
    for i in range(1, 31):
        module_dir = base_path / f"module-{i:02d}"
        module_results = {
            "exists": module_dir.exists(),
            "files": {},
            "missing_files": [],
            "complete": True
        }
        
        if module_dir.exists():
            # Check each expected file
            for expected_file in expected_files:
                file_path = module_dir / expected_file
                file_exists = file_path.exists()
                module_results["files"][expected_file] = file_exists
                
                if not file_exists:
                    module_results["missing_files"].append(expected_file)
                    module_results["complete"] = False
                    all_complete = False
        else:
            module_results["complete"] = False
            all_complete = False
            
        results[f"module-{i:02d}"] = module_results
    
    # Print summary
    print("📊 MODULE COMPLETENESS CHECK")
    print("=" * 50)
    
    for module, data in results.items():
        if data["complete"]:
            print(f"✅ {module}: Complete - All 16 files present")
        else:
            print(f"❌ {module}: Incomplete")
            if not data["exists"]:
                print(f"   └─ Module directory doesn't exist")
            elif data["missing_files"]:
                print(f"   └─ Missing {len(data['missing_files'])} files:")
                for missing in data["missing_files"][:5]:  # Show first 5
                    print(f"      - {missing}")
                if len(data["missing_files"]) > 5:
                    print(f"      ... and {len(data['missing_files']) - 5} more")
    
    # Summary statistics
    print("\n📈 SUMMARY")
    print("=" * 50)
    complete_count = sum(1 for m in results.values() if m["complete"])
    print(f"Complete modules: {complete_count}/30")
    print(f"Incomplete modules: {30 - complete_count}/30")
    
    # List incomplete modules
    if not all_complete:
        print("\n⚠️  Incomplete modules:")
        for module, data in results.items():
            if not data["complete"]:
                print(f"  - {module}")
    
    # Save detailed report
    report_path = base_path.parent / "module_completeness_report.json"
    with open(report_path, 'w') as f:
        json.dump(results, f, indent=2)
    print(f"\n📄 Detailed report saved to: {report_path}")
    
    return all_complete, results

if __name__ == "__main__":
    check_module_completeness()