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

  import flash.events.Event;
  import flash.events.EventDispatcher;

  import mx.core.Application;

  // This class is used globally to fetch comments for any story.
  // We batch them into one fql query at the end of the frame.
  //
  // To get comments, you want to call:
  //   CommentCache.getComments(postID) or
  //
  // They will return an EventDispatcher that'll dispatch
  //   COMMENTS_FETCHED with an FBEvent that has as it's data
  //   the values for the requested postID.
  //
  // Say we have post 488_188
  //   CommentCache.getComments(488_188).addEventListener(COMMENTS_FETCHED,
  //     function(event:FBEvent):void {
  //       trace("My comment is : " + event.data.text);
  //       trace("The author's id: " + event.data.fromid);
  //       trace("The time of comment was: " + event.data.time);
  //     });
  public class CommentCache {
    public static const COMMENTS_FETCHED:String = "commentFetched";
    public static const COMMENT_CREATED:String = "commentCreated";
    public static const COMMENT_REMOVED:String = "commentRemoved";

    // How long before comment data is stale
    private static const CommentLifeSpan:int = 8000;

    // We dispatch events thru here to any globally interested party
    public static var dispatcher:EventDispatcher = new EventDispatcher();

    // Our comments thus far fetched, keyed by post_id
    public static var commentCache:Object = new Object();
    private static var fetchTime:Number = 0;

    // This holds the list of every id requested thus far this frame
    // So that we can batch-request them at end of frame
    private static var queuedRequests:Object = new Object;

    // Whether we have fresh comments for a given id
    public static function hasFreshComments(post_id:String,
                                            comment_count:int):Boolean {
      return commentCache[post_id] &&
        commentCache[post_id].length == comment_count &&
        (new Date()).time - fetchTime < CommentLifeSpan;
    }

    // Remove a comment we've deleted locally
    public static function removeComment(commentData:Object):void {
      // Remove from cache
      if (commentCache[commentData.post_id])
        for (var i:int = 0; i < commentCache[commentData.post_id].length; i++)
          if (commentCache[commentData.post_id][i].id == commentData.id)
              commentCache[commentData.post_id].splice(i--, 1);

      // Dispatch it from here
      dispatcher.dispatchEvent(new FBEvent(CommentCache.COMMENT_REMOVED,
                                           commentData));
    }

    // Add a comment we've created locally
    public static function addComment(commentData:Object):void {
      // Add to cache
      if (!commentCache[commentData.post_id])
        commentCache[commentData.post_id] = new Array();
      commentCache[commentData.post_id].push(commentData);

      // Dispatch event of add
      dispatcher.dispatchEvent(new FBEvent(CommentCache.COMMENT_CREATED,
                                           commentData));
    }

    // Main Getter for the comments of a post id
    // Returns an EventDispatcher to fire when it has the data.
    public static function getComments(postID:String,
                                       lastUpdate:int):EventDispatcher {
      if (!postID || postID == "0" || postID == "null")
        return new EventDispatcher();

      // Set an event listener to request these at end of frame
      Application.application.addEventListener(
        Event.ENTER_FRAME, fetchComments);

      // We put all our requests into a queue to fire at end of frame
      if (! queuedRequests[postID]) {
        var dispatcher:EventDispatcher = new EventDispatcher();
        queuedRequests[postID] = {dispatcher:dispatcher, time:lastUpdate};
      }

      return queuedRequests[postID].dispatcher;
    }

    // Internal utility function to fetch all the comments from the server
    private static function fetchComments(event:Event):void {
      Application.application.removeEventListener(
        Event.ENTER_FRAME, fetchComments);

      var requested_ids:Array = new Array();
      for (var request_id:String in queuedRequests)
        requested_ids.push("(post_id = '" + request_id + "' and " +
          "time >= " + queuedRequests[request_id].time + ")");

      // Local reference to this for the callback
      var currentRequests:Object = queuedRequests;

      FBAPI.callMethod("fql.query", {
        query:"select post_id, id, fromid, text, time from comment " +
          "where " + requested_ids.join(" or ") + " " +
          "order by time desc"
      }).addEventListener(FBEvent.SUCCESS, function(event:FBEvent):void {
        // Mark our time for freshness
        fetchTime = (new Date()).time;

        var results:Array = event.data as Array;

        // We need to break up the results by post_id
        commentCache = new Object();
        for each (var result:Object in results) {
          if (!commentCache[result.post_id])
            commentCache[result.post_id] = new Array();
          commentCache[result.post_id].push(result);
        }

        // Now dispatch our groups to the listeners
        for (var post_id:String in commentCache)
          currentRequests[post_id].dispatcher.dispatchEvent(
            new FBEvent(COMMENTS_FETCHED, commentCache[post_id]));
      });

      // Clear our list of queued requests now that we're done
      queuedRequests = new Object();
    }
  }
}
