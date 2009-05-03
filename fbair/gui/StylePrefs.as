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
  import flash.filesystem.File;

  import mx.styles.StyleManager;

  // We hold style prefs here of the user
  public class StylePrefs {
    // We use these constants to represent dynamic css resources
    public static const SIZE_LARGE:String =
      "fbair/styles/bin/size_large.css.swf";

    public static const SIZE_SMALL:String =
      "fbair/styles/bin/size_small.css.swf";

    private static var _instance:StylePrefs = new StylePrefs();
    public static function get prefs():StylePrefs { return _instance; }

    public function StylePrefs() {
      if (_instance) throw new Error("StylePrefs is a singleton");

      var styleData:Object = ApplicationBase.getPreference("styles");
      if (styleData) {
        sizeStyle = styleData.sizeStyle;
      } else {
        sizeStyle = SIZE_LARGE;
      }
    }

    private var _sizeStyle:String;
    [Bindable] public function get sizeStyle():String { return _sizeStyle; }
    public function set sizeStyle(to:String):void {
      if (_sizeStyle == to) return;
      if (_sizeStyle) {
        var resourcePath:String = File.applicationDirectory
                                      .resolvePath(_sizeStyle).url;
        StyleManager.unloadStyleDeclarations(resourcePath, false);
      }
      _sizeStyle = to;
      resourcePath = File.applicationDirectory.resolvePath(_sizeStyle).url;
      StyleManager.loadStyleDeclarations(resourcePath);
    }
  }
}
