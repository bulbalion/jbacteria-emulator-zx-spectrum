;Exomizer 2 Z80 decoder
;Copyright (C) 2008-2016 by Jaime Tejedor Gomez (Metalbrain)
;
;Optimized by Antonio Villena and Urusergi
;
;Compression algorithm by Magnus Lind
;
;   This depacker is free software; you can redistribute it and/or
;   modify it under the terms of the GNU Lesser General Public
;   License as published by the Free Software Foundation; either
;   version 2.1 of the License, or (at your option) any later version.
;
;   This library is distributed in the hope that it will be useful,
;   but WITHOUT ANY WARRANTY; without even the implied warranty of
;   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;   Lesser General Public License for more details.
;
;   You should have received a copy of the GNU Lesser General Public
;   License along with this library; if not, write to the Free Software
;   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
;
      IF  mapbase-mapbase/256*256<240 AND mapbase-mapbase/256*256>135
        ld      iy, 256+mapbase/256*256
      ELSE
        ld      iy, (mapbase+16)/256*256+112
      ENDIF
        ld      a, 128
        ld      b, 52
        push    de
        cp      a
init    ld      c, 16
        jr      nz, get4
        ld      de, 1
        ld      ixl, c
        defb    218
gb4     ld      a, (hl)
        dec     hl
get4    adc     a, a
        jr      z, gb4
        rl      c
        jr      nc, get4
        inc     c
      IF  mapbase-mapbase/256*256<240 AND mapbase-mapbase/256*256>135
        ld      (iy-256+mapbase-mapbase/256*256), c
      ELSE
        ld      (iy-112+mapbase-(mapbase+16)/256*256), c
      ENDIF
        push    hl
        ld      hl, 1
        defb    48
setbit  add     hl, hl
        dec     c
        jr      nz, setbit
      IF  mapbase-mapbase/256*256<240 AND mapbase-mapbase/256*256>135
        ld      (iy-204+mapbase-mapbase/256*256), e
        ld      (iy-152+mapbase-mapbase/256*256), d
      ELSE
        ld      (iy-60+mapbase-(mapbase+16)/256*256), e
        ld      (iy-8+mapbase-(mapbase+16)/256*256), d
      ENDIF
        add     hl, de
        ex      de, hl
        inc     iyl
        pop     hl
        dec     ixl
        djnz    init
        pop     de
      IF  literals=1
litcop  inc     c
litseq  lddr
      ELSE
litcop  ldd
      ENDIF
mloop   add     a, a
        jr      z, gbm
        jr      c, litcop
      IF  mapbase-mapbase/256*256<240 AND mapbase-mapbase/256*256>135
gbmc    ld      c, 256-1
      ELSE
gbmc    ld      c, 112-1
      ENDIF
getind  add     a, a
        jr      z, gbi
gbic    inc     c
        jr      c, getind
    IF  mapbase-mapbase/256*256<240 AND mapbase-mapbase/256*256>135
        bit     4, c
      IF  literals=1
        jr      nz, litcat
      ELSE
        ret     nz
      ENDIF
    ELSE
      IF  literals=1
        jp      m, litcat
      ELSE
        ret     m
      ENDIF
    ENDIF
        push    de
        ld      iyl, c
        ld      de, 0
        call    getpair
        push    de
      IF  mapbase-mapbase/256*256<240 AND mapbase-mapbase/256*256>135
        ld      bc, 512+48
        dec     e
        jr      z, goit
        dec     e
        ld      bc, 1024+32
        jr      z, goit
        ld      c, 16
      ELSE
        ld      bc, 512+160
        dec     e
        jr      z, goit
        dec     e
        ld      bc, 1024+144
        jr      z, goit
        ld      c, 128
      ENDIF
        ld      e, 0
goit    ld      d, e
        call    getbits
        ld      iyl, c
        add     iy, de
        ld      e, d
        call    getpair
        pop     bc
        ex      (sp), hl
        ex      de, hl
        add     hl, de
        lddr
        pop     hl
        jr      mloop

    IF  literals=1
      IF  mapbase-mapbase/256*256<240 AND mapbase-mapbase/256*256>135
litcat  rl      c
        ret     pe
      ELSE
litcat  ret     po
      ENDIF
        ld      b, (hl)
        dec     hl
        ld      c, (hl)
        dec     hl
        jr      litseq
    ENDIF

gbm     ld      a, (hl)
        dec     hl
        adc     a, a
        jr      nc, gbmc
        jp      litcop

gbi     ld      a, (hl)
        dec     hl
        adc     a, a
        jp      gbic

      IF  mapbase-mapbase/256*256<240 AND mapbase-mapbase/256*256>135
getpair ld      b, (iy-256+mapbase-mapbase/256*256)
      ELSE
getpair ld      b, (iy-112+mapbase-(mapbase+16)/256*256)
      ENDIF
        dec     b
        call    nz, getbits
        ex      de, hl
      IF  mapbase-mapbase/256*256<240 AND mapbase-mapbase/256*256>135
        ld      c, (iy-204+mapbase-mapbase/256*256)
        ld      b, (iy-152+mapbase-mapbase/256*256)
      ELSE
        ld      c, (iy-60+mapbase-(mapbase+16)/256*256)
        ld      b, (iy-8+mapbase-(mapbase+16)/256*256)
      ENDIF
        add     hl, bc
        ex      de, hl
        ret

gbg     ld      a, (hl)
        dec     hl
getbits adc     a, a
        jr      z, gbg
        rl      e
        rl      d
        djnz    getbits
        ret