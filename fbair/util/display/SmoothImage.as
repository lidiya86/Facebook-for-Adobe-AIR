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
// This class extends mx:Image to provide bicubic smoothing to loaded images
package fbair.util.display {
  import flash.display.Bitmap;
  import flash.display.Loader;
  import flash.events.Event;

  import mx.controls.Image;
  import mx.core.mx_internal;

  use namespace mx_internal;

  public class SmoothImage extends Image {
    override mx_internal function
      contentLoaderInfo_completeEventHandler(event:Event):void {
      var smoothLoader:Loader = event.target.loader as Loader;
      var smoothImage:Bitmap = smoothLoader.content as Bitmap;
      if (smoothImage)
        smoothImage.smoothing = true;

      super.contentLoaderInfo_completeEventHandler(event);
    }
  }
}
