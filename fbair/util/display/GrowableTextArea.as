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
  import flash.events.FocusEvent;
  import flash.events.KeyboardEvent;
  import flash.events.MouseEvent;
  import flash.ui.Keyboard;

  import mx.controls.TextArea;
  import mx.events.FlexEvent;

  public class GrowableTextArea extends TextArea {
    private static const TextPadding:int = 6;

    [Bindable] public var enabledColor:uint = 0x333333;
    [Bindable] public var disabledColor:uint = 0x808080;
    [Bindable] public var focusOutHeight:int = 25;
    [Bindable] public var focusInHeight:int = 40;
    [Bindable] public var focusOutText:String = "Write a comment...";

    private var _active:Boolean = false;

    public function GrowableTextArea() {
      addEventListener(Event.CHANGE, changed);
      addEventListener(KeyboardEvent.KEY_UP, changed);
      addEventListener(KeyboardEvent.KEY_DOWN, keyPressed);
      addEventListener(FocusEvent.FOCUS_IN, focusIn);
      addEventListener(FocusEvent.FOCUS_OUT, focusOut);
      addEventListener(FlexEvent.CREATION_COMPLETE, creationComplete);
    }
    private function creationComplete(event:FlexEvent):void {
      updateState();
    }

    // Setting active
    [Bindable] public function get active():Boolean { return _active; }
    public function set active(to:Boolean):void {
      _active = to;
      updateState();
    }

    // Update our settings based on active and all our vars
    private function updateState():void {
      setStyle("color", active ? enabledColor : disabledColor);
      if (!active) text = focusOutText;
      height = (active ? focusInHeight : focusOutHeight);
    }

    // Focusing
    private function focusIn(event:FocusEvent):void {
      active = true;
      if (text == focusOutText) text = "";
      stage.addEventListener(MouseEvent.MOUSE_UP, prepareUp, true);
    }
    private function prepareUp(event:MouseEvent):void {
      stage.removeEventListener(MouseEvent.MOUSE_UP, prepareUp, true);
      stage.addEventListener(MouseEvent.MOUSE_DOWN, stageDown, true);
    }

    private function stageDown(event:MouseEvent):void {
      if (hitTestPoint(event.stageX, event.stageY)) return;
      stage.addEventListener(MouseEvent.MOUSE_UP, stageUp, true);
    }

    private function stageUp(event:MouseEvent):void {
      stage.removeEventListener(MouseEvent.MOUSE_UP, stageUp, true);
      if (hitTestPoint(event.stageX, event.stageY)) return;
      if (stage.focus && contains(stage.focus))
        stage.focus = null;
    }

    private function focusOut(event:FocusEvent = null):void {
      stage.removeEventListener(MouseEvent.MOUSE_DOWN, stageDown, true);
      stage.removeEventListener(MouseEvent.MOUSE_UP, stageUp, true);
      active = (text.length > 0);
    }

    // Height change
    override public function set height(to:Number):void {
      // If no text at all, or focus out text, then do as you wish
      if (text == focusOutText || text.length == 0) super.height = to;
      // Otherwise, you're not allowed to become smaller than our user text
      else super.height = Math.max(to, realTextHeight);
    }

    // Called when the user presses a key
    private function changed(event:Event):void {
      super.height = Math.max(realTextHeight, focusInHeight);
    }

    // Gets our real Text height
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
