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
// To the dump, to the dump, to the dump, dump, dump!
package fbair.gc {
  import fb.util.Output;

  import fbair.gc.Recyclable;

  import flash.utils.Dictionary;

  public class Depot {
    private static var pool:Dictionary = new Dictionary();

    public static function get(type:Class):* {
      if (pool[type] is Array && pool[type].length > 0)
        return pool[type].pop();
      return new type();
    }

    public static function put(item:*):void {
      if (item is Recyclable) item.recycle();

      if (!pool[item.constructor])
        pool[item.constructor] = new Array();
      pool[item.constructor].push(item);
    }
  }
}
