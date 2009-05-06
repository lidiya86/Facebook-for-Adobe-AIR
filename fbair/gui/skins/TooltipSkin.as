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
// Skin for tooltips
package fbair.gui.skins {
  import flash.geom.Matrix;
  import flash.geom.Point;

  import flash.display.GraphicsPathCommand;

  import mx.skins.halo.HaloBorder;

  public class TooltipSkin extends HaloBorder {

    override protected function updateDisplayList(unscaledWidth:Number,
                                                  unscaledHeight:Number):void {
      super.updateDisplayList(unscaledWidth, unscaledHeight);

      var points:Vector.<Number> = new Vector.<Number>(18, true);
      var commands:Vector.<int> = new Vector.<int>(9, true);

      // draw rect
      commands[0] = GraphicsPathCommand.MOVE_TO;
        points[0] = 0; points[1] = 0;
      commands[1] = GraphicsPathCommand.LINE_TO;
        points[2] = unscaledWidth; points[3] = 0;
      commands[2] = GraphicsPathCommand.LINE_TO;
        points[4] = unscaledWidth; points[5] = unscaledHeight;
      commands[3] = GraphicsPathCommand.LINE_TO;
        points[6] = 0; points[7] = unscaledHeight;
      commands[4] = GraphicsPathCommand.LINE_TO;
        points[8] = 0; points[9] = 0;

      // draw arrow
      var arrowSize:Number = 4;
      var midPoint:Number = Math.round(unscaledWidth * 0.5);
      commands[5] = GraphicsPathCommand.MOVE_TO;
        points[10] = midPoint; points[11] = -arrowSize;
      commands[6] = GraphicsPathCommand.LINE_TO;
        points[12] = midPoint + arrowSize; points[13] = 0;
      commands[7] = GraphicsPathCommand.LINE_TO;
        points[14] = midPoint - arrowSize; points[15] = 0;
      commands[8] = GraphicsPathCommand.LINE_TO;
        points[16] = midPoint; points[17] = -arrowSize;

      graphics.clear();
      graphics.beginFill(style("backgroundColor", 0x000000));
      graphics.drawPath(commands, points);
      graphics.endFill();
    }

    private function style(... styles):* {
      if (!styles || styles.length == 0) return null;
      for (var i:int = 0; i < styles.length-1; i++)
        if (getStyle(styles[i]))
          return getStyle(styles[i]);
      return styles[styles.length-1];
    }
  }
}
