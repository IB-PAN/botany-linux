#!/usr/bin/deno --allow-read --allow-write --allow-env

import * as fs from "node:fs/promises";
import * as path from "node:path";
import * as util from "node:util";
import * as ini from "jsr:@std/ini";

const mimeAppsListText = await Deno.readTextFile("/usr/share/applications/mimeapps.list");
const mimeAppsList = ini.parse(mimeAppsListText);
//console.log(mimeAppsList);
const defaultApps = mimeAppsList["Default Applications"];

// split into array
for (const [key, val] of Object.entries(defaultApps)) {
    defaultApps[key] = val.split(";").filter(v => !!v);
    if (defaultApps[key].length === 0)
        delete defaultApps[key];
}

function getOrNew(mime) {
    if (!(mime in defaultApps))
        defaultApps[mime] = [];
    return defaultApps[mime];
}

function prependAppToMime(mime, appName) {
    let arr = getOrNew(mime);
    arr = arr.filter(v => v !== appName);
    arr.unshift(appName);
    defaultApps[mime] = arr;
}

function deleteAppFromAll(appName) {
    for (const [key, val] of Object.entries(defaultApps)) {
        if (val.includes(appName)) {
            defaultApps[key] = val.filter(v => v !== appName);
        }
    }
}

function deleteAppFromSome(appName, mimeRegex) {
    for (const [key, val] of Object.entries(defaultApps)) {
        if (key === mimeRegex || mimeRegex.test?.(key)) {
            defaultApps[key] = val.filter(v => v !== appName);
        }
    }
}

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

async function getNewFileMimes() {
    const fileToMimes = {};
    const fileListGlobs = [
        "/var/lib/flatpak/app/org.mozilla.firefox/x86_64/stable/active/export/share/applications/org.mozilla.firefox.desktop",
        "/usr/share/applications/org.mozilla.firefox.desktop",
        "/var/lib/flatpak/app/org.kde.haruna/x86_64/stable/active/export/share/applications/org.kde.haruna.desktop",
        "/usr/share/applications/org.kde.haruna.desktop",
        "/var/lib/flatpak/app/org.kde.okular/x86_64/stable/active/export/share/applications/*.desktop",
        "/usr/share/applications/org.kde.okular*.desktop",
        "/usr/share/applications/org.kde.kate.desktop",
        "/var/lib/flatpak/app/org.kde.gwenview/x86_64/stable/active/export/share/applications/org.kde.gwenview.desktop",
        "/usr/share/applications/org.kde.gwenview.desktop",
        "/usr/share/applications/org.kde.ark.desktop",
        "/usr/share/applications/libreoffice-*.desktop",
        "/usr/share/applications/onlyoffice-desktopeditors.desktop",
        "/var/lib/flatpak/app/org.onlyoffice.desktopeditors/x86_64/stable/active/export/share/applications/org.onlyoffice.desktopeditors.desktop",
        "/usr/share/applications/libreoffice-impress.desktop", // override with Impress for Presentations
        "/usr/share/applications/org.inkscape.Inkscape.desktop",
        "/usr/share/applications/wine.desktop",
    ];
    //const fileList = await Array.fromAsync(fs.glob(fileListGlobs));
    const fileList = (await Promise.all(fileListGlobs.map(g => Array.fromAsync(fs.glob(g))))).flat();
    for (const filePath of fileList) {
        const fileName = path.basename(filePath);
        const mimes = (await Deno.readTextFile(filePath))
            .split("\n").find(l => l.trim().toLocaleLowerCase().startsWith("mimetype="))
            ?.replace(/\s*MimeType\s*=\s*/i, "").split(";").map(m => m.trim()).filter(m => !!m);
        //console.log({ filePath, fileName, mimes });
        if (mimes)
            fileToMimes[fileName] = mimes;
    }
    return fileToMimes;
}
//const fileToMimes = await getNewFileMimes(); console.log(util.inspect(fileToMimes, { breakLength: Infinity, compact: 1 }).replaceAll("'", "\"")); process.exit(0);

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

const fileToMimes = {
  "org.mozilla.firefox.desktop": [ "text/html", "text/xml", "application/xhtml+xml", "application/vnd.mozilla.xul+xml", "text/mml", "x-scheme-handler/http", "x-scheme-handler/https" ],
  "org.kde.haruna.desktop": [
    "video/mp4",       "video/x-matroska",
    "video/mpeg",      "video/ogg",
    "video/quicktime", "video/vnd.avi",
    "video/mp2t",      "video/webm",
    "video/x-ms-wmv",  "audio/aac",
    "audio/ac3",       "audio/flac",
    "audio/mp4",       "audio/mpeg",
    "audio/ogg",       "audio/vnd.wave",
    "audio/webm",      "audio/x-matroska",
    "audio/x-mpegurl"
  ],
  "org.kde.okular-comicbook.desktop": [ "application/x-cbz", "application/x-cbr", "application/x-cbt", "application/x-cb7" ],
  "org.kde.okular-djvu.desktop": [ "image/vnd.djvu" ],
  "org.kde.okular-doc_calligra.desktop": [ "application/msword" ],
  "org.kde.okular-docx_calligra.desktop": [ "application/vnd.openxmlformats-officedocument.wordprocessingml.document", "application/vnd.openxmlformats-officedocument.wordprocessingml.template" ],
  "org.kde.okular-dvi.desktop": [ "application/x-dvi", "application/x-gzdvi", "application/x-bzdvi" ],
  "org.kde.okular-epub.desktop": [ "application/epub+zip" ],
  "org.kde.okular-fax.desktop": [ "image/fax-g3", "image/g3fax" ],
  "org.kde.okular-fb.desktop": [ "application/x-fictionbook+xml" ],
  "org.kde.okular-ghostview.desktop": [ "application/postscript", "image/x-eps", "application/x-gzpostscript", "application/x-bzpostscript", "image/x-gzeps", "image/x-bzeps" ],
  "org.kde.okular-kimgio.desktop": [
    "image/bmp",                "image/x-dds",
    "image/x-eps",              "image/x-exr",
    "image/gif",                "image/x-hdr",
    "image/x-ico",              "image/jp2",
    "image/jpeg",               "video/x-mng",
    "image/x-portable-bitmap",  "image/x-pcx",
    "image/x-portable-graymap", "image/png",
    "image/x-portable-pixmap",  "image/x-psd",
    "image/x-rgb",              "image/x-tga",
    "image/tiff",               "image/x-xbitmap",
    "image/x-xcf",              "image/x-xpixmap",
    "image/x-gzeps",            "image/x-bzeps",
    "image/avif",               "image/heif",
    "image/webp",               "image/jxl"
  ],
  "org.kde.okular-md.desktop": [ "text/markdown" ],
  "org.kde.okular-mobi.desktop": [ "application/x-mobipocket-ebook" ],
  "org.kde.okular-odp_calligra.desktop": [ "application/vnd.oasis.opendocument.presentation", "application/vnd.oasis.opendocument.presentation-template" ],
  "org.kde.okular-odt_calligra.desktop": [ "application/vnd.oasis.opendocument.text", "application/vnd.oasis.opendocument.text-template" ],
  "org.kde.okular-pdf.desktop": [ "application/pdf", "application/x-gzpdf", "application/x-bzpdf", "application/x-wwf" ],
  "org.kde.okular-powerpoint_calligra.desktop": [ "application/vnd.ms-powerpoint" ],
  "org.kde.okular-pptx_calligra.desktop": [ "application/vnd.openxmlformats-officedocument.presentationml.presentation" ],
  "org.kde.okular-rtf_calligra.desktop": [ "text/rtf", "application/rtf" ],
  "org.kde.okular-tiff.desktop": [ "image/tiff" ],
  "org.kde.okular-txt.desktop": [ "text/plain" ],
  "org.kde.okular-wpd_calligra.desktop": [ "application/vnd.wordperfect" ],
  "org.kde.okular-xps.desktop": [ "application/oxps", "application/vnd.ms-xpsdocument" ],
  "org.kde.okular.desktop": [ "application/vnd.kde.okular-archive" ],
  "org.kde.kate.desktop": [ "text/plain", "inode/directory" ],
  "org.kde.gwenview.desktop": [
    "inode/directory",          "image/avif",
    "image/gif",                "image/heif",
    "image/jpeg",               "image/jxl",
    "image/png",                "image/bmp",
    "image/x-eps",              "image/x-icns",
    "image/x-ico",              "image/x-portable-bitmap",
    "image/x-portable-graymap", "image/x-portable-pixmap",
    "image/x-xbitmap",          "image/x-xpixmap",
    "image/tiff",               "image/x-psd",
    "image/x-webp",             "image/webp",
    "image/x-tga",              "image/x-xcf",
    "application/x-krita"
  ],
  "org.kde.ark.desktop": [
    "application/x-deb",                  "application/x-cd-image",
    "application/x-bcpio",                "application/x-cpio",
    "application/x-cpio-compressed",      "application/x-sv4cpio",
    "application/x-sv4crc",               "application/x-rpm",
    "application/x-compress",             "application/gzip",
    "application/x-bzip",                 "application/x-bzip2",
    "application/x-lzma",                 "application/x-xz",
    "application/zlib",                   "application/zstd",
    "application/x-lz4",                  "application/x-lzip",
    "application/x-lrzip",                "application/x-lzop",
    "application/x-source-rpm",           "application/vnd.debian.binary-package",
    "application/vnd.efi.iso",            "application/vnd.ms-cab-compressed",
    "application/x-xar",                  "application/x-iso9660-appimage",
    "application/x-archive",              "application/x-tar",
    "application/x-compressed-tar",       "application/x-bzip-compressed-tar",
    "application/x-bzip2-compressed-tar", "application/x-tarz",
    "application/x-xz-compressed-tar",    "application/x-lzma-compressed-tar",
    "application/x-lzip-compressed-tar",  "application/x-tzo",
    "application/x-lrzip-compressed-tar", "application/x-lz4-compressed-tar",
    "application/x-zstd-compressed-tar",  "application/x-7z-compressed",
    "application/vnd.rar",                "application/zip",
    "application/x-java-archive",         "application/x-lha",
    "application/x-stuffit",              "application/x-arj",
    "application/arj"
  ],
  "libreoffice-startcenter.desktop": [ "application/vnd.openofficeorg.extension", "x-scheme-handler/vnd.libreoffice.cmis", "x-scheme-handler/vnd.sun.star.webdav", "x-scheme-handler/vnd.sun.star.webdavs", "x-scheme-handler/vnd.libreoffice.command", "x-scheme-handler/ms-word", "x-scheme-handler/ms-powerpoint", "x-scheme-handler/ms-excel", "x-scheme-handler/ms-visio", "x-scheme-handler/ms-access" ],
  "libreoffice-writer.desktop": [ "application/clarisworks", "application/docbook+xml", "application/macwriteii", "application/msword", "application/prs.plucker", "application/rtf", "application/vnd.apple.pages", "application/vnd.lotus-wordpro", "application/vnd.ms-word", "application/vnd.ms-word.document.macroEnabled.12", "application/vnd.ms-word.template.macroEnabled.12", "application/vnd.ms-works", "application/vnd.oasis.opendocument.text", "application/vnd.oasis.opendocument.text-flat-xml", "application/vnd.oasis.opendocument.text-master", "application/vnd.oasis.opendocument.text-master-template", "application/vnd.oasis.opendocument.text-template", "application/vnd.oasis.opendocument.text-web", "application/vnd.openxmlformats-officedocument.wordprocessingml.document", "application/vnd.openxmlformats-officedocument.wordprocessingml.template", "application/vnd.palm", "application/vnd.stardivision.writer-global", "application/vnd.sun.xml.writer", "application/vnd.sun.xml.writer.global", "application/vnd.sun.xml.writer.template", "application/vnd.wordperfect", "application/wordperfect", "application/x-abiword", "application/x-aportisdoc", "application/x-doc", "application/x-extension-txt", "application/x-fictionbook+xml", "application/x-hwp", "application/x-iwork-pages-sffpages", "application/x-mswrite", "application/x-pocket-word", "application/x-sony-bbeb", "application/x-starwriter", "application/x-starwriter-global", "application/x-t602", "text/plain", "text/rtf" ],
  "libreoffice-impress.desktop": [ "application/mspowerpoint", "application/vnd.apple.keynote", "application/vnd.ms-powerpoint", "application/vnd.ms-powerpoint.presentation.macroEnabled.12", "application/vnd.ms-powerpoint.slideshow.macroEnabled.12", "application/vnd.ms-powerpoint.template.macroEnabled.12", "application/vnd.oasis.opendocument.presentation", "application/vnd.oasis.opendocument.presentation-flat-xml", "application/vnd.oasis.opendocument.presentation-template", "application/vnd.openxmlformats-officedocument.presentationml.presentation", "application/vnd.openxmlformats-officedocument.presentationml.slide", "application/vnd.openxmlformats-officedocument.presentationml.slideshow", "application/vnd.openxmlformats-officedocument.presentationml.template", "application/vnd.stardivision.impress", "application/vnd.sun.xml.impress", "application/vnd.sun.xml.impress.template", "application/x-iwork-keynote-sffkey", "application/x-starimpress" ],
  "libreoffice-calc.desktop": [ "application/clarisworks", "application/csv", "application/excel", "application/msexcel", "application/tab-separated-values", "application/vnd.apache.parquet", "application/vnd.apple.numbers", "application/vnd.lotus-1-2-3", "application/vnd.ms-excel", "application/vnd.ms-excel.sheet.binary.macroEnabled.12", "application/vnd.ms-excel.sheet.macroEnabled.12", "application/vnd.ms-excel.template.macroEnabled.12", "application/vnd.ms-works", "application/vnd.oasis.opendocument.chart", "application/vnd.oasis.opendocument.chart-template", "application/vnd.oasis.opendocument.spreadsheet", "application/vnd.oasis.opendocument.spreadsheet-flat-xml", "application/vnd.oasis.opendocument.spreadsheet-template", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", "application/vnd.openxmlformats-officedocument.spreadsheetml.template", "application/vnd.stardivision.calc", "application/vnd.stardivision.chart", "application/vnd.sun.xml.calc", "application/vnd.sun.xml.calc.template", "application/x-123", "application/x-dbase", "application/x-dbf", "application/x-dos_ms_excel", "application/x-excel", "application/x-gnumeric", "application/x-iwork-numbers-sffnumbers", "application/x-ms-excel", "application/x-msexcel", "application/x-quattropro", "application/x-starcalc", "application/x-starchart", "text/comma-separated-values", "text/csv", "text/spreadsheet", "text/tab-separated-values", "text/x-comma-separated-values", "text/x-csv" ],
  "libreoffice-xsltfilter.desktop": [ "application/vnd.oasis.opendocument.text-flat-xml", "application/vnd.oasis.opendocument.spreadsheet-flat-xml", "application/vnd.oasis.opendocument.graphics-flat-xml", "application/vnd.oasis.opendocument.presentation-flat-xml" ],
  "libreoffice-draw.desktop": [ "application/clarisworks", "application/pdf", "application/vnd.corel-draw", "application/vnd.ms-publisher", "application/vnd.oasis.opendocument.graphics", "application/vnd.oasis.opendocument.graphics-flat-xml", "application/vnd.oasis.opendocument.graphics-template", "application/vnd.quark.quarkxpress", "application/vnd.stardivision.draw", "application/vnd.sun.xml.draw", "application/vnd.sun.xml.draw.template", "application/vnd.visio", "application/x-pagemaker", "application/x-stardraw", "application/x-wpg", "image/x-emf", "image/x-freehand", "image/x-wmf" ],
  "org.onlyoffice.desktopeditors.desktop": [ "application/vnd.oasis.opendocument.text", "application/vnd.oasis.opendocument.text-template", "application/vnd.oasis.opendocument.text-web", "application/vnd.oasis.opendocument.text-master", "application/vnd.sun.xml.writer", "application/vnd.sun.xml.writer.template", "application/vnd.sun.xml.writer.global", "application/msword", "application/vnd.ms-word", "application/x-doc", "application/rtf", "text/rtf", "application/vnd.wordperfect", "application/wordperfect", "application/vnd.openxmlformats-officedocument.wordprocessingml.document", "application/vnd.ms-word.document.macroenabled.12", "application/vnd.openxmlformats-officedocument.wordprocessingml.template", "application/vnd.ms-word.template.macroenabled.12", "application/vnd.oasis.opendocument.spreadsheet", "application/vnd.oasis.opendocument.spreadsheet-template", "application/vnd.sun.xml.calc", "application/vnd.sun.xml.calc.template", "application/msexcel", "application/vnd.ms-excel", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", "application/vnd.ms-excel.sheet.macroenabled.12", "application/vnd.openxmlformats-officedocument.spreadsheetml.template", "application/vnd.ms-excel.template.macroenabled.12", "application/vnd.ms-excel.sheet.binary.macroenabled.12", "text/csv", "text/spreadsheet", "application/csv", "application/excel", "application/x-excel", "application/x-msexcel", "application/x-ms-excel", "text/comma-separated-values", "text/tab-separated-values", "text/x-comma-separated-values", "text/x-csv", "application/vnd.oasis.opendocument.presentation", "application/vnd.oasis.opendocument.presentation-template", "application/vnd.sun.xml.impress", "application/vnd.sun.xml.impress.template", "application/mspowerpoint", "application/vnd.ms-powerpoint", "application/vnd.openxmlformats-officedocument.presentationml.presentation", "application/vnd.ms-powerpoint.presentation.macroenabled.12", "application/vnd.openxmlformats-officedocument.presentationml.template", "application/vnd.ms-powerpoint.template.macroenabled.12", "application/vnd.openxmlformats-officedocument.presentationml.slide", "application/vnd.openxmlformats-officedocument.presentationml.slideshow", "application/vnd.ms-powerpoint.slideshow.macroEnabled.12", "x-scheme-handler/oo-office", "text/docxf", "text/oform", "application/pdf" ],
  "org.inkscape.Inkscape.desktop": [ "image/svg+xml", "image/svg+xml-compressed", "application/vnd.corel-draw", "application/pdf", "application/postscript", "image/x-eps", "application/illustrator", "image/x-wmf", "image/x-emf", "application/x-xccx", "application/x-xcdt", "application/x-xcmx", "image/x-xcdr", "application/visio", "application/x-visio", "application/vnd.visio", "application/vnd.ms-visio.viewer", "application/visio.drawing", "application/vsd", "application/x-vsd", "image/x-vsd" ],
  "wine.desktop": [ "application/x-ms-dos-executable", "application/x-msi", "application/x-ms-shortcut", "application/x-bat", "application/x-mswinurl"],
};

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

delete fileToMimes["org.kde.okular-doc_calligra.desktop"];
delete fileToMimes["org.kde.okular-docx_calligra.desktop"];
delete fileToMimes["org.kde.okular-powerpoint_calligra.desktop"];
delete fileToMimes["org.kde.okular-pptx_calligra.desktop"];

// change org.onlyoffice.desktopeditors.desktop → onlyoffice-desktopeditors.desktop (we're not using Flatpak version)
if ("org.onlyoffice.desktopeditors.desktop" in fileToMimes) {
    if (!("onlyoffice-desktopeditors.desktop" in fileToMimes)) {
        fileToMimes["onlyoffice-desktopeditors.desktop"] = fileToMimes["org.onlyoffice.desktopeditors.desktop"];
    }
    delete fileToMimes["org.onlyoffice.desktopeditors.desktop"];
}

for (const [appName, mimes] of Object.entries(fileToMimes)) {
    for (const mime of mimes) {
        prependAppToMime(mime, appName);
    }
}

///////////////////////////////////////////////////////////////////////////////

deleteAppFromAll("org.gnome.Evince.desktop");
deleteAppFromAll("org.gnome.eog.desktop");
deleteAppFromAll("org.gnome.Nautilus.desktop")
deleteAppFromAll("org.gnome.FileRoller.desktop");
deleteAppFromAll("org.gnome.Totem.desktop");
deleteAppFromSome("org.inkscape.Inkscape.desktop", /^image\/svg.*/);
deleteAppFromSome("org.inkscape.Inkscape.desktop", "application/pdf");

defaultApps["text/csv"] = ["onlyoffice-desktopeditors.desktop", "libreoffice-calc.desktop", "org.kde.kate.desktop"];
defaultApps["text/plain"] = ["org.kde.kate.desktop"];

prependAppToMime("inode/directory", "org.kde.dolphin.desktop");
prependAppToMime("application/pdf", "org.kde.okular-pdf.desktop");
prependAppToMime("application/svg+xml", "org.mozilla.firefox.desktop");
prependAppToMime("application/svg+xml-compressed", "org.mozilla.firefox.desktop");

for (const [key, val] of Object.entries(defaultApps)) {
    //if (val[0] === )
}

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

// re-join into string
for (const [key, val] of Object.entries(defaultApps)) {
    if (val.length === 0) {
        delete defaultApps[key];
    } else {
        defaultApps[key] = val.join(";");
    }
}

const newMimeAppsListText = ini.stringify(mimeAppsList);
console.log(newMimeAppsListText);
await Deno.writeTextFile("/usr/share/applications/mimeapps.list", newMimeAppsListText);
