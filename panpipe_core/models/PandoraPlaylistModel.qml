/*
Copyright (C) 2015 Micah Losli <micah.losli@gmail.com>

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

Item {
    /* Signals */
    signal updated()
    signal receivedError()
    signal dataTimeout()

    /* Aliases */
    property alias model: model
    property alias count: model.count

    /* Public properties */
    property bool loading
    property var pandoraInterface   //Must be bound to a PandoraInterface component
    property int timeoutTime        //Defaults to 10 seconds if not set
    property var currentStationToken
    property string currentStationName
    property int currentPlaylistIndex: -1
    property var currentPlaylistItem: getAnyPlaylistItem(currentPlaylistIndex)

    property bool playlistDataAvailable: false

    /* Private properties */
    property var lastReceivedGoodData


    /* Initialization */
    Component.onCompleted: {
        loading = false;

        /* If timeoutTime is nil, set it to a default of 10 seconds */
        if(!timeoutTime || 0 === timeoutTime) {
            timeoutTime = 10000;
        }
    }

    onCurrentStationTokenChanged: {
        if(currentStationToken != "") {
            playlistDataAvailable = false;
            currentPlaylistIndex = -1;
            clearPlaylist();
            retrieveMoreSongs();
        }
    }

    ListModel {
        id: model
    }

    Timer {
        id: requestResponseTimeout

        interval: timeoutTime
        repeat: false

        /* Handle data timeout */
        onTriggered: {
            dataTimeout();
            loading = false;
            console.log("Failed to receive request for playlist data inside timeout time of", timeoutTime / 1000, "seconds");
        }
    }


    /* Public functions */

    function retrieveMoreSongs() {
        function dataRetrieved(data) {
            requestResponseTimeout.stop();
            loading = false;

            if(data.stat == "ok") {
                console.log("Playlist data received!!!");
                lastReceivedGoodData = data;

                /* Add received playlist data to the model */
                var playlistArray = data.result.items;

                if(model.count == 0) {
                    /* Don't reset index until model is updated */
                    var resetPlaylistIndex = true;
                }

                for ( var key in playlistArray ) {
                    var jo = playlistArray[key];

                    /* 'object-ify items in the additionalAudioUrl array */
                    if(jo.additionalAudioUrl) {
                        if(jo.additionalAudioUrl.constructor === Array) {
                            jo.audioUrlMap.extraUrls = {};
                            jo.audioUrlMap.extraUrls.aacMono = jo.additionalAudioUrl[0];
                            jo.audioUrlMap.extraUrls.aac64 = jo.additionalAudioUrl[1];
                            jo.audioUrlMap.extraUrls.aacp32 = jo.additionalAudioUrl[2];
                            jo.audioUrlMap.extraUrls.aacp64 = jo.additionalAudioUrl[3];
                            jo.audioUrlMap.extraUrls.adts24 = jo.additionalAudioUrl[4];
                            jo.audioUrlMap.extraUrls.adts32 = jo.additionalAudioUrl[5];
                            jo.audioUrlMap.extraUrls.adts64 = jo.additionalAudioUrl[6];
                            jo.audioUrlMap.extraUrls.mp3 = jo.additionalAudioUrl[7];
                            jo.audioUrlMap.extraUrls.wma = jo.additionalAudioUrl[8];
                        }
                    }

                    /* Only add songs to the playlist model */
                    if( jo.songName ) {
                        model.append(jo);
                        console.log(jo.songName);
                    }
                }

                if(resetPlaylistIndex) {
                    currentPlaylistIndex = 0;
                }

                updated();
                playlistDataAvailable = true;
            }
            else {
                console.log("Playlist data retrieval failed");
                console.log("stat:", data.stat);
                console.log("checksum:", data.result.checksum);
                console.log("stations:", data.result);
                receivedError();
            }
        }

        requestResponseTimeout.start();
        loading = true;

        pandoraInterface.retrieveMoreSongs(currentStationToken, dataRetrieved);
    }


    function clearPlaylist() {
        model.clear();
        currentPlaylistIndex = -1;
    }

    function getAnyPlaylistItem(index) {


        var default_song_json = {
            "artistName": "",
            "albumName": "",
            "songName": "",
            "albumArtUrl": "./resources/images/cover_default.png",
            "songRating": 0,
            "audioUrlMap": {
                "highQuality": {
                    "bitrate": "",
                    "encoding": "",
                    "audioUrl": "",
                    "protocol": "",
                },
                "mediumQuality": {
                    "bitrate": "",
                    "encoding": "",
                    "audioUrl": "",
                    "protocol": "",
                },
                "lowQuality": {
                    "bitrate": "",
                    "encoding": "",
                    "audioUrl": "",
                    "protocol": "",
                },
            },
            "stationId": "",
            "additionalAudioUrl": [
                "",
            ],
        }

        console.log("getAnyPlaylistItem ran");
        if( index <= model.count && index >= 0 && model.count > 0 ) {
            return model.get(index);
        }
        else {
            console.log("getAnyPlaylistItem returning an empty object");
            return default_song_json;
        }
    }

    function loadNextSong() {
        /* Update location in the playlist */
        currentPlaylistIndex++;
        console.log("advancing to the next song!");

        /* Retrieve more songs for playlist if necessary */
        if (currentPlaylistIndex >= (model.count - 1)) {
            retrieveMoreSongs();
        }
    }

    /*****************************************************
    Example playlist object

    {
         "stat": "ok",
         "result": {
             "items": [{
                 "trackToken": "40b892bc5376e695c2e5c2b347227b85af2761b6aa417f736d9a79319b8f4cb97c9695a5f9a9a32aa2abaed43571235c",
                 "artistName": "Cannabich, Christian",
                 "albumName": "London Mozart Players, Christian Cannabich: Symphonies",
                 "amazonAlbumUrl": "http://www.amazon.com/dp/B000GW8ATU/?tag=wwwpandoracom-20",
                 "songExplorerUrl": "http://www.pandora.com/xml/music/song/london-mozart-players/christian-cannabich-symphonies/2-andantino?explicit=false",
                 "albumArtUrl": "http://cont-sv5-2.pandora.com/images/public/amz/5/2/9/7/095115137925_500W_488H.jpg",
                 "artistDetailUrl": "http://www.pandora.com/christian-cannabich?...",
                 "audioUrlMap": {
                     "highQuality": {
                         "bitrate": "64",
                         "encoding": "aacplus",
                         "audioUrl": "http://audio-sjl-t1-2.pandora.com/access/166132182435087962.mp4?...",
                         "protocol": "http"
                     },
                     "mediumQuality": {
                         "bitrate": "64",
                         "encoding": "aacplus",
                         "audioUrl": "http://t1-2.cdn.pandora.com/access/4127124196771074419.mp4?...",
                         "protocol": "http"
                     },
                     "lowQuality": {
                         "bitrate": "32",
                         "encoding": "aacplus",
                         "audioUrl": "http://audio-sv5-t1-1.pandora.com/access/3464788359714661029.mp4?...",
                         "protocol": "http"
                     }
                 },
                 "itunesSongUrl": "http://click.linksynergy.com/fs-bin/stat?...",
                 "additionalAudioUrl": [
                     "http://t1-2.cdn.pandora.com/access/6705986462049243054.mp4?...",
                     "http://audio-sjl-t1-1.pandora.com/access/2473529637452270302.mp4?..."
                 ],
                 "amazonAlbumAsin": "B000GW8ATU",
                 "amazonAlbumDigitalAsin": "B003H37NN4",
                 "artistExplorerUrl": "http://www.pandora.com/xml/music/composer/christian-cannabich?explicit=false",
                 "songName": "Symphony In G Major",
                 "albumDetailUrl": "http://www.pandora.com/london-mozart-players/christian-cannabich-symphonies?...",
                 "songDetailUrl": "http://www.pandora.com/london-mozart-players/christian-cannabich-symphonies/2-andantino?...",
                 "stationId": "121193154444133035",
                 "songRating": 0,
                 "trackGain": "10.09",
                 "albumExplorerUrl": "http://www.pandora.com/xml/music/album/london-mozart-players/christian-cannabich-symphonies?explicit=false",
                 "allowFeedback": true,
                 "amazonSongDigitalAsin": "B003H39AGW",
                 "nowPlayingStationAdUrl": "http://ad.doubleclick.net/pfadx/pand.android/prod.nowplaying..."
             }, {
                 "adToken": "121193154444133035-none"
             },
             < 3 more songs >
             ]
         }
    }
    *****************************************************/

}
