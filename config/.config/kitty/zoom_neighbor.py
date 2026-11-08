from kittens.tui.handler import result_handler


def main():
    pass


@result_handler(no_ui=True)
def handle_result(args, result, target_window_id, boss):
    tab = boss.active_tab
    if tab is None:
        return

    was_zoomed = tab.current_layout.name == "stack"
    if was_zoomed:
        tab.goto_layout("splits")

    previous_window = tab.active_window
    tab.neighboring_window(args[1])
    if tab.active_window is previous_window:
        if was_zoomed:
            tab.goto_layout("stack")
    elif not was_zoomed:
        tab.goto_layout("stack")
