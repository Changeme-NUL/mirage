// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import "../.."
import "../../Base"
import "../../Base/Buttons"
import "../../ShortcutBundles"

HListView {
    id: root

    property string userId

    property bool enableFlickShortcuts:
        SwipeView ? SwipeView.isCurrentItem : true

    // {model.id: {notify, highlight, bubble, sound, urgency_hint}}
    property var pendingEdits: ({})
    property string saveFutureId: ""

    function takeFocus() {
        // deviceList.headerItem.exportButton.forceActiveFocus() TODO
    }

    function save() {
        const args = []

        for (const [modelId, kwargs] of Object.entries(pendingEdits)) {
            if (! model.find(modelId)) continue  // pushrule was deleted

            const [kind, rule_id] = JSON.parse(modelId)
            args.push(Object.assign({}, {kind, rule_id}, kwargs))
        }

        saveFutureId = py.callClientCoro(
            userId,
            "mass_tweak_pushrules",
            args,
            () => {
                if (! root) return
                saveFutureId = ""
                pendingEdits = {}
            }
        )
    }


    clip: true
    model: ModelStore.get(userId, "pushrules")
    implicitHeight: Math.min(window.height, contentHeight + bottomMargin)

    section.property: "kind"
    section.delegate: HLabel {
        width: root.width
        padding: theme.spacing
        font.pixelSize: theme.fontSize.big
        text:
            section === "override" ? qsTr("High-priority general rules") :
            section === "content" ? qsTr("Message text rules") :
            section === "room" ? qsTr("Room rules") :
            section === "sender" ? qsTr("Sender rules") :
            qsTr("General rules")
    }

    delegate: NotificationRuleDelegate {
        page: root
        width: root.width
    }

    footer: AutoDirectionLayout {
        z: 100
        width: root.width
        enabled: Object.keys(root.pendingEdits).length !== 0

        ApplyButton {
            onClicked: root.save()
            loading: root.saveFutureId !== ""

            Layout.topMargin: theme.spacing
        }

        CancelButton {
            onClicked: pendingEdits = {}

            Layout.topMargin: theme.spacing
        }
    }

    Layout.fillWidth: true
    Layout.fillHeight: true

    FlickShortcuts {
        flickable: root
        active: ! mainUI.debugConsole.visible && root.enableFlickShortcuts
    }
}
