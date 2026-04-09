import argparse
import json
import os
from pathlib import Path
from typing import Any, List

from openlane.common import get_opdks_rev
from openlane.flows.misc import OpenInKLayout
from openlane.flows.classic import Classic
from openlane.steps.odb import OdbpyStep
from openlane.steps import OpenROAD
import volare


class CustomPower(OdbpyStep):
    id = "TT.Top.CustomPower"
    name = "Custom Power connections for RAM32 macro"

    def get_script_path(self):
        return os.path.join(os.path.dirname(__file__), "odb_power.py")

    def get_command(self) -> List[str]:
        macro = self.config["MACROS"]["RAM32"]
        instance = macro.instances["memory.ram_macro"]
        return super().get_command() + [
            "--macro-x-pos", str(instance.location[0]),
        ]


class ProjectFlow(Classic):
    pass


def rewrite_path_string(s: str) -> str:
    # 1) Fix tt_tool-generated paths that escape src/ with ../tt/...
    if s.startswith("./../tt/"):
        return "tt/" + s[len("./../tt/"):]
    if s.startswith("../tt/"):
        return "tt/" + s[len("../tt/"):]

    # 2) Fix dir:: paths that were originally intended to be relative to src/
    if s.startswith("dir::"):
        inner = s[len("dir::"):]
        if inner.startswith("src/") or inner.startswith("tt/") or inner.startswith("/"):
            return s
        return "dir::src/" + inner

    return s


def rewrite_obj(obj: Any) -> Any:
    if isinstance(obj, dict):
        return {k: rewrite_obj(v) for k, v in obj.items()}
    if isinstance(obj, list):
        return [rewrite_obj(v) for v in obj]
    if isinstance(obj, str):
        return rewrite_path_string(obj)
    return obj


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument(
        "--open-in-klayout",
        action="store_true",
        help="Open the last run in KLayout",
    )
    args = parser.parse_args()

    ProjectFlow.Steps.insert(
        ProjectFlow.Steps.index(OpenROAD.GeneratePDN) + 1,
        CustomPower
    )

    pdk_root = volare.get_volare_home(os.getenv("PDK_ROOT"))
    volare.enable(pdk_root, "sky130", get_opdks_rev())

    src_cfg = Path("src/config_merged.json")
    patched_cfg = Path("build_config.json")

    with src_cfg.open("r", encoding="utf-8") as f:
        cfg = json.load(f)

    cfg = rewrite_obj(cfg)

    with patched_cfg.open("w", encoding="utf-8") as f:
        json.dump(cfg, f, indent=2, ensure_ascii=False)
        f.write("\n")

    flow_class = OpenInKLayout if args.open_in_klayout else ProjectFlow
    flow = flow_class(
        str(patched_cfg),
        design_dir=".",
        pdk_root=pdk_root,
        pdk="sky130A",
    )
    flow.start(tag="wokwi")