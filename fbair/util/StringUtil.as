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
  public final class StringUtil {

    public static var UrlRegExp:RegExp =
      new RegExp('(?:(?:ht|f)tps?):\\/\\/([^\\s<\\)\\]"\']*[^\\s<\\.\\)\\]"\':])', 'gi');

    // Simple util builds an html link out of a string and a url
    public static function linkify(str:String, url:String,
                                   bold:Boolean=true):String {
      if (empty(str)) return '';
      var link:String = '<a href="' + url + '">' + str + '</a>';
      if (bold) {
        link = '<b>' + link + '</b>';
      }
      return colorize(link, '3b5998');
    }

    // Wrap some text in a font color tag
    public static function colorize(str:String, color:String):String {
      if (empty(str)) return '';
      return '<font color="#' + color + '">' + str + '</font>';
    }

    // Take a word and a total and phrase it with optional plurality
    public static function pluralize(word:String, amount:int):String {
      if (empty(word)) return '';
      return amount + " " + word + (amount == 1 ? '' : 's');
    }

    // Find all the links in text and linkify them
    public static function htmlize(str:String):String {
      if (empty(str)) return '';
      // hearts
      str = str.replace(/<3\b/g, '&hearts;');
      // html encode
      str = replaceAll(str, ['&',     '<',    '>',    '\'',     '"'],
                            ['&amp;', '&lt;', '&gt;', '&apos;', '&quot;']);
      // post fix
      // Note also that the <3 conversion is done as a post-fixup hack,
      // so that there is a way to literally put '&hearts;'
      str = replaceAll(str, ['\r\n',   '\n',     '&amp;hearts;'],
                            ['<br />', '<br />', '♥']);
      // linkify
      str = str.replace(UrlRegExp, function():String {
        var str:String = arguments[1];
        if (str.charAt(str.length-1) == '/') {
          str = str.substring(0, str.length-1);
        }
        return linkify(str, arguments[0], false);
      });
      return str;
    }

    public static function replaceAll(str:String, pre:*, post:*):String {
      if (empty(str)) return '';
      if (pre is String) {
        return str.split(pre).join(post);
      } else if (pre is Array) {
        var preA:Array = pre as Array;
        var postA:Array = post as Array;
        for (var i:int = 0; i < preA.length; i++) {
          str = str.split(preA[i]).join(postA[i]);
        }
      }
      return str;
    }

    // pulls url out of shared.php crap
    public static function extractURL(str:String):String {
      if (empty(str)) return '';

      var sliced:String = unescape(str);
      while (sliced.indexOf("&src=") != -1)
        sliced = sliced.substr(sliced.indexOf("&src=") + 5);
      while (sliced.indexOf("&url=") != -1)
        sliced = sliced.substr(sliced.indexOf("&url=") + 5);
      return sliced;
    }

    public static function empty(str:*):Boolean {
      return (!str || str == '');
    }
  }
}
