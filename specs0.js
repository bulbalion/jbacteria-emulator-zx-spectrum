function paintScreen(){
  var dxmin= 32,
      dxmax= 0,
      dymin= 24,
      dymax= 0;
  t= -1;
  while( t++ < 0x2ff )
    for ( col= m[t+0x5800]
        , bk= pal[col    & 7
                | col>>3 & 8]
        , fo= pal[col>>3 & 15]
        , dx= t & 0x1f
        , dy= t>>5
        , o=  dy<<13
            | t<<5 & 0x3ff
        , u=  0x4000
            | t    & 0xff 
            | t<<3 & 0x1800
        , n=  0
        ; n < 8
        ; u+= 0x100
        , o+= 0x400
        , n++ )
      if( k=  col>>7
            & flash>>4
              ? ~m[u]
              : m[u]
        , vm[u] != (col | k<<8) ){
        vm[u]= col | k<<8;
        dx<dxmin && (dxmin= dx);
        dx>dxmax && (dxmax= dx);
        dy<dymin && (dymin= dy);
        dy>dymax && (dymax= dy);
        if( k&128 )
          eld[o  ]= bk[0],
          eld[o+1]= bk[1],
          eld[o+2]= bk[2];
        else
          eld[o  ]= fo[0],
          eld[o+1]= fo[1],
          eld[o+2]= fo[2];
        if( k&64 )
          eld[o+4]= bk[0],
          eld[o+5]= bk[1],
          eld[o+6]= bk[2];
        else
          eld[o+4]= fo[0],
          eld[o+5]= fo[1],
          eld[o+6]= fo[2];
        if( k&32 )
          eld[o+8 ]= bk[0],
          eld[o+9 ]= bk[1],
          eld[o+10]= bk[2];
        else
          eld[o+8 ]= fo[0],
          eld[o+9 ]= fo[1],
          eld[o+10]= fo[2];
        if( k&16 )
          eld[o+12]= bk[0],
          eld[o+13]= bk[1],
          eld[o+14]= bk[2];
        else
          eld[o+12]= fo[0],
          eld[o+13]= fo[1],
          eld[o+14]= fo[2];
        if( k&8 )
          eld[o+16]= bk[0],
          eld[o+17]= bk[1],
          eld[o+18]= bk[2];
        else
          eld[o+16]= fo[0],
          eld[o+17]= fo[1],
          eld[o+18]= fo[2];
        if( k&4 )
          eld[o+20]= bk[0],
          eld[o+21]= bk[1],
          eld[o+22]= bk[2];
        else
          eld[o+20]= fo[0],
          eld[o+21]= fo[1],
          eld[o+22]= fo[2];
        if( k&2 )
          eld[o+24]= bk[0],
          eld[o+25]= bk[1],
          eld[o+26]= bk[2];
        else
          eld[o+24]= fo[0],
          eld[o+25]= fo[1],
          eld[o+26]= fo[2];
        if( k&1 )
          eld[o+28]= bk[0],
          eld[o+29]= bk[1],
          eld[o+30]= bk[2];
        else
          eld[o+28]= fo[0],
          eld[o+29]= fo[1],
          eld[o+30]= fo[2];
      }
  dymax >= dymin &&
    ct.putImageData(elm, 0, 0, (dxmin<<3)-1, (dymin<<3)-1, (dxmax-dxmin<<3)+10, (dymax-dymin<<3)+10);
}