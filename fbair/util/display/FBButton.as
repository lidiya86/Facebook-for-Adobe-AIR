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
// A Button with styles per state
package fbair.util.display {
  import flash.events.Event;
  import flash.events.MouseEvent;

  import mx.containers.Box;

  public class FBButton extends Box {

    public static const UP:String = "Up";
    public static const OVER:String = "Over";
    public static const DOWN:String = "Down";
    public static const DISABLED:String = "Disabled";

    private var _autoStyle:Boolean = false;
    private var _styleNamePrefix:String = "fbButton";
    private var _state:String = UP;
    private var grabbed:Boolean = false;

    public function FBButton() {
      buttonMode = true;
      mouseChildren = false;

      addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
      addEventListener(MouseEvent.ROLL_OUT, rollOutHandler);
      addEventListener(MouseEvent.ROLL_OVER, rollOverHandler);
    }

    override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
      trace(unscaledWidth+", "+unscaledHeight);
      super.updateDisplayList(unscaledWidth, unscaledHeight);
    }

    [Bindable]
    public function get autoStyle():Boolean { return _autoStyle; }
    public function set autoStyle(to:Boolean):void {
      if (_autoStyle == to) return;
      _autoStyle = to;
      compileStyleName();
    }

    [Bindable]
    public function get styleNamePrefix():String { return _styleNamePrefix; }
    public function set styleNamePrefix(to:String):void {
      if (_styleNamePrefix == to) return;
      _styleNamePrefix = to;
      compileStyleName();
    }

    [Bindable]
    public function get state():String { return _state; }
    public function set state(to:String):void {
      if (_state == to) return;
      _state = to;
      compileStyleName();
    }

    override public function set enabled(to:Boolean):void {
      if (super.enabled == to) return;
      super.enabled = to;
      grabbed = false;
      state = enabled ? UP : DISABLED;
    }

    override public function set visible(to:Boolean):void {
      if (super.visible == to) return;
      super.visible = to;
      grabbed = false;
      state = enabled ? UP : DISABLED;
    }

    protected function mouseDownHandler(event:MouseEvent):void {
      if (!enabled) return;
      stage.addEventListener(MouseEvent.MOUSE_UP, stageMouseUp);
      stage.addEventListener(Event.MOUSE_LEAVE, stageMouseUp);
      grabbed = true;
      state = DOWN;
    }

    protected function stageMouseUp(event:Event):void {
      stage.removeEventListener(Event.MOUSE_LEAVE, stageMouseUp);
      stage.removeEventListener(MouseEvent.MOUSE_UP, stageMouseUp);
      grabbed = false;
      if (enabled) {
        state = UP;
      }
    }

    protected function rollOutHandler(event:MouseEvent):void {
      if (!enabled) return;
      if (grabbed) {
        state = OVER;
      } else {
        state = UP;
      }
    }

    protected function rollOverHandler(event:MouseEvent):void {
      if (!enabled) return;
      if (grabbed) {
        state = DOWN;
      } else {
        state = OVER;
      }
    }

    private function compileStyleName():void {
      if (!autoStyle) return;
      styleName = styleNamePrefix + state;
    }

  }
}
