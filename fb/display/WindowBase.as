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
package fb.display {
  import flash.events.Event;

  import mx.core.Container;
  import mx.core.ScrollPolicy;
  import mx.core.Window;
  
  public class WindowBase extends Window {
    public function WindowBase() {
      alwaysInFront = true;
      showStatusBar = false;
      resizable = minimizable = maximizable = false;
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
    }
  }
}
