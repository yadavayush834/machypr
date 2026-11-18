pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property var map: ({
        pdf: "application-pdf", png: "image-png", jpg: "image-jpeg", jpeg: "image-jpeg", gif: "image-gif", svg: "image-svg+xml", webp: "image-x-generic",
        mp4: "video-mp4", mkv: "video-x-matroska", webm: "video-webm", mp3: "audio-mpeg", wav: "audio-x-wav", flac: "audio-flac",
        zip: "application-zip", gz: "application-x-gzip", xz: "application-x-xz", tar: "application-x-tar",
        doc: "x-office-document", docx: "x-office-document", odt: "x-office-document", xls: "x-office-spreadsheet", xlsx: "x-office-spreadsheet",
        ppt: "x-office-presentation", pptx: "x-office-presentation", txt: "text-plain", md: "text-markdown",
        js: "text-javascript", ts: "text-x-typescript", py: "text-x-python", sh: "text-x-script", html: "text-html", css: "text-css",
        json: "application-json", c: "text-x-csrc", cpp: "text-x-c++src", h: "text-x-chdr", rs: "text-rust", go: "text-x-go", java: "text-x-java",
        qml: "text-x-qml", lua: "text-x-lua", gd: "text-x-script",
    })
    function iconFor(name) {
        const i = name.lastIndexOf(".")
        if (i < 0) return name.indexOf(".") === 0 ? "text-x-generic" : "folder"
        return map[name.slice(i + 1).toLowerCase()] ?? "text-x-generic"
    }
}
