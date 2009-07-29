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
package fbair.gui.filters {
  import fbair.util.display.SpritedImage;
  import fbair.util.display.StubbornImage;

  import flash.display.DisplayObject;

  import mx.containers.Canvas;

  public class FilterImage extends Canvas {
    public static const IMAGE_SIZE:int = 16;

    private var image:*;

    override public function set data(new_data:Object):void {
      if (image) removeChild(DisplayObject(image));

      super.data = new_data;
      if (!data) return;

      if (data.is_page) {
        image = new StubbornImage();
      }
      else {
        image = new SpritedImage();
        image.offsetX = IMAGE_SIZE;
      }
      image.source = data.icon_url;
      image.width = image.height = IMAGE_SIZE;

      addChild(DisplayObject(image));
    }
  }
}
