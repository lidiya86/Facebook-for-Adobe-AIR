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
// Flexible Skin we've built for easily skinning parts of the app
package fbair.gui.skins {
  import fb.util.FlexUtil;

  import flash.geom.Matrix;
  import flash.geom.Point;

  import mx.skins.halo.HaloBorder;

  public class FBAIRSkin extends HaloBorder {
    override protected function updateDisplayList(unscaledWidth:Number,
                                                  unscaledHeight:Number):void {
      super.updateDisplayList(unscaledWidth, unscaledHeight);

      var insetT:Number = FlexUtil.getStyle(this, "insetTopBorder", "inset", 0);
      var insetB:Number = FlexUtil.getStyle(this, "insetBottomBorder", "inset", 0);
      var insetL:Number = FlexUtil.getStyle(this, "insetLeftBorder", "inset", 0);
      var insetR:Number = FlexUtil.getStyle(this, "insetRightBorder", "inset", 0);

      var upperLeft:Point = new Point(0+insetL, 0+insetT);
      var upperRight:Point = new Point(unscaledWidth-1-insetR, 0+insetT);
      var lowerLeft:Point = new Point(0+insetL, unscaledHeight-1-insetB);
      var lowerRight:Point = new Point(unscaledWidth-1-insetR,
                                       unscaledHeight-1-insetB);

      var w:Number = unscaledWidth - (insetL + insetR);
      var h:Number = unscaledHeight - (insetT + insetB);

      // draw background
      var bg:* = getStyle("backgroundColors");
      var bga:* = getStyle("backgroundAlphas");
      var bgr:* = getStyle("backgroundRatios");
      var bgp:* = getStyle("backgroundPositions");
      if (bg) {
        var i:int = 0;
        if (bg is Array) {
          if (bga == null) {
            bga = new Array(bg.length);
            for (i = 0; i < bg.length; i++) {
              bga[i] = 1;
            }
          }

          if (bgr == null) {
            bgr = new Array(bg.length);
            for (i = 0; i < bg.length; i++) {
              bgr[i] = 255 * i / (bg.length-1);
            }
          }

          if (bgp != null) {
            for (i=0; i < bgp.length; i++) {
              var y:Number = bgp[i] < 0 ? (h+bgp[i]) : bgp[i];
              bgr[i] = 255 * (y/h);
            }
          }

          var angle:Number = FlexUtil.getStyle(this, "backgroundAngle", 0);
          angle *= (Math.PI/180);

          var gradMatrix:Matrix = new Matrix();
          gradMatrix.createGradientBox(w, h, Math.PI*0.5 - angle,
                                       insetT, insetL);

          graphics.beginGradientFill("linear", bg, bga, bgr, gradMatrix);
        } else {
          if (bga == null) {
            bga = 1;
          }

          graphics.beginFill(bg, bga);
        }

        graphics.lineStyle(0, 0, 0);
        graphics.drawRect(insetT, insetL, w, h);
        graphics.endFill();
      }

      // draw borders
      drawBorder("top", upperLeft, upperRight);
      drawBorder("left", upperLeft, lowerLeft);
      drawBorder("right", upperRight, lowerRight);
      drawBorder("bottom", lowerLeft, lowerRight);
    }

    private function drawBorder(side:String, start:Point, end:Point):void {
      var borderColor:uint = FlexUtil.getStyle(this,
                               side + "BorderColor", null);
      if (borderColor) {
        var borderThickness:int = FlexUtil.getStyle(this,
          side + "BorderThickness", "borderThickness", 1);
        var borderAlpha:int = FlexUtil.getStyle(this,
          side + "BorderAlpha", "borderAlpha", 1);
        graphics.lineStyle(borderThickness, borderColor, borderAlpha);
        graphics.moveTo(start.x, start.y);
        graphics.lineTo(end.x, end.y);
      }
    }
  }
}
