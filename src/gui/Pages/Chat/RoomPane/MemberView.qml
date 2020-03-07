// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import SortFilterProxyModel 0.2
import "../../.."
import "../../../Base"

HColumnLayout {
    HListView {
        id: memberList
        clip: true

        model: SortFilterProxyModel {
            sourceModel: ModelStore.get(chat.userId, chat.roomId, "members")

            filters: ExpressionFilter {
                expression: utils.filterMatches(
                   filterField.text, model.display_name,
                )
            }
        }

        delegate: MemberDelegate {
            width: memberList.width
        }

        Layout.fillWidth: true
        Layout.fillHeight: true
    }

    HRowLayout {
        Layout.minimumHeight: theme.baseElementsHeight
        Layout.maximumHeight: Layout.minimumHeight

        HTextField {
            id: filterField
            saveName: "memberFilterField"
            saveId: chat.roomId

            placeholderText: qsTr("Filter members")
            backgroundColor: theme.chat.roomPane.filterMembers.background
            bordered: false
            opacity: width >= 16 * theme.uiScale ? 1 : 0

            Layout.fillWidth: true
            Layout.fillHeight: true

            Behavior on opacity { HNumberAnimation {} }
        }

        HButton {
            id: inviteButton
            icon.name: "room-send-invite"
            backgroundColor: theme.chat.roomPane.inviteButton.background
            enabled: chat.roomInfo.can_invite

            toolTip.text:
                enabled ?
                qsTr("Invite members to this room") :
                qsTr("No permission to invite members to this room")

            topPadding: 0 // XXX
            bottomPadding: 0

            onClicked: utils.makePopup(
                "Popups/InviteToRoomPopup.qml",
                chat,
                {
                    userId: chat.userId,
                    roomId: chat.roomId,
                    roomName: chat.roomInfo.display_name,
                    invitingAllowed: Qt.binding(() => inviteButton.enabled),
                },
            )

            // onEnabledChanged: if (openedPopup && ! enabled)

            Layout.fillHeight: true
        }
    }
}