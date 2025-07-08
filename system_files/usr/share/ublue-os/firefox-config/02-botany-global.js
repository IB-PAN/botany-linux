pref("widget.use-xdg-desktop-portal.file-picker", 1);
pref("media.webspeech.synth.enabled", false);

// Teams open in native app (override user-agent to Windows)
Services.mm.loadFrameScript('data:application/javascript;charset=UTF-8,' + encodeURIComponent('(' + (function () {
    addEventListener("DOMContentLoaded", event => {
        const doc = event.target;
        const loc = doc.location;
        const win = doc.defaultView;
        const nav = win.navigator;
        if (loc && win && nav && loc.toString().startsWith("https://teams.microsoft.com/")) {
            const fun = '(' + (function () {
                const newUserAgent = navigator.userAgent.replace("X11; Linux x86_64", "Windows NT 10.0; Win64; x64")
                Object.defineProperty(window, "navigator", {
                    value: { userAgent: newUserAgent },
                    writable: false,
                });
            }).toString() + ')();';
            win.eval(fun);
        }
    });
}).toString() + ')();'), true);
