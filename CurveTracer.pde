import processing.serial.*;
import java.util.Collections;
import java.util.ArrayList;
import java.lang.Comparable;

        PFont  f18;            // for the text
        float  rc = 984.0;      // resistor values
        float  rb = 100104.0;
        
        int CURRENT_MODE = 0;  // three modes of operation
        int VOLTAGE_MODE = 1;
        int VV_MODE = 2;
        
        boolean clearFlag = false;  // used to clear the graph
        
        int mode = CURRENT_MODE;
        
// this class will store the data, allowing it to be sorted by ib
// and also calculate the various values
public class DataPoint implements Comparable<DataPoint>{
  private
  
  float  vs, vb, vc, rc, rb;
  
  public
  
  DataPoint( float vs, float vb,float  vc,float  rc,float  rb) {
    this.vs = vs;
    this.vb = vb;
    this.vc = vc;
    this.rc = rc;
    this.rb = rb;
  }
  
  // access methods
  
  float ib() {
    return (vs - vb) / rb;
  }
  
  float ic() {
    return (5.0 - vc) / rc;
  }
  
  float gain() {
    return ic()/ib();
  }
  
  float vc() {
    return vc;
  }
  
  float vs() {
    return vs;
  }
  
  // compare method for sorting
  int compareTo(DataPoint dp) {
    if (this.ib() > dp.ib()) return 1;
    if (this.ib() < dp.ib()) return -1;
    return 0;
  }
}

ArrayList<DataPoint> data = new ArrayList<DataPoint>();

Serial myPort;  // The serial port

void setup() {
  size(550,550);
  background(255);
  // Open the port you are using at the rate you want. Change as needed.
  // Windows users will need something like COM30
  myPort = new Serial(this,"/dev/tty.usbserial-A4012ZA0",9600);
  // Set up the serial event on newline characters
  myPort.bufferUntil('\n');
  // load & prepare the font for text drawing
  f18 = loadFont("Baskerville-18.vlw");
  textFont(f18, 18);
}

// in current mode
// max ib = 5 x 10-5
// max ic = 5 * 10-3
// whereas voltages are 0 - 5V

// functions to plot values and keep them on the graph
// yc inverts because 0 is at the top
int xc(int v) { return 50+v; }
int yc(int v) { return 550 - v - 50; }


void draw() {
  if (keyPressed) {
    if (key == 'C') mode = CURRENT_MODE;
    if (key == 'V') mode = VOLTAGE_MODE;
    if (key == 'B') mode = VV_MODE;
    if (key == 'P') {
      clearFlag = true;
      myPort.write("G\n");
      println("---------------->Sent a G");
      delay(1000); // wait to avoid multiples
    }
    if (key == 'Q') 
      myPort.stop();
    }
}

void serialEvent(Serial myPort) {
  if (myPort.available() > 0) { // check still open
    
    if (clearFlag) { // new graph on demand
      data = new ArrayList<DataPoint>();
      clearFlag = false;
    }
    
    String inBuffer = myPort.readString();   
    if (inBuffer != null) {
      String[] stArr = split(inBuffer,",");
      if (stArr.length != 4) {
        println(" there were " + stArr.length + "values"); // error
        println(inBuffer);
      } else {
        // creat object, add to list & sort
        float  vc = float(stArr[0]);
        float  vb = float(stArr[1]);
        float  vs = float(stArr[2]);
        DataPoint dp = new DataPoint(vs,vb,vc,rc,rb);
        data.add(dp);
        Collections.sort(data);
 
        // for diagnostics       
        println("---"+mode);
        println(inBuffer);
        println("IC: "+dp.ic());
        println("IB: "+dp.ib());
        println("gain: "+dp.gain());
        
        // plot 100% new graph
        clear();
        background(255);
        stroke(0,0,0);
        line(xc(0),yc(0),xc(500),yc(0)); // draw two axes
        line(xc(0),yc(0),xc(0),yc(500));
        fill(128,128,128);
        for (int xp = 100; xp < 450; xp += 100) { // and grid
          stroke(192,192,192);
          line(xc(xp),yc(-10),xc(xp),yc(500));
          line(xc(-10),yc(xp),xc(500),yc(xp));
        }
        if (mode == VV_MODE) { // label X axis 
          text("input voltage  (V)",xc(220), yc(-40));
          text("1",xc(90),yc(-20));
          text("2",xc(190),yc(-20));
          text("3",xc(290),yc(-20));
          text("4",xc(390),yc(-20));
          
        } else {
          text("base current  (uA)",xc(220), yc(-40));
          text("10",xc(90),yc(-20));
          text("20",xc(190),yc(-20));
          text("30",xc(290),yc(-20));
          text("40",xc(390),yc(-20));
        }
        
        stroke(0,0,0);
        if (mode == CURRENT_MODE) { // label Y axis & plot correct data
          pushMatrix();
          rotate(PI/2);
          text("collector current  (mA)",200, -10);
          text("1",390,-25);
          text("2",290,-25);
          text("3",190,-25);
          text("4",90,-25);
          popMatrix();
          for (int jj = 1; jj<data.size(); jj++) {
            int x1 = round(data.get(jj-1).ib() * 10000000.0);
            int y1 = round(data.get(jj-1).ic() * 100000.0);
            int x2 = round(data.get(jj).ib() * 10000000.0);
            int y2 = round(data.get(jj).ic() * 100000.0);
            line(xc(x1),yc(y1),xc(x2),yc(y2));
          }
        } else {
          pushMatrix();
          rotate(PI/2);
          text("collector voltage  (V)",200, -10);
          text("1",390,-25);
          text("2",290,-25);
          text("3",190,-25);
          text("4",90,-25);
          popMatrix();
          for (int jj = 1; jj<data.size(); jj++) {
            int x1,x2;
            if (mode == VV_MODE) {
              x1 = round(data.get(jj-1).vs() * 100.0);
              x2 = round(data.get(jj).vs() * 100.0);
              
            } else {
              x1 = round(data.get(jj-1).ib() * 10000000.0);
              x2 = round(data.get(jj).ib() * 10000000.0);
            }
            int y1 = round(data.get(jj-1).vc() * 100.0);
            int y2 = round(data.get(jj).vc() * 100.0);
            line(xc(x1),yc(y1),xc(x2),yc(y2));
          }
          
        }
      }
      
    }
  }
}
