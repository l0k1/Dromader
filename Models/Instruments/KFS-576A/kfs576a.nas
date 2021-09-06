var FALSE = 0;
var TRUE = 1;
var DOWN = 0;
var UP = 1;

var OFF = 0;
var SBY = 1;
var TST = 2;
var GND = 3;
var ON  = 4;
var ALT = 5;

var modes = [SBY, ON, ALT, TST]; # internal modes to FG modes mapping
var current_mode = 0;

var dig0 = props.globals.getNode("/instrumentation/transponder/inputs/digit");
var dig1 = props.globals.getNode("/instrumentation/transponder/inputs/digit[1]");
var dig2 = props.globals.getNode("/instrumentation/transponder/inputs/digit[2]");
var dig3 = props.globals.getNode("/instrumentation/transponder/inputs/digit[3]");
var pwr  = props.globals.getNode("/instrumentation/transponder/power-btn");
var mode = props.globals.getNode("/instrumentation/transponder/inputs/knob-mode");
var idcode = props.globals.getNode("/instrumentation/transponder/id-code");
var altft = props.globals.getNode("/instrumentation/altimeter/mode-c-alt-ft");

var local_channel = 1200;
var local_channel_written = FALSE;
var pointer_array = [195, 250, 305, 360];
var pointer_position = 0;

var write_channel = func(chan) {
  if (current_mode == 3) {
    return;
  }
  var thousand = math.floor(chan/1000);
  var hundred = math.floor((chan - (thousand * 1000)) / 100);
  var ten = math.floor(chan - (thousand * 1000) - (hundred * 100) / 10);
  var one = math.floor(chan - (thousand * 1000) - (hundred * 100) - (ten * 10));
  dig3.setValue(thousand);
  dig2.setValue(hundred);
  dig1.setValue(ten);
  dig0.setValue(one);
  KFS_LCD_DISPLAY.channel.setText(sprintf("%04i",idcode.getValue()));
};

var code_selector_press = func(dir) {
  if (current_mode == 3) {
    return;
  }
  #print(dir);
  #if (dir == 1) { # button pressed
  #  local_timer.restart(3);
  #} else {
  #  local_timer.stop();
  #  if (local_channel_written == FALSE) {
      pointer_position = math.periodic(0, 4, pointer_position + dir);
      KFS_LCD_DISPLAY.selectcursor.setTranslation(pointer_array[pointer_position], 225);
  #  }
  #  local_channel_written = FALSE;
  #}
}

var local_timer = maketimer(3,func(){
  local_channel_written = TRUE;
  write_channel(local_channel);
});
local_timer.simulatedTime = TRUE;

var test_timer = maketimer(1, func(){
  KFS_LCD_DISPLAY.channel.setText(sprintf("-%03i",(altft.getValue() / 100)));
});
test_timer.simulatedTime = TRUE;

# dir needs to be 1 or -1
# probably a more elegant way to do this buy /lazy/
var cycle_number = func(dir) { 
  if (current_mode == 3) {
    return;
  }
  if (pointer_position == 0 ) {
    dig3.setValue(math.periodic(0,8,dig3.getValue() + dir));
  } elsif (pointer_position == 1) {
    dig2.setValue(math.periodic(0,8,dig2.getValue() + dir));
  } elsif (pointer_position == 2) {
    dig1.setValue(math.periodic(0,8,dig1.getValue() + dir));
  } elsif (pointer_position == 3) {
    dig0.setValue(math.periodic(0,8,dig0.getValue() + dir));
  }
  KFS_LCD_DISPLAY.channel.setText(sprintf("%04i",idcode.getValue()));
}

var power = func() {
  if (pwr.getValue()) {
    pwr.setValue(0);
    mode.setValue(OFF);
    KFS_LCD_DISPLAY.displays.setVisible(FALSE);
    test_timer.stop();
  } else {
    pwr.setValue(1);
    KFS_LCD_DISPLAY.displays.setVisible(TRUE);
    change_mode(SBY);
    KFS_LCD_DISPLAY.channel.setText(sprintf("%04i",idcode.getValue()));
  }
}

var change_mode = func(xpdr_mode){
  if (xpdr_mode == SBY) {
    KFS_LCD_DISPLAY.selectcursor.setVisible(TRUE);
    KFS_LCD_DISPLAY.sby.setVisible(TRUE);
    KFS_LCD_DISPLAY.on.setVisible(FALSE);
    KFS_LCD_DISPLAY.alt.setVisible(FALSE);
    current_mode = 0;
    test_timer.stop();
    KFS_LCD_DISPLAY.reply.setVisible(FALSE);
    KFS_LCD_DISPLAY.flightlevel.setVisible(FALSE);
    KFS_LCD_DISPLAY.channel.setText(sprintf("%04i",idcode.getValue()));
  } elsif (xpdr_mode == ON) {
    KFS_LCD_DISPLAY.selectcursor.setVisible(TRUE);
    KFS_LCD_DISPLAY.sby.setVisible(FALSE);
    KFS_LCD_DISPLAY.on.setVisible(TRUE);
    KFS_LCD_DISPLAY.alt.setVisible(FALSE);
    current_mode = 1;
    test_timer.stop();
    KFS_LCD_DISPLAY.reply.setVisible(FALSE);
    KFS_LCD_DISPLAY.flightlevel.setVisible(FALSE);
    KFS_LCD_DISPLAY.channel.setText(sprintf("%04i",idcode.getValue()));
  } elsif (xpdr_mode == ALT) {
    KFS_LCD_DISPLAY.selectcursor.setVisible(TRUE);
    KFS_LCD_DISPLAY.sby.setVisible(FALSE);
    KFS_LCD_DISPLAY.on.setVisible(TRUE);
    KFS_LCD_DISPLAY.alt.setVisible(TRUE);
    current_mode = 2;
    test_timer.stop();
    KFS_LCD_DISPLAY.reply.setVisible(FALSE);
    KFS_LCD_DISPLAY.flightlevel.setVisible(FALSE);
    KFS_LCD_DISPLAY.channel.setText(sprintf("%04i",idcode.getValue()));
  } elsif (xpdr_mode == TST) {
    KFS_LCD_DISPLAY.selectcursor.setVisible(FALSE);
    KFS_LCD_DISPLAY.sby.setVisible(FALSE);
    KFS_LCD_DISPLAY.on.setVisible(FALSE);
    KFS_LCD_DISPLAY.alt.setVisible(FALSE);
    current_mode = 3;
    KFS_LCD_DISPLAY.channel.setText("----");
    test_timer.restart(1);
    KFS_LCD_DISPLAY.reply.setVisible(TRUE);
    KFS_LCD_DISPLAY.flightlevel.setVisible(TRUE);
  }
  mode.setValue(xpdr_mode);
}

var cycle_modes = func(dir) {
  current_mode = math.periodic(0, 4, current_mode + dir);
  change_mode(modes[current_mode]);
}

var red = [1,0,0,1];

var LCDKFS576A = {

  canvas_settings: {
    "name": "LCD_KFS576A",   # The name is optional but allow for easier identification
    "size": [1024, 1024], # Size of the underlying texture (should be a power of 2, required) [Resolution]
    "view": [1024, 1024],  # Virtual resolution (Defines the coordinate system of the canvas [Dimensions]
    # which will be stretched the size of the texture, required)
    "mipmapping": 1       # Enable mipmapping (optional)
  },
  new: func(placement)
  {
    var m = {
      parents: [LCDKFS576A],
      LCD_KFS576A: canvas.new(LCDKFS576A.canvas_settings)
    };

    m.LCD_KFS576A.addPlacement(placement);
    m.LCD_KFS576A.setColorBackground(0,0,0,1);
    m.displays = m.LCD_KFS576A.createGroup();


    m.channel = m.displays.createChild("text", "topDisplay")
      .setTranslation(400, 155)      # The origin is in the top left corner
      .setAlignment("right-center") # All values from osgText are supported (see $FG_ROOT/Docs/README.osgtext)
      .setFont("DSEG/DSEG7/Modern/DSEG7Modern-BoldItalic.ttf") # Fonts are loaded either from $AIRCRAFT_DIR/Fonts or $FG_ROOT/Fonts
      .setFontSize(68, 1.0)        # Set fontsize and optionally character aspect ratio
      .setColor(red);            # Text color
    m.selectcursor = m.displays.createChild("text", "selectcursor")
      .setTranslation(195, 225)
      .setVisible(1)
      .setAlignment("center-bottom")
      .setFont("Helvetica.txf")
      .setFontSize(34)
      .setColor(red)
      .setText("V");
      # 195, 250, 305 360
    m.reply =  m.displays.createChild("text", "r")
      .setTranslation(160, 135)
      .setVisible(0)
      .setAlignment("right-center")
      .setFont("Helvetica.txf")
      .setFontSize(45)
      .setColor(red)
      .setText("R");
    m.flightlevel =  m.displays.createChild("text", "fl")
      .setTranslation(160, 175)
      .setVisible(0)
      .setAlignment("right-center")
      .setFont("Helvetica.txf")
      .setFontSize(45)
      .setColor(red)
      .setText("FL");
    m.x =  m.displays.createChild("text", "x")
      .setTranslation(410, 175)
      .setVisible(0)
      .setAlignment("center-center")
      .setFont("Helvetica.txf")
      .setFontSize(45)
      .setColor(red)
      .setText("X");
    m.sby =  m.displays.createChild("text", "sby")
      .setTranslation(150, 255)
      .setVisible(0)
      .setAlignment("center-center")
      .setFont("Helvetica.txf")
      .setFontSize(45)
      .setColor(red)
      .setText("SBY");
    m.on =  m.displays.createChild("text", "on")
      .setTranslation(233, 255)
      .setVisible(0)
      .setAlignment("center-center")
      .setFont("Helvetica.txf")
      .setFontSize(45)
      .setColor(red)
      .setText("ON");
    m.alt =  m.displays.createChild("text", "alt")
      .setTranslation(321, 255)
      .setVisible(0)
      .setAlignment("center-center")
      .setFont("Helvetica.txf")
      .setFontSize(45)
      .setColor(red)
      .setText("ALT");
    m.idt =  m.displays.createChild("text", "IdT")
      .setTranslation(400, 255)
      .setVisible(0)
      .setAlignment("center-center")
      .setFont("Helvetica.txf")
      .setFontSize(45)
      .setColor(red)
      .setText("IDT");
    return m;
  }
};


var KFS_LCD_DISPLAY = 0;
var init = setlistener("/sim/signals/fdm-initialized", func() {
  removelistener(init); # only call once
  KFS_LCD_DISPLAY = LCDKFS576A.new({"node": "kfs576aLCD"});
  if (pwr.getValue()) {
    KFS_LCD_DISPLAY.displays.setVisible(TRUE);
    change_mode(SBY);
    KFS_LCD_DISPLAY.channel.setText(sprintf("%3i",idcode.getValue()));
  } else {
    mode.setValue(OFF);
    KFS_LCD_DISPLAY.displays.setVisible(FALSE);
  }
  setlistener("/instrumentation/transponder/ident", func(v) {
  print(v.getValue());
  if (v.getValue()) {
    KFS_LCD_DISPLAY.idt.setVisible(1);
  } else {
    KFS_LCD_DISPLAY.idt.setVisible(0);
  }
});
  #volume_knob(-0.05);
  #update_bottom(sprintf("%.2f",standby_freq.getValue()));
  #update_top(sprintf("%.2f",active_freq.getValue()));
});
