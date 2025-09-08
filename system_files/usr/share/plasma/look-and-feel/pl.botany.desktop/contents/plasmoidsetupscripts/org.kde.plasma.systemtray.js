systemtrayId = applet.readConfig("SystrayContainmentId");
if (systemtrayId) {
    const systrayContainer = desktopById(systemtrayId);
    systrayContainer.currentConfigGroup = ["General"];
    systrayContainer.writeConfig("scaleIconsToFit", true);
    const hiddenItems = systrayContainer.readConfig("hiddenItems").split(",");
    const hiddenItemsToAdd = ["chrome_status_icon_1"]; // kopia.io
    hiddenItemsToAdd.forEach(i => { if (!hiddenItems.includes(i)) hiddenItems.push(i); });
    systrayContainer.writeConfig("hiddenItems", hiddenItems);
}
