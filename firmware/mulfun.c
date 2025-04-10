#include "firmware.h"

void mulfun(void){

    uint16_t a=0x00004000;
    uint16_t b=0x00000002;
    uint16_t result=0;
    uint16_t c=0x00000001;
    uint16_t d=0x00000000;
    uint16_t e=0x00000000;
    
    d=12;

    result=a*b;

    print_hex(a,8);
    print_str("*");
    print_hex(b,8);
    print_str("=");
    print_hex(result,8);
    print_chr('\n');
    print_str("mul is finished");
    print_chr('\n');

    print_str("use coprocessor");
    print_chr('\n');


    for (int i=0;i<d*d;i++){
        hard_load(c,i);
      c=c+1;
       
    }

    hard_weight_load();
    c=0x00000001;
   
    for(int i=0;i<d*d;i++){
        hard_load(c,i);
        c=c+1;
    
    }
    
    //c=0x0000003;
    //hard_load(c,0x00000001);

    hard_compute();
    
  

    for(int i=0;i<10;i++){
        e=hard_read(i);
        print_str("the result is ");
        print_hex(e,8);
        print_chr('\n');

    }
    

    
   
    

   



}