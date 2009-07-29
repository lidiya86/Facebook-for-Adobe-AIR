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
package fbair.notification {
  import fb.FBConnect;
  import fb.FBEvent;

  import fbair.server.Fetcher;

  import flash.desktop.NativeApplication;
  import flash.events.Event;

  /**
   * Receives toast data and shows toasts when appropriate.
   */
  public class ToastManager {
    // Seconds to wait without mouse/keyboard activity to consider user idle
    private static const IDLE_THRESHOLD:int = 30;

    // Maximum number of notifications to display singly
    private static const MAX_DISPLAY_SINGLE_ALERT_TOAST:int = 3;

    // Maximum number of notifications to display in a batch toast
    public static const MAX_DISPLAY_BATCH_ALERT_TOAST:int = 10;

    // If we are idle, time we went idle. 0 if we are not idle.
    private var wentIdleTime:int = 0;

    // Queues for each of the toast types
    private var alertsQueue:Array = new Array();
    private var messagesQueue:Array = new Array();

    public function ToastManager() {
      // Set some idle/presence traps
      var nativeapp:NativeApplication = NativeApplication.nativeApplication;
      nativeapp.idleThreshold = IDLE_THRESHOLD;
      nativeapp.addEventListener(Event.USER_IDLE, userIdle);
      nativeapp.addEventListener(Event.USER_PRESENT, userPresent);

      // Listen for when fetcher is going to the server
      //   so we can feed it our request in fql
      Fetcher.steve.addEventListener(FBEvent.FETCHING_DATA, fetchingData);

      // Called by fetcher when it has our new data
      Fetcher.steve.addEventListener(FBEvent.DATA_RECEIVED, dataReceived);
    }

    // Called by Fetcher when it's about to fetch data
    private function fetchingData(event:FBEvent):void {
      Fetcher.queries.notifications = "select notification_id, sender_id, " +
          "title_text, body_text, href, app_id from notification where " +
          "recipient_id = " + FBConnect.session.uid + " " +
          "and is_unread = 1 " +
          "and sender_id != recipient_id " +
          "and created_time > " + Math.round(Fetcher.updateTime / 1000) + " "
          "limit " + int(ToastManager.MAX_DISPLAY_BATCH_ALERT_TOAST + 1);

      // If this isn't the first time on startup, also query for inboxes
      if (Fetcher.updateTime > 0)
        Fetcher.queries.inbox =
          "select thread_id, subject, snippet, snippet_author " +
          "from thread where folder_id = 0 " +
          "and updated_time > " + Math.round(Fetcher.updateTime / 1000) + " " +
          "order by updated_time desc limit 3";
    }

    // Called by Fetcher with our new data
    private function dataReceived(event:FBEvent):void {
      if (event.data.notifications.length > 0)
        feedNewNotifications(event.data.notifications);

      if (event.data.hasOwnProperty("inbox") && event.data.inbox.length > 0)
        feedNewMessages(event.data.inbox);
    }

    /**
     * Feed new notifications into the toaster,
     * which can then release those toasts either immediately or when the user
     * comes back from idle.
     */
    private function feedNewNotifications(alerts:Array):void {
      for each (var alert:Object in alerts)
        alertsQueue.push(alert);

      // If we're not idle right now, release the toasts now
      if (wentIdleTime == 0) triggerToastRelease();
    }

    /**
     * Counterpart to feedNewNotifications() for inbox messages.
     */
    private function feedNewMessages(threads:Array):void {
      for each (var thread:Object in threads)
        messagesQueue.push(thread);

      // If we're not idle right now, release the toasts now
      if (wentIdleTime == 0) triggerToastRelease();
    }

    /**
     * Triggers toasts in the queues to be released. Called by the feed
     * functions if the user is not idle, or if the user comes back from idle.
     */
    private function triggerToastRelease():void {
      // Release messages first; release as many as we have
      if (messagesQueue.length > 0) {
        for each (var msg:Object in messagesQueue)
          Toast.makeInboxToast(msg);
        messagesQueue = new Array();
      }

      // Release either individual notifications or a batch toast
      if (alertsQueue.length > 0) {
        if (alertsQueue.length > MAX_DISPLAY_SINGLE_ALERT_TOAST) {
          Toast.makeBatchToast(alertsQueue);
        } else {
          for each (var alert:Object in alertsQueue)
            Toast.makeNotificationToast(alert);
        }
        alertsQueue = new Array();
      }
    }

    /**
     * Triggered when the user goes idle.
     */
    private function userIdle(event:Event): void {
      wentIdleTime = Math.round((new Date()).time / 1000);
    }

    /**
     * Triggered whenever the user comes back from idle. Releases any toasts
     * that came in during the time the user was away.
     */
    private function userPresent(event:Event): void {
      wentIdleTime = 0;
      triggerToastRelease();
    }

  }
}
