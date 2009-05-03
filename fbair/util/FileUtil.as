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
  import flash.filesystem.File;

  public class FileUtil {
    private static const ValidImageTypes:Array = ["png", "gif", "jpg", "jpeg"];

    // Recursively pull all the valid image Files out of every dir/subdir
    public static function slurpImages(file:File):Array {
      if (file.name.indexOf(".") == 0) return new Array();
      if (file.isDirectory) {
        var top_files:Array = file.getDirectoryListing();
        var all_files:Array = new Array();
        for each (var top_file:File in top_files)
          all_files = all_files.concat(slurpImages(top_file));
        return all_files;
      } else if (ValidImageTypes.indexOf(file.extension) != -1) {
        return [file];
      } else return new Array();
    }
  }
}
