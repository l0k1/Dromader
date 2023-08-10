var FALSE = 0;
var TRUE = 1;

var mw_prop = props.globals.getNode("payload/weight[2]/max-lb");
var cw_prop = props.globals.getNode("payload/weight[2]/weight-lb");

var perc = 0;

var display_timer = maketimer(0.25,func() {
  perc = cw_prop.getValue() / mw_prop.getValue();
  perc = perc * 100;
  QTY_DISPLAY.percent.setText(sprintf("%03i",perc));
});
display_timer.restart(0.25);

var TANKQTYLCDDISPLAY = {

  canvas_settings: {
    "name": "LCD_TNKQTY",   # The name is optional but allow for easier identification
    "size": [1024, 1024], # Size of the underlying texture (should be a power of 2, required) [Resolution]
    "view": [1024, 1024],  # Virtual resolution (Defines the coordinate system of the canvas [Dimensions]
    # which will be stretched the size of the texture, required)
    "mipmapping": 1       # Enable mipmapping (optional)
  },
  new: func(placement)
  {
    var m = {
      parents: [TANKQTYLCDDISPLAY],
      LCD_TNKQTY: canvas.new(TANKQTYLCDDISPLAY.canvas_settings)
    };

    m.LCD_TNKQTY.addPlacement(placement);
    m.LCD_TNKQTY.setColorBackground(1,1,0.8,1);
    m.displays = m.LCD_TNKQTY.createGroup();


    m.percent = m.displays.createChild("text", "Display")
      .setTranslation(860, 70)      # The origin is in the top left corner
      .setAlignment("right-top") # All values from osgText are supported (see $FG_ROOT/Docs/README.osgtext)
      .setFont("DSEG/DSEG7/Modern/DSEG7Modern-BoldItalic.ttf") # Fonts are loaded either from $AIRCRAFT_DIR/Fonts or $FG_ROOT/Fonts
      .setFontSize(320, 1.0)        # Set fontsize and optionally character aspect ratio
      .setColor(0,0,0)
      .setText("000");            # Text color
    m.shade = m.displays.createChild("text", "Display")
      .setTranslation(860, 70)      # The origin is in the top left corner
      .setAlignment("right-top") # All values from osgText are supported (see $FG_ROOT/Docs/README.osgtext)
      .setFont("DSEG/DSEG7/Modern/DSEG7Modern-BoldItalic.ttf") # Fonts are loaded either from $AIRCRAFT_DIR/Fonts or $FG_ROOT/Fonts
      .setFontSize(320, 1.0)        # Set fontsize and optionally character aspect ratio
      .setColor(0,0,0,0.2)
      .setText("000");            # Text color

    return m;
  }
};


var QTY_DISPLAY = 0;
var init = setlistener("/sim/signals/fdm-initialized", func() {
  removelistener(init); # only call once
  QTY_DISPLAY = TANKQTYLCDDISPLAY.new({"node": "tankqtyLCD"});
});
