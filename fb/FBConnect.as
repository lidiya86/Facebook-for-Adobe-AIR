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
package fb {
  import com.adobe.serialization.json.JSON;

  import fb.FBAPI;
  import fb.FBEvent;
  import fb.FBSession;
  import fb.display.FBAuthDialog;
  import fb.display.FBDialog;
  import fb.display.FBPermDialog;
  import fb.display.FBPagePermDialog;
  import fb.net.JSONLoader;
  import fb.net.RedirectTester;
  import fb.util.Output;

  import flash.events.Event;
  import flash.events.EventDispatcher;
  import flash.net.SharedObject;

  public class FBConnect {
    // Enum constants
    public static const Connected:String = "Connected";
    public static const NotLoggedIn:String = "NotLoggedIn";

    // Path to check for logged in status
    private static const LoggedInPath:String = FBDialog.FacebookURL +
      "/extern/desktop_login_status.php";

    // Universal dispatcher of authorization changes
    public static var dispatcher:EventDispatcher = new EventDispatcher();

    // Publicly accessible globals about session states
    public static var api_key:String;
    [Bindable] public static var session:FBSession;

    // List of extra session params passed to requireSession()
    private static var extraSessionParams:Object;

    // Permissions
    private static var permissions:Array = new Array();
    private static var validating_permissions:Array;

    // Page Adminning
    private static var adminnedPages:Array = new Array();
    private static var requesting_page:String;

    // Local filestorage (desktop "cookie")
    private static var sharedObject:SharedObject;

    // Status getter/setter.  Setter triggers event.
    private static var _status:String = NotLoggedIn;
    public static function get status():String { return _status; }
    public static function set status(new_status:String):void {
      if (new_status != Connected &&
          new_status != NotLoggedIn) {
        return;
      }
      _status = new_status;

      dispatcher.dispatchEvent(new FBEvent(FBEvent.STATUS_CHANGED));
    }

    // Must be called to start things off.
    public static function init(new_api_key:String):void {
      Output.log("FBConnect init beginning...");
      api_key = new_api_key;

      _status = NotLoggedIn;
      session = null;

      // If we have stored session data, let's pull it in
      sharedObject = SharedObject.getLocal(api_key);
      if (sharedObject.data["session_key"]) {
        session = new FBSession();
        session.key = sharedObject.data["session_key"];
        session.uid = sharedObject.data["uid"];
        session.expires = sharedObject.data["expires"];
        session.secret = sharedObject.data["secret"];
        Output.log("Loaded session from cache: ",
          session.key, session.uid, session.expires, session.secret);
      }
    }

    /**********************************
     * PAGE ADMINISTRATION
     **********************************/
    // Can we admin the given page id?
    public static function canAdminPage(page_id:Number):Boolean {
      return (adminnedPages.indexOf(page_id) != -1);
    }

    // Call this to require that we admin a page
    public static function requestPageAdministration(page_id:String):void {
      if (!FBConnect.session.uid) return;
      if (requesting_page) return;

      // Check to see whether we already got these
      dispatcher.dispatchEvent(new FBEvent(FBEvent.ALERT,
        "Verifying Page Administration"));
      requesting_page = page_id;
      FBAPI.callMethod("fql.multiquery", {queries:{
        allPages:"select page_id " +
          "from page_admin where uid = " + FBConnect.session.uid,
        grantedPages:"select uid, publish_stream " +
          "from permissions where uid in (select page_id from #allPages)"
      }}).addEventListener(FBEvent.SUCCESS, gotAdminInfo);
    }

    // Callback on page admin data
    public static function gotAdminInfo(event:FBEvent):void {
      var resultsByKey:Object = FBAPI.multiqueryByKey(event.data);

      // Rebuild list of pages we know we can publish to
      adminnedPages = new Array();
      for each (var grantedPage:Object in resultsByKey.grantedPages)
        if (grantedPage.publish_stream == 1)
          adminnedPages.push(grantedPage.uid);

      Output.bug(resultsByKey);
      Output.bug("fql adminned pages:", adminnedPages);

      // If we found out we can in fact administer this page
      //   then just fire the event to say so.
      if (canAdminPage(Number(requesting_page))) {
        dispatcher.dispatchEvent(new FBEvent(FBEvent.RESOLVED));
        dispatcher.dispatchEvent(new FBEvent(FBEvent.PAGE_PERMISSION_CHANGED));
      }
      // Ok we're gonna need some dialog action to get this permission
      else {
        var dialog:FBPagePermDialog = new FBPagePermDialog();
        dialog.ext_perm = "publish_stream";
        dialog.page_id = requesting_page;
        dialog.addEventListener(FBEvent.CLOSED, adminDialogClosed);
        dialog.show();
      }
    }

    private static function adminDialogClosed(event:FBEvent):void {
      Output.bug("admin dialog closed", event.data);
      // Loop thru and add all those permissions we've gotten
      if (event.data) adminnedPages.push(event.data);

      Output.bug("adminned pages", adminnedPages);

      requesting_page = null;
      dispatcher.dispatchEvent(new FBEvent(FBEvent.PAGE_PERMISSION_CHANGED));
    }

    /**********************************
     * EXTENDED PERMISSIONS
     **********************************/
    // Simply informs if we have had this permission granted
    public static function hasPermission(permission_name:String):Boolean {
      return (permissions.indexOf(permission_name) != -1);
    }

    // Call this to require/validate a permission
    public static function requirePermissions(permission_names:Array):void {
      if (!FBConnect.session.uid) return;
      if (validating_permissions) return;

      // Ask about all these first, to see if we're already auth'd
      dispatcher.dispatchEvent(new FBEvent(FBEvent.ALERT,
        "Checking Extended Permissions"));
      validating_permissions = permission_names;
      FBAPI.callMethod("fql.query", {query:
        "select " + permission_names.join(", ") + " " +
          "from permissions where uid = " + FBConnect.session.uid
      }).addEventListener(FBEvent.SUCCESS, gotPermissionInfo);
    }

    // Callback from restserver of whether we have permission
    private static function gotPermissionInfo(event:FBEvent):void {
      var permissions_array:Array = event.data as Array;
      var permissions_granted:Object = permissions_array[0];

      // Update our cache of what we know about these permissions
      for (var permission_granted:String in permissions_granted) {
        if (permissions_granted[permission_granted] == 1 &&
            permissions.indexOf(permission_granted) == -1)
          permissions.push(permission_granted);
        else if (permissions_granted[permission_granted] == 0 &&
                 permissions.indexOf(permission_granted) != -1)
          permissions.splice(permissions.indexOf(permission_granted), 1);
      }

      // Check to see if we need more
      var permissions_needed:Array = new Array();
      for each (var validating_permission:String in validating_permissions)
        if (!hasPermission(validating_permission))
          permissions_needed.push(validating_permission);

      if (permissions_needed.length == 0) {
        validating_permissions = null;
        dispatcher.dispatchEvent(new FBEvent(FBEvent.PERMISSION_CHANGED));
      } else {
        dispatcher.dispatchEvent(new FBEvent(FBEvent.ALERT,
          "Confirming Logged In Status"));
        // Confirm we are logged in before trying the perm dialog
        var redirectTester:RedirectTester = new RedirectTester(
          LoggedInPath + "?next=" + FBDialog.NextPath + "&api_key=" + api_key,
          FBDialog.NextPath, 'result=logged_in');
        redirectTester.addEventListener(FBEvent.FAILURE,
          function(event:FBEvent):void {
            unauthenticated();
          });
        redirectTester.addEventListener(FBEvent.SUCCESS,
          function(event:FBEvent):void {
            confirmedLoggedIn(unescape(event.target.location),
                              permissions_needed);
          });
      }
    }

    // Callback when desktop_login_status has confirmed our login
    // We confirm our uid and proceed with PermDialog or we bail
    private static function confirmedLoggedIn(url:String,
                                              permissions_needed:Array):void {
      var uid_pattern:RegExp = /uid=(\d+)/;
      var uid:Number = Number(uid_pattern.exec(url)[1]);
      if (uid != session.uid) {
        unauthenticated();
      } else {
        var dialog:FBPermDialog = new FBPermDialog();
        dialog.ext_perm = permissions_needed.join(",");
        dialog.addEventListener(FBEvent.CLOSED, permissionsDialogClosed);
        dialog.show();
      }
    }

    // Callback when permissions dialog has closed
    private static function permissionsDialogClosed(event:FBEvent):void {
      // Loop thru and add all those permissions we've gotten
      if (event.data && event.data is Array) {
        var validated_permissions:Array = event.data as Array;
        for each (var validated_permission:String in validated_permissions) {
          permissions.push(validated_permission);
        }
      }
      validating_permissions = null;

      dispatcher.dispatchEvent(new FBEvent(FBEvent.PERMISSION_CHANGED));
    }

    /**********************************
     * AUTHORIZATION
     **********************************/
    // Our session key may have been deauthorized by the user
    // This method allows us to confirm it's still valid
    private static function validateSession():void {
      if (!api_key || !session) return;

      dispatcher.dispatchEvent(new FBEvent(FBEvent.ALERT,
        "Validating Session Key"));
      var loggedIn:JSONLoader =
        FBAPI.callMethod("users.isAppUser");
      loggedIn.retry = false; // Only try once here, we're watching failure...
      loggedIn.addEventListener(FBEvent.SUCCESS, gotLoggedInUser);
      loggedIn.addEventListener(FBEvent.FAILURE, noLoggedInUser);
    }

    // This will require we get a session key.
    // And validate if we already have one.
    public static function requireSession(extra_params:Object = null):void {
      if (!api_key) return;

      extraSessionParams = extra_params;

      if (session) {
        validateSession();
      } else {
        var dialog:FBAuthDialog = new FBAuthDialog(extraSessionParams);
        dialog.addEventListener(FBEvent.CLOSED, loginDialogClosed);
        dialog.show();
      }
    }

    // Callback from restserver if session key causes error
    private static function noLoggedInUser(event:FBEvent = null):void {
      session = null;
      SharedObject.getLocal(api_key).data["session_key"] = null;
      requireSession(extraSessionParams);
    }

    // Callback from restserver of whether session key is valid
    private static function gotLoggedInUser(event:FBEvent):void {
      if (event.data) status = Connected;
      else noLoggedInUser();
    }

    // Callback when authorization dialog has closed
    private static function loginDialogClosed(event:FBEvent):void {
      var dialog:FBAuthDialog = event.target as FBAuthDialog;
      if (event.data) {
        var session_pattern:RegExp = /\{.+?\}/;
        var session_json:String = session_pattern.exec(
          unescape(dialog.htmlWindow.location))[0];
        var session_obj:Object = JSON.decode(session_json);

        session = new FBSession();
        session.key = session_obj.session_key;
        session.secret = session_obj.secret;
        session.expires = session_obj.expires;
        session.uid = session_obj.uid;

        sharedObject.data["session_key"] = session.key;
        sharedObject.data["uid"] = session.uid;
        sharedObject.data["expires"] = session.expires;
        sharedObject.data["secret"] = session.secret;

        status = Connected;
      } else {
        status = NotLoggedIn;
      }
    }

    // This will log us out if we have a session
    public static function logout():void {
      if (!api_key) return;

      if (status == Connected) {
        var expiration:JSONLoader = FBAPI.callMethod("auth.expireSession");
        expiration.addEventListener(FBEvent.SUCCESS, loggedOutUser);
        expiration.addEventListener(FBEvent.FAILURE, loggedOutUser);
      } else loggedOutUser();
    }

    // Callback from restserver of when session is dead
    private static function loggedOutUser(event:FBEvent = null):void {
      session = null;
      status = NotLoggedIn;
    }

    // Called internally when we've discovered we're unauthenticated
    private static function unauthenticated():void {
      validating_permissions = null;
      session = null;
      SharedObject.getLocal(api_key).data["session_key"] = null;
      status = NotLoggedIn;
    }
  }
}
