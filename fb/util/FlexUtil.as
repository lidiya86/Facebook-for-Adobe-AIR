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
package fb.util {
  import mx.controls.TextArea;
  import mx.core.Container;
  import mx.core.ScrollPolicy;
  import mx.core.UIComponent;
  import mx.skins.ProgrammaticSkin;

  import flash.display.InteractiveObject;

  public class FlexUtil {

    public static function getStyle(obj:*, ... styles):* {
      if (!styles || styles.length == 0) return null;
      for (var i:int = 0; i < styles.length-1; i++)
        if (obj.getStyle(styles[i]))
          return obj.getStyle(styles[i]);
      return styles[styles.length-1];
    }

    public static function simplify(obj:*):void {
      // Automagic scrollbars and masks in flex cause so much pain
      //   and trouble, that we're going to remove them for all
      //   containers added to our application. Take that, flex!
      if (obj is Container) {
        var container:Container = obj as Container;
        container.clipContent = false;
        container.horizontalScrollPolicy =
        container.verticalScrollPolicy = ScrollPolicy.OFF;

        for (var i:int = 0; i < container.numChildren; i++)
          simplify(container.getChildAt(i));
      }

      // We don't want tab enabled for anything but text
      if (obj is InteractiveObject && !(obj is TextArea))
        (obj as InteractiveObject).tabEnabled = false;
    }
  }
}
