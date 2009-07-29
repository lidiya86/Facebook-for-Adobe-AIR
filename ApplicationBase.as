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
  import fb.util.FlexUtil;
  import fb.util.Output;

  import flash.events.Event;
  import flash.events.KeyboardEvent;
  import flash.ui.Keyboard;

  import mx.core.WindowedApplication;

  public class ApplicationBase extends WindowedApplication {
    // Our app id
    public static const AppID:Number = 62972033868;//75647677556;

    public function ApplicationBase() {
      layout = "absolute";
      showGripper = showStatusBar = false;
      addEventListener(Event.ADDED, added);
      addEventListener(Event.ADDED_TO_STAGE, addedToStage);
    }

    private function addedToStage(event:Event):void {
      stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDown);
    }

    private function added(event:Event):void {
      if (event.target == this) return;
      FlexUtil.simplify(event.target);
    }

    // Keybord shortcut to dump data
    private function keyDown(event:KeyboardEvent):void {
      if (event.commandKey && event.keyCode == Keyboard.D)
        Output.logDump();
    }
  }
}
