/*
 * OBLinux Calamares slideshow (docs/CALAMARES.md, phase 3/4 item 3).
 *
 * First draft: text + the existing mark (logo.png) on every slide,
 * Slate & Amber background drawn explicitly per-slide rather than
 * relying on whatever the surrounding Calamares chrome uses. No new
 * icon assets yet -- a deliberate first pass to react to before
 * investing in real screenshots or custom per-slide icons (see the
 * design conversation in docs/CALAMARES.md).
 *
 * Structure follows Calamares' own reference slideshow
 * (src/branding/default/show.qml) verbatim: import calamares.slideshow,
 * a Presentation with Slide children, a Timer driving goToNextSlide(),
 * and onActivate()/onLeave() for API v2 (branding.desc: slideshowAPI: 2).
 */
import QtQuick 2.0;
import calamares.slideshow 1.0;

Presentation
{
    id: presentation

    function nextSlide() {
        presentation.goToNextSlide();
    }

    Timer {
        id: advanceTimer
        interval: 6000
        running: presentation.activatedInCalamares
        repeat: true
        onTriggered: nextSlide()
    }

    Slide {
        Rectangle { anchors.fill: parent; color: "#151a22" }
        Image {
            id: logo1
            source: "logo.png"
            width: 96; height: 96
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -60
        }
        Text {
            anchors.top: logo1.bottom
            anchors.topMargin: 24
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width * 0.7
            horizontalAlignment: Text.Center
            wrapMode: Text.WordWrap
            color: "#f2f3f5"
            font.pixelSize: 22
            font.bold: true
            text: qsTr("Welcome to OBLinux")
        }
        Text {
            anchors.top: logo1.bottom
            anchors.topMargin: 60
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width * 0.7
            horizontalAlignment: Text.Center
            wrapMode: Text.WordWrap
            color: "#a9b8c8"
            font.pixelSize: 14
            text: qsTr("Setting up your new system now. Here's a quick look at what's included.")
        }
    }

    Slide {
        Rectangle { anchors.fill: parent; color: "#151a22" }
        Image {
            id: logo2
            source: "logo.png"
            width: 64; height: 64
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -60
        }
        Text {
            anchors.top: logo2.bottom
            anchors.topMargin: 24
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width * 0.7
            horizontalAlignment: Text.Center
            wrapMode: Text.WordWrap
            color: "#f2f3f5"
            font.pixelSize: 20
            font.bold: true
            text: qsTr("A modern GNOME desktop")
        }
        Text {
            anchors.top: logo2.bottom
            anchors.topMargin: 58
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width * 0.7
            horizontalAlignment: Text.Center
            wrapMode: Text.WordWrap
            color: "#a9b8c8"
            font.pixelSize: 14
            text: qsTr("Wallpapers, icons, and the GNOME Shell itself, all in OBLinux's own Slate & Amber palette.")
        }
    }

    Slide {
        Rectangle { anchors.fill: parent; color: "#151a22" }
        Image {
            id: logo3
            source: "logo.png"
            width: 64; height: 64
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -60
        }
        Text {
            anchors.top: logo3.bottom
            anchors.topMargin: 24
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width * 0.7
            horizontalAlignment: Text.Center
            wrapMode: Text.WordWrap
            color: "#f2f3f5"
            font.pixelSize: 20
            font.bold: true
            text: qsTr("A terminal that's ready to go")
        }
        Text {
            anchors.top: logo3.bottom
            anchors.topMargin: 58
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width * 0.7
            horizontalAlignment: Text.Center
            wrapMode: Text.WordWrap
            color: "#a9b8c8"
            font.pixelSize: 14
            text: qsTr("A branded prompt, a system-info banner on every new shell, and modern tools like bat, eza, fzf, and ripgrep.")
        }
    }

    Slide {
        Rectangle { anchors.fill: parent; color: "#151a22" }
        Image {
            id: logo4
            source: "logo.png"
            width: 64; height: 64
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -60
        }
        Text {
            anchors.top: logo4.bottom
            anchors.topMargin: 24
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width * 0.7
            horizontalAlignment: Text.Center
            wrapMode: Text.WordWrap
            color: "#f2f3f5"
            font.pixelSize: 20
            font.bold: true
            text: qsTr("Your packages, your way")
        }
        Text {
            anchors.top: logo4.bottom
            anchors.topMargin: 58
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width * 0.7
            horizontalAlignment: Text.Center
            wrapMode: Text.WordWrap
            color: "#a9b8c8"
            font.pixelSize: 14
            text: qsTr("Arch's own pacman, the AUR through paru, and a signed OBLinux repository for everything built specifically for this project.")
        }
    }

    Slide {
        Rectangle { anchors.fill: parent; color: "#151a22" }
        Image {
            id: logo5
            source: "logo.png"
            width: 64; height: 64
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -60
        }
        Text {
            anchors.top: logo5.bottom
            anchors.topMargin: 24
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width * 0.7
            horizontalAlignment: Text.Center
            wrapMode: Text.WordWrap
            color: "#f2f3f5"
            font.pixelSize: 20
            font.bold: true
            text: qsTr("Almost there")
        }
        Text {
            anchors.top: logo5.bottom
            anchors.topMargin: 58
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width * 0.7
            horizontalAlignment: Text.Center
            wrapMode: Text.WordWrap
            color: "#a9b8c8"
            font.pixelSize: 14
            text: qsTr("This will just take a few minutes. Questions or issues afterward? github.com/marcoobaid/oblinux")
        }
    }

    function onActivate() {
        presentation.currentSlide = 0;
    }

    function onLeave() {
    }
}
