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
// Simple TextArea extension grows with text size
package fbair.util.display {
  import fb.util.Output;

  import flash.events.Event;
  import flash.events.KeyboardEvent;
  import flash.ui.Keyboard;

  import mx.controls.TextArea;

  public class GrowableTextArea extends TextArea {
    private static const TextPadding:int = 6;

    public var minTextHeight:int = 0;

    public function GrowableTextArea() {
      addEventListener(Event.CHANGE, changed);
      addEventListener(KeyboardEvent.KEY_UP, changed);
      addEventListener(KeyboardEvent.KEY_DOWN, keyPressed);
    }

    override public function set height(to:Number):void {
      super.height = Math.max(to, realTextHeight);
    }

    private function changed(event:Event):void {
      height = Math.max(realTextHeight, minTextHeight);
    }

    private function get realTextHeight():Number {
      return textField.textHeight + TextPadding +
        getStyle("paddingTop") + getStyle("paddingBottom");
    }

    // This solves an issue where holding Shift and hitting space
    //   wasn't entering a space
    private function keyPressed(event:KeyboardEvent):void {
      if (event.keyCode == Keyboard.SPACE && event.shiftKey) {
        textField.replaceText(caretIndex, caretIndex, ' ');
        setSelection(caretIndex+1, caretIndex+1);
      }
    }

    private function get caretIndex():int { return textField.caretIndex; }
  }
}
