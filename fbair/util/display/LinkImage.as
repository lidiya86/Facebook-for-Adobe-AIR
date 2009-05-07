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
// This class extends display:StubbonImage to provide:
//   url:String When clicked it'll navigate to this url
// LinkImage is also careful to utilize maxWidth/maxHeight
//   properly.
package fbair.util.display {
  import fb.util.Output;

  import fbair.util.StringUtil;
  import fbair.util.display.StubbornImage;

  import flash.events.Event;
  import flash.events.MouseEvent;
  import flash.net.URLRequest;
  import flash.net.navigateToURL;

  public class LinkImage extends StubbornImage {
    private var _url:String;

    public function LinkImage() {
      addEventListener(MouseEvent.CLICK, gotoLink);
      addEventListener(Event.COMPLETE, imageLoaded);
    }

    [Bindable]
    public function get url():String { return _url; }
    public function set url(to:String):void {
      _url = to;
      buttonMode = useHandCursor = !StringUtil.empty(url);
    }

    public function gotoLink(event:MouseEvent=null):void {
      if (url) navigateToURL(new URLRequest(url));
    }

    // Unfortunately setting maxWidth and maxHeight
    //   on mx:Image doesn't always do the trick..
    // So we listen for image loading completion here
    //   and set their sizes manually.
    private function imageLoaded(event:Event):void {
      if (explicitMaxWidth && explicitMaxHeight) {
        var maxAspectRatio:Number = explicitMaxWidth / explicitMaxHeight;
        if (aspectRatio > maxAspectRatio) {
          boundByWidth()
        } else {
          boundByHeight();
        }
      } else if (explicitMaxWidth) {
        boundByWidth();
      } else if (explicitMaxHeight) {
        boundByHeight();
      }
    }

    private function get aspectRatio():Number {
      return contentWidth / contentHeight;
    }

    private function boundByWidth():void {
      width = Math.min(contentWidth, explicitMaxWidth);
      height = width / aspectRatio;
    }

    private function boundByHeight():void {
      height = Math.min(contentHeight, explicitMaxHeight);
      width = height * aspectRatio;
    }
  }
}
