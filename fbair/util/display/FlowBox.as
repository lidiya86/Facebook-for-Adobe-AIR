package fbair.util.display {

  import mx.containers.Box;
  import mx.core.mx_internal;

  import fbair.util.display.layout.FlowBoxLayout;

  use namespace mx_internal;

  public class FlowBox extends Box {

    public function FlowBox() {
      super();

      mx_internal::layoutObject = new FlowBoxLayout();
      mx_internal::layoutObject.target = this;
    }
  }
}
