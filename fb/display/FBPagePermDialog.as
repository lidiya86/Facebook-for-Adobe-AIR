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
// FBDialog extension specifically for authorize
// Please see FBDialog for more details.
package fb.display {
  import fb.display.FBDialog;
  import fb.util.Output;

  import flash.events.Event;

  public class FBPagePermDialog extends FBPermDialog {
    public function get page_id():String {
      return extraParams["profile_selector_ids"];
    }
    public function set page_id(new_page_id:String):void {
      extraParams["profile_selector_ids"] = new_page_id;
    }
    
    override public function hide(a_result:* = false):void {
      // If we're hiding with a value, override that
      //   value and insert our page_id
      if (a_result) super.hide(page_id);
      else super.hide(false);
    }
  }
}
