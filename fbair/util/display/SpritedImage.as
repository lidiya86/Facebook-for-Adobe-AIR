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
// This class creates a sprite mask around a sprited image
package fbair.util.display {
  import mx.containers.Canvas;
  import flash.display.Shape;

  public class SpritedImage extends Canvas {
    public var img:StubbornImage;

    private var maskShape:Shape;
    private var _offsetX:Number = 0;
    private var _offsetY:Number = 0;

    public function SpritedImage() {
      img = new StubbornImage();
      maskShape = new Shape();
    }

    override protected function createChildren():void {
      super.createChildren();
      rawChildren.addChild(maskShape);
      mask = maskShape;

      addChild(img);
    }

    [Bindable]
    public function get source():Object { return img.source; }
    public function set source(new_source:Object):void {
      img.source = new_source;
    }

    [Bindable]
    public function get offsetX():Number { return _offsetX; }
    public function set offsetX(to:Number):void {
      _offsetX = to;
      img.x = -to;
    }

    [Bindable]
    public function get offsetY():Number { return _offsetY; }
    public function set offsetY(to:Number):void {
      _offsetY = to;
      img.y = -to;
    }

    override public function set width(to:Number):void {
      super.width = to;
      addEventListener(Event.RENDER, drawMask);
    }

    override public function set height(to:Number):void {
      super.height = to;
      addEventListener(Event.RENDER, drawMask);
    }

    private function drawMask(event:Event):void {
      removeEventListener(Event.RENDER, drawMask);
      maskShape.graphics.clear();
      maskShape.graphics.beginFill(0);
      maskShape.graphics.drawRect(0,0,width,height);
      maskShape.graphics.endFill();
    }
  }
}
