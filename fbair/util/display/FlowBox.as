package fbair.util.display {
  import mx.containers.Box;
  import mx.collections.ArrayCollection;
  import mx.containers.BoxDirection;
  import flash.display.DisplayObject;
  import mx.controls.Alert;
  import flash.events.Event;
  import mx.events.ResizeEvent;
  import mx.core.IUIComponent;

  // The default property assigned to when
  //   this component is used in mxml
  [DefaultProperty("children")]

  public class FlowBox extends Box {

    private var _children:ArrayCollection = new ArrayCollection();
    private var _childrenChanged:Boolean = false;

    public function FlowBox() {
      this.addEventListener(ResizeEvent.RESIZE, resizeHandler);
    }

    // If this component is resized, the child
    //   components must be laid out again
    private function resizeHandler(event:Event):void {
      //invalidateSize();
      //validateNow();
      relayoutChildren();
    }

    // Layout all child components (if we need to) during
    //   the commit properties phase of execution
    protected override function commitProperties():void {
      super.commitProperties();

      if (_childrenChanged) {
        _childrenChanged = false;
        layoutChildren();
      }
    }

    // Detect if any styles have been set which would
    //   require the child components to be laid out again
    override public function setStyle(styleProp:String, newValue:*):void {
      super.setStyle(styleProp, newValue);

      if (this.initialized &&
          (styleProp == "horizontalAlign"
          || styleProp == "verticalAlign"
          || styleProp == "horizontalGap"
          || styleProp == "verticalGap"
          || styleProp == "paddingLeft"
          || styleProp == "paddingTop"
          || styleProp == "paddingRight"
          || styleProp == "paddingBottom"))
        relayoutChildren();
    }

    // Add all child components to ourself, creating
    //   sub containers as required for the layout
    private function layoutChildren():void {
      clearContentsForRelayout();

      var currentSubContainer:Box = createSubContainer();
      super.addChildAt(currentSubContainer, super.numChildren);

      for each (var child:DisplayObject in _children) {
        if (!canFit(child, currentSubContainer)) {
          currentSubContainer = createSubContainer();
          super.addChildAt(currentSubContainer, super.numChildren);
        }
        currentSubContainer.addChild(child);
      }
    }

    // Create a sub container (row or column) for
    //   this component will the required configuration
    private function createSubContainer():Box {
      var subContainer:Box = new Box();
      subContainer.direction = this.direction;

      if (this.direction == BoxDirection.HORIZONTAL) {
        subContainer.width = super.width - super.getStyle("paddingLeft")
                             - super.getStyle("paddingRight");
      } else {
        subContainer.height = super.height - super.getStyle("paddingTop")
                              - super.getStyle("paddingBottom");
      }

      subContainer.setStyle("paddingLeft", 0);
      subContainer.setStyle("paddingTop", 0);
      subContainer.setStyle("paddingBottom", 0);
      subContainer.setStyle("paddingRight", 0);

      subContainer.setStyle("horizontalAlign",
                            this.getStyle("horizontalAlign"));
      subContainer.setStyle("verticalAlign",
                            this.getStyle("verticalAlign"));
      subContainer.setStyle("horizontalGap", this.getStyle("horizontalGap"));
      subContainer.setStyle("verticalGap", this.getStyle("verticalGap"));

      subContainer.setStyle("backgroundAlpha", 0);

      return subContainer;
    }

    // Removes all internal layout containers from this
    //   container so that the children can be re-laid out
    private function clearContentsForRelayout():void {
      var kids:Array = super.getChildren();
      for each (var child:DisplayObject in kids)
        super.removeChild(child);
    }

    // Tests whether the specified component could fit within
    //   the specfied container without any clipping or scrollbars
    private function canFit(child:DisplayObject, parent:Box):Boolean {
      var gap:Number;
      var padding:Number;
      var criticalDimension:String;

      if (parent.direction == BoxDirection.HORIZONTAL) {
        gap = parent.getStyle("horizontalGap");
        padding = parent.getStyle("paddingLeft") +
                  parent.getStyle("paddingRight");
        criticalDimension = "width";
      } else {
        gap = parent.getStyle("verticalGap");
        padding = parent.getStyle("paddingTop") +
                  parent.getStyle("paddingBottom");
        criticalDimension = "height";
      }

      var usedSpace:Number = padding;
      var seperator:Number = 0;
      var kids:Array = parent.getChildren();
      for each (var existingChild:DisplayObject in kids) {
        usedSpace += seperator + existingChild[criticalDimension];
        seperator = gap;
      }

      var requiredSpace:Number = usedSpace + gap + child[criticalDimension];
      return requiredSpace < parent[criticalDimension];
    }

    // Flag that the children of this control have changed,
    //   and should be redrawn at the next convenient time
    public function relayoutChildren(event:Event = null):void {
      _childrenChanged = true;
      invalidateProperties();
    }

    // Need to invert the direction property of this control
    //   so that the behaviour is logical
    override public function set direction(value:String):void {
      if (value == BoxDirection.HORIZONTAL)
        super.direction = BoxDirection.VERTICAL;
      else
        super.direction = BoxDirection.HORIZONTAL;

      relayoutChildren();
    }

    override public function get direction():String {
      if (super.direction == BoxDirection.HORIZONTAL)
        return BoxDirection.VERTICAL;
      else
        return BoxDirection.HORIZONTAL;
    }

    /**
     * Override all of the child manipulation functions to mask
     * the internal child layout functions of this container
     */
    public override function addChild(child:DisplayObject):DisplayObject {
      _children.addItem(child);
      relayoutChildren();
      child.addEventListener(ResizeEvent.RESIZE, relayoutChildren);
      return child;
    }

    override public function addChildAt(child:DisplayObject, index:int):DisplayObject {
      _children.addItemAt(child, index);
      relayoutChildren();
      child.addEventListener(ResizeEvent.RESIZE, relayoutChildren);
      return child;
    }

    override public function removeChild(child:DisplayObject):DisplayObject {
      var tmp:DisplayObject = _children.removeItemAt(
        _children.getItemIndex(child)) as DisplayObject;
      tmp.removeEventListener(ResizeEvent.RESIZE, relayoutChildren);
      relayoutChildren();
      return tmp;
    }

    override public function removeChildAt(index:int):DisplayObject {
      var tmp:DisplayObject = _children.removeItemAt(index) as DisplayObject;
      tmp.removeEventListener(ResizeEvent.RESIZE, relayoutChildren);
      relayoutChildren();
      return tmp;
    }

    override public function removeAllChildren():void {
      for each (var child:DisplayObject in _children)
        child.removeEventListener(ResizeEvent.RESIZE, relayoutChildren);
      _children.removeAll();
      relayoutChildren();
    }

    override public function getChildren():Array {
      return _children.toArray();
    }

    override public function getChildIndex(child:DisplayObject):int {
      return _children.getItemIndex(child);
    }

    // This property recieves the child components
    //   of this container when they are set in MXML
    //   This is set as the default property of this component
    public function set children(value:*):void {
      if (value is DisplayObject) {
        _children = new ArrayCollection([value]);
      } else if( value is Array ) {
        var tmp:Array = value as Array;
        _children = new ArrayCollection();

        for each (var child:DisplayObject in tmp) {
          _children.addItem(child);
          child.addEventListener(ResizeEvent.RESIZE, relayoutChildren);
        }
      }
      relayoutChildren();
    }
  }
}
