/*
Copyright (C) 2014 Micah Losli <micah.losli@gmail.com>

This file is part of Panpipe.

Panpipe is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Panpipe is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Panpipe.  If not, see <http://www.gnu.org/licenses/>.
*/

import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.0 as ListItem
import Ubuntu.Components.Popups 1.0 as Popups
import "components"

Item {
    /* Aliases */
    property alias stationsListItem: stationsView

    /* Private properties */
    property int _pressAndHoldIndex
    property int _pressIndex
    property var _tempQuickMixIdsArray
    property string _tempStationToBeDeletedName
    property var _tempStationToBeDeletedToken
    property int _tempStationToBeDeletedIndex


    Component.onCompleted: {
        /* Get the list of stations in the QuickMix from the data model */
        _tempQuickMixIdsArray = root.stationsModel.quickMixStationIds;
    }

    Component.onDestruction: {
        console.log("Updating quickmix.");
        pandoraInterface.updateQuickMix(_tempQuickMixIdsArray);

        pandoraInterface.retrieveStations();
    }


    Button {
        id: searchNewStationButton

        text: "Create a New Station"

        anchors {
            top: parent.top
            topMargin: units.gu(2)
            left: parent.left
            leftMargin: units.gu(2)
            right: parent.right
            rightMargin: units.gu(2)
        }

        onClicked: {
            PopupUtils.open(searchStationDialog);
        }
    }

    ListView {
        id: stationsView
        clip: true

        anchors.top: searchNewStationButton.bottom
        anchors.topMargin: units.gu(2)
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        model: root.stationsModel.model

        onModelChanged: {
            currentIndex = -1;
            console.log("Manage station model changed");
        }

        Component.onCompleted: {
            currentIndex = -1;
        }

        delegate: manageStationDelegateComponent
    }

    Component {
        id: searchStationDelegateComponent

        ListItem.Empty {
            id: searchStationDelegate

            Component.onCompleted: {
                console.log(model + "\n\n");
            }

            Label {
                id: searchResultText
                text: model.artistName
                color: "white"
                fontSize: "medium"
                elide: Text.ElideRight

                anchors {
                    left: parent.left
                    leftMargin: units.gu(1)
                    right: parent.right
                    rightMargin: units.gu(1)
                    top: parent.top
                    topMargin:units.gu(2)
                }
            }
        }
    }

    Component {
        id: manageStationDelegateComponent

        ListItem.Empty {
            id: manageStationDelegate

            state: (stationsView.currentIndex === index) ? "expanded" : ""

            MouseArea {
                anchors.fill: parent

                onClicked: {
                    if(index != 0) {
                        if(stationsView.currentIndex !== index) {
                            stationsView.currentIndex = index;
                            selectedStationToken = model.stationToken;
                        } else {
                            stationsView.currentIndex = -1;
                        }
                    }
                }
            }


            Label {
                id: manageListText
                text: stationName
                color: "white"
                fontSize: "medium"
                elide: Text.ElideRight

                anchors {
                    left: parent.left
                    leftMargin: units.gu(1)
                    right: checkBox.left
                    rightMargin: units.gu(1)
                    top: parent.top
                    topMargin:units.gu(2)
                }
            }

            CheckBox {
                id: checkBox

                enabled: (index !== 0)
                visible: (index !== 0)

                anchors {
                    right: parent.right
                    rightMargin: units.gu(2)
                    top: parent.top
                    topMargin: units.gu(0.5)
                }

                checked: (_tempQuickMixIdsArray.indexOf(stationId) !== -1)

                MouseArea {
                    anchors.fill: parent

                    onClicked: {
                        if(!checkBox.checked) {
                            console.log("Adding station to list.");
                            _tempQuickMixIdsArray.push(stationId);
                            checkBox.checked = true;
                        }
                        else {
                            var tempIndex = _tempQuickMixIdsArray.indexOf(stationId);
                            if(tempIndex >= 0) {
                                console.log("Removing station from list.");
                                _tempQuickMixIdsArray.splice(tempIndex, 1);
                                checkBox.checked = false;
                            }
                        }
                    }
                }
            }

            Label {
                id: inMixLabel
                text: "QuickMix"
                fontSize: "xx-small"

                enabled: (index !== 0)
                visible: (index !== 0)

                anchors {
                    horizontalCenter: checkBox.horizontalCenter
                    top: checkBox.bottom
                }

            }

            Button {
                id: deleteButton
                color: "red"
                text: "Delete"

                /* These properties changed when state === "expanded" */
                enabled: false
                visible: false
                opacity: 0

                anchors {
                    left: parent.left
                    leftMargin: units.gu(1)
                    bottom: parent.bottom
                    bottomMargin: units.gu(1)
                }

                onClicked: {
                    _tempStationToBeDeletedName = stationName;
                    _tempStationToBeDeletedToken = stationToken;
                    _tempStationToBeDeletedIndex = index;
                    PopupUtils.open(deleteStationDialog);
                }
            }

            Button {
                id: detailsButton
                text: "Details"

                /* These properties changed when state === "expanded" */
                enabled: false
                visible: false
                opacity: 0

                anchors {
                    left: deleteButton.right
                    leftMargin: units.gu(2)
                    verticalCenter: deleteButton.verticalCenter
                }

                onClicked: {
                    pagestack.push(stationDetailsPage)
                }
            }

            states: [
                State {
                    name: "expanded"
                    PropertyChanges {
                        target: manageStationDelegate; height: units.gu(12)
                    }
                    PropertyChanges {
                        target: deleteButton; enabled: true; visible:true; opacity: 1
                    }
                    PropertyChanges {
                        target: detailsButton; enabled: true; visible:true; opacity: 1
                    }
                }
            ]

            transitions: [
                Transition {
                    SequentialAnimation {
                        NumberAnimation {
                            duration: 50;
                            properties: "height"
                        }
                        NumberAnimation {
                            duration: 50;
                            properties: "opacity"
                        }
                    }
                }
            ]
        }
    }

    /* Delete station confirmation dialog */
    Component {
        id: deleteStationDialog

        Popups.Dialog {
            id: deleteStationScreen
            title: i18n.tr("Delete Station")
            text: i18n.tr("Are you sure that you want to delete " + _tempStationToBeDeletedName + "?");

            Button {
                id: confirmDeleteButton
                text: i18n.tr("Delete")
                color: "red"

                onClicked: {
                    console.log("attempting to delete index: " + _tempStationToBeDeletedIndex);

                    /* Update the data model */
                    stationsView.currentIndex = -1;
                    dataModel.model.remove(_tempStationToBeDeletedIndex);

                    /* Send delete command to Pandora */
                    pandoraModel.deleteUserStation(_tempStationToBeDeletedToken);

                    /* Clear temp variables */
                    _tempStationToBeDeletedName = "";
                    _tempStationToBeDeletedToken = 0;
                    _tempStationToBeDeletedIndex = -1;

                    /* close dialog */
                    PopupUtils.close(deleteStationScreen);
                }
            }

            Button {
                id: cancelButton
                text: i18n.tr("Cancel")
                color: UbuntuColors.darkGrey

                onClicked: {
                    /* Clear temp variables */
                    _tempStationToBeDeletedName = "";
                    _tempStationToBeDeletedToken = 0;
                    _tempStationToBeDeletedIndex = -1;

                    /* close dialog */
                    PopupUtils.close(deleteStationScreen)
                }
            }
        }
    }

    /* Search for new station component */
    Component {
        id: searchStationDialog

        Popups.DefaultSheet {
            id: searchStationScreen

            property bool stationPicked

            Component.onCompleted: {
                stationPicked = false;
                pandoraModel.stationSearchResults = {};
                searchQueryForm.forceActiveFocus();
            }

            Component.onDestruction: {
                searchDataModel.model.clear();
                searchQueryForm.text = "";
            }

            TextField {
                id: searchQueryForm
                placeholderText: i18n.tr("Search by Artist or Song")
                color: "black"

                anchors {
                    top: parent.top
                    topMargin: units.gu(2)
                    left: parent.left
                    leftMargin: units.gu(2)
                    right: parent.right
                    rightMargin: units.gu(2)
                }

                onTextChanged: {
                    if( text === "" ) {
                        searchDataModel.model.clear();
                    } else {
                        newStationSearchQuery(searchQueryForm.text);
                    }
                }
            }

            JSONListModel {
                id: searchDataModel

                json: JSON.stringify(pandoraModel.stationSearchResults)

                onJsonChanged: {
                    console.log(json + "\n\n");
                }
            }

            ListView {
                id: searchResultListView

                model: searchDataModel.model

                clip: true

                section.property: "matchType"
                section.delegate: ListItem.Empty {
                    Rectangle {
                        anchors.fill: parent
                        color: "orange"

                        Label {
                            text: section
                            color: "black"

                            anchors {
                                left: parent.left
                                leftMargin: units.gu(1)
                                right: parent.right
                                rightMargin: units.gu(1)
                                top: parent.top
                                topMargin:units.gu(2)
                            }
                        }
                    }
                }

                anchors {
                    top: searchQueryForm.bottom
                    topMargin: units.gu(2)
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }

                delegate: ListItem.Empty {

                    Label {
                        id: searchResultText
                        text: (model.matchType === "Songs") ? model.songName + " by " + model.artistName : model.artistName
                        color: "black"
                        fontSize: "medium"
                        elide: Text.ElideRight

                        anchors {
                            left: parent.left
                            leftMargin: units.gu(2)
                            right: parent.right
                            rightMargin: units.gu(1)
                            top: parent.top
                            topMargin:units.gu(2)
                        }
                    }

                    MouseArea {
                        anchors.fill: parent

                        onClicked: {
                            pandoraModel.newUserStation(model.musicToken);
                            PopupUtils.close(searchStationScreen);
                            stationPicked = true;
                            pagestack.pop();
                        }
                    }
                }
            }
        }
    }
}
