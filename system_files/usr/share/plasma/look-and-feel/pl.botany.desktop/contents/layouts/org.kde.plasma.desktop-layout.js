loadTemplate("org.kde.plasma.desktop.defaultPanel");

for (const panel of panels()) {
    for (const widget of panel.widgets()) {
        if (widget.type === "org.kde.plasma.icontasks") {
            widget.currentConfigGroup = ["General"];
            widget.writeConfig("launchers", [
                "preferred://browser",
                "preferred://filemanager",
            ]);
            widget.reloadConfig();
        }
    }
}
