// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import Qt.labs.qmlmodels 1.0
import ".."
import "../Base"

HListView {
    id: roomList
    model: ModelStore.get("all_rooms")

    delegate: DelegateChooser {
        role: "type"

        DelegateChoice {
            roleValue: "Account"
            Account {
                width: roomList.width
                filterActive: Boolean(filter)
                isCurrent:
                    currentIndexModel &&
                    (currentIndexModel.for_account || currentIndexModel.id) ===
                    model.id
            }
        }

        DelegateChoice {
            roleValue: "Room"
            Room {
                width: roomList.width
                onActivated: showItemAtIndex(model.index)
            }
        }
    }

    onFilterChanged: py.callCoro("set_substring_filter", ["all_rooms", filter])


    property string filter: ""

    readonly property bool currentShouldBeAccount:
        window.uiState.page === "Pages/AccountSettings/AccountSettings.qml"
    readonly property bool currentShouldBeRoom:
        window.uiState.page === "Pages/Chat/Chat.qml"
    readonly property string wantedUserId:
        window.uiState.pageProperties.userId || ""
    readonly property string wantedRoomId:
        window.uiState.pageProperties.roomId || ""

    readonly property var accountIndice: {
        const accounts = {}

        for (let i = 0; i < model.count; i++) {
            if (model.get(i).type === "Account")
                accounts[model.get(i).id] = i
        }

        return accounts
    }


    function goToAccount(userId) {
        model.get(accountIndice[userId] + 1).type === "Room" ?
        currentIndex = accountIndice[userId] + 1 :
        currentIndex = accountIndice[userId]

        showItemLimiter.restart()
    }

    function goToAccountNumber(num) {
        const index = Object.values(accountIndice).sort()[num]

        model.get(index + 1).type === "Room" ?
        currentIndex = index + 1 :
        currentIndex = index

        showItemLimiter.restart()
    }

    function showItemAtIndex(index=currentIndex) {
        if (index === -1) index = 0
        index = Math.min(index, model.count - 1)

        const item = model.get(index)

        item.type === "Account" ?
        pageLoader.showPage(
            "AccountSettings/AccountSettings", { "userId": item.id }
        ) :
        pageLoader.showRoom(item.for_account, item.id)

        currentIndex = index
    }

    function showAccountRoomAtIndex(index) {
        const item = model.get(currentIndex === -1 ?  0 : currentIndex)

        const currentUserId =
            item.type === "Account" ? item.id : item.for_account

        showItemAtIndex(accountIndice[currentUserId] + 1 + index)
    }


    function setCorrectCurrentItem() {
        if (! currentShouldBeRoom && ! currentShouldBeAccount) {
            currentIndex = -1
            return
        }

        for (let i = 0; i < model.count; i++) {
            const item = model.get(i)

            if ((
                currentShouldBeRoom &&
                item.type === "Room" &&
                item.id === wantedRoomId &&
                item.for_account === wantedUserId
            ) || (
                currentShouldBeAccount &&
                item.type === "Account" &&
                item.id === wantedRoomId &&
                item.for_account === wantedUserId
            )) {
                currentIndex = i
                return
            }
        }
    }


    Timer {
        // On startup, the account/room takes an unknown amount of time to
        // arrive in the model, try to find it until then.
        interval: 200
        running: currentIndex === -1
        repeat: true
        triggeredOnStart: true
        onTriggered: setCorrectCurrentItem()
    }

    Timer {
        id: showItemLimiter
        interval: 200
        onTriggered: showItemAtIndex()
    }

    HShortcut {
        sequences: window.settings.keys.goToPreviousRoom
        onActivated: { decrementCurrentIndex(); showItemLimiter.restart() }
    }

    HShortcut {
        sequences: window.settings.keys.goToNextRoom
        onActivated: { incrementCurrentIndex(); showItemLimiter.restart() }
    }

    Repeater {
        model: Object.keys(window.settings.keys.focusRoomAtIndex)

        Item {
            HShortcut {
                sequence: window.settings.keys.focusRoomAtIndex[modelData]
                onActivated:
                    showAccountRoomAtIndex(parseInt(modelData - 1, 10))
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        z: -100
        color: theme.mainPane.listView.background
    }
}
