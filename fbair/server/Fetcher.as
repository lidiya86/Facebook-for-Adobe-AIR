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
package fbair.server {
  import fb.FBAPI;
  import fb.FBConnect;
  import fb.FBEvent;
  import fb.net.JSONLoader;

  import flash.events.Event;
  import flash.events.EventDispatcher;
  import flash.events.TimerEvent;
  import flash.utils.Timer;

  import mx.events.FlexEvent

  public class Fetcher extends EventDispatcher {
    // Singular instance
    public static var steve:Fetcher = new Fetcher();

    // Our queries
    public static var queries:Object = new Object();

    // Polling delay
    private static const PollingDelay:int = 120000;

    // Our polling timer
    private var pollingTimer:Timer = new Timer(PollingDelay);

    // Time since our last update
    public static var updateTime:Number = 0;

    
    public function Fetcher() {
      // Listen to our polling timer
      pollingTimer.addEventListener(TimerEvent.TIMER, poll);
    }

    // Called only once when initialization is complete.
    public function beginPolling():void {
      // We need to have a nile AND be authed
      if (FBConnect.status != FBConnect.Connected) return;

      // Let's do this thing...
      FBConnect.dispatcher.dispatchEvent(
        new FBEvent(FBEvent.ALERT, "Loading Stream"));
      poll();
    }


    // Called on a loop to fetch new entries from the stream
    public function poll(event:TimerEvent = null):void {
      pollingTimer.reset();

      // Clear our queries and call for new
      queries = new Object();
      dispatchEvent(new FBEvent(FBEvent.FETCHING_DATA));

      // Now call the server!
      var query:JSONLoader = FBAPI.callMethod("fql.multiquery",
                                              {queries:queries});
      query.addEventListener(FBEvent.SUCCESS, updatesReturned);
      query.addEventListener(FBEvent.RETRY, queryRetried);
    }

    // Called when a net connection was flaky and the query is reattempted
    private function queryRetried(event:FBEvent):void {
      FBConnect.dispatcher.dispatchEvent(new FBEvent(FBEvent.ALERT,
        "Connecting to Facebook"));
    }

    // Called every time we have new updates from the server
    private function updatesReturned(event:FBEvent):void {
      // Dispatch that we're happy
      FBConnect.dispatcher.dispatchEvent(new FBEvent(FBEvent.RESOLVED));

      // Now dispatch all of it!
      dispatchEvent(new FBEvent(FBEvent.DATA_RECEIVED,
        FBAPI.multiqueryByKey(event.data)));

      // Update our currentTime
      updateTime = (new Date()).time;

      // Begin timer for next run
      pollingTimer.start();
    }
  }
}
