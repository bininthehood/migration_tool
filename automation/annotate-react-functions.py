#!/usr/bin/env python3
import argparse
import os
import re
from pathlib import Path

PHRASES = {
    "legacy": "마이그레이션된 React 흐름을 처리합니다.",
    "parse": "입력 데이터를 파싱합니다.",
    "decode": "인코딩된 값을 디코딩합니다.",
    "encode": "값을 인코딩합니다.",
    "read": "필요한 데이터를 조회합니다.",
    "map": "표시/처리용 데이터 형태로 변환합니다.",
    "build": "요청/표시용 데이터를 생성합니다.",
    "ui": "화면 상태 또는 팝업 동작을 제어합니다.",
    "event": "사용자 이벤트를 처리합니다.",
    "state": "상태값을 갱신하거나 목록을 조정합니다.",
    "condition": "조건 충족 여부를 판별합니다.",
    "validate": "실행 조건 또는 유효성을 점검합니다.",
    "default": "해당 화면의 핵심 로직을 수행합니다.",
}

PREFIX_MAP = [
    (re.compile(r"^parse"), "parse"),
    (re.compile(r"^decode"), "decode"),
    (re.compile(r"^encode"), "encode"),
    (re.compile(r"^(load|fetch|get|select)"), "read"),
    (re.compile(r"^(map|normalize|format|to)"), "map"),
    (re.compile(r"^(build|create)"), "build"),
    (re.compile(r"^(open|close|toggle)"), "ui"),
    (re.compile(r"^(onclick|onsubmit|onchange|onsearch|onprocess|oncreate|on|handle)"), "event"),
    (re.compile(r"^(set|update|apply|move|remove|add)"), "state"),
    (re.compile(r"^(is|has|can|should)"), "condition"),
    (re.compile(r"^(wait|check|verify|validate)"), "validate"),
]

FUNC_PATTERNS = [
    re.compile(r"^(?:export\s+)?function\s+([A-Za-z_][A-Za-z0-9_]*)\s*\("),
    re.compile(r"^(?:export\s+)?const\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(?:async\s+)?\([^)]*\)\s*=>"),
    re.compile(r"^(?:export\s+)?const\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(?:async\s+)?function\s*\("),
]

GENERATED_COMMENT = re.compile(r"^//\s*([A-Za-z_][A-Za-z0-9_]*):\s+(.+)$")


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--project-root", default=os.getcwd())
    parser.add_argument("--target-root", default="src/main/frontend/src")
    return parser.parse_args()


def find_js_files(target_root: Path):
    for path in target_root.rglob("*.js"):
        path_str = str(path)
        if any(part in {"node_modules", "build", "dist"} for part in path.parts):
            continue
        if path_str.endswith(".min.js") or ".bak" in path.name:
            continue
        yield path


def is_generated_comment(line: str) -> bool:
    match = GENERATED_COMMENT.match(line.strip())
    if not match:
      return False
    suffix = match.group(2).strip()
    if suffix == "handles migrated React flow logic.":
        return True
    if suffix in PHRASES.values():
        return True
    return "React" in suffix


def get_top_level_func(line: str, brace_depth: int):
    if brace_depth != 0 or line[:1].isspace():
        return None
    for pattern in FUNC_PATTERNS:
        match = pattern.match(line)
        if match:
            return match.group(1)
    return None


def has_comment_before(output):
    for candidate in reversed(output):
        trimmed = candidate.strip()
        if not trimmed:
            continue
        return trimmed.startswith("//") or trimmed.startswith("/*") or trimmed.startswith("*")
    return False


def get_suffix(func_name: str) -> str:
    lowered = func_name.lower()
    for pattern, key in PREFIX_MAP:
        if pattern.search(lowered):
            return PHRASES[key]
    return PHRASES["default"]


def read_text(path: Path) -> tuple[str, str]:
    text = path.read_text(encoding="utf-8")
    newline = "\r\n" if "\r\n" in text else "\n"
    return text, newline


def process_file(js_file: Path):
    original, newline = read_text(js_file)
    lines = original.splitlines()
    output = []
    brace_depth = 0
    comments_added = 0

    for line in lines:
        if is_generated_comment(line):
            continue
        func_name = get_top_level_func(line, brace_depth)
        if func_name and not has_comment_before(output):
            output.append(f"// {func_name}: {get_suffix(func_name)}")
            comments_added += 1
        output.append(line)
        brace_depth += line.count("{") - line.count("}")
        if brace_depth < 0:
            brace_depth = 0

    rewritten = newline.join(output)
    if original.endswith("\n"):
        rewritten += newline

    if rewritten != original:
        js_file.write_text(rewritten, encoding="utf-8", newline="")
        return True, comments_added
    return False, 0


def main():
    args = parse_args()
    target_root = Path(args.project_root) / args.target_root
    if not target_root.exists():
        raise SystemExit(f"Target root not found: {target_root}")

    files_changed = 0
    comments_added = 0
    for js_file in find_js_files(target_root):
        changed, added = process_file(js_file)
        if changed:
            files_changed += 1
            comments_added += added

    print(f"ANNOTATE_FILES_CHANGED={files_changed}")
    print(f"ANNOTATE_COMMENTS_ADDED={comments_added}")


if __name__ == "__main__":
    main()
