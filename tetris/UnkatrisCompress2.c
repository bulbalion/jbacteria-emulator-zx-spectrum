/*
 * UnkatrisCompress (c) Copyright 2013 by Antonio Villena. All rights reserved.
 *
 * Based on ZX7 <http://www.worldofspectrum.org/infoseekid.cgi?id=0027996>
 * (c) Copyright 2012 by Einar Saukas. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * The name of its author may not be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_OFFSET   22
#define MAX_LEN   65536
#define FILAS        10

unsigned char *output_data;
size_t output_index;
int bit_mask, total= -7;

typedef struct match_t {
  size_t index;
  struct match_t *next;
} Match;

typedef struct optimal_t {
  size_t bits;
  int offset;
  int len;
} Optimal;

int elias_gamma_bits(int value){
  int bits= 1;
  while ( value > 1 )
    bits+= 2,
    value>>= 1;
  return bits;
}

int count_bits(int offset, int len){
  if ( offset == 1 )
    return 3 + elias_gamma_bits(len-1);
  else if( offset == 11 )
    return 4 + elias_gamma_bits(len-1);
  else
    return 6 + elias_gamma_bits(len-1);
}

Optimal* optimize(unsigned char *input_data, size_t input_size){
  size_t *min;
  size_t *max;
  Match *matches;
  Match *match_slots;
  Optimal *optimal;
  Match *match;
  int match_index;
  int offset;
  size_t len;
  size_t best_len;
  size_t bits;
  size_t i;
  min= (size_t *)calloc(MAX_OFFSET+1, sizeof(size_t));
  max= (size_t *)calloc(MAX_OFFSET+1, sizeof(size_t));
  matches= (Match *)calloc(256*256, sizeof(Match));
  match_slots= (Match *)calloc(input_size, sizeof(Match));
  optimal= (Optimal *)calloc(input_size, sizeof(Optimal));
  if( !min || !max || !matches || !match_slots || !optimal  )
    fprintf(stderr, "Error: Insufficient memory\n"),
    exit(1);
  optimal[1].bits= 1;
  for ( i= 2; i < input_size; i++ ){
    optimal[i].bits=  optimal[i-1].bits + 1 + (input_data[i]==2 ? 5 : 1);
    match_index= input_data[i-1] << 8 | input_data[i];
    best_len= 1;
    for ( match= &matches[match_index]
        ; match->next != NULL && best_len < MAX_LEN
        ; match= match->next){
      offset= i - match->next->index;
      if( offset > MAX_OFFSET || offset==12 ){
        match->next = NULL;
        break;
      }
      for ( len= 2; len <= MAX_LEN; len++ ){
        if( len > best_len  ){
          best_len= len;
          bits= optimal[i-len].bits + count_bits(offset, len);
          if (optimal[i].bits > bits)
              optimal[i].bits= bits,
              optimal[i].offset= offset,
              optimal[i].len= len;
        }
        else if( i+1 == max[offset]+len && max[offset] != 0 ){
          len= i-min[offset];
          if( len > best_len )
            len= best_len;
        }
        if( i < offset+len || input_data[i-len] != input_data[i-len-offset] )
          break;
      }
      min[offset]= i+1-len;
      max[offset]= i;
    }
    match_slots[i].index= i;
    match_slots[i].next= matches[match_index].next;
    matches[match_index].next= &match_slots[i];
  }
  free(match_slots);
 printf("size %d bits (%.3f bytes)\n", optimal[input_size-1].bits, (float)optimal[input_size-1].bits/8 );
 total+= optimal[input_size-1].bits;
  return optimal;
}

void write_bit(int value){
  if( bit_mask == 0 )
    bit_mask= 128,
    output_data[output_index++]= 0;
  if( value > 0 )
    output_data[output_index-1]|= bit_mask;
  bit_mask>>= 1;
}

void write_elias_gamma(int value) {
  int bits= 0, rvalue= 0;
  while ( value>1 )
    ++bits,
    rvalue<<= 1,
    rvalue|= value&1,
    value>>= 1;
  while ( bits-- )
    write_bit(0),
    write_bit(rvalue & 1),
    rvalue>>= 1;
  write_bit(1);
}

unsigned char *compress(Optimal *optimal, unsigned char *input_data,
                        size_t input_size){
  size_t input_prev;
  int offset1;
  int mask;
  int i;
  size_t input_index= input_size-1;
  optimal[input_index].bits= 0;
  while (input_index > 0)
    input_prev= input_index - (optimal[input_index].len > 0 ? optimal[input_index].len : 1),
    optimal[input_prev].bits= input_index,
    input_index= input_prev;
  printf("lit %d\n", input_data[input_index+1]);
  write_bit(input_data[++input_index]^1);
  while ( (input_index = optimal[input_index].bits) > 0 )
    if( optimal[input_index].len == 0 ){
      printf("lit %d\n", input_data[input_index]);
      if( input_data[input_index]==2 )
        write_bit(0),
        write_bit(1),
        write_bit(0),
        write_bit(1),
        write_bit(0),
        write_bit(1);
      else
        write_bit(1),
        write_bit(input_data[input_index]^1);
    }
    else{
      write_bit(0);
      offset1= optimal[input_index].offset-1;
      printf("pat %d, %d\n", offset1, optimal[input_index].len);
      if( offset1 == 0)
        write_bit(0),
        write_bit(0);
      else if( offset1 == 11-1)
        write_bit(0),
        write_bit(1),
        write_bit(0);
      else
        offset1+= 11-(offset1<10?0:1),
        write_bit(offset1&16),
        write_bit(offset1&8),
        write_bit(offset1&4),
        write_bit(offset1&2),
        write_bit(offset1&1);
      write_elias_gamma(optimal[input_index].len-1);
    }
}

int empty(unsigned char *input_data){
  int scrsize= 0;
  int i, j;

  for ( i= 0; i<20; i++ ){
    if( *input_data++ == 2 )
      scrsize++;
    for ( j= 0; j<10; j++ )
      if( !*input_data++ )
        scrsize++;
  }
  return scrsize == 220;
}

void main(void){
  unsigned char tmpchar, *mem, *out, *input_data;
  int error, width, height, size= 0, tmpi, i, j, k, l;
  char *fou, *token, tmpstr[1000];
  FILE *fi, *fo;
  mem= (unsigned char *) malloc (0x10000);
  printf( "\nUnkatrisCompress v1.12b, by Antonio Villena, 15 Aug 2014\n\n");
  fi= fopen("unkatris2.tmx", "r");
  while ( !feof(fi) && !strstr(tmpstr, "data e") ){
    fgets(tmpstr, 1000, fi);
  }
  fgets(tmpstr, 1000, fi);
  while ( !strstr(tmpstr, "/layer") ){
    token= (char *) strtok(tmpstr, ",");
    while ( token != NULL ){
      tmpi= atoi(token);
      if( tmpi )
        mem[size++]= tmpi-1;
      token= (char *) strtok(NULL, ",");
    }
    fgets(tmpstr, 1000, fi);
  }
  out= (unsigned char *) malloc (size);
  for ( tmpi= i= 0; i<FILAS; i++ )
    for ( j= 0; j<10; j++ )
      for ( k= 0; k<20; k++ )
        for ( l= 0; l<11; l++ )
          out[tmpi++]= mem[i*2240+j*11+k*110+l];

  for ( i= 0; i<tmpi>>1; i++ )
    tmpchar= out[i],
    out[i]= out[tmpi-1-i],
    out[tmpi-1-i]= tmpchar;
  free(mem);
  fgets(tmpstr, 1000, fi);
  while ( !feof(fi) )
    fgets(tmpstr, 1000, fi);
  fclose(fi);
  output_data= (unsigned char *) malloc (10000);
  fo= fopen("unkatris.map", "wb+");
  output_index= 0;
  bit_mask= 0;
  write_bit(0);
  for ( i= FILAS*10-1; i>-1; i-- ){
    input_data= out+i*220;
    if( i==FILAS*10-1 || !empty(input_data= out+i*220) ){
      printf("\nlevel %02d, ", FILAS*10-1-i );
      compress(optimize(input_data, 220), input_data, 220);
      if( i!=FILAS*10-100 )
        total+= 2,
        write_bit(mem[((FILAS*10-1-i)/10)*2240+((FILAS*10-1-i)%10)*4+2202]-3),
        write_bit(mem[((FILAS*10-1-i)/10)*2240+((FILAS*10-1-i)%10)*4+2203]-3);
    }
  }
  for ( k= 0; k<output_index>>1; k++ )
    tmpchar= output_data[k],
    output_data[k]= output_data[output_index-1-k],
    output_data[output_index-1-k]= tmpchar;
  fwrite(output_data, 1, output_index-1, fo);
  printf("\ntotal %d, %.3f\n", total, (float)total/8);
}
