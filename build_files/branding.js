import { $ } from "bun";
import imageInfo from "/usr/share/ublue-os/image-info.json" with { type: "json" };

const imageName = process.env.IMAGE_NAME; // botany-linux

imageInfo["image-name"] = imageName;
imageInfo["image-vendor"] = "IB-PAN";
imageInfo["image-tag"] = new Date().toISOString().split("T")[0].replaceAll("-", "");
imageInfo["image-flavor"] = "main";
imageInfo["image-ref"] = `ostree-image-signed:docker://${process.env.IMAGE_REGISTRY}/${process.env.IMAGE_NAME}`;

await $`
mkdir -p /usr/icons/hicolor/scalable/{apps,places}/
rm -f /usr/share/icons/hicolor/scalable/places/distributor-logo{,-white}.svg
rm -f /usr/share/icons/hicolor/scalable/{apps,places}/start-here.svg
cp /usr/share/icons/ibpan-logo.svg /usr/share/icons/hicolor/scalable/distributor-logo.svg
cp /usr/share/icons/ibpan-logo.svg /usr/share/icons/hicolor/scalable/distributor-logo-white.svg
ln -sr /usr/share/icons/hicolor/scalable/distributor-logo.svg /usr/share/icons/hicolor/scalable/places/distributor-logo.svg
ln -sr /usr/share/icons/hicolor/scalable/distributor-logo-white.svg /usr/share/icons/hicolor/scalable/places/distributor-logo-white.svg
ln -sr /usr/share/icons/ibpan-logo-notext.svg /usr/share/icons/hicolor/scalable/places/start-here.svg
ln -sr /usr/share/icons/ibpan-logo-notext.svg /usr/share/icons/hicolor/scalable/apps/start-here.svg
cp /usr/share/icons/ibpan-logo.svg /usr/share/icons/hicolor/scalable/places/distributor-logo.svg
cp /usr/share/icons/ibpan-logo.svg /usr/share/icons/hicolor/scalable/places/distributor-logo-white.svg
rm /usr/share/pixmaps/system-logo*.png
cp /usr/share/icons/ibpan-logo.svg /usr/share/pixmaps/system-logo.svg
cp /usr/share/icons/ibpan-logo-text-black.svg /usr/share/pixmaps/fedora-logo.svg
cp /usr/share/icons/ibpan-logo.svg /usr/share/pixmaps/fedora-logo-sprite.svg
cp /usr/share/icons/ibpan-logo-text-white.svg /usr/share/pixmaps/fedora_whitelogo.svg
magick -background none -size 150x47 /usr/share/pixmaps/fedora-logo.svg /usr/share/pixmaps/fedora-logo-small.png
magick -background none -size 252x252 /usr/share/pixmaps/fedora-logo-sprite.svg /usr/share/pixmaps/fedora-logo-sprite.png
magick -background none -size 521x164 /usr/share/pixmaps/fedora-logo.svg /usr/share/pixmaps/fedora-logo.png
magick -background none -size 279x80 /usr/share/pixmaps/fedora-logo.svg /usr/share/pixmaps/fedora_logo_med.png
magick -background none -size 279x80 /usr/share/pixmaps/fedora_whitelogo.svg /usr/share/pixmaps/fedora_whitelogo_med.png
magick -background none -size 149x43 /usr/share/pixmaps/fedora_whitelogo.svg /usr/share/pixmaps/fedora-gdm-logo.png
magick -background none -size 256x256 /usr/share/icons/ibpan-logo.svg /usr/share/pixmaps/system-logo.png
magick -background none -size 256x256 /usr/share/icons/ibpan-logo.svg /usr/share/pixmaps/system-logo-white.png
magick -background none -size 660x192 /usr/share/icons/ibpan-logo-text-white.svg /usr/share/plymouth/themes/spinner/watermark.png
cp /usr/share/plymouth/themes/spinner/watermark.png /usr/share/plymouth/themes/spinner/kinoite-watermark.png
mkdir -p /usr/share/plasma/look-and-feel/pl.botany.desktop/contents/splash/images/
cp /usr/share/plasma/look-and-feel/org.kde.breeze.desktop/contents/splash/images/* /usr/share/plasma/look-and-feel/pl.botany.desktop/contents/splash/images/
rm /usr/share/plasma/look-and-feel/pl.botany.desktop/contents/splash/images/plasma.svgz
gzip -c /usr/share/icons/ibpan-logo.svg > /usr/share/plasma/look-and-feel/pl.botany.desktop/contents/splash/images/ibpan_logo.svgz
`;

// Generate a preview screenshot.png of wallpapers
for await (const contents of new Bun.Glob("ibpan_*/contents").scan({ cwd: "/usr/share/wallpapers", onlyFiles: false, absolute: true })) {
    //console.log(contents);
    const screenshot_png = `${contents}/screenshot.png`;
    if (!(await Bun.file(screenshot_png).exists())) {
        const wallpaper_1920_1080_svg = `${contents}/images/1920x1080.svg`;
        const wallpaper_1920_1080_png = `${contents}/images/1920x1080.png`;
        const wallpaper_1920_1080_jpg = `${contents}/images/1920x1080.jpg`;
        let wallpaper = null;
        if (await Bun.file(wallpaper_1920_1080_svg).exists()) wallpaper = wallpaper_1920_1080_svg;
        else if (await Bun.file(wallpaper_1920_1080_png).exists()) wallpaper = wallpaper_1920_1080_png;
        else if (await Bun.file(wallpaper_1920_1080_jpg).exists()) wallpaper = wallpaper_1920_1080_jpg;
        else {
            try {
                const fallback = await Array.fromAsync(new Bun.Glob("images/*").scan({ cwd: contents, onlyFiles: true, absolute: true }));
                if (fallback && fallback[0])
                    wallpaper = fallback[0];
            } catch (e) {}
        }

        if (wallpaper) {
            await $`magick -background none -size 400x225 ${wallpaper} ${screenshot_png}`;
        }
    }
}

// fix default wallpaper until we have our own ones
await $`
ln -sf /usr/share/backgrounds/images/default.jxl /usr/share/backgrounds/default.jxl
ln -sf /usr/share/backgrounds/images/default-dark.jxl /usr/share/backgrounds/default-dark.jxl
ln -sf /usr/share/backgrounds/f*/default/f*.xml /usr/share/backgrounds/default.xml
ln -sf /usr/share/backgrounds/default.jxl /usr/share/backgrounds/default.png
ln -sf /usr/share/backgrounds/default-dark.jxl /usr/share/backgrounds/default-dark.png
`;

const osReleaseFile = Bun.file("/usr/lib/os-release");
const osRelease = Object.fromEntries((await osReleaseFile.text()).split("\n").map(l => l.trim()).filter(l => !!l)
    .map(line => {
        const arr = line.split("=");
        const key = arr[0];
        let value = arr.splice(1).join("=");
        if (value.startsWith('"') && value.endsWith('"')) {
            value = value.slice(1, -1).replaceAll("\\\"", "\"");
        }
        return [key, value];
    }));

osRelease.PRETTY_NAME = `Botany Linux ${osRelease.VERSION_ID}`;
osRelease.NAME = "Botany Linux";
osRelease.HOME_URL = "https://botany.pl";
osRelease.LOGO = "ibpan-logo";
osRelease.DEFAULT_HOSTNAME = "botany-linux-default-hostname";
osRelease.VERSION_CODENAME = ""; // Stargazer
osRelease.VARIANT = ""; // Kinoite
osRelease.VARIANT_ID = imageName; // aurora
osRelease.ID = imageName; // aurora
delete osRelease.CPE;
osRelease.VERSION = `${osRelease.VERSION_ID}.${new Date().toISOString().split("T")[0].replaceAll("-", "")} (Botany Linux)`; // 42.20250629.1 (Kinoite)

await Bun.write("/usr/share/ublue-os/image-info.json", JSON.stringify(imageInfo, null, '  '));
await Bun.write("/usr/lib/os-release", Object.entries(osRelease).map(([key, val]) => {
    let out = `${key}=`;
    if (/^[A-Za-z0-9]+$/.test(val))
        out += val;
    else
        out += '"' + val.replaceAll("\"", "\\\"") + '"';
    return out;
}).join("\n") + "\n");
