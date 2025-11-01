$fn = 60;
/*
**  Überrahmen
*/
Xseite   =  82.0  ;   //mm
Yseite   =  22.0  ;   //mm
Zseite   =   5.5  ;   //mm
staerke  =   1.5  ;   //mm

/*
**  Filter
*/

FilterX  = 78.5 ;
FilterY  = 18.0 ;
FilterZ  = 1.0  ;

/*
**  Rahmen über LED
*/
LedX     =  78.0  ;   // led = 76 plus 2x Wand
LedY     =  18.2  ;   // led = 17,2 plus 2 x Wand
LedZ     =   5.0  ;
Wand     =   1.0  ;



module rahmen(xLength,yLength,zLength,thickness)
{
  cut = 2.0 * thickness;
  difference(){
    cube([xLength ,yLength, zLength],center = true);
    cube([xLength - cut ,yLength- cut, zLength+1],center = true);
  }
}

module Halter (){
  rahmen ( Xseite,Yseite,Zseite, staerke);
  translate ([0,0,Zseite/2.0 + 0.5]) rahmen ( Xseite,Yseite,1.0, 3.0);
}




module lippe(){
  translate ([3.5,0.0,0.0]) cylinder ( d = 2.0 , h = 8.0);
  translate ([1.0,-1.0,0.0]) cube ( [3.0,2.0,8.0]);
  translate ([0.0,-1.0,0.0]) cube ( [1.5,8.0,8.0]);
}

//lippe();

translate ([(LedX/2.0+2.0),-4.0,-9.0])  rotate([ 90.0,0.0,180.0])lippe();
translate ([-(LedX/2.0+2.0),4.0,-9.0])  rotate([ 90.0,0.0,  0.0])lippe();

Halter ();



