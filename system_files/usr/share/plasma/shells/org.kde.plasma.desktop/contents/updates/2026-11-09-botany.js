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
            "io.github.kolunmi.Bazaar",
        ];
        for (const item of hiddenItemsToAdd) {
            if (!hiddenItems.includes(item))
                hiddenItems.push(item);
        }
        widget.writeConfig("hiddenItems", hiddenItems);
        widget.reloadConfig();
    }
}

{
    const config = ConfigFile("PlasmaUserFeedback", "Global");
    if (config.readEntry("FeedbackLevel") != 64) {
        config.writeEntry("FeedbackLevel", 64);
    }
}
