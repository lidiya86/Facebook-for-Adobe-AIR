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
package fbair.util {
  import fb.FBAPI;
  import fb.FBEvent;
  import fb.util.Output;

  import fbair.util.FBUpdater;

  import flash.events.Event;
  import flash.events.EventDispatcher;

  import mx.core.Application;
  import mx.events.FlexEvent;

  // This class holds a reference to all the data about
  //   any profile-id we've fetched.
  //
  // It batches user fetches per frame with fql to reduce
  //   the number of round trips to the server.
  //
  // You can check to see if the ID of interest is already
  //    cached with Profile.hasProfile(profileID)
  // And if true, you can get the data out of Profile.cache[profileID]
  // Each object in the cache contains:  {id, name, pic_square, url}
  //
  // If the item is not already cached.  You want to call:
  //   Profile.getProfile(profileID) or
  //   Profile.getProfiles(Array[profileID])
  //
  // They will return an EventDispatcher that'll dispatch
  //   PROFILE_FETCHED with an FBEvent that has as it's data
  //   the values for the requested profileID.
  //
  // My id is 688626964.  So an example of how to get my information would be:
  //   Profile.getProfile(688626964).addEventListener(PROFILE_FETCHED,
  //     function(event:FBEvent):void {
  //       trace("My name is : " + event.data.name);
  //       trace("My profile url is : " + event.data.url);
  //       trace("My profile pic is at : " + event.data.pic_square);
  //     });
  public class ProfileCache {
    public static const PROFILE_FETCHED:String = "profileFetched";

    // How long till our profile data is "old"
    private static const MaxProfileAge:int = 86400; // One day

    // Contains all the Profile objects already fetched.
    // key => profileID
    // value => {id, name, pic_square, url}
    public static var cache:Object = new Object();

    // This holds the list of every id requested thus far this frame
    // So that we can batch-request them at end of frame
    private static var queuedRequests:Object = new Object;

    // Initializing
    private static var initialized:Boolean = initialize();
    private static function initialize():Boolean {
      Application.application.addEventListener(FlexEvent.INITIALIZE,
        opening);
      Application.application.addEventListener(Event.CLOSING,
        closing);
      return true;
    }

    // Laod preferences
    private static function opening(event:FlexEvent):void {
      if (!FBUpdater.firstRun()) {
        Output.log("Loading profile cache");

        var profileCache:Object = ApplicationBase.getPreference("profileCache");
        if (profileCache) cache = profileCache;
      }
    }

    // Simply tells us whether given profileID is already cached
    public static function hasProfile(profileID:String):Boolean {
      return cache.hasOwnProperty(profileID) &&
        (new Date().time / 1000) - cache[profileID].time < MaxProfileAge;
    }

    // If you want to request a bunch of ID's at once, you can pass
    //   an entire array to this function.
    // When the returned EventDispatcher fires PROFILE_FETCHED
    //   you can be guaranteed every requested profileID
    //   will be cached in ProfileCache.cache for access.
    public static function getProfiles(profileIDs:Array):EventDispatcher {
      var dispatcher:EventDispatcher;
      for each (var profileID:String in profileIDs)
        dispatcher = getProfile(profileID);
      return dispatcher;
    }

    // Main Getter for a profileID.
    // Returns an EventDispatcher to fire when it has the data.
    // The dispatcher will fire immediately if the data is already cached.
    public static function getProfile(profileID:String):EventDispatcher {
      if (!profileID || profileID == "0" || profileID == "null")
        return new EventDispatcher();

      // Set an event listener to request these at end of frame
      Application.application.addEventListener(
        Event.ENTER_FRAME, fetchProfiles);

      // We put all our requests into a queue to fire at end of frame
      if (! queuedRequests[profileID]) {
        var dispatcher:EventDispatcher = new EventDispatcher();
        queuedRequests[profileID] = dispatcher;
      }

      return queuedRequests[profileID];
    }

    // Internal utility function to fetch all the profiles from the server
    private static function fetchProfiles(event:Event):void {
      Application.application.removeEventListener(
        Event.ENTER_FRAME, fetchProfiles);

      // Loop thru all requested id's and determine which are uncached
      var uncached_requests:Object = new Object();
      var cached_requests:Object = new Object();
      for (var request_id:String in queuedRequests) {
        if (hasProfile(request_id))
          cached_requests[request_id] = queuedRequests[request_id];
        else uncached_requests[request_id] = queuedRequests[request_id];
      }

      var uncached_ids:Array = new Array();
      for (var uncached_request_id:String in uncached_requests)
        uncached_ids.push(uncached_request_id);

      // If we have some uncached, then request them from the server.
      if (uncached_ids.length > 0) {
        FBAPI.callMethod("fql.query", {
          query:"select id, name, pic_square, " +
            "url from profile where id in " +
            "(" + uncached_ids.join(", ")  + ")"
        }).addEventListener(FBEvent.SUCCESS, function(event:FBEvent):void {
          var results:Array = event.data as Array;
          var result:Object;

          // Put all results into the cache first, and timestamp
          var now:Number = (new Date().time / 1000);
          for each (result in results) {
            result.time = now;
            cache[result.id] = result;
          }

          // Now fire every event dispatcher for every request
          for each (result in results)
            uncached_requests[result.id].dispatchEvent(
              new FBEvent(PROFILE_FETCHED, cache[result.id]));
        });
      }

      // Fire an event dispatcher for everything already cached right now.
      for (var cached_id:String in cached_requests)
        cached_requests[cached_id].dispatchEvent(
          new FBEvent(PROFILE_FETCHED, cache[cached_id]));

      // Clear our list of queued requests now that we're done
      queuedRequests = new Object();
    }

    // Save preferences at end
    private static function closing(event:Event):void {
      ApplicationBase.setPreference("profileCache", cache);
    }
  }
}
