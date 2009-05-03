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
package fb.net {
  import air.net.URLMonitor;

  import com.adobe.serialization.json.JSON;

  import fb.FBEvent;

  import fbair.util.Output;

  import flash.events.Event;
  import flash.events.IOErrorEvent;
  import flash.events.SecurityErrorEvent;
  import flash.events.StatusEvent;
  import flash.net.URLLoader;
  import flash.net.URLRequest;

  // Simple URLLoader extender will wrap the result from
  // it's own COMPLETE in a JSON.decode then dispatch a
  // FBEvent.SUCCESS with the JSON data.
  public class JSONLoader extends URLLoader {
    private static const MaxAttempts:int = 2;
    private var attempts:int = 0;

    private var request:URLRequest;
    private var urlMonitor:URLMonitor;

    public function JSONLoader(new_request:URLRequest = null) {
      request = new_request;
      addEventListener(Event.COMPLETE, success);
      addEventListener(IOErrorEvent.IO_ERROR, error);
      addEventListener(SecurityErrorEvent.SECURITY_ERROR, error);
    }

    private function error(event:Event):void {
      Output.put("JSON Error: " + urlMonitor.available);
      dispatchEvent(new FBEvent(FBEvent.RETRY));
      if (urlMonitor.available) {
        if (attempts++ < MaxAttempts) reload();
      }
      else {
        attempts = 0;
        urlMonitor.start();
      }
    }

    private function statusChanged(event:StatusEvent):void {
      Output.put("JSON Status changed: " + urlMonitor.available);
      if (urlMonitor.available)
        reload();
    }
    
    public function reload():void {
      Output.put("Reloading JSON");
      load(request);
    }

    override public function load(new_request:URLRequest):void {
      if (++attempts > MaxAttempts) return;
      Output.log("JSON Loading: " + new_request.url);
      if (new_request) request = new_request;
      if (!urlMonitor) {
        urlMonitor = new URLMonitor(request);
        urlMonitor.addEventListener(StatusEvent.STATUS, statusChanged);
      }
      super.load(new_request);
    }

    private function success(event:Event):void {
      Output.log("JSON Return:", event.target.data);
      if (event.target.data.indexOf("<") != 0) {
        var eventData:* = JSON.decode(event.target.data);
        if (eventData.constructor == Object && eventData.error_code) {
          Output.put("Server Error", eventData);
          fbair.loadingIndicator.errorStatus("Server Error (Click To Retry)",
            function():void { attempts = 0; reload(); } , true);
          dispatchEvent(new FBEvent(FBEvent.FAILURE, eventData));
          urlMonitor.start();
        }
        else {
          urlMonitor.stop();
          dispatchEvent(new FBEvent(FBEvent.SUCCESS, eventData));
        }
      } else {
        Output.put("Server XML returned", event.target.data);
        fbair.loadingIndicator.errorStatus("Server XML (Click To Retry)",
          function():void { attempts = 0; reload(); } , true);
        dispatchEvent(new FBEvent(FBEvent.FAILURE));
        urlMonitor.start();
      }
    }
  }
}
