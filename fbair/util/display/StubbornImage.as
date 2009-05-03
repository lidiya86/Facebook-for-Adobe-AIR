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
// This class extends display:SmoothImage
// As it's name implies, it stubbornly tries to
//   load it's image assets. It doesn't give up.
package fbair.util.display {
  import air.net.URLMonitor;

  import fbair.util.Output;
  import fbair.util.StringUtil;

  import flash.events.Event;
  import flash.events.IOErrorEvent;
  import flash.events.SecurityErrorEvent;
  import flash.events.StatusEvent;
  import flash.net.URLRequest;

  public class StubbornImage extends SmoothImage {
    private static const MaxAttempts:int = 3;
    private var attempts:int = 0;

    private var origSource:Object;

    private var urlMonitor:URLMonitor;

    public function StubbornImage() {
      addEventListener(IOErrorEvent.IO_ERROR, error);
      addEventListener(SecurityErrorEvent.SECURITY_ERROR, error);
    }

    private function error(event:Event):void {
      Output.put("Image Error : " + urlMonitor.available + ",  " + source);
      if (attempts++ < MaxAttempts) reload();
      else if (!urlMonitor.available) {
        attempts = 0;
        urlMonitor.start();
      }
    }

    private function statusChanged(event:StatusEvent):void {
      Output.put("Image Status changed: " + urlMonitor.available);
      if (urlMonitor.available)
        reload();
    }

    private function reload():void {
      Output.put("Reloading image: " + origSource);
      load(origSource);
    }

    override public function set source(new_source:Object):void {
      Output.log("Image Setting source: " + new_source);
      if (!StringUtil.empty(source)) {
        if (urlMonitor.available) {
          Output.put("Image Stopping urlMonitor");
          urlMonitor.stop();
        }
        super.source = '';
      }
      else {
        if (!urlMonitor) {
          urlMonitor = new URLMonitor(new URLRequest(String(new_source)));
          urlMonitor.addEventListener(StatusEvent.STATUS, statusChanged);
        }
        super.source = origSource = new_source;
      }
    }
  }
}
