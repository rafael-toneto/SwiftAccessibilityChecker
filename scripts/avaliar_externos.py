#!/usr/bin/env python3
"""Reproduz a análise inicial a partir da amostra congelada, sem executar código externo."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
SAMPLE = ROOT / "docs/avaliacao/amostra.json"
EXTERNAL = ROOT.parent / "ProjetosExternos"


def git_head(directory):
    return subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=directory, text=True).strip()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("checker", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    checker = args.checker.resolve(strict=True)
    output = args.output.resolve()
    if EXTERNAL in output.parents:
        parser.error("a saída deve permanecer fora dos clones externos")
    sample = json.loads(SAMPLE.read_text(encoding="utf-8"))
    output.mkdir(parents=True, exist_ok=True)
    run = {
        "checkerGitHead": git_head(ROOT),
        "sampleProtocolCommit": sample["protocolCommit"],
        "date": sample["selectionDate"],
        "platform": platform.platform(),
        "swift": subprocess.run(["swift", "--version"], capture_output=True, text=True).stdout.strip(),
        "xcode": subprocess.run(["xcodebuild", "-version"], capture_output=True, text=True).stdout.strip(),
        "developerDir": os.environ.get("DEVELOPER_DIR", ""),
        "projects": [],
    }
    for project in sample["projects"]:
        folder = EXTERNAL / project["id"]
        if git_head(folder) != project["commit"]:
            raise RuntimeError(f"commit alterado: {project['id']}")
        files = []
        for entry in project["files"]:
            path = folder / entry["path"]
            if hashlib.sha256(path.read_bytes()).hexdigest() != entry["sha256"]:
                raise RuntimeError(f"arquivo alterado: {path}")
            files.append(str(path))
        destination = output / project["id"]
        destination.mkdir(parents=True, exist_ok=True)
        report = destination / "report.json"
        command = [str(checker), "--format", "json", "--output", str(report), "--", *files]
        (destination / "command.json").write_text(json.dumps(command, indent=2, ensure_ascii=False) + "\n")
        completed = subprocess.run(command, capture_output=True, text=True)
        (destination / "stdout.txt").write_text(completed.stdout)
        (destination / "stderr.txt").write_text(completed.stderr)
        run["projects"].append({"id": project["id"], "exitCode": completed.returncode,
                                "analyzedFiles": len(files), "report": str(report)})
        print(project["id"], "exit", completed.returncode, "files", len(files))
    (output / "execucao.json").write_text(json.dumps(run, indent=2, ensure_ascii=False) + "\n")
    return 0 if all(p["exitCode"] == 0 for p in run["projects"]) else 1


if __name__ == "__main__":
    sys.exit(main())
