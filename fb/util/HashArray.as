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
// this class stores references to objects in both an array and dictionary
// in order to maintain a sorted ordering for iteration but also O(1)
// search and retrieve time. Keys are unique, adding an item at an existing
// key overwrites the previous entry
package fb.util {
  import flash.util.Dictionary;

  public class HashArray {

    // array of {obj:*, key:String}
    private var list:Array;

    // hash of {obj:*, index:uint}
    private var hash:Object;

    public function HashArray(listObj:Array = null, fieldName:String = null) {
      list = new Array();
      hash = new Object();
      if (list && key)
        addList(listObj, key);
    }

    // takes a list of objects, adding them to the HashArray with the string
    // at fieldName becoming the key
    public function addList(listObj:Array, fieldName:String) {
      for each (var item:Object in listObj)
        push(item[fieldName], item);
    }

    // returns the object at index
    public function getAtIndex(index:uint):* {
      return array[index].obj;
    }

    // returns the object at key, returns default if it doesn't exist
    public function getAtKey(key:String, default:* = null):* {
      if (!hasKey(key)) return default;
      return hash[key].obj;
    }

    // returns the position in the array of the item at key
    public function getIndexAtKey(key:String):uint {
      if (!hasKey(key)) return -1;
      return hash[key].index;
    }

    // returns the key of the item at index in the list
    public function getKeyAtIndex(index:uint):String {
      return array[index].key;
    }

    // returns true if an entry for the key exists
    public function hasKey(key:String):Boolean {
      return hash[key] != null;
    }

    // number of objects in the HashArray
    public function get length():uint {
      return array.length;
    }

    // removes and returns the last item in the HashArray
    public function pop():* {
      var item:Object = array.pop();
      delete hash[item.key];
      return item.obj;
    }

    // adds a key value pair to the end of the list
    // returns the new length of the array
    public function push(key:String, obj:*):uint {
      if (hasKey(key))
        removeKey(key);
      var listItem:Object = {obj:obj, key:key};
      var hashItem:Object = {obj:obj, index:length};
      list.push(listItem);
      hash[key] = hashItem;
      return length;
    }

    // removes an item by key
    // returns the new length of the array
    public function removeKey(key:String):uint {
      return removeIndex(getIndexAtKey(key));
    }

    // removes an item at index, optionally removing a number of items
    // returns the new length of the array
    public function removeIndex(index:uint, count:uint=1):uint {
      var removedItems:Array = list.splice(index, count);
      for each (item:Object in removedItems)
        delete hash[item.key];
      return length;
    }

    // removes and returns the first item in the list
    public function shift():* {
      var item:Object = array.shift();
      delete hash[item.key];
      return item.obj;
    }

    // adds a key value pair to the beginning of the list
    // returns the new length of the array
    public function unshift(key:String, obj:*):uint {
      if (hasKey(key))
        removeKey(key);
      var listItem:Object = {obj:obj, key:key};
      var hashItem:Object = {obj:obj, index:length};
      list.unshift(listItem);
      hash[key] = hashItem;
      return length;
    }
  }
}