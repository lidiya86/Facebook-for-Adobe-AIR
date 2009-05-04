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
// Global manager of style prefs.
package fbair.gui {
  import fb.util.Output;

  import flash.events.Event;
  import flash.filesystem.File;

  import mx.core.Application;
  import mx.events.FlexEvent;
  import mx.styles.StyleManager;

  // We hold style prefs here of the user
  public class StylePrefs {
    // We use these constants to represent dynamic css resources
    public static const SIZE_LARGE:String =
      "fbair/styles/bin/size_large.css.swf";

    public static const SIZE_SMALL:String =
      "fbair/styles/bin/size_small.css.swf";

    [Bindable] public static var sizeStyle:String;

    // Initializing
    private static var initialized:Boolean = initialize();
    private static function initialize():Boolean {
      Application.application.addEventListener(FlexEvent.INITIALIZE,
        opening);
      Application.application.addEventListener(Event.CLOSING,
        closing);
      return true;
    }
    
    // Load preferences
    private static function opening(event:FlexEvent):void {
      var styleData:Object = ApplicationBase.getPreference("styles");

      // Set size
      if (styleData) setSizeStyle(styleData.sizeStyle);
      else setSizeStyle(SIZE_LARGE);
    }

    public static function setSizeStyle(to:String):void {
      if (sizeStyle == to) return;
      if (!to) to = SIZE_LARGE;

      Output.log("Setting style size: " + to);

      // Unload old style size
      if (sizeStyle) {
        var resourcePath:String = File.applicationDirectory
                                      .resolvePath(sizeStyle).url;
        StyleManager.unloadStyleDeclarations(resourcePath, false);
      }

      // Load new style size
      sizeStyle = to;
      resourcePath = File.applicationDirectory
                         .resolvePath(sizeStyle).url;
      StyleManager.loadStyleDeclarations(resourcePath);
    }

    // Save preferences when done
    private static function closing(event:Event):void {
      ApplicationBase.setPreference("styles", {
        sizeStyle:sizeStyle
      });
    }
  }
}
