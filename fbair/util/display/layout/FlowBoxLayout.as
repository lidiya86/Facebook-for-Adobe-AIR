////////////////////////////////////////////////////////////////////////////////
//
//  ADOBE SYSTEMS INCORPORATED
//  Copyright 2005-2006 Adobe Systems Incorporated
//  All Rights Reserved.
//
//  NOTICE: Adobe permits you to use, modify, and distribute this file
//  in accordance with the terms of the license agreement accompanying it.
//
////////////////////////////////////////////////////////////////////////////////

package fbair.util.display.layout {

  import mx.styles.IStyleClient;
  import mx.containers.BoxDirection;
  import mx.containers.utilityClasses.BoxLayout;
  import mx.core.EdgeMetrics;
  import mx.core.IUIComponent;
  import mx.core.mx_internal;

  use namespace mx_internal;

  public class FlowBoxLayout extends BoxLayout {

    public function FlowBoxLayout() {
      super();
      direction = BoxDirection.HORIZONTAL;
    }

    private function get isVertical():Boolean {
      return direction != BoxDirection.HORIZONTAL;
    }

    override public function measure():void {
      var minWidth:Number = 0;
      var minHeight:Number = 0;

      var n:int = target.numChildren;
      for (var i:int = 0; i < n; i++) {
        var child:IUIComponent = target.getChildAt(i) as IUIComponent;

        if (!child.includeInLayout) continue;

        minWidth = Math.max(!isNaN(child.percentWidth) ?
          child.minWidth : child.getExplicitOrMeasuredWidth(), minWidth);

        minHeight = Math.max(!isNaN(child.percentHeight) ?
          child.minHeight : child.getExplicitOrMeasuredHeight(), minHeight);
      }

      target.measuredMinWidth = minWidth;
      target.measuredMinHeight = minHeight;
    }

    /**
     *  @private
     *  Lay out children as per Box layout rules.
     */
    override public function updateDisplayList(unscaledWidth:Number,
                                               unscaledHeight:Number):void {
      var n:int = target.numChildren;
      if (n == 0) return;

      // get positional properties
      var vm:EdgeMetrics = target.viewMetricsAndPadding;
      var vGap:Number = target.getStyle("verticalGap");
      var hGap:Number = target.getStyle("horizontalGap");
      var isVertical:Boolean = (direction != BoxDirection.HORIZONTAL);

      // set the available size of this component
      var mw:Number = target.scaleX > 0 && target.scaleX != 1 ?
              target.minWidth / Math.abs(target.scaleX) :
              target.minWidth;
      var mh:Number = target.scaleY > 0 && target.scaleY != 1 ?
              target.minHeight / Math.abs(target.scaleY) :
              target.minHeight;
      var w:Number = Math.max(unscaledWidth, mw) - vm.right - vm.left;
      var h:Number = Math.max(unscaledHeight, mh) - vm.bottom - vm.top;

      // set (row/col) properties
      var i:int;
      var child:IUIComponent;
      var totalWidth:Number = 0;
      var totalHeight:Number = 0;
      var itemsInSet:int = 0;
      var setWidth:Number = 0;
      var setHeight:Number = 0;
      var top:Number;
      var left:Number;

      // for every child in layout, size and move
      for (i = 0; i < n; i++) {
        child = target.getChildAt(i) as IUIComponent;

        // relative positions
        var relativeTop:Number = 0;
        var relativeLeft:Number = 0;
        var relativeBottom:Number = 0;
        var relativeRight:Number = 0;
        if (child is IStyleClient) {
          relativeTop = (child as IStyleClient).getStyle("top");
          relativeLeft = (child as IStyleClient).getStyle("left");
          relativeBottom = (child as IStyleClient).getStyle("bottom");
          relativeRight = (child as IStyleClient).getStyle("right");
          if (isNaN(relativeTop)) relativeTop = 0;
          if (isNaN(relativeLeft)) relativeLeft = 0;
          if (isNaN(relativeBottom)) relativeBottom = 0;
          if (isNaN(relativeRight)) relativeRight = 0;
        }

        if (!child.includeInLayout) {
          child.move(Math.floor(vm.left + relativeLeft),
                     Math.floor(vm.top + relativeTop));
          continue;
        }

        // get child's dimensions
        var percentWidth:Number = child.percentWidth;
        var percentHeight:Number = child.percentHeight;
        var width:Number;
        var height:Number;
        var expW:Number = child.getExplicitOrMeasuredWidth();
        var expH:Number = child.getExplicitOrMeasuredHeight();

        if (percentWidth) {
          width = (percentWidth >= 100) ? w : (w * percentWidth / 100);
          if (!isNaN(expW) && expW > 0)
            width = Math.min(width, expW);
          width = Math.max(child.minWidth, Math.min(child.maxWidth, width));
        } else {
          width = expW;
        }

        if (percentHeight) {
          height = (percentHeight >= 100) ? h : (h * percentHeight / 100);
          if (!isNaN(expH) && expH > 0)
            height = Math.min(height, expH);
          height = Math.max(child.minHeight,
                            Math.min(child.maxHeight, height));
        } else {
          height = expH;
        }

        // if scaled and zoom is playing, best to let the sizes be non-integer
        if (child.scaleX == 1 && child.scaleY == 1)
          child.setActualSize(Math.floor(width), Math.floor(height));
        else
          child.setActualSize(width, height);

        // offset size due to relative padding and flex resize effect bug
        width = child.width + relativeLeft + relativeRight;
        height = child.height + relativeTop + relativeBottom;

        // position within the flow box
        if (isVertical) {
          // if it's overflowing it's set, create a new set
          if (itemsInSet > 0 && setHeight + vGap + height > h) {
            totalWidth += setWidth + hGap;
            totalHeight = Math.max(totalHeight, setHeight);
            setWidth = 0;
            setHeight = 0;
            itemsInSet = 0;
          }

          // add to the set
          left = vm.left + relativeLeft + totalWidth;
          top = vm.top + relativeTop + setHeight;
          child.move(Math.floor(left), Math.floor(top));

          // update set attributes
          setHeight += (itemsInSet > 0 ? vGap : 0) + height;
          setWidth = Math.max(setWidth, width);
          itemsInSet++;
        } else {
          // if it's overflowing it's set, create a new set
          if (itemsInSet > 0 && setWidth + hGap + width > w) {
            totalWidth = Math.max(totalWidth, setWidth);
            totalHeight += setHeight + vGap;
            setWidth = 0;
            setHeight = 0;
            itemsInSet = 0;
          }

          // add to the set
          left = vm.left + relativeLeft + setWidth;
          top = vm.top + relativeTop + totalHeight;
          child.move(Math.floor(left), Math.floor(top));

          // update set attributes
          setHeight = Math.max(setHeight, height);
          setWidth += (itemsInSet > 0 ? hGap : 0) + width;
          itemsInSet++;
        }
      }

      // update sizes
      if (isVertical) {
        totalWidth += setWidth;
        totalHeight = Math.max(totalHeight, setHeight);
        target.width = totalWidth + vm.right + vm.left;
      } else {
        totalWidth = Math.max(totalWidth, setWidth);
        totalHeight += setHeight;
        target.height = totalHeight + vm.bottom + vm.top;
      }
    }

  }
}
