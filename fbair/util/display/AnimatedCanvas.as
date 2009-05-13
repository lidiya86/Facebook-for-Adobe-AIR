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
  import fb.util.FlexUtil;

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
    [Bindable] public var _animateIn:Boolean = true;
    public function get animateIn():Boolean { return _animateIn; }
    public function set animateIn(to:Boolean):void {
//      trace("setting animateIn on "+this);
      _animateIn = to;
    }

    // should animate to 0 when destroyed
    [Bindable] public var _animateOut:Boolean = false;
    public function get animateOut():Boolean { return _animateOut; }
    public function set animateOut(to:Boolean):void {
//      trace("setting animateOut on "+this);
      _animateOut = to;
    }

    // subsequent resize operations are immediate
    [Bindable] public var animateOnce:Boolean = false;

    // animate speed. 0 is stopped and 1 is immediate
    [Bindable] public var speed:Number = 0.15;

    // animate speed. 0 is stopped and 1 is immediate
    [Bindable] public var gain:Number = 0.30;

    // epsilon is a very small value, we use it in this case when we're
    //   'close enough' to the target value to end the animation
    private var epsilon:Number = 0.1;

    // number of frames animated so far
    private var frameNum:int = 0;

    // we maintain this to know if we were animating larger or smaller so that
    //   in case we accelerate past our target, we still know when to stop
    private var isGrowing:Boolean;

    private var isAnimating:Boolean = false;
    private var velocity:Number = 0;
    private var _visible:Boolean = true;
    private var managedHeight:Number = 0;
    private var allowSetHeight:Boolean = true;
    private var hasBeenVisible:Boolean = false;

    public function AnimatedCanvas() {
      addEventListener(Event.ADDED_TO_STAGE, addedToStage);
    }

    private function addedToStage(event:Event):void {
      trace("added to stage "+this+" animateIn:"+animateIn+" Animate:"+Animate+" isVisible:"+isVisible());
      animate = animateIn && Animate && isVisible();
      if (animate) {
        managedHeight = 0;
        startAnimation();
      }
    }

    public function remove(immediately:Boolean = false):void {
      if (animateOut && hasBeenVisible && !immediately && isVisible()) {
        animate = true;
        measuredHeight = 0;
        allowSetHeight = false;
        alpha = 0.3;
        startAnimation();
        addEventListener(TWEEN_COMPLETE, removeCanvas);
      } else {
        removeCanvas();
      }
    }

    private function removeCanvas(evt:Event = null):void {
      removeEventListener(TWEEN_COMPLETE, removeCanvas);
      alpha = 1;
      if (parent) parent.removeChild(this);
    }

    [Bindable]
    public function get immediateVisible():Boolean {
      return super.visible;
    }
    public function set immediateVisible(to:Boolean):void {
      if (to == true) hasBeenVisible = true;
      super.includeInLayout = super.visible = _visible = to;
    }

    [Bindable]
    override public function get visible():Boolean { return _visible; }
    override public function set visible(to:Boolean):void {
      if (visible == to) return;
      _visible = to;

      if (visible) {
        if (measuredHeight) hasBeenVisible = true;
        immediateVisible = true;
        if (Animate && animateIn && isVisible()) {
          animate = true;
          managedHeight = 0;
          startAnimation();
        }
      } else {
        if (Animate && animateOut && hasBeenVisible && isVisible()) {
          animate = true;
          allowSetHeight = false;
          super.measuredHeight = 0;
          startAnimation();
          addEventListener(TWEEN_COMPLETE, hideCanvas);
        } else {
          immediateVisible = false;
        }
      }
    }

    private function hideCanvas(event:Event):void {
      removeEventListener(TWEEN_COMPLETE, hideCanvas);
      immediateVisible = false;
    }

    override public function get measuredHeight():Number {
      return managedHeight;
    }

    override public function set measuredHeight(to:Number):void {
      if (to == 0) return;
      if (visible) hasBeenVisible = true;
      if ((super.measuredHeight == to && managedHeight == to) ||
          !allowSetHeight) return;

      super.measuredHeight = to;
      if (isAnimating) return;

      if (!animate || !Animate || !isVisible())
        managedHeight = to;
      else
        startAnimation();
    }

    public function startAnimation():void {
      if (isAnimating) return;
      clipContent = isAnimating = true;
      addEventListener(Event.ENTER_FRAME, tweenFrame);
      frameNum = 0;
      isGrowing = managedHeight < super.measuredHeight;
    }

    public function endAnimation():void {
      if (!isAnimating) return;
      clipContent = isAnimating = false;
      removeEventListener(Event.ENTER_FRAME, tweenFrame);
      managedHeight = super.measuredHeight;
      allowSetHeight = true;
      velocity = 0;
      if (animateOnce) animate = false;
      invalidateSize();
      dispatchEvent(new Event(TWEEN_COMPLETE));
    }

    private function tweenFrame(event:Event):void {
      Output.assert(frameNum++ < 64, "Runaway animation in: " + this);

      var targetV:Number = (super.measuredHeight - managedHeight) * speed;
      velocity += (targetV - velocity) * gain;
      managedHeight += velocity;

      if ((isGrowing && (managedHeight + epsilon >= super.measuredHeight)) ||
          (!isGrowing && (managedHeight - epsilon <= super.measuredHeight))) {
        endAnimation();
      }
      invalidateSize();
    }

    public function isVisible():Boolean {
      trace("isVisible? "+this);
      if (!stage) return false;
      var elder:DisplayObject = parent;
      do {
        if (!elder.visible) return false;
      } while (elder = elder.parent);
      return true;
    }
  }
}
