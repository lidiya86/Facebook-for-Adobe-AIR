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
package {
  import flash.data.EncryptedLocalStore;
  import flash.display.InteractiveObject;
  import flash.events.Event;
  import flash.utils.ByteArray;

  import mx.controls.TextArea;
  import mx.core.Container;
  import mx.core.ScrollPolicy;
  import mx.core.WindowedApplication;

  public class ApplicationBase extends WindowedApplication {
    // Our app id
    public static const AppID:Number = 75647677556;
    
    public function ApplicationBase() {
      layout = "absolute";
      showGripper = showStatusBar = false;
      addEventListener(Event.ADDED, added);
    }

    private function added(event:Event):void {
      clean(event.target);
    }
    
    private function clean(container:*):void {
      if (container == this) return;
      
      // Automagic scrollbars and masks in flex cause so much pain
      //   and trouble, that we're going to remove them for all
      //   containers added to our application. Take that, flex!
      if (container is Container) {
        container.clipContent = false;
        container.horizontalScrollPolicy =
        container.verticalScrollPolicy = ScrollPolicy.OFF;
        
        for (var i:int = 0; i < container.numChildren; i++)
          clean(container.getChildAt(i));
      }
      
      // We don't want tab enabled for anything but text
      if (container is InteractiveObject &&
          !(container is TextArea))
        container.tabEnabled = false;
    }

    // We manage locally stored preferences with these functions
    public static function getPreference(prefName:String):Object {
      var bytes:ByteArray = EncryptedLocalStore.getItem(prefName);
      if (!bytes) return null;
      return bytes.readObject();
    }

    public static function setPreference(prefName:String, 
                                         prefObject:Object):void {
      var bytes:ByteArray = new ByteArray();
      bytes.writeObject(prefObject);
      EncryptedLocalStore.setItem(prefName, bytes);
    }
  }
}
