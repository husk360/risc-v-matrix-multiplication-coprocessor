#include "firmware.h"

void mulfun(void){

    uint32_t a=0x00004000;
    uint32_t b=0x00000002;
    uint32_t result=0;
    uint32_t c=0x00000001;
    uint32_t d=0x00000000;
    uint32_t e=0x00000000;
    
    d=12;
    /*
       result=a*b;

    print_hex(a,8);
    print_str("*");
    print_hex(b,8);
    print_str("=");
    print_hex(result,8);
    print_chr('\n');
    print_str("mul is finished");
    print_chr('\n');
    
    */
 

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
    uint32_t a3[d*d];
  for (int i;i<d*d;i++){
        a3[i]= e=hard_read(i);

  }

    for(int i=0;i<d;i++){
       for (int k=0;k<d;k++){

        /* 
        print_str("the (");
        print_dec(i);
        print_str(",");
        print_dec(k);
        print_str(") is ");
     */
       


        print_hex(a3[k+d*i],8);
        print_str("   ");

    }
    print_chr('\n');
}

   // print_str("soft calculation");
    print_chr('\n');
    
    uint32_t a1=1;
    uint32_t a2=1;
    
    
  for (int k1=0;k1<d;k1++){
    for (int k=0;k<d;k++){
        a=0;
    for (int i=0;i<d;i++){
        //c=a2*a1;
        c=hard_mul(a2,a1);
        a=a+c;
    }
    a3[k]=a;
}
   
}

   



}