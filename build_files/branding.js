import { $ } from "bun";
import imageInfo from "/usr/share/ublue-os/image-info.json" with { type: "json" };

const imageName = process.env.IMAGE_NAME; // botany-linux

imageInfo["image-name"] = imageName;
imageInfo["image-vendor"] = "IB-PAN";
delete imageInfo["image-tag"];
imageInfo["image-flavor"] = "main";
imageInfo["image-ref"] = `ostree-image-signed:docker://${process.env.IMAGE_REGISTRY}/${process.env.IMAGE_NAME}`;

await $`
rm /usr/share/icons/hicolor/scalable/places/distributor-logo.svg
cp /usr/share/icons/ibpan-logo.svg /usr/share/icons/hicolor/scalable/distributor-logo{,white}.svg
ln -sr /usr/share/icons/hicolor/scalable/distributor-logo.svg /usr/share/icons/hicolor/scalable/places/distributor-logo.svg
ln -sr /usr/share/icons/hicolor/scalable/distributor-logo-white.svg /usr/share/icons/hicolor/scalable/places/distributor-logo-white.svg
ln -sr /usr/share/icons/hicolor/scalable/distributor-logo-white.svg /usr/share/icons/hicolor/scalable/places/start-here.svg
ln -sr /usr/share/icons/hicolor/scalable/distributor-logo-white.svg /usr/share/icons/hicolor/scalable/apps/start-here.svg
cp /usr/share/icons/ibpan-logo.svg /usr/share/icons/hicolor/scalable/places/distributor-logo.svg
cp /usr/share/icons/ibpan-logo.svg /usr/share/icons/hicolor/scalable/places/distributor-logo-white.svg
rm /usr/share/pixmaps/system-logo*.png
cp /usr/share/icons/ibpan-logo.svg /usr/share/pixmaps/system-logo.svg
cp /usr/share/icons/ibpan-logo.svg /usr/share/pixmaps/fedora-logo.svg
cp /usr/share/icons/ibpan-logo.svg /usr/share/pixmaps/fedora-logo-sprite.svg
cp /usr/share/icons/ibpan-logo.svg /usr/share/pixmaps/fedora_whitelogo.svg
magick -size 128x32 /usr/share/icons/ibpan-logo.svg /usr/share/pixmaps/fedora-logo-small.png
magick -size 128x128 /usr/share/pixmaps/fedora-logo-sprite.svg /usr/share/pixmaps/fedora-logo-sprite.png
magick -size 400x100 /usr/share/pixmaps/fedora-logo.svg /usr/share/pixmaps/fedora-logo.png
magick -size 200x50 /usr/share/pixmaps/fedora-logo.svg /usr/share/pixmaps/fedora_logo_med.png
magick -size 256x256 /usr/share/icons/ibpan-logo.svg /usr/share/pixmaps/system-logo.png
magick -size 256x256 /usr/share/icons/ibpan-logo.svg /usr/share/pixmaps/system-logo-white.png
magick -size 128x128 /usr/share/icons/ibpan-logo.svg /usr/share/plymouth/themes/spinner/watermark.png
cp /usr/share/plymouth/themes/spinner/watermark.png /usr/share/plymouth/themes/spinner/kinoite-watermark.png
`;

const osReleaseFile = Bun.file("/usr/lib/os-release");
const osRelease = Object.fromEntries(await osReleaseFile.text()).split("\n").map(l => l.trim()).filter(l => !!l)
    .map(line => {
        const arr = line.split("=");
        const key = arr[0];
        let value = arr.splice(1).join("=");
        if (value.startsWith('"') && value.endsWith('"')) {
            value = value.slice(1, -1).replaceAll("\\\"", "\"");
        }
        return [key, value];
    })

osRelease.PRETTY_NAME = "Botany Linux 42";
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
