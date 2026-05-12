for (const panel of panels()) {
    for (const widget of panel.widgets()) {
        if (widget.type === "org.kde.plasma.systemtray") {
            widget.currentConfigGroup = ["General"];
            print(widget.type + "\n");
            print(widget.readConfig("hiddenItems") + "\n");
            const hiddenItems = widget.readConfig("hiddenItems").split(",");
            const hiddenItemsToAdd = [
                "KopiaUI_status_icon_1",
                "Sigillum Monitor",
            ];
            hiddenItemsToAdd.forEach(i => { if (!hiddenItems.includes(i)) hiddenItems.push(i); });
            widget.writeConfig("hiddenItems", hiddenItems);
            widget.reloadConfig();
        }
    }
}
