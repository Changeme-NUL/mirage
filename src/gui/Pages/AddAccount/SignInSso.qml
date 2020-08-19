// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"
import "../../Base/Buttons"

SignInBase {
    id: page

    function takeFocus() { copyUrlButton.forceActiveFocus() }

    function startSignIn() {
        errorMessage.text = ""

        page.loginFuture = py.callCoro("start_sso_auth", [serverUrl], url => {
            urlArea.text           = url
            urlArea.cursorPosition = 0

            Qt.openUrlExternally(url)

            page.loginFuture = py.callCoro("continue_sso_auth", [], userId => {
                page.loginFuture = null
                page.finishSignIn(userId)
            })
        })
    }

    function cancel() {
        if (loginFuture) {
            page.loginFuture.cancel()
            page.loginFuture = null
        }

        page.exitRequested()
    }


    applyButton.text: qsTr("Waiting")
    applyButton.loading: true
    Component.onCompleted: page.startSignIn()

    HLabel {
        wrapMode: HLabel.Wrap
        text: qsTr(
            "Complete the single sign-on process in your web browser to " +
            "continue.\n\n" +
            "If no page appeared, you can also manually open this address:"
        )

        Layout.fillWidth: true
    }

    HRowLayout {
        HTextArea {
            id: urlArea
            width: parent.width
            readOnly: true
            radius: 0
            wrapMode: HTextArea.WrapAnywhere

            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        HButton {
            id: copyUrlButton
            icon.name: "copy-text"
            iconItem.small: true

            toolTip.text: qsTr("Copy")
            toolTip.onClosed: toolTip.text = qsTr("Copy")
            toolTip.label.wrapMode: HLabel.NoWrap

            onClicked: {
                urlArea.selectAll()
                urlArea.copy()
                urlArea.deselect()

                toolTip.text = qsTr("Copied!")
                toolTip.instantShow(2000)
            }

            Layout.fillHeight: true
        }
    }
}
