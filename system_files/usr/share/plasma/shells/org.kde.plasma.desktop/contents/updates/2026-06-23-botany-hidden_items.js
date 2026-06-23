for (const panel of panels()) {
    for (const widget of panel.widgets("org.kde.plasma.systemtray")) {
        widget.currentConfigGroup = ["General"];
        //print(widget.type + "\n");
        //print(widget.readConfig("hiddenItems") + "\n");
        const hiddenItems = widget.readConfig("hiddenItems").split(",");
        const hiddenItemsToAdd = [
            "KopiaUI_status_icon_1",
            "Sigillum Monitor",
            "org.gnome.World.PikaBackup",
        ];
        for (const item of hiddenItemsToAdd) {
            if (!hiddenItems.includes(item))
                hiddenItems.push(item);
        }
        widget.writeConfig("hiddenItems", hiddenItems);
        widget.reloadConfig();
    }
}
