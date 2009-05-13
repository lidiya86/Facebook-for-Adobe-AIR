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
// Animating Canvas
package fbair.util.display {
  import fb.util.Output;

  import flash.display.DisplayObject;
  import flash.events.Event;

  import mx.containers.Canvas;
  import mx.events.FlexEvent;

  public class AnimatedCanvas extends Canvas {

    [Bindable] public static var Animate:Boolean = false;

    public static const TWEEN_COMPLETE:String = "tweenComplete";

    // animates if true
    [Bindable] public var animate:Boolean = true;

    // should animate from 0 when created
    [Bindable] public var animateIn:Boolean = true;

    // should animate to 0 when destroyed
    [Bindable] public var animateOut:Boolean = false;

    // subsequent resize operations are immediate
    [Bindable] public var animateOnce:Boolean = false;

    // animate speed. 0 is stopped and 1 is immediate
    [Bindable] public var speed:Number = 0.15;

    // animate speed. 0 is stopped and 1 is immediate
    [Bindable] public var gain:Number = 0.30;
    
    // number of frames animated so far
    private var frameNum:int = 0;

    private var velocity:Number = 0;
    private var _visible:Boolean = true;
    private var managedHeight:Number = 0;
    private var allowSetHeight:Boolean = true;
    private var hasBeenVisible:Boolean = false;

    public function AnimatedCanvas() {
      addEventListener(FlexEvent.CREATION_COMPLETE, creationComplete);
    }

    public function remove():void {
      if (animateOut && hasBeenVisible) {
        animate = true;
        measuredHeight = 0;
        allowSetHeight = false;
        alpha = 0.3;
        addEventListener(TWEEN_COMPLETE, removeCanvas);
      } else {
        removeCanvas();
      }
    }

    public function removeCanvas(evt:Event = null):void {
      removeEventListener(TWEEN_COMPLETE, removeCanvas);
      alpha = 1;
      if (parent) parent.removeChild(this);
    }

    [Bindable]
    public function get immediateVisible():Boolean {
      return super.visible;
    }
    public function set immediateVisible(to:Boolean):void {
      if (to == true) {
        hasBeenVisible = true;
      }
      super.includeInLayout = super.visible = _visible = to;
    }

    [Bindable]
    override public function get visible():Boolean { return _visible; }
    override public function set visible(to:Boolean):void {
      if (super.visible == to) return;

      if (to && measuredHeight) hasBeenVisible = true;

      if (!Animate || !shouldAnimate()) {
        immediateVisible = to;
        return;
      }

      _visible = to;

      if (to == true) {
        creationComplete(null);
        immediateVisible = to;
      } else {
        if (animateOut && hasBeenVisible) {
          animate = true;
          measuredHeight = 0;
          allowSetHeight = false;
          addEventListener(TWEEN_COMPLETE, hideCanvas);
        } else {
          immediateVisible = to;
        }
      }
    }

    private function hideCanvas(event:Event):void {
      removeEventListener(TWEEN_COMPLETE, hideCanvas);
      immediateVisible = false;
    }

    private function creationComplete(event:FlexEvent):void {
      animate = animateIn;
      if (animateIn) {
        managedHeight = 0;
        measuredHeight = super.measuredHeight;
      }
    }

    override public function get measuredHeight():Number {
      return managedHeight;
    }

    override public function set measuredHeight(to:Number):void {
      if (visible) {
        hasBeenVisible = true;
      }

      if (!Animate || !shouldAnimate()) {
        managedHeight = super.measuredHeight = to;
        return;
      }

      if (super.measuredHeight == to && managedHeight == to) return;

      if (allowSetHeight) {
        super.measuredHeight = to;
        if (animate) {
          startAnimation();
        } else {
          managedHeight = to;
        }
      }
    }

    public function startAnimation():void {
      addEventListener(Event.ENTER_FRAME, tweenFrame);
      clipContent = true;
      frameNum = 0;
    }

    public function endAnimation():void {
      removeEventListener(Event.ENTER_FRAME, tweenFrame);
      clipContent = false;
      managedHeight = super.measuredHeight;
      invalidateSize();
      velocity = 0;
      allowSetHeight = true;
      if (animateOnce) {
        animate = false;
      }
      dispatchEvent(new Event(TWEEN_COMPLETE));
    }

    private function tweenFrame(event:Event):void {
      // Sanity check for runaway animations
      if (frameNum++ > 64) {
        Output.error("Runaway animation in: " + this);
        endAnimation();
        return;
      }
      var isGrowing:Boolean = managedHeight < super.measuredHeight;
      var targetV:Number = (super.measuredHeight - managedHeight) * speed;
      velocity += (targetV - velocity) * gain;
      managedHeight += velocity;
      if ((isGrowing && (managedHeight >= super.measuredHeight)) ||
          (!isGrowing && (managedHeight <= super.measuredHeight))) {
        endAnimation();
      }
      invalidateSize();
    }

    private function shouldAnimate():Boolean {
      if (!stage) return false;
      var elder:DisplayObject = parent;
      do {
        if (!elder.visible) return false;
      } while (elder = elder.parent);
      return true;
    }

  }
}
