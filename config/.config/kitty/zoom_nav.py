import re
from kittens.tui.handler import result_handler

def main(args):
    pass

@result_handler(no_ui=True)
def handle_result(args, answer, target_window_id, boss):
    direction = args[1]
    tab = boss.active_tab
    if tab is None:
        return

    in_stack = tab.current_layout.name == "stack"

    # Map direction to neighboring_window action
    direction_map = {
        "left":  "left",
        "right": "right",
        "up":    "top",
        "down":  "bottom",
    }

    if in_stack:
        # Switch to splits temporarily, move focus, switch back to stack
        tab.goto_layout("splits")
        w = tab.neighboring_window(direction_map[direction])
        tab.goto_layout("stack")
    else:
        tab.neighboring_window(direction_map[direction])
