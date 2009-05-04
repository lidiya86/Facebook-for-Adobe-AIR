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
  import fb.util.MathUtil;

  public class TimeUtil {
    private static const OneMinute:int = 60;
    private static const OneHour:int = OneMinute * 60;
    private static const OneDay:int = OneHour * 24;
    private static const Months:Array = ["Jan", "Feb", "Mar", "Apr", "May",
      "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

    // This takes a time in the past and then returns a string that says
    //   in a natural fashion how long ago that time was.
    // Like "about an hour ago" or "yesterday", etc.
    public static function describeWhen(past:Number):String {
      var nowDate:Date = new Date();
      var now:Number = nowDate.time;
      var pastDate:Date = new Date(past * 1000);

      var secondsToday:int = nowDate.seconds +
        nowDate.minutes * OneMinute +
        nowDate.hours * OneHour;
      var maxHours:int = Math.min(nowDate.hours, 10);
      var elapsed:int = (now / 1000) - past;

      if (elapsed < OneMinute)
        return "less than a minute ago";
      if (elapsed < OneMinute * 2)
        return "about a minute ago";
      if (elapsed < OneHour)
        return int(elapsed / OneMinute) + " minutes ago";
      if (elapsed < OneHour * 2)
        return "about an hour ago";
      if (elapsed < OneHour * maxHours)
        return int(elapsed / OneHour) + " hours ago";
      if (elapsed < secondsToday)
        return "Today at " + describeTime(pastDate);
      if (elapsed < secondsToday + OneDay)
        return "Yesterday at " + describeTime(pastDate);
      return describeDate(pastDate) + " at " + describeTime(pastDate);
    }

    // This returns an english time string, but tuned for a comment
    public static function describeWhenShort(past:Number):String {
      var pastDate:Date = new Date(past * 1000);
      return "at " + describeTime(pastDate) + " " + describeDate(pastDate);
    }

    private static function describeTime(time:Date):String {
      var hour:int = (time.hours > 12 ? time.hours - 12 : time.hours);
      if (hour == 0) hour = 12;
      var minute:String = (time.minutes < 10 ? "0" : "") + time.minutes;
      var meridiem:String = (time.hours < 12 ? "am" : "pm");
      return hour + ":" + minute + meridiem;
    }

    private static function describeDate(time:Date):String {
      return Months[time.month] + " " + MathUtil.ordinal(time.date);
    }
  }
}