// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import SortFilterProxyModel 0.2
import ".."
import "../Base"

HListView {
    id: mainPaneList
    model: ModelStore.get("accounts")

    delegate: AccountRoomsDelegate {
        width: mainPaneList.width
        height: childrenRect.height
    }

    // Must handle the highlight's position and size manually because
    // of our nested lists
    highlightFollowsCurrentItem: false
    highlightRangeMode: ListView.NoHighlightRange

    highlight: Rectangle {
        id: highlightRectangle
        y:
            selectedRoom ?
            currentItem.y + currentItem.account.height +
            currentItem.roomList.currentItem.y :
            currentItem.y

        width: mainPaneList.width
        height:
            selectedRoom ?
            currentItem.roomList.currentItem.height :
            currentItem.account.height

        color: theme.controls.listView.highlight

        Behavior on y { HNumberAnimation { id: yAnimation } }
        Behavior on height { HNumberAnimation {} }

        Binding {
            target: mainPaneList
            property: "contentY"
            value: highlightRectangle.y + highlightRectangle.height / 2 -
                   mainPaneList.height / 2
            delayed: true
            when: yAnimation.running
        }

        Connections {
            target: mainPaneList
            enabled: yAnimation.running
            onContentYChanged: mainPaneList.returnToBounds()
        }
    }


    readonly property Room selectedRoom:
        currentItem ? currentItem.roomList.currentItem : null

    function previous() {
        if (! mainPane.filter) {
            _previous()
            return
        }

        let reachedStart = false
        do {
            if (currentIndex === count - 1 && reachedStart) break
            _previous()
            if (currentIndex === 0) reachedStart = true
        } while (! currentItem.roomList.currentItem)
    }

    function _previous() {
        let currentAccount = currentItem

        // Nothing is selected
        if (! currentAccount) {
            decrementCurrentIndex()
        }

        let roomList = currentAccount.roomList

        // An account is selected
        if (! roomList.currentItem) {
            decrementCurrentIndex()
            // Select the last room of the previous account that's now selected
            currentItem.roomList.decrementCurrentIndex()
            return
        }

        // A room is selected
        const selectedIsFirst = roomList.currentIndex === 0
        const noRooms         = roomList.count === 0

        if (currentAccount.collapsed || selectedIsFirst || noRooms) {
            // Have the account itself be selected
            roomList.currentIndex = -1
        } else {
            roomList.decrementCurrentIndex()
        }
    }

    function next() {
        if (! mainPane.filter) {
            _next()
            return
        }

        let reachedEnd = false
        do {
            if (currentIndex === 0 && reachedEnd) break
            _next()
            if (currentIndex === count - 1) reachedEnd = true
        } while (! currentItem.roomList.currentItem)
    }

    function _next() {
        const currentAccount = currentItem

        // Nothing is selected
        if (! currentAccount) {
            incrementCurrentIndex()
            return
        }

        const roomList = currentAccount.roomList

        // An account is selected
        if (! roomList.currentItem) {
            if (currentAccount.collapsed || roomList.count === 0) {
                incrementCurrentIndex()
            } else {
                roomList.incrementCurrentIndex()
            }
            return
        }

        // A room is selected
        const selectedIsLast = roomList.currentIndex >= roomList.count - 1
        const noRooms        = roomList.count === 0

        if (currentAccount.collapsed || selectedIsLast || noRooms) {
            roomList.currentIndex = -1
            mainPaneList.incrementCurrentIndex()
        } else {
            roomList.incrementCurrentIndex()
        }
    }

    function requestActivate() {
        activateLimiter.restart()
    }

    function activate() {
        if (! currentItem) next()

        selectedRoom ?
        currentItem.roomList.currentItem.activated() :
        currentItem.account.activated()
    }

    function accountSettings() {
        if (! currentItem) next()

        currentItem.roomList.currentIndex = -1
        currentItem.account.activated()
    }

    function addNewChat() {
        if (! currentItem) next()

        currentItem.roomList.currentIndex = -1
        currentItem.account.addChat.clicked()
    }

    function setCollapseAccount(collapse) {
        if (! currentItem) return
        currentItem.account.setCollapse(collapse)
    }

    function toggleCollapseAccount() {
        if (mainPane.filter) return
        if (! currentItem) next()

        currentItem.account.toggleCollapse()
    }

    function clearSelection() {
        if (selectedRoom) currentItem.roomList.currentIndex = -1
        currentIndex = -1
    }

    function forceUpdateSelection() {
        // When the selection is cleared, if an account or room delegate is
        // supposed to be selected, it will try to be so again.
        clearSelection()
    }


    Timer {
        id: activateLimiter
        interval: 300
        onTriggered: activate()
    }
}