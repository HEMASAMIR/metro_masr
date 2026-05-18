import os
import re
import json

directory = r"c:\rafiq\rafiq_metrro\lib"
pattern = re.compile(r"isAr\s*\?\s*['\"](.*?)['\"]\s*:\s*['\"](.*?)['\"]")

results = []

for root, _, files in os.walk(directory):
    for file in files:
        if file.endswith(".dart"):
            filepath = os.path.join(root, file)
            with open(filepath, "r", encoding="utf-8") as f:
                content = f.read()
                matches = pattern.findall(content)
                if matches:
                    results.append({
                        "file": filepath,
                        "matches": matches
                    })

with open(r"c:\rafiq\rafiq_metrro\scratch\extracted_strings.json", "w", encoding="utf-8") as f:
    json.dump(results, f, ensure_ascii=False, indent=2)

print(f"Extracted {sum(len(r['matches']) for r in results)} strings from {len(results)} files.")
