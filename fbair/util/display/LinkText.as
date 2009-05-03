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
package fbair.util.display {
  import flash.events.MouseEvent;
  import flash.net.URLRequest;
  import flash.net.navigateToURL;

  import mx.controls.Text;

  // Like an HTML <a> tag, but multi-line
  public class LinkText extends Text {
    [Bindable] public var url:String;

    public function LinkText() {
      buttonMode = useHandCursor = true;
      mouseChildren = false;
      addEventListener(MouseEvent.MOUSE_OVER, mouseOver);
      addEventListener(MouseEvent.MOUSE_OUT, mouseOut);
      addEventListener(MouseEvent.CLICK, clicked);
    }

    private function clicked(event:MouseEvent):void {
      if (url) navigateToURL(new URLRequest(url));
    }

    private function mouseOver(event:MouseEvent):void {
      setStyle("textDecoration", "underline");
    }

    private function mouseOut(event:MouseEvent):void {
      setStyle("textDecoration", "none");
    }
  }
}
