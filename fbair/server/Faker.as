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
  public class Faker {
    private static realUserIds:Array = [4];

    public static function getFakeNotification():Object {
      var uid:int = realUserIds[Math.floor(Math.random() *
    realUserIds.length])];
      return {
        notification_id:Math.round(Math.random() * 100000000),

    href:"http://www.facebook.com/profile.php?v=feed&id=665215028&story_fbid
    =245247440028",
        app_id:2719290516,
        sender_id:uid,
        title_text:"Something posted something on your Wall.",
        body_text:"Hello thus is a test 2"
      }
    }

    public static function getFakeInboxMessage():Object {
      var uid:int = realUserIds[Math.floor(Math.random() *
    realUserIds.length])];
      return {
        thread_id:Math.round(Math.random() * 100000000),
        subject:"Hi test"
        snippet:"TGis is a test lalalalalalalal"
        snippet_author:uid
      }
    }

    public static function getFakeStream():Object {
      var fake:Object = new Object();
      fake.source_id = Math.round(Math.random() * 100000000);
      fake.attachment = new Object();
      if (Math.random() >= 0.5) {
        fake.attachment.properties = new Object();
        fake.attachment.caption = "This is a test caption";
        fake.attachment.description = 
          "This is a test description for the description field";
        }
      }
    }
  }