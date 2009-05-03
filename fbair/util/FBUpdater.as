/*
  Copyright Facebook Inc.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
 */
// This class checks our version number and sees if we want to do an update
// It also checks to see if this is our first run since an update.
//   and marks that version for the check again on the next launch, etc.
package fbair.util {
  import fb.display.FBDialog;

  import flash.desktop.Updater;
  import flash.events.Event;
  import flash.events.IOErrorEvent;
  import flash.filesystem.File;
  import flash.filesystem.FileMode;
  import flash.filesystem.FileStream;
  import flash.net.URLLoader;
  import flash.net.URLRequest;
  import flash.net.URLStream;
  import flash.utils.ByteArray;

  public class FBUpdater {
    private static const version:Number = 0.73;

    private static const InfoURL:String = FBDialog.FacebookURL +
      "/fbair/fbair_version.php";
    private static const FileName:String = "Facebook_for_Adobe_AIR.air";
    private static const VersionFile:String = "Preferences/version.txt";

    private static var checkedForNewVersion:Boolean = false;
    private static var newest_version:Number;
    private static var stream:URLStream = new URLStream();
    private static var bytes:ByteArray = new ByteArray();

    private static var _firstRun:Boolean;
    // Whether or not this is our first run post-update
    public static function firstRun():Boolean {
      if (_firstRun) return _firstRun;
      var versionFile:File = File.applicationStorageDirectory
        .resolvePath(VersionFile);
      if (versionFile.exists) {
        var versionStream:FileStream = new FileStream();
        versionStream.open(versionFile, FileMode.READ);
        var previousVersion:String =
          versionStream.readUTFBytes(versionStream.bytesAvailable);
        versionStream.close();
        _firstRun = (previousVersion != String(version));
      } else _firstRun = true;
      return _firstRun;
    }

    // Saves our version number to a file for checking later
    public static function saveVersionToFile():void {
      var versionFile:File = File.applicationStorageDirectory
        .resolvePath(VersionFile);
      var versionStream:FileStream = new FileStream();
      versionStream.open(versionFile, FileMode.WRITE);
      versionStream.writeUTFBytes(String(version));
      versionStream.close();
    }

    // Deletes our autoupdate file if present
    public static function deleteInstallationFile():void {
      var file:File = File.desktopDirectory.resolvePath(FileName);
      if (file.exists) {
        try { file.deleteFile(); }
        catch(error:Error) {/* do nothing */}
      }
    }

    // This is what we call once per app load to check for a new version
    public static function checkForNewVersion(event:Event = null):void {
      if (checkedForNewVersion) return;
      checkedForNewVersion = true;

      var loader:URLLoader = new URLLoader();
      loader.addEventListener(Event.COMPLETE, versionDataLoaded);
      loader.addEventListener(IOErrorEvent.IO_ERROR, errorOccurred);
      loader.load(new URLRequest(InfoURL));
    }

    // This is called when we've loaded the version xml from our server
    // At this point we can check to see if we're out of date
    private static function versionDataLoaded(event:Event):void {
      var xml:XML = new XML(event.target.data);
      newest_version = xml.version;
      if (newest_version > version) {
        stream.addEventListener(Event.COMPLETE, newVersionLoaded);
        stream.addEventListener(IOErrorEvent.IO_ERROR, errorOccurred);
        stream.load(new URLRequest(xml.url));
      }
    }

    // If we've decided to downlaod a new .air file
    // This gets called when our download is complete.
    private static function newVersionLoaded(event:Event):void {
      stream.readBytes(bytes, 0, stream.bytesAvailable);

      var file:File = File.desktopDirectory.resolvePath(FileName);

      var fileStream:FileStream = new FileStream();
      fileStream.addEventListener(Event.CLOSE, fileClosed);

      fileStream.openAsync(file, FileMode.WRITE);
      fileStream.writeBytes(bytes, 0, bytes.length);
      fileStream.close();
    }

    // When we've totally written to the file this gets called.
    // So at this point we're ready to trigger the auto-update
    private static function fileClosed(event:Event):void {
      var updater:Updater = new Updater();
      var file:File = File.desktopDirectory.resolvePath(FileName);
      updater.update(file, String(newest_version));
    }

    // Called if we failed to load something somewhere and we don't care
    //   we'll just give up.
    private static function errorOccurred(event:Event):void {
      Output.put("Failed to fetch Auto-Update data");
    }
  }
}
