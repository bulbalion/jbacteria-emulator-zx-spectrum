.data
.global st, sttap, stint, counter, mem, v, intr, tap, pc, start, endd
.global sp, mp, t, u, ff, ff_, fa, fa_, fb, fb_, fr, fr_    
.global a, c, b, e, d, l, h, a_, c_, b_, e_, d_, l_, h_
.global xl, xh, yl, yh, i, r, rs, prefix, iff, im, w, halted

st:     .quad   0
sttap:  .quad   0
stint:  .quad   0
counter:.quad   100000000
mem:    .word   0
v:      .word   0
intr:   .word   0
tap:    .word   0
ff:     .short  0
pc:     .short  0
start:  .short  0
xl:     .byte   0
xh:     .byte   0
endd:   .short  0
mp:     .short  0
l:      .byte   0
h:      .byte   0
t:      .short  0
u:      .short  0
ff_:    .short  0
fa:     .short  0
sp:     .short  0
fa_:    .short  0
fb:     .short  0
c:      .byte   0
b:      .byte   0
fb_:    .short  0
fr:     .short  0
e:      .byte   0
d:      .byte   0
fr_:    .short  0
prefix: .byte   0
rs:     .byte   0
r:      .byte   0
a:      .byte   0
a_:     .byte   0
c_:     .byte   0
b_:     .byte   0
e_:     .byte   0
d_:     .byte   0
l_:     .byte   0
h_:     .byte   0
dummy:  .byte   0
i:      .byte   0
yl:     .byte   0
yh:     .byte   0
im:     .byte   0
iff:    .byte   0
halted: .byte   0
w:      .byte   0

        .equ    ost,      0
        .equ    osttap,   8+ost
        .equ    ostint,   8+osttap
        .equ    ocounter, 8+ostint
        .equ    omem,     8+ocounter
        .equ    ov,       4+omem
        .equ    ointr,    4+ov
        .equ    otap,     4+ointr
        .equ    off,      4+otap
        .equ    opc,      2+off
        .equ    ostart,   2+opc
        .equ    oxl,      2+ostart
        .equ    oxh,      1+oxl
        .equ    oendd,    1+oxh
        .equ    omp,      2+oendd
        .equ    ol,       2+omp
        .equ    oh,       1+ol
        .equ    ot,       1+oh
        .equ    ou,       2+ot
        .equ    off_,     2+ou
        .equ    ofa,      2+off_
        .equ    osp,      2+ofa
        .equ    ofa_,     2+osp
        .equ    ofb,      2+ofa_
        .equ    oc,       2+ofb
        .equ    ob,       1+oc
        .equ    ofb_,     1+ob
        .equ    ofr,      2+ofb_
        .equ    oe,       2+ofr
        .equ    od,       1+oe
        .equ    ofr_,     1+od
        .equ    oprefix,  2+ofr_
        .equ    ors,      1+oprefix
        .equ    or,       1+ors
        .equ    oa,       1+or
        .equ    oa_,      1+oa
        .equ    oc_,      1+oa_
        .equ    ob_,      1+oc_
        .equ    oe_,      1+ob_
        .equ    od_,      1+oe_
        .equ    ol_,      1+od_
        .equ    oh_,      1+ol_
        .equ    odummy,   1+oh_
        .equ    oi,       1+odummy
        .equ    oyl,      1+oi
        .equ    oyh,      1+oyl
        .equ    oim,      1+oyh
        .equ    oiff,     1+im
        .equ    ohalted,  1+oiff
        .equ    ow,       1+ohalted

        punt    .req      r0
        mem     .req      r1
        stlo    .req      r2
        pcff    .req      r3
        spfa    .req      r4
        bcfb    .req      r5
        defr    .req      r6
        hlmp    .req      r7
        arvpref .req      r8
        ixstart .req      r9
        iyi     .req      r12

      .macro    TIME  cycles
        adds    stlo, stlo, #\cycles
        blcs    insth
      .endm

      .macro    PREFIX0
        bic     arvpref, #0xff
        b       salida
      .endm

      .macro    PREFIX1
        bic     arvpref, #0xff
        add     arvpref, arvpref, #1
        b       salida
      .endm

      .macro    PREFIX2
        orr     arvpref, #0xff
        b       salida
      .endm

      .macro    LDRRIM  regis
        TIME    10
        ldr     lr, [mem, pcff, lsr #16]
        add     pcff, #0x00020000
        pkhbt   \regis, \regis, lr, lsl #16
        PREFIX0
      .endm

      .macro    LDRIM   regis, ofs
        TIME    7
        bic     \regis, #0x00ff0000 << \ofs
        ldrb    lr, [mem, pcff, lsr #16]
        add     pcff, #0x00010000
        orr     \regis, lr, lsl #16+\ofs
        PREFIX0
      .endm

      .macro    LDRRPNN regis, cycl
        TIME    \cycl
        ldr     lr, [mem, pcff, lsr #16]
        mov     lr, lr, lsl #16
        ldr     r11, [mem, lr, lsr #16]
        pkhbt   \regis, \regis, r11, lsl #16
        add     pcff, #0x00020000
        add     lr, #0x00010000
        pkhtb   hlmp, hlmp, lr, asr #16
        PREFIX0
      .endm

      .macro    LDPNNRR regis, cycl
        TIME    \cycl
        ldr     lr, [mem, pcff, lsr #16]
        uxtah   r11, mem, lr
        mov     r10, \regis, lsr #16
        strh    r10, [r11]
        add     pcff, #0x00020000
        add     lr, #0x00000001
        pkhtb   hlmp, hlmp, lr
        PREFIX0
      .endm

      .macro    LDXX    dst, ofd, src, ofs
        TIME    4
        bic     \dst, #0x00ff0000 << \ofd
        and     lr, \src, #0x00ff0000 << \ofs
      .if \ofs-\ofd==-8
        orr     \dst, lr, ror #24
      .else
        orr     \dst, lr, ror #\ofs-\ofd
      .endif
        PREFIX0
      .endm

      .macro    INC     regis, ofs
        TIME    4
      .if \ofs==0
        and     lr, \regis, #0x00ff0000
        pkhtb   spfa, spfa, lr, asr #16
      .else
        mov     lr, \regis, lsr #24
        pkhtb   spfa, spfa, lr
      .endif
        mov     lr, #0x00000001
        pkhtb   bcfb, bcfb, lr
        uadd8   lr, lr, spfa
        bic     \regis, #0x00ff0000 << \ofs
        orr     \regis, \regis, lr, lsl #16+\ofs
        pkhtb   defr, defr, lr
        and     r11, pcff, #0x00000100
        orr     lr, r11
        pkhtb   pcff, pcff, lr
        PREFIX0
      .endm

      .macro    DEC     regis, ofs
        TIME    4
      .if \ofs==0
        and     lr, \regis, #0x00ff0000
        pkhtb   spfa, spfa, lr, asr #16
      .else
        mov     lr, \regis, lsr #24
        pkhtb   spfa, spfa, lr
      .endif
        mov     lr, #0xffff00ff
        pkhtb   bcfb, bcfb, lr, asr #16
        uadd8   lr, lr, spfa
        bic     \regis, #0x00ff0000 << \ofs
        orr     \regis, \regis, lr, lsl #16+\ofs
        pkhtb   defr, defr, lr
        and     r11, pcff, #0x00000100
        orr     lr, r11
        pkhtb   pcff, pcff, lr
        PREFIX0
      .endm

      .macro    XADD    regis, ofs, cycl
        TIME    \cycl
        mov     r11, arvpref, lsr #24
        pkhtb   spfa, spfa, r11
    .if \ofs==0
        and     lr, \regis, #0x00ff0000
        pkhtb   bcfb, bcfb, lr, asr #16
    .else
      .if \ofs<24
        mov     lr, \regis, lsr #24
      .endif
        pkhtb   bcfb, bcfb, lr
    .endif
        add     lr, spfa, bcfb
        pkhtb   pcff, pcff, lr
        uxtb    lr, lr
        bic     arvpref, #0xff000000
        orr     arvpref, lr, lsl #24
        pkhtb   defr, defr, lr
        PREFIX0
      .endm

      .macro    XAND    regis, ofs, cycl
        TIME    \cycl
    .if \ofs==24
        mov     r10, #0xffffff00
        orr     lr, r10
        and     arvpref, lr, ror #8
    .else
      .if \ofs==0
        mov     lr, #0xff00ffff
        orr     lr, \regis
        and     arvpref, lr, ror #24
      .else
        mov     lr, #0x00ffffff
        orr     lr, \regis
        and     arvpref, lr
      .endif
    .endif
        mov     lr, arvpref, lsr #24
        pkhtb   bcfb, bcfb, lr, asr #16
        pkhtb   defr, defr, lr
        pkhtb   pcff, pcff, lr
        mvn     lr, lr
        pkhtb   spfa, spfa, lr
        PREFIX0
      .endm

      .macro    OR      regis, ofs
        TIME    4
        and     lr, \regis, #0x00ff0000 << \ofs
        orr     arvpref, lr, lsl #8-\ofs
        mov     lr, arvpref, lsr #24
        pkhtb   defr, defr, lr
        pkhtb   pcff, pcff, lr
        add     lr, #0x00000100
        pkhtb   spfa, spfa, lr
        pkhtb   bcfb, bcfb, lr, asr #16
        PREFIX0
      .endm

      .macro    XOR     regis, ofs, cycl
        TIME    \cycl
      .if \ofs==24
        eor     arvpref, lr, lsl #24
      .else
        and     lr, \regis, #0x00ff0000 << \ofs
        eor     arvpref, lr, lsl #8-\ofs
      .endif
        mov     lr, arvpref, lsr #24
        pkhtb   defr, defr, lr
        pkhtb   pcff, pcff, lr
        add     lr, #0x00000100
        pkhtb   spfa, spfa, lr
        pkhtb   bcfb, bcfb, lr, asr #16
        PREFIX0
      .endm

      .macro    CP      regis, ofs
        TIME    4
        mov     lr, arvpref, lsr #24
        pkhtb   spfa, spfa, lr
      .if \ofs==0
        and     lr, \regis, #0x00ff0000
        mvn     r11, lr, asr #16
        pkhtb   bcfb, bcfb, r11
        sub     r10, spfa, lr, asr #16
        and     r11, r10, #0x000000ff
        pkhtb   defr, defr, r11
        eor     r10, lr, lsr #16
        and     r10, #0xffffffd7
        eor     r10, lr, lsr #16
      .else
        mov     lr, \regis, lsr #24
        mvn     r11, lr
        pkhtb   bcfb, bcfb, r11
        sub     r10, spfa, lr
        and     r11, r10, #0x000000ff
        pkhtb   defr, defr, r11
        eor     r10, lr
        and     r10, #0xffffffd7
        eor     r10, lr
      .endif
        pkhtb   pcff, pcff, r10
        PREFIX0
      .endm

      .macro    INCW    regis
        TIME    6
        add     \regis, #0x00010000
        PREFIX0
      .endm

      .macro    DECW    regis
        TIME    6
        sub     \regis, #0x00010000
        PREFIX0
      .endm

      .macro    CALLC
        beq     callnn
        TIME    10
        add     pcff, #0x00020000
        PREFIX0
      .endm

      .macro    CALLCI
        bne     callnn
        TIME    10
        add     pcff, #0x00020000
        PREFIX0
      .endm

      .macro    RETC
        beq     ret11
        TIME    5
        PREFIX0
      .endm

      .macro    RETCI
        bne     ret11
        TIME    5
        PREFIX0
      .endm

      .macro    LDRP    src, dst, ofs
        TIME    7
        mov     r11, \src, lsr #16
        ldrb    lr, [mem, r11]
        bic     \dst, #0x00ff0000 << \ofs
        orr     \dst, \dst, lr, lsl #16+\ofs
        add     r11, #1 
        pkhtb   hlmp, hlmp, r11
        PREFIX0
      .endm

      .macro    LDRPI   src, dst, ofs
        TIME    15
        ldr     lr, [mem, pcff, lsr #16]
        add     pcff, #0x00010000
        sxtb    lr, lr
        add     lr, \src, lr, lsl #16
        ldrb    lr, [mem, lr, lsr #16]
        bic     \dst, #0x00ff0000 << \ofs
        orr     \dst, lr, lsl #16+\ofs
        PREFIX0
      .endm

      .macro    LDPR    src, dst, ofs
        TIME    7
        mov     lr, \dst, lsr #16+\ofs
        strb    lr, [mem, \src, lsr #16]
        mov     lr, #0x00010000
        uadd8   lr, lr, \src
        pkhtb   hlmp, hlmp, lr, asr #16
        PREFIX0
      .endm

      .macro    LDPRI   src, dst, ofs
        TIME    15
        PREFIX0
      .endm

      .macro    RET
        ldr     lr, [mem, spfa, lsr #16]
        add     spfa, #0x00020000
        pkhtb   hlmp, hlmp, lr
        pkhbt   pcff, pcff, lr, lsl #16
        PREFIX0
      .endm

      .macro    JRC
        beq     jrnn
        TIME    7
        add     pcff, #0x00010000
        PREFIX0
      .endm

      .macro    JRCI
        bne     jrnn
        TIME    7
        add     pcff, #0x00010000
        PREFIX0
      .endm

      .macro    PUS     regis
        TIME    11
        sub     spfa, #0x00020000
        mov     lr, spfa, lsr #16
        mov     r11, \regis, lsr #16
        strh    r11, [mem, lr]
      .endm

      .macro    POPP    regis
        TIME    10
        ldr     lr, [mem, spfa, lsr #16]
        pkhbt   \regis, \regis, lr, lsl #16
        add     spfa, #0x00020000
      .endm

      .macro    RL      regis, ofs
        TIME    8
        movs    lr, pcff, lsl #24
        uxtb    lr, \regis, ror #16+\ofs
        adc     lr, lr
        pkhtb   pcff, pcff, lr
        uxtb    lr, lr
        bic     \regis, #0x00ff0000 << \ofs
        orr     \regis, lr, lsl #16+\ofs
        pkhtb   defr, defr, lr
        add     lr, #0x00000100
        pkhtb   spfa, spfa, lr
        pkhtb   bcfb, bcfb, lr, asr #16
      .endm

      .macro    RR      regis, ofs
        TIME    8
        uxtb    lr, \regis, ror #16+\ofs
        add     lr, lr, lr, lsl #9
        and     r10, pcff, #0x00000100
        orr     lr, r10
        pkhtb   pcff, pcff, lr, asr #1
        uxtb    lr, pcff
        bic     \regis, #0x00ff0000 << \ofs
        orr     \regis, lr, lsl #16+\ofs
        pkhtb   defr, defr, lr
        add     lr, #0x00000100
        pkhtb   spfa, spfa, lr
        pkhtb   bcfb, bcfb, lr, asr #16
      .endm

      .macro    SLL     regis, ofs
        TIME    8
        and     lr, \regis, #0x00ff0000 << \ofs
        mov     lr, lr, lsr #15+\ofs
        orr     lr, #1
        pkhtb   pcff, pcff, lr
        uxtb    lr, lr
        bic     \regis, #0x00ff0000 << \ofs
        orr     \regis, lr, lsl #16+\ofs
        pkhtb   defr, defr, lr
        add     lr, #0x00000100
        pkhtb   spfa, spfa, lr
        pkhtb   bcfb, bcfb, lr, asr #16
      .endm

      .macro    SRL     regis, ofs
        TIME    8
        uxtb    lr, \regis, ror #16+\ofs
        add     lr, lr, lr, lsl #9
        pkhtb   pcff, pcff, lr, asr #1
        uxtb    lr, pcff
        bic     \regis, #0x00ff0000 << \ofs
        orr     \regis, lr, lsl #16+\ofs
        pkhtb   defr, defr, lr
        add     lr, #0x00000100
        pkhtb   spfa, spfa, lr
        pkhtb   bcfb, bcfb, lr, asr #16
      .endm

      .macro    RES     const, regis
        TIME    8
        and     \regis, #\const
      .endm

      .macro    RESXD   const
        RES     \const, r10
        strb    r10, [mem, r11]
        PREFIX0
      .endm

      .macro    BITI    const
        TIME    5
        and     lr, r10, #\const
        eor     lr, hlmp, lsr #8
        and     lr, #0xffffffd7
        eor     lr, hlmp, lsr #8
        bic     pcff, #0x000000ff
        uxtab   pcff, pcff, lr
        pkhtb   defr, defr, r10
        mvn     lr, r10
        pkhtb   spfa, spfa, lr
        pkhtb   bcfb, bcfb, r10, asr #16
        PREFIX0
      .endm

      .macro    EXSPI   regis
        TIME    19
        add     r10, mem, spfa, lsr #16
        mov     lr, \regis, lsr #16
        swpb    r11, lr, [r10]
        mov     lr, \regis, lsr #24
        add     r10, #1
        swpb    lr, lr, [r10]
        orr     lr, r11, lr, lsl #8
        pkhbt   \regis, \regis, lr, lsl #16
        pkhtb   hlmp, hlmp, lr
      .endm

      .macro    ADDRRRR dst, src
        TIME    11
        mov     lr, \src, lsr #16
        add     lr, \dst, lsr #16
        and     r11, lr, #0x00012800
        and     r10, pcff, #0x00000080
        orr     r10, r11, lsr #8
        pkhtb   pcff, pcff, r10
        eor     r11, defr, spfa
        eor     r10, \dst, \src
        eor     r10, lr, lsl #16
        eor     r11, r10, lsr #24
        and     r11, #0x00000010
        and     r10, bcfb, #0x00000080
        orr     r11, r10
        pkhtb   bcfb, bcfb, r11
        add     r11, \dst, #0x00010000
        pkhtb   hlmp, hlmp, r11, asr #16
        pkhbt   \dst, \dst, lr, lsl #16
        PREFIX0
      .endm

      .macro    ADCHLRR regis
        TIME    15
        movs    lr, pcff, lsl #24
        mov     r11, hlmp, lsr #16
        mov     r10, \regis, lsr #16
        adc     lr, r11, \regis, lsr #16
        pkhtb   pcff, pcff, lr, asr #8
        pkhtb   spfa, spfa, r11, asr #8
        pkhtb   bcfb, bcfb, r10, asr #8
        add     r11, #1
        pkhbt   hlmp, r11, lr, lsl #16
        rev     lr, hlmp
        pkhtb   defr, defr, lr
        PREFIX0
      .endm

      .macro    RST     addr
        TIME    11
        mov     lr, pcff, lsr #16
      .if \addr==0
        uxth    pcff, pcff
      .else
        mov     r11, #\addr
        pkhbt   pcff, pcff, r11, lsl #16
      .endif
        pkhtb   hlmp, hlmp, pcff, asr #16
        sub     spfa, #0x00020000
        mov     r11, spfa, lsr #16
        strh    lr, [mem, r11]
        PREFIX0
      .endm

/*      r0      punt
        r1      mem
        r2      stlo
        r3      pc | ff
        r4      sp | fa
        r5      bc | fb
        r6      de | fr
        r7      hl | mp
        r8      ar | r7 iff im halted : prefix
        r9      ix | start
        r12     iy | i : intr tap
*/

.text
.global execute
execute:push    {r4-r12, lr}

        ldr     punt, _st
        @ cambiar todo esto por un ldm
        ldr     mem, [punt, #omem]
        ldr     stlo, [punt, #ost]
        ldr     pcff, [punt, #off]    @ pc | ff
        ldr     spfa, [punt, #ofa]    @ sp | fa
        ldr     bcfb, [punt, #ofb]    @ bc | fb
        ldr     defr, [punt, #ofr]    @ de | fr
        ldr     hlmp, [punt, #omp]    @ hl | mp
        ldr     arvpref, [punt, #oprefix] @ ar | r7 halted_3 iff_2 im: prefix
        ldr     ixstart, [punt, #ostart]  @ ix | start
        ldr     iyi, [punt, #odummy]  @ iy | i: intr tap
        ldr     lr, [punt, #oim]      @ halted | iff im    0000000h i0000000 000000mm
        add     lr, lr, lsr #13
        uxtb    lr, lr
        orr     arvpref, lr, lsl #8

exec1:  ldrh    lr, [punt, #ostart]
        cmp     lr, pcff, lsr #16
        bne     exec2
exec2:

        mov     lr, #0x00010000
        uadd8   arvpref, arvpref, lr

        ldrb    lr, [mem, pcff, lsr #16]
        add     pcff, #0x00010000
        ldr     pc, [pc, lr, lsl #2]
_st:    .word   st
        .word   nop           @ 00 NOP
        .word   ldbcnn        @ 01 LD BC,nn
        .word   nop           @ 02 LD (BC),A
        .word   incbc         @ 03 INC BC
        .word   incb          @ 04 INC B
        .word   decb          @ 05 DEC B
        .word   ldbn          @ 06 LD B,n
        .word   nop           @ 07 RLCA
        .word   nop           @ 08 EX AF,AF
        .word   addxxbc       @ 09 ADD HL,BC
        .word   ldabc         @ 0a LD A,(BC)
        .word   decbc         @ 0b DEC BC
        .word   incc          @ 0c INC C
        .word   decc          @ 0d DEC C
        .word   ldcn          @ 0e LD C,n
        .word   rrca          @ 0f RRCA
        .word   nop           @ 10 DJNZ
        .word   lddenn        @ 11 LD DE,nn
        .word   nop           @ 12 LD (DE),A
        .word   incde         @ 13 INC DE
        .word   incd          @ 14 INC D
        .word   decd          @ 15 DEC D
        .word   lddn          @ 16 LD D,n
        .word   nop           @ 17 RLA
        .word   jr            @ 18 JR
        .word   addxxde       @ 19 ADD HL,DE
        .word   ldade         @ 1a LD A,(DE)
        .word   decde         @ 1b DEC DE
        .word   ince          @ 1c INC E
        .word   dece          @ 1d DEC E
        .word   lden          @ 1e LD E,n
        .word   nop           @ 1f RRA
        .word   jrnz          @ 20 JR NZ,s8
        .word   ldxxnn        @ 21 LD HL,nn
        .word   ldpnnxx       @ 22 LD (nn),HL
        .word   inchlx        @ 23 INC HL
        .word   inchx         @ 24 INC H
        .word   dechx         @ 25 DEC H
        .word   lxhn          @ 26 LD H,n
        .word   nop           @ 27 DAA
        .word   jrz           @ 28 JR Z,s8
        .word   addxxxx       @ 29 ADD HL,HL
        .word   ldxxpnn       @ 2a LD HL,(nn)
        .word   dechlx        @ 2b DEC HL
        .word   inclx         @ 2c INC L
        .word   declx         @ 2d DEC L
        .word   lxln          @ 2e LD L,n
        .word   nop           @ 2f CPL
        .word   jrnc          @ 30 JR NC,s8
        .word   nop           @ 31 LD SP,nn
        .word   nop           @ 32 LD (nn),A
        .word   incsp         @ 33 INC SP
        .word   nop           @ 34 INC (HL)
        .word   nop           @ 35 DEC (HL)
        .word   nop           @ 36 LD (HL),n
        .word   scf           @ 37 SCF
        .word   jrc           @ 38 JR C,s8
        .word   addxxsp       @ 39 ADD HL,SP
        .word   nop           @ 3a LD A,(nn)
        .word   decsp         @ 3b DEC SP
        .word   inca          @ 3c INC A
        .word   deca          @ 3d DEC A
        .word   ldan          @ 3e LD A,n
        .word   nop           @ 3f CCF
        .word   nop           @ 40 LD B,B
        .word   ldbc          @ 41 LD B,C
        .word   ldbd          @ 42 LD B,D
        .word   ldbe          @ 43 LD B,E
        .word   lxbh          @ 44 LD B,H
        .word   lxbl          @ 45 LD B,L
        .word   lxbhl         @ 46 LD B,(HL)
        .word   ldba          @ 47 LD B,A
        .word   ldcb          @ 48 LD C,B
        .word   nop           @ 49 LD C,C
        .word   ldcd          @ 4a LD C,D
        .word   ldce          @ 4b LD C,E
        .word   lxch          @ 4c LD C,H
        .word   lxcl          @ 4d LD C,L
        .word   lxchl         @ 4e LD C,(HL)
        .word   ldca          @ 4f LD C,A
        .word   lddb          @ 50 LD D,B
        .word   lddc          @ 51 LD D,C
        .word   nop           @ 52 LD D,D
        .word   ldde          @ 53 LD D,E
        .word   lxdh          @ 54 LD D,H
        .word   lxdl          @ 55 LD D,L
        .word   lxdhl         @ 56 LD D,(HL)
        .word   ldda          @ 57 LD D,A
        .word   ldeb          @ 58 LD E,B
        .word   ldec          @ 59 LD E,C
        .word   lded          @ 5a LD E,D
        .word   nop           @ 5b LD E,E
        .word   lxeh          @ 5c LD E,H
        .word   lxel          @ 5d LD E,L
        .word   lxehl         @ 5e LD E,(HL)
        .word   ldea          @ 5f LD E,A
        .word   lxhb          @ 60 LD H,B
        .word   lxhc          @ 61 LD H,C
        .word   lxhd          @ 62 LD H,D
        .word   lxhe          @ 63 LD H,E
        .word   nop           @ 64 LD H,H
        .word   lxhl          @ 65 LD H,L
        .word   lxhhl         @ 66 LD H,(HL)
        .word   lxha          @ 67 LD H,A
        .word   lxlb          @ 68 LD L,B
        .word   lxlc          @ 69 LD L,C
        .word   lxld          @ 6a LD L,D
        .word   lxle          @ 6b LD L,E
        .word   lxlh          @ 6c LD L,H
        .word   nop           @ 6d LD L,L
        .word   lxlhl         @ 6e LD L,(HL)
        .word   lxla          @ 6f LD L,A
        .word   ldxxb         @ 70 LD (HL),B
        .word   ldxxc         @ 71 LD (HL),C
        .word   ldxxd         @ 72 LD (HL),D
        .word   ldxxe         @ 73 LD (HL),E
        .word   ldxxh         @ 74 LD (HL),H
        .word   ldxxl         @ 75 LD (HL),L
        .word   nop           @ 76 HALT
        .word   ldxxa         @ 77 LD (HL),A
        .word   ldab          @ 78 LD A,B
        .word   ldac          @ 79 LD A,C
        .word   ldad          @ 7a LD A,D
        .word   ldae          @ 7b LD A,E
        .word   lxah          @ 7c LD A,H
        .word   lxal          @ 7d LD A,L
        .word   lxahl         @ 7e LD A,(HL)
        .word   nop           @ 7f LD A,A
        .word   addab         @ 80 ADD A,B
        .word   addac         @ 81 ADD A,C
        .word   addad         @ 82 ADD A,D
        .word   addae         @ 83 ADD A,E
        .word   addxh         @ 84 ADD A,H
        .word   addxl         @ 85 ADD A,L
        .word   nop           @ 86 ADD A,(HL)
        .word   addaa         @ 87 ADD A,A
        .word   nop           @ 88 ADC A,B
        .word   nop           @ 89 ADC A,C
        .word   nop           @ 8a ADC A,D
        .word   nop           @ 8b ADC A,E
        .word   nop           @ 8c ADC A,H
        .word   nop           @ 8d ADC A,L
        .word   nop           @ 8e ADC A,(HL
        .word   adcaa         @ 8f ADC A,A
        .word   nop           @ 90 SUB A,B
        .word   nop           @ 91 SUB A,C
        .word   nop           @ 92 SUB A,D
        .word   nop           @ 93 SUB A,E
        .word   nop           @ 94 SUB A,H
        .word   nop           @ 95 SUB A,L
        .word   nop           @ 96 SUB A,(HL)
        .word   nop           @ 97 SUB A,A
        .word   nop           @ 98 SBC A,B
        .word   nop           @ 99 SBC A,C
        .word   nop           @ 9a SBC A,D
        .word   nop           @ 9b SBC A,E
        .word   nop           @ 9c SBC A,H
        .word   nop           @ 9d SBC A,L
        .word   nop           @ 9e SBC A,(HL)
        .word   nop           @ 9f SBC A,A
        .word   andb          @ a0 AND B
        .word   andc          @ a1 AND C
        .word   andd          @ a2 AND D
        .word   ande          @ a3 AND E
        .word   andxh         @ a4 AND H
        .word   andxl         @ a5 AND L
        .word   nop           @ a6 AND (HL)
        .word   anda          @ a7 AND A
        .word   xorb          @ a8 XOR B
        .word   xorc          @ a9 XOR C
        .word   xord          @ aa XOR D
        .word   xore          @ ab XOR E
        .word   xorxh         @ ac XOR H
        .word   xorxl         @ ad XOR L
        .word   xorxx         @ ae XOR (HL)
        .word   xora          @ af XOR A
        .word   orb           @ b0 OR B
        .word   orc           @ b1 OR C
        .word   ord           @ b2 OR D
        .word   ore           @ b3 OR E
        .word   orxh          @ b4 OR H
        .word   orxl          @ b5 OR L
        .word   nop           @ b6 OR (HL)
        .word   ora           @ b7 OR A
        .word   cpb           @ b8 CP B
        .word   cpc           @ b9 CP C
        .word   cp_d          @ ba CP D
        .word   cpe           @ bb CP E
        .word   cpxh          @ bc CP H
        .word   cpxl          @ bd CP L
        .word   nop           @ be CP (HL)
        .word   cpa           @ bf CP A
        .word   retnz         @ c0 RET NZ
        .word   popbc         @ c1 POP BC
        .word   nop           @ c2 JP NZ
        .word   jpnn          @ c3 JP nn
        .word   callnz        @ c4 CALL NZ
        .word   pushbc        @ c5 PUSH BC
        .word   addan         @ c6 ADD A,n
        .word   rst00         @ c7 RST 0x00
        .word   retz          @ c8 RET Z
        .word   ret10         @ c9 RET
        .word   nop           @ ca JP Z
        .word   opcb          @ cb op cb
        .word   callz         @ cc CALL Z
        .word   callnn        @ cd CALL NN
        .word   nop           @ ce ADC A,n
        .word   rst08         @ cf RST 0x08
        .word   retnc         @ d0 RET NC
        .word   popde         @ d1 POP DE
        .word   nop           @ d2 JP NC
        .word   nop           @ d3 OUT (n),A
        .word   callnc        @ d4 CALL NC
        .word   pushde        @ d5 PUSH DE
        .word   nop           @ d6 SUB A,n
        .word   rst10         @ d7 RST 0x10
        .word   retc          @ d8 RET C
        .word   nop           @ d9 EXX
        .word   nop           @ da JP C
        .word   nop           @ db IN A,(n)
        .word   callc         @ dc CALL C
        .word   opdd          @ dd OP dd
        .word   nop           @ de SBC A,n
        .word   rst18         @ df RST 0x18
        .word   retpo         @ e0 RET PO
        .word   popxx         @ e1 POP HL
        .word   nop           @ e2 JP PO
        .word   exspxx        @ e3 EX (SP),HL
        .word   callpo        @ e4 CALL PO
        .word   pushxx        @ e5 PUSH HL
        .word   andan         @ e6 AND A,n
        .word   rst20         @ e7 RST 0x20
        .word   retpe         @ e8 RET PE
        .word   jpxx          @ e9 JP (HL)
        .word   nop           @ ea JP PE
        .word   exdehl        @ eb EX DE,HL
        .word   callpe        @ ec CALL PE
        .word   oped          @ ed op ed
        .word   nop           @ ee XOR A,n
        .word   rst28         @ ef RST 0x28
        .word   retp          @ f0 RET P
        .word   nop           @ f1 POP AF
        .word   nop           @ f2 JP P
        .word   di            @ f3 DI
        .word   callp         @ f4 CALL P
        .word   nop           @ f5 PUSH AF
        .word   nop           @ f6 OR A,n
        .word   rst30         @ f7 RST 0x30
        .word   retm          @ f8 RET M
        .word   ldspxx        @ f9 LD SP,HL
        .word   nop           @ fa JP M
        .word   ei            @ fb EI
        .word   callm         @ fc CALL M
        .word   opfd          @ fd op fd
        .word   nop           @ fe CP A,n
        .word   rst38         @ ff RST 0x38

nop:    TIME    4
        PREFIX0

opdd:   TIME    4
        PREFIX1

opfd:   TIME    4
        PREFIX2

ei:     TIME    4
        orr     arvpref, #0x00000400
        PREFIX0

di:     TIME    4
        and     arvpref, #0xfffffbff
        PREFIX0

ldbcnn: LDRRIM  bcfb
lddenn: LDRRIM  defr

ldxxnn: movs    lr, arvpref, lsl #24
        beq     ldhlnn
        bmi     ldiynn
        LDRRIM  ixstart
ldiynn: LDRRIM  iyi
ldhlnn: LDRRIM  hlmp

jpxx:   TIME    4
        movs    lr, arvpref, lsl #24
        beq     jphl
        bmi     jpiy
        pkhbt   pcff, pcff, ixstart
        PREFIX0
jpiy:   pkhbt   pcff, pcff, iyi
        PREFIX0
jphl:   pkhbt   pcff, pcff, hlmp
        PREFIX0

ldspxx: TIME    4
        movs    lr, arvpref, lsl #24
        beq     ldsphl
        bmi     ldspiy
        pkhbt   spfa, spfa, ixstart
        PREFIX0
ldspiy: pkhbt   spfa, spfa, iyi
        PREFIX0
ldsphl: pkhbt   spfa, spfa, hlmp
        PREFIX0

ldxxpnn:movs    lr, arvpref, lsl #24
        beq     ldhlpnn
        bmi     ldiypnn
        LDRRPNN ixstart, 16
ldiypnn:LDRRPNN iyi, 16
ldhlpnn:LDRRPNN hlmp, 16

ldbcpnn:LDRRPNN bcfb, 20
lddepnn:LDRRPNN defr, 20
ldxepnn:LDRRPNN hlmp, 20
ldsppnn:LDRRPNN spfa, 20


ldpnnxx:movs    lr, arvpref, lsl #24
        beq     ldpnnhl
        bmi     ldpnniy
        LDPNNRR ixstart, 16
ldpnniy:LDPNNRR iyi, 16
ldpnnhl:LDPNNRR hlmp, 16

ldpnnbc:LDPNNRR bcfb, 20
ldpnnde:LDPNNRR defr, 20
ldpnnxe:LDPNNRR hlmp, 20
ldpnnsp:LDPNNRR spfa, 20

addxxbc:movs    lr, arvpref, lsl #24
        beq     addhlbc
        bmi     addiybc
        ADDRRRR ixstart, bcfb
addiybc:ADDRRRR iyi, bcfb
addhlbc:ADDRRRR hlmp, bcfb

addxxde:movs    lr, arvpref, lsl #24
        beq     addhlde
        bmi     addiyde
        ADDRRRR ixstart, defr
addiyde:ADDRRRR iyi, defr
addhlde:ADDRRRR hlmp, defr

addxxxx:movs    lr, arvpref, lsl #24
        beq     addhlhl
        bmi     addiyiy
        ADDRRRR ixstart, ixstart
addiyiy:ADDRRRR iyi, iyi
addhlhl:ADDRRRR hlmp, hlmp

addxxsp:movs    lr, arvpref, lsl #24
        beq     addhlsp
        bmi     addiysp
        ADDRRRR ixstart, spfa
addiysp:ADDRRRR iyi, spfa
addhlsp:ADDRRRR hlmp, spfa

callnn: TIME    17
        mov     r11, pcff, lsr #16
        ldrh    lr, [mem, r11]
        add     r11, r11, #2
        pkhbt   pcff, pcff, lr, lsl #16
        pkhtb   hlmp, hlmp, lr
        sub     spfa, #0x00020000
        mov     r10, spfa, lsr #16
        strh    r11, [mem, r10]
        PREFIX0

callz:  movs    lr, defr, lsl #16
        CALLC

callnz: movs    lr, defr, lsl #16
        CALLCI

callnc: tst     pcff, #0x00000100
        CALLC

callc:  tst     pcff, #0x00000100
        CALLCI

callp:  tst     pcff, #0x00000080
        CALLC

callm:  tst     pcff, #0x00000080
        CALLCI

ret11:  TIME    10
        RET

ret10:  TIME    10
        RET

retz:   movs    lr, defr, lsl #16
        RETC

retnz:  movs    lr, defr, lsl #16
        RETCI

retnc:  tst     pcff, #0x00000100
        RETC

retc:   tst     pcff, #0x00000100
        RETCI

retp:   tst     pcff, #0x00000080
        RETC

retm:   tst     pcff, #0x00000080
        RETCI

jr:     TIME    12
        ldr     lr, [mem, pcff, lsr #16]
        sxtb    lr, lr
        add     pcff, lr, lsl #16
        add     pcff, #0x00010000
        pkhtb   hlmp, hlmp, pcff, asr #16
        PREFIX0

jrnc:   tst     pcff, #0x00000100
        JRC
jrnn:   TIME    12
        ldr     lr, [mem, pcff, lsr #16]
        sxtb    lr, lr
        add     pcff, lr, lsl #16
        add     pcff, #0x00010000
        PREFIX0

jrc:    tst     pcff, #0x00000100
        JRCI

jrz:    movs    lr, defr, lsl #16
        JRC

jrnz:   movs    lr, defr, lsl #16
        JRCI

jpnn:   TIME    10
        ldr     lr, [mem, pcff, lsr #16]
        add     pcff, pcff, #0x00020000
        pkhbt   pcff, pcff, lr, lsl #16
        pkhtb   hlmp, hlmp, lr
        PREFIX0

ldbn:   LDRIM   bcfb, 8
ldcn:   LDRIM   bcfb, 0
lddn:   LDRIM   defr, 8
lden:   LDRIM   defr, 0

lxhn:   movs    lr, arvpref, lsl #24
        beq     ldhn
        bmi     ldyhn
        LDRIM   ixstart, 8
ldyhn:  LDRIM   iyi, 8
ldhn:   LDRIM   hlmp, 8

lxln:   movs    lr, arvpref, lsl #24
        beq     ldln
        bmi     ldyln
        LDRIM   ixstart, 0
ldyln:  LDRIM   iyi, 0
ldln:   LDRIM   hlmp, 0

ldan:   LDRIM   arvpref, 8

ldbc:   LDXX    bcfb, 8, bcfb, 0
ldbd:   LDXX    bcfb, 8, defr, 8
ldbe:   LDXX    bcfb, 8, defr, 0
lxbh:   movs    lr, arvpref, lsl #24
        beq     ldbh
        bmi     ldbyh
        LDXX    bcfb, 8, ixstart, 8
ldbyh:  LDXX    bcfb, 8, iyi, 8
ldbh:   LDXX    bcfb, 8, hlmp, 8

lxbl:   movs    lr, arvpref, lsl #24
        beq     ldbl
        bmi     ldbyl
        LDXX    bcfb, 8, ixstart, 0
ldbyl:  LDXX    bcfb, 8, iyi, 0
ldbl:   LDXX    bcfb, 8, hlmp, 0

ldba:   LDXX    bcfb, 8, arvpref, 8
ldcb:   LDXX    bcfb, 0, bcfb, 8
ldcd:   LDXX    bcfb, 0, defr, 8
ldce:   LDXX    bcfb, 0, defr, 0

lxch:   movs    lr, arvpref, lsl #24
        beq     ldch
        bmi     ldcyh
        LDXX    bcfb, 0, ixstart, 8
ldcyh:  LDXX    bcfb, 0, iyi, 8
ldch:   LDXX    bcfb, 0, hlmp, 8

lxcl:   movs    lr, arvpref, lsl #24
        beq     ldcl
        bmi     ldcyl
        LDXX    bcfb, 0, ixstart, 0
ldcyl:  LDXX    bcfb, 0, iyi, 0
ldcl:   LDXX    bcfb, 0, hlmp, 0

ldca:   LDXX    bcfb, 0, arvpref, 8
lddb:   LDXX    defr, 8, bcfb, 8
lddc:   LDXX    defr, 8, bcfb, 0
ldde:   LDXX    defr, 8, defr, 0

lxdh:   movs    lr, arvpref, lsl #24
        beq     lddh
        bmi     lddyh
        LDXX    defr, 8, ixstart, 8
lddyh:  LDXX    defr, 8, iyi, 8
lddh:   LDXX    defr, 8, hlmp, 8

lxdl:   movs    lr, arvpref, lsl #24
        beq     lddl
        bmi     lddyl
        LDXX    defr, 8, ixstart, 0
lddyl:  LDXX    defr, 8, iyi, 0
lddl:   LDXX    defr, 8, hlmp, 0

ldda:   LDXX    defr, 8, arvpref, 8
ldeb:   LDXX    defr, 0, bcfb, 8
ldec:   LDXX    defr, 0, bcfb, 0
lded:   LDXX    defr, 0, defr, 8
lxeh:   movs    lr, arvpref, lsl #24
        beq     ldeh
        bmi     ldeyh
        LDXX    defr, 0, ixstart, 8
ldeyh:  LDXX    defr, 0, iyi, 8
ldeh:   LDXX    defr, 0, hlmp, 8

lxel:   movs    lr, arvpref, lsl #24
        beq     ldel
        bmi     ldeyl
        LDXX    defr, 0, ixstart, 0
ldeyl:  LDXX    defr, 0, iyi, 0
ldel:   LDXX    defr, 0, hlmp, 0

ldea:   LDXX    defr, 0, arvpref, 8

lxhb:   movs    lr, arvpref, lsl #24
        beq     ldhb
        bmi     ldyhb
        LDXX    ixstart, 8, bcfb, 8
ldyhb:  LDXX    iyi, 8, bcfb, 8
ldhb:   LDXX    hlmp, 8, bcfb, 8

lxhc:   movs    lr, arvpref, lsl #24
        beq     ldhc
        bmi     ldyhc
        LDXX    ixstart, 8, bcfb, 0
ldyhc:  LDXX    iyi, 8, bcfb, 0
ldhc:   LDXX    hlmp, 8, bcfb, 0

lxhd:   movs    lr, arvpref, lsl #24
        beq     ldhd
        bmi     ldyhd
        LDXX    ixstart, 8, defr, 8
ldyhd:  LDXX    iyi, 8, defr, 8
ldhd:   LDXX    hlmp, 8, defr, 8

lxhe:   movs    lr, arvpref, lsl #24
        beq     ldhe
        bmi     ldyhe
        LDXX    ixstart, 8, defr, 0
ldyhe:  LDXX    iyi, 8, defr, 0
ldhe:   LDXX    hlmp, 8, defr, 0

lxhl:   movs    lr, arvpref, lsl #24
        beq     ldhl
        bmi     ldyhl
        LDXX    ixstart, 8, ixstart, 0
ldyhl:  LDXX    iyi, 8, iyi, 0
ldhl:   LDXX    hlmp, 8, hlmp, 0

lxha:   movs    lr, arvpref, lsl #24
        beq     ldha
        bmi     ldyha
        LDXX    ixstart, 8, arvpref, 8
ldyha:  LDXX    iyi, 8, arvpref, 8
ldha:   LDXX    hlmp, 8, arvpref, 8

lxlb:   movs    lr, arvpref, lsl #24
        beq     ldlb
        bmi     ldylb
        LDXX    ixstart, 0, bcfb, 8
ldylb:  LDXX    iyi, 0, bcfb, 8
ldlb:   LDXX    hlmp, 0, bcfb, 8

lxlc:   movs    lr, arvpref, lsl #24
        beq     ldlc
        bmi     ldylc
        LDXX    ixstart, 0, bcfb, 0
ldylc:  LDXX    iyi, 0, bcfb, 0
ldlc:   LDXX    hlmp, 0, bcfb, 0

lxld:   movs    lr, arvpref, lsl #24
        beq     ldld
        bmi     ldyld
        LDXX    ixstart, 0, defr, 8
ldyld:  LDXX    iyi, 0, defr, 8
ldld:   LDXX    hlmp, 0, defr, 8

lxle:   movs    lr, arvpref, lsl #24
        beq     ldle
        bmi     ldyle
        LDXX    ixstart, 0, defr, 0
ldyle:  LDXX    iyi, 0, defr, 0
ldle:   LDXX    hlmp, 0, defr, 0

lxlh:   movs    lr, arvpref, lsl #24
        beq     ldlh
        bmi     ldylh
        LDXX    ixstart, 0, ixstart, 8
ldylh:  LDXX    iyi, 0, iyi, 8
ldlh:   LDXX    hlmp, 0, hlmp, 8

lxla:   movs    lr, arvpref, lsl #24
        beq     ldla
        bmi     ldyla
        LDXX    ixstart, 0, arvpref, 8
ldyla:  LDXX    iyi, 0, arvpref, 8
ldla:   LDXX    hlmp, 0, arvpref, 8

ldab:   LDXX    arvpref, 8, bcfb, 8
ldac:   LDXX    arvpref, 8, bcfb, 0
ldad:   LDXX    arvpref, 8, defr, 8
ldae:   LDXX    arvpref, 8, defr, 0

lxah:   movs    lr, arvpref, lsl #24
        beq     ldah
        bmi     ldayh
        LDXX    arvpref, 8, ixstart, 8
ldayh:  LDXX    arvpref, 8, iyi, 8
ldah:   LDXX    arvpref, 8, hlmp, 8

lxal:   movs    lr, arvpref, lsl #24
        beq     ldal
        bmi     ldayl
        LDXX    arvpref, 8, ixstart, 0
ldayl:  LDXX    arvpref, 8, iyi, 0
ldal:   LDXX    arvpref, 8, hlmp, 0

inca:   INC     arvpref, 8
incb:   INC     bcfb, 8
incc:   INC     bcfb, 0
incd:   INC     defr, 8
ince:   INC     defr, 0

inchx:  movs    lr, arvpref, lsl #24
        beq     inch
        bmi     incyh
        INC     ixstart, 8
incyh:  INC     iyi, 8
inch:   INC     hlmp, 8

inclx:  movs    lr, arvpref, lsl #24
        beq     incl
        bmi     incyl
        INC     ixstart, 0
incyl:  INC     iyi, 0
incl:   INC     hlmp, 0

deca:   DEC     arvpref, 8
decb:   DEC     bcfb, 8
decc:   DEC     bcfb, 0
decd:   DEC     defr, 8
dece:   DEC     defr, 0

dechx:  movs    lr, arvpref, lsl #24
        beq     dech
        bmi     decyh
        DEC     ixstart, 8
decyh:  DEC     iyi, 8
dech:   DEC     hlmp, 8

declx:  movs    lr, arvpref, lsl #24
        beq     decl
        bmi     decyl
        DEC     ixstart, 0
decyl:  DEC     iyi, 0
decl:   DEC     hlmp, 0

rst00:  RST     0x00
rst08:  RST     0x18
rst10:  RST     0x10
rst18:  RST     0x18
rst20:  RST     0x20
rst28:  RST     0x28
rst30:  RST     0x30
rst38:  RST     0x38

addaa:  TIME    4
        mov     lr, arvpref, lsr #24
        pkhtb   spfa, spfa, lr
        pkhtb   bcfb, bcfb, lr
        mov     lr, lr, lsl #1
        pkhtb   pcff, pcff, lr
        uxtb    lr, lr  @ importante
        bic     arvpref, #0xff000000
        orr     arvpref, lr, lsl #24
        pkhtb   defr, defr, lr
        PREFIX0

addab:  XADD    bcfb, 8, 4
addac:  XADD    bcfb, 0, 4
addad:  XADD    defr, 8, 4
addae:  XADD    defr, 0, 4

addxh:  movs    lr, arvpref, lsl #24
        beq     addah
        bmi     addayh
        XADD    ixstart, 8, 4
addayh: XADD    iyi, 8, 4
addah:  XADD    hlmp, 8, 4

addxl:  movs    lr, arvpref, lsl #24
        beq     addal
        bmi     addayl
        XADD    ixstart, 0, 4
addayl: XADD    iyi, 0, 4
addal:  XADD    hlmp, 0, 4

addan:  ldrb    lr, [mem, pcff, lsr #16]
        add     pcff, #0x00010000
        XADD    lr, 24, 7

adcaa:  TIME    4
        mov     lr, arvpref, lsr #24
        pkhtb   spfa, spfa, lr
        pkhtb   bcfb, bcfb, lr
        movs    r11, pcff, lsr #9
        adc     lr, lr, lr
        pkhtb   pcff, pcff, lr
        uxtb    lr, lr  @ importante
        bic     arvpref, #0xff000000
        orr     arvpref, lr, lsl #24
        pkhtb   defr, defr, lr
        PREFIX0

andb:   XAND    bcfb, 8, 4
andc:   XAND    bcfb, 0, 4
andd:   XAND    defr, 8, 4
ande:   XAND    defr, 0, 4

andxh:  movs    lr, arvpref, lsl #24
        beq     andh
        bmi     andyh
        XAND    ixstart, 8, 4
andyh:  XAND    iyi, 8, 4
andh:   XAND    hlmp, 8, 4

andxl:  movs    lr, arvpref, lsl #24
        beq     andl
        bmi     andyl
        XAND    ixstart, 0, 4
andyl:  XAND    iyi, 0, 4
andl:   XAND    hlmp, 0, 4

andan:  ldrb    lr, [mem, pcff, lsr #16]
        add     pcff, #0x00010000
        XAND    lr, 24, 7

anda:   TIME    4
        mov     lr, arvpref, lsr #24
        pkhtb   bcfb, bcfb, lr, asr #16
        pkhtb   defr, defr, lr
        pkhtb   pcff, pcff, lr
        mvn     lr, lr
        pkhtb   spfa, spfa, lr
        PREFIX0

xorb:   XOR     bcfb, 8, 4
xorc:   XOR     bcfb, 0, 4
xord:   XOR     defr, 8, 4
xore:   XOR     defr, 0, 4

xorxh:  movs    lr, arvpref, lsl #24
        beq     xorh
        bmi     xoryh
        XOR     ixstart, 8, 4
xoryh:  XOR     iyi, 8, 4
xorh:   XOR     hlmp, 8, 4

xorxl:  movs    lr, arvpref, lsl #24
        beq     xorl
        bmi     xoryl
        XOR     ixstart, 0, 4
xoryl:  XOR     iyi, 0, 4
xorl:   XOR     hlmp, 0, 4

xorxx:  movs    lr, arvpref, lsl #24
        beq     xorhl
        ldr     lr, [mem, pcff, lsr #16]
        add     pcff, #0x00010000
        sxtb    lr, lr
        bmi     xoriy
        add     lr, ixstart, lsr #16
        ldrb    lr, [mem, lr]
        XOR     lr, 24, 7
xoriy:  add     lr, iyi, lsr #16
        ldrb    lr, [mem, lr]
        XOR     lr, 24, 7
xorhl:  ldrb    lr, [mem, hlmp, lsr #16]
        XOR     lr, 24, 7

xora:   TIME    4
        mov     lr, #0x00000100
        pkhtb   bcfb, bcfb, lr, asr #16
        pkhtb   defr, defr, lr, asr #16
        pkhtb   pcff, pcff, lr, asr #16
        bic     arvpref, #0xff000000
        pkhtb   spfa, spfa, lr
        PREFIX0

orb:    OR      bcfb, 8
orc:    OR      bcfb, 0
ord:    OR      defr, 8
ore:    OR      defr, 0

orxh:   movs    lr, arvpref, lsl #24
        beq     orh
        bmi     oryh
        OR      ixstart, 8
oryh:   OR      iyi, 8
orh:    OR      hlmp, 8

orxl:   movs    lr, arvpref, lsl #24
        beq     orl
        bmi     oryl
        OR      ixstart, 0
oryl:   OR      iyi, 0
orl:    OR      hlmp, 0

ora:    TIME    4
        mov     lr, arvpref, lsr #24
        pkhtb   defr, defr, lr
        pkhtb   pcff, pcff, lr
        add     lr, #0x00000100
        pkhtb   spfa, spfa, lr
        pkhtb   bcfb, bcfb, lr, asr #16
        PREFIX0

cpb:    CP      bcfb, 8
cpc:    CP      bcfb, 0
cp_d:   CP      defr, 8
cpe:    CP      defr, 0

cpxh:   movs    lr, arvpref, lsl #24
        beq     cph
        bmi     cpyh
        CP      ixstart, 8
cpyh:   CP      iyi, 8
cph:    CP      hlmp, 8

cpxl:   movs    lr, arvpref, lsl #24
        beq     cpl
        bmi     cpyl
        CP      ixstart, 0
cpyl:   CP      iyi, 0
cpl:    CP      hlmp, 0

cpa:    TIME    4
        mov     lr, arvpref, lsr #24
        pkhtb   defr, defr, lr, asr #16
        pkhtb   spfa, spfa, lr
        mvn     r11, lr
        pkhtb   bcfb, bcfb, lr
        and     lr, #0x00000028
        pkhtb   pcff, pcff, lr
        PREFIX0

scf:    TIME    4
        and     lr, bcfb, #0x00000080
        eor     r11, defr, spfa
        and     r11, #0x00000010
        orr     lr, r11
        pkhtb   bcfb, bcfb, lr
        and     lr, arvpref, #0x28000000
        and     r11, pcff, #0x00000080
        orr     r11, lr, lsr #24
        orr     r11, #0x00000100
        pkhtb   pcff, pcff, r11
        PREFIX0

lxbhl:  movs    lr, arvpref, lsl #24
        beq     ldbhl
        bmi     ldbiy
        LDRPI   ixstart, bcfb, 8
ldbiy:  LDRPI   iyi, bcfb, 8
ldbhl:  LDRP    hlmp, bcfb, 8

lxchl:  movs    lr, arvpref, lsl #24
        beq     ldchl
        bmi     ldciy
        LDRPI   ixstart, bcfb, 0
ldciy:  LDRPI   iyi, bcfb, 0
ldchl:  LDRP    hlmp, bcfb, 0

lxdhl:  movs    lr, arvpref, lsl #24
        beq     lddhl
        bmi     lddiy
        LDRPI   ixstart, defr, 8
lddiy:  LDRPI   iyi, defr, 8
lddhl:  LDRP    hlmp, defr, 8

lxehl:  movs    lr, arvpref, lsl #24
        beq     ldehl
        bmi     ldeiy
        LDRPI   ixstart, defr, 0
ldeiy:  LDRPI   iyi, defr, 0
ldehl:  LDRP    hlmp, defr, 0

lxhhl:  movs    lr, arvpref, lsl #24
        beq     ldhhl
        bmi     ldhiy
        LDRPI   ixstart, hlmp, 8
ldhiy:  LDRPI   iyi, hlmp, 8
ldhhl:  LDRP    hlmp, hlmp, 8

lxlhl:  movs    lr, arvpref, lsl #24
        beq     ldlhl
        bmi     ldliy
        LDRPI   ixstart, hlmp, 0
ldliy:  LDRPI   iyi, hlmp, 0
ldlhl:  LDRP    hlmp, hlmp, 0

lxahl:  movs    lr, arvpref, lsl #24
        beq     ldahl
        bmi     ldaiy
        LDRPI   ixstart, arvpref, 8
ldaiy:  LDRPI   iyi, arvpref, 8
ldahl:  LDRP    hlmp, arvpref, 8

ldade:  LDRP    defr, arvpref, 8
ldabc:  LDRP    bcfb, arvpref, 8

ldxxb:  movs    lr, arvpref, lsl #24
        beq     ldhlb
        bmi     ldiyb
        LDPRI   ixstart, bcfb, 8
ldiyb:  LDPRI   iyi, bcfb, 8
ldhlb:  LDPR    hlmp, bcfb, 8

ldxxc:  movs    lr, arvpref, lsl #24
        beq     ldhlc
        bmi     ldiyc
        LDPRI   ixstart, bcfb, 0
ldiyc:  LDPRI   iyi, bcfb, 0
ldhlc:  LDPR    hlmp, bcfb, 0

ldxxd:  movs    lr, arvpref, lsl #24
        beq     ldhld
        bmi     ldiyd
        LDPRI   ixstart, defr, 8
ldiyd:  LDPRI   iyi, defr, 8
ldhld:  LDPR    hlmp, defr, 8

ldxxe:  movs    lr, arvpref, lsl #24
        beq     ldhle
        bmi     ldiye
        LDPRI   ixstart, defr, 0
ldiye:  LDPRI   iyi, defr, 0
ldhle:  LDPR    hlmp, defr, 0

ldxxh:  movs    lr, arvpref, lsl #24
        beq     ldhlh
        bmi     ldiyh
        LDPRI   ixstart, hlmp, 8
ldiyh:  LDPRI   iyi, hlmp, 8
ldhlh:  LDPR    hlmp, hlmp, 8

ldxxl:  movs    lr, arvpref, lsl #24
        beq     ldhll
        bmi     ldiyl
        LDPRI   ixstart, hlmp, 0
ldiyl:  LDPRI   iyi, hlmp, 0
ldhll:  LDPR    hlmp, hlmp, 0

ldxxa:  movs    lr, arvpref, lsl #24
        beq     ldhla
        bmi     ldiya
        LDPRI   ixstart, arvpref, 8
ldiya:  LDPRI   iyi, arvpref, 8
ldhla:  LDPR    hlmp, arvpref, 8

incbc:  INCW    bcfb
incde:  INCW    defr
incsp:  INCW    defr

inchlx: movs    lr, arvpref, lsl #24
        beq     inchl
        bmi     incyhl
        INCW    ixstart
incyhl: INCW    iyi
inchl:  INCW    hlmp

decbc:  DECW    bcfb
decde:  DECW    defr
decsp:  DECW    defr

dechlx: movs    lr, arvpref, lsl #24
        beq     dechl
        bmi     decyhl
        DECW    ixstart
decyhl: DECW    iyi
dechl:  DECW    hlmp

pushbc: PUS     bcfb
        PREFIX0

pushde: PUS     defr
        PREFIX0

pushxx: movs    lr, arvpref, lsl #24
        beq     pushhl
        bmi     pushiy
        PUS     ixstart
        PREFIX0
pushiy: PUS     iyi
        PREFIX0
pushhl: PUS     hlmp
        PREFIX0

popbc:  POPP    bcfb
        PREFIX0

popde:  POPP    defr
        PREFIX0

popxx:  movs    lr, arvpref, lsl #24
        beq     pophl
        bmi     popiy
        POPP    ixstart
        PREFIX0
popiy:  POPP    iyi
        PREFIX0
pophl:  POPP    hlmp
        PREFIX0

exspxx: movs    lr, arvpref, lsl #24
        beq     exsphl
        bmi     exspiy
        EXSPI   ixstart
        PREFIX0
exspiy: EXSPI   iyi
        PREFIX0
exsphl: EXSPI   hlmp
        PREFIX0

exdehl: TIME    4
        mov     lr, hlmp
        pkhbt   hlmp, hlmp, defr
        pkhbt   defr, defr, lr
        PREFIX0

callpo: tst     spfa, #0x00000100
        beq     over1
        ldr     r11, c9669
        eor     lr, defr, defr, lsr #4
        tst     r11, r11, lsl lr
        bmi     callnn
        TIME    10
        add     pcff, #0x00020000
        PREFIX0
over1:  eor     lr, spfa, defr
        eor     r11, bcfb, defr
        and     lr, r11
        tst     lr, #0x80
        CALLC

callpe: tst     spfa, #0x00000100
        beq     over2
        ldr     r11, c9669
        eor     lr, defr, defr, lsr #4
        tst     r11, r11, lsl lr
        bpl     callnn
        TIME    10
        add     pcff, #0x00020000
        PREFIX0
over2:  eor     lr, spfa, defr
        eor     r11, bcfb, defr
        and     lr, r11
        tst     lr, #0x80
        CALLCI

retpo:  tst     spfa, #0x00000100
        beq     over3
        ldr     r11, c9669
        eor     lr, defr, defr, lsr #4
        tst     r11, r11, lsl lr
        bmi     ret11
        TIME    5
        PREFIX0
over3:  eor     lr, spfa, defr
        eor     r11, bcfb, defr
        and     lr, r11
        tst     lr, #0x80
        RETC

retpe:  tst     spfa, #0x00000100
        beq     over4
        ldr     r11, c9669
        eor     lr, defr, defr, lsr #4
        tst     r11, r11, lsl lr
        bpl     ret11
        TIME    5
        PREFIX0
over4:  eor     lr, spfa, defr
        eor     r11, bcfb, defr
        and     lr, r11
        tst     lr, #0x80
        RETCI

oped:   mov     lr, #0x00010000
        uadd8   arvpref, arvpref, lr
        ldrb    lr, [mem, pcff, lsr #16]
        add     pcff, #0x00010000
        ldr     pc, [pc, lr, lsl #2]
c9669:  .word   0x96690000
        .word   nop8          @ 00 NOP8
        .word   nop8          @ 01 NOP8
        .word   nop8          @ 02 NOP8
        .word   nop8          @ 03 NOP8
        .word   nop8          @ 04 NOP8
        .word   nop8          @ 05 NOP8
        .word   nop8          @ 06 NOP8
        .word   nop8          @ 07 NOP8
        .word   nop8          @ 08 NOP8
        .word   nop8          @ 09 NOP8
        .word   nop8          @ 0a NOP8
        .word   nop8          @ 0b NOP8
        .word   nop8          @ 0c NOP8
        .word   nop8          @ 0d NOP8
        .word   nop8          @ 0e NOP8
        .word   nop8          @ 0f NOP8
        .word   nop8          @ 10 NOP8
        .word   nop8          @ 11 NOP8
        .word   nop8          @ 12 NOP8
        .word   nop8          @ 13 NOP8
        .word   nop8          @ 14 NOP8
        .word   nop8          @ 15 NOP8
        .word   nop8          @ 16 NOP8
        .word   nop8          @ 17 NOP8
        .word   nop8          @ 18 NOP8
        .word   nop8          @ 19 NOP8
        .word   nop8          @ 1a NOP8
        .word   nop8          @ 1b NOP8
        .word   nop8          @ 1c NOP8
        .word   nop8          @ 1d NOP8
        .word   nop8          @ 1e NOP8
        .word   nop8          @ 1f NOP8
        .word   nop8          @ 20 NOP8
        .word   nop8          @ 21 NOP8
        .word   nop8          @ 22 NOP8
        .word   nop8          @ 23 NOP8
        .word   nop8          @ 24 NOP8
        .word   nop8          @ 25 NOP8
        .word   nop8          @ 26 NOP8
        .word   nop8          @ 27 NOP8
        .word   nop8          @ 28 NOP8
        .word   nop8          @ 29 NOP8
        .word   nop8          @ 2a NOP8
        .word   nop8          @ 2b NOP8
        .word   nop8          @ 2c NOP8
        .word   nop8          @ 2d NOP8
        .word   nop8          @ 2e NOP8
        .word   nop8          @ 2f NOP8
        .word   nop8          @ 30 NOP8
        .word   nop8          @ 31 NOP8
        .word   nop8          @ 32 NOP8
        .word   nop8          @ 33 NOP8
        .word   nop8          @ 34 NOP8
        .word   nop8          @ 35 NOP8
        .word   nop8          @ 36 NOP8
        .word   nop8          @ 37 NOP8
        .word   nop8          @ 38 NOP8
        .word   nop8          @ 39 NOP8
        .word   nop8          @ 3a NOP8
        .word   nop8          @ 3b NOP8
        .word   nop8          @ 3c NOP8
        .word   nop8          @ 3d NOP8
        .word   nop8          @ 3e NOP8
        .word   nop8          @ 3f NOP8
        .word   nop8          @ 40 IN B,(C)
        .word   nop8          @ 41 OUT (C),B
        .word   nop8          @ 42 SBC HL,BC
        .word   ldpnnbc       @ 43 LD (NN),BC
        .word   nop8          @ 44 NEG
        .word   nop8          @ 45 RETN
        .word   nop8          @ 46 IM 0
        .word   nop8          @ 47 LD I,A
        .word   nop8          @ 48 IN C,(C)
        .word   nop8          @ 49 OUT (C),C
        .word   adchlbc       @ 4a ADC HL,BC
        .word   ldbcpnn       @ 4b LD BC,(NN)
        .word   nop8          @ 4c NEG
        .word   nop8          @ 4d RETI
        .word   nop8          @ 4e IM 0
        .word   nop8          @ 4f LD R,A
        .word   nop8          @ 50 IN D,(C)
        .word   nop8          @ 51 OUT (C),D
        .word   nop8          @ 52 SBC HL,DE
        .word   ldpnnde       @ 53 LD (NN),DE
        .word   nop8          @ 54 NEG
        .word   nop8          @ 55 RETN
        .word   nop8          @ 56 IM 1
        .word   nop8          @ 57 LD A,I
        .word   nop8          @ 58 IN E,(C)
        .word   nop8          @ 59 OUT (C),E
        .word   adchlde       @ 5a ADC HL,DE
        .word   lddepnn       @ 5b LD DE,(NN)
        .word   nop8          @ 5c NEG
        .word   nop8          @ 5d RETI
        .word   nop8          @ 5e IM 2
        .word   nop8          @ 5f LD A,R
        .word   nop8          @ 60 IN H,(C)
        .word   nop8          @ 61 OUT (C),H
        .word   nop8          @ 62 SBC HL,HL
        .word   ldpnnxe       @ 63 LD (NN),HL
        .word   nop8          @ 64 NEG
        .word   nop8          @ 65 RETN
        .word   nop8          @ 66 IM 0
        .word   nop8          @ 67 RRD
        .word   nop8          @ 68 IN L,(C)
        .word   nop8          @ 69 OUT (C),L
        .word   adchlhl       @ 6a ADC HL,HL
        .word   ldxepnn       @ 6b LD HL,(NN)
        .word   nop8          @ 6c NEG
        .word   nop8          @ 6d RETI
        .word   nop8          @ 6e IM 0
        .word   nop8          @ 6f RLD
        .word   nop8          @ 70 IN X,(C)
        .word   nop8          @ 71 OUT (C),X
        .word   nop8          @ 72 SBC HL,SP
        .word   ldpnnsp       @ 73 LD (NN),SP
        .word   nop8          @ 74 NEG
        .word   nop8          @ 75 RETN
        .word   nop8          @ 76 IM 1
        .word   nop8          @ 77 NOP
        .word   nop8          @ 78 IN A,(C)
        .word   nop8          @ 79 OUT (C),A
        .word   adchlsp       @ 7a ADC HL,SP
        .word   ldsppnn       @ 7b LD SP,(NN)
        .word   nop8          @ 7c NEG
        .word   nop8          @ 7d RETI
        .word   nop8          @ 7e IM 2
        .word   nop8          @ 7f NOP8
        .word   nop8          @ 80 NOP8
        .word   nop8          @ 81 NOP8
        .word   nop8          @ 82 NOP8
        .word   nop8          @ 83 NOP8
        .word   nop8          @ 84 NOP8
        .word   nop8          @ 85 NOP8
        .word   nop8          @ 86 NOP8
        .word   nop8          @ 87 NOP8
        .word   nop8          @ 88 NOP8
        .word   nop8          @ 89 NOP8
        .word   nop8          @ 8a NOP8
        .word   nop8          @ 8b NOP8
        .word   nop8          @ 8c NOP8
        .word   nop8          @ 8d NOP8
        .word   nop8          @ 8e NOP8
        .word   nop8          @ 8f NOP8
        .word   nop8          @ 90 NOP8
        .word   nop8          @ 91 NOP8
        .word   nop8          @ 92 NOP8
        .word   nop8          @ 93 NOP8
        .word   nop8          @ 94 NOP8
        .word   nop8          @ 95 NOP8
        .word   nop8          @ 96 NOP8
        .word   nop8          @ 97 NOP8
        .word   nop8          @ 98 NOP8
        .word   nop8          @ 99 NOP8
        .word   nop8          @ 9a NOP8
        .word   nop8          @ 9b NOP8
        .word   nop8          @ 9c NOP8
        .word   nop8          @ 9d NOP8
        .word   nop8          @ 9e NOP8
        .word   nop8          @ 9f NOP8
        .word   nop8          @ a0 LDI
        .word   nop8          @ a1 CPI
        .word   nop8          @ a2 INI
        .word   nop8          @ a3 OUTI
        .word   nop8          @ a4 NOP8
        .word   nop8          @ a5 NOP8
        .word   nop8          @ a6 NOP8
        .word   nop8          @ a7 NOP8
        .word   ldd           @ a8 LDD
        .word   nop8          @ a9 CPD
        .word   nop8          @ aa IND
        .word   nop8          @ ab OUTD
        .word   nop8          @ ac NOP8
        .word   nop8          @ ad NOP8
        .word   nop8          @ ae NOP8
        .word   nop8          @ af NOP8
        .word   nop8          @ b0 LDIR
        .word   nop8          @ b1 CPIR
        .word   nop8          @ b2 INIR
        .word   nop8          @ b3 OTIR
        .word   nop8          @ b4 NOP8
        .word   nop8          @ b5 NOP8
        .word   nop8          @ b6 NOP8
        .word   nop8          @ b7 NOP8
        .word   lddr          @ b8 LDDR
        .word   nop8          @ b9 CPDR
        .word   nop8          @ ba INDR
        .word   nop8          @ bb OTDR
        .word   nop8          @ bc NOP8
        .word   nop8          @ bd NOP8
        .word   nop8          @ be NOP8
        .word   nop8          @ bf NOP8
        .word   nop8          @ c0 NOP8
        .word   nop8          @ c1 NOP8
        .word   nop8          @ c2 NOP8
        .word   nop8          @ c3 NOP8
        .word   nop8          @ c4 NOP8
        .word   nop8          @ c5 NOP8
        .word   nop8          @ c6 NOP8
        .word   nop8          @ c7 NOP8
        .word   nop8          @ c8 NOP8
        .word   nop8          @ c9 NOP8
        .word   nop8          @ ca NOP8
        .word   nop8          @ cb NOP8
        .word   nop8          @ cc NOP8
        .word   nop8          @ cd NOP8
        .word   nop8          @ ce NOP8
        .word   nop8          @ cf NOP8
        .word   nop8          @ d0 NOP8
        .word   nop8          @ d1 NOP8
        .word   nop8          @ d2 NOP8
        .word   nop8          @ d3 NOP8
        .word   nop8          @ d4 NOP8
        .word   nop8          @ d5 NOP8
        .word   nop8          @ d6 NOP8
        .word   nop8          @ d7 NOP8
        .word   nop8          @ d8 NOP8
        .word   nop8          @ d9 NOP8
        .word   nop8          @ da NOP8
        .word   nop8          @ db NOP8
        .word   nop8          @ dc NOP8
        .word   nop8          @ dd NOP8
        .word   nop8          @ de NOP8
        .word   nop8          @ df NOP8
        .word   nop8          @ e0 NOP8
        .word   nop8          @ e1 NOP8
        .word   nop8          @ e2 NOP8
        .word   nop8          @ e3 NOP8
        .word   nop8          @ e4 NOP8
        .word   nop8          @ e5 NOP8
        .word   nop8          @ e6 NOP8
        .word   nop8          @ e7 NOP8
        .word   nop8          @ e8 NOP8
        .word   nop8          @ e9 NOP8
        .word   nop8          @ ea NOP8
        .word   nop8          @ eb NOP8
        .word   nop8          @ ec NOP8
        .word   nop8          @ ed NOP8
        .word   nop8          @ ee NOP8
        .word   nop8          @ ef NOP8
        .word   nop8          @ f0 NOP8
        .word   nop8          @ f1 NOP8
        .word   nop8          @ f2 NOP8
        .word   nop8          @ f3 NOP8
        .word   nop8          @ f4 NOP8
        .word   nop8          @ f5 NOP8
        .word   nop8          @ f6 NOP8
        .word   nop8          @ f7 NOP8
        .word   nop8          @ f8 NOP8
        .word   nop8          @ f9 NOP8
        .word   nop8          @ fa NOP8
        .word   nop8          @ fb NOP8
        .word   nop8          @ fc NOP8
        .word   nop8          @ fd NOP8
        .word   nop8          @ fe NOP8
        .word   nop8          @ ff NOP8

nop8:   TIME    8
        PREFIX0

adchlbc:ADCHLRR bcfb
adchlde:ADCHLRR defr
adchlhl:ADCHLRR hlmp
adchlsp:ADCHLRR spfa

ldd:    TIME    16
        ldrb    lr, [mem, hlmp, lsr #16]
        strb    lr, [mem, defr, lsr #16]
        mov     r11, #0x00010000
        sub     hlmp, r11
        sub     defr, r11
        sub     bcfb, r11
        movs    r10, defr, lsl #24
        pkhtbne defr, defr, r11, asr #16
        add     lr, arvpref, lsr #24
        and     lr, #0b00001010
        add     lr, lr, lsl #4
        eor     lr, pcff
        and     lr, #40
        eor     pcff, lr
        pkhtb   spfa, spfa, lr, asr #8
        movs    lr, bcfb, lsr #16
        eorne   spfa, #0x00000080
        pkhbt   bcfb, spfa, lr, lsl #16
        PREFIX0

lddr:   TIME    16
        ldrb    lr, [mem, hlmp, lsr #16]
        strb    lr, [mem, defr, lsr #16]
        mov     r11, #0x00010000
        sub     hlmp, r11
        sub     defr, r11
        sub     bcfb, r11
        movs    r10, defr, lsl #24
        pkhtbne defr, defr, r11, asr #16
        add     lr, arvpref, lsr #24
        and     lr, #0b00001010
        add     lr, lr, lsl #4
        eor     lr, pcff
        and     lr, #40
        eor     pcff, lr
        pkhtb   spfa, spfa, lr, asr #8
        movs    lr, bcfb, lsr #16
        beq     lddr2
        eor     spfa, #0x00000080
        sub     pcff, #0x00010000
        pkhtb   hlmp, hlmp, pcff, asr #16
        sub     pcff, #0x00010000
        TIME    5
lddr2:  pkhbt   bcfb, spfa, lr, lsl #16
        PREFIX0

opcb:   movs    lr, arvpref, lsl #25
        bne     opxdcb
        mov     lr, #0x00010000
        uadd8   arvpref, arvpref, lr
        ldrb    lr, [mem, pcff, lsr #16]
        add     pcff, #0x00010000
        ldr     pc, [pc, lr, lsl #2]
        .word   0             @ relleno
        .word   nop8          @ 00 RLC B
        .word   nop8          @ 01 RLC C
        .word   nop8          @ 02 RLC D
        .word   nop8          @ 03 RLC E
        .word   nop8          @ 04 RLC H
        .word   nop8          @ 05 RLC L
        .word   nop8          @ 06 RLC (HL)
        .word   nop8          @ 07 RLC A
        .word   nop8          @ 08 RRC B
        .word   nop8          @ 09 RRC C
        .word   nop8          @ 0a RRC D
        .word   nop8          @ 0b RRC E
        .word   nop8          @ 0c RRC H
        .word   nop8          @ 0d RRC L
        .word   nop8          @ 0e RRC (HL)
        .word   nop8          @ 0f RRC A
        .word   rl_b          @ 10 RL B
        .word   rl_c          @ 11 RL C
        .word   rl_d          @ 12 RL D
        .word   rl_e          @ 13 RL E
        .word   rl_h          @ 14 RL H
        .word   rl_l          @ 15 RL L
        .word   rl_hl         @ 16 RL (HL)
        .word   rl_a          @ 17 RL A
        .word   rr_b          @ 18 RR B
        .word   rr_c          @ 19 RR C
        .word   rr_d          @ 1a RR D
        .word   rr_e          @ 1b RR E
        .word   rr_h          @ 1c RR H
        .word   rr_l          @ 1d RR L
        .word   rr_hl         @ 1e RR (HL)
        .word   rr_b          @ 1f RR A
        .word   nop8          @ 20 SLA B
        .word   nop8          @ 21 SLA C
        .word   nop8          @ 22 SLA D
        .word   nop8          @ 23 SLA E
        .word   nop8          @ 24 SLA H
        .word   nop8          @ 25 SLA L
        .word   nop8          @ 26 SLA (HL)
        .word   nop8          @ 27 SLA A
        .word   nop8          @ 28 SRA B
        .word   nop8          @ 29 SRA C
        .word   nop8          @ 2a SRA D
        .word   nop8          @ 2b SRA E
        .word   nop8          @ 2c SRA H
        .word   nop8          @ 2d SRA L
        .word   nop8          @ 2e SRA (HL)
        .word   nop8          @ 2f SRA A
        .word   sll_b         @ 30 SLL B
        .word   sll_c         @ 31 SLL C
        .word   sll_d         @ 32 SLL D
        .word   sll_e         @ 33 SLL E
        .word   sll_h         @ 34 SLL H
        .word   sll_l         @ 35 SLL L
        .word   sll_hl        @ 36 SLL (HL)
        .word   sll_a         @ 37 SLL A
        .word   srl_b         @ 38 SRL B
        .word   srl_c         @ 39 SRL C
        .word   srl_d         @ 3a SRL D
        .word   srl_e         @ 3b SRL E
        .word   srl_h         @ 3c SRL H
        .word   srl_l         @ 3d SRL L
        .word   srl_hl        @ 3e SRL (HL)
        .word   srl_a         @ 3f SRL A
        .word   nop8          @ 40 BIT 0,B
        .word   nop8          @ 41 BIT 0,C
        .word   nop8          @ 42 BIT 0,D
        .word   nop8          @ 43 BIT 0,E
        .word   nop8          @ 44 BIT 0,H
        .word   nop8          @ 45 BIT 0,L
        .word   nop8          @ 46 BIT 0,(HL)
        .word   nop8          @ 47 BIT 0,A
        .word   nop8          @ 48 BIT 1,B
        .word   nop8          @ 49 BIT 1,C
        .word   nop8          @ 4a BIT 1,D
        .word   nop8          @ 4b BIT 1,E
        .word   nop8          @ 4c BIT 1,H
        .word   nop8          @ 4d BIT 1,L
        .word   nop8          @ 4e BIT 1,(HL)
        .word   nop8          @ 4f BIT 1,A
        .word   nop8          @ 50 BIT 2,B
        .word   nop8          @ 51 BIT 2,C
        .word   nop8          @ 52 BIT 2,D
        .word   nop8          @ 53 BIT 2,E
        .word   nop8          @ 54 BIT 2,H
        .word   nop8          @ 55 BIT 2,L
        .word   nop8          @ 56 BIT 2,(HL)
        .word   nop8          @ 57 BIT 2,A
        .word   nop8          @ 58 BIT 3,B
        .word   nop8          @ 59 BIT 3,C
        .word   nop8          @ 5a BIT 3,D
        .word   nop8          @ 5b BIT 3,E
        .word   nop8          @ 5c BIT 3,H
        .word   nop8          @ 5d BIT 3,L
        .word   nop8          @ 5e BIT 3,(HL)
        .word   nop8          @ 5f BIT 3,A
        .word   nop8          @ 60 BIT 4,B
        .word   nop8          @ 61 BIT 4,C
        .word   nop8          @ 62 BIT 4,D
        .word   nop8          @ 63 BIT 4,E
        .word   nop8          @ 64 BIT 4,H
        .word   nop8          @ 65 BIT 4,L
        .word   nop8          @ 66 BIT 4,(HL)
        .word   nop8          @ 67 BIT 4,A
        .word   nop8          @ 68 BIT 5,B
        .word   nop8          @ 69 BIT 5,C
        .word   nop8          @ 6a BIT 5,D
        .word   nop8          @ 6b BIT 5,E
        .word   nop8          @ 6c BIT 5,H
        .word   nop8          @ 6d BIT 5,L
        .word   nop8          @ 6e BIT 5,(HL)
        .word   nop8          @ 6f BIT 5,A
        .word   nop8          @ 70 BIT 6,B
        .word   nop8          @ 71 BIT 6,C
        .word   nop8          @ 72 BIT 6,D
        .word   nop8          @ 73 BIT 6,E
        .word   nop8          @ 74 BIT 6,H
        .word   nop8          @ 75 BIT 6,L
        .word   nop8          @ 76 BIT 6,(HL)
        .word   nop8          @ 77 BIT 6,A
        .word   nop8          @ 78 BIT 7,B
        .word   nop8          @ 79 BIT 7,C
        .word   nop8          @ 7a BIT 7,D
        .word   nop8          @ 7b BIT 7,E
        .word   nop8          @ 7c BIT 7,H
        .word   nop8          @ 7d BIT 7,L
        .word   nop8          @ 7e BIT 7,(HL)
        .word   nop8          @ 7f BIT 7,A
        .word   nop8          @ 80 RES 0,B
        .word   nop8          @ 81 RES 0,C
        .word   nop8          @ 82 RES 0,D
        .word   nop8          @ 83 RES 0,E
        .word   nop8          @ 84 RES 0,H
        .word   nop8          @ 85 RES 0,L
        .word   nop8          @ 86 RES 0,(HL)
        .word   nop8          @ 87 RES 0,A
        .word   nop8          @ 88 RES 1,B
        .word   nop8          @ 89 RES 1,C
        .word   nop8          @ 8a RES 1,D
        .word   nop8          @ 8b RES 1,E
        .word   nop8          @ 8c RES 1,H
        .word   nop8          @ 8d RES 1,L
        .word   nop8          @ 8e RES 1,(HL)
        .word   nop8          @ 8f RES 1,A
        .word   nop8          @ 90 RES 2,B
        .word   nop8          @ 91 RES 2,C
        .word   nop8          @ 92 RES 2,D
        .word   nop8          @ 93 RES 2,E
        .word   nop8          @ 94 RES 2,H
        .word   nop8          @ 95 RES 2,L
        .word   nop8          @ 96 RES 2,(HL)
        .word   nop8          @ 97 RES 2,A
        .word   nop8          @ 98 RES 3,B
        .word   nop8          @ 99 RES 3,C
        .word   nop8          @ 9a RES 3,D
        .word   nop8          @ 9b RES 3,E
        .word   nop8          @ 9c RES 3,H
        .word   nop8          @ 9d RES 3,L
        .word   nop8          @ 9e RES 3,(HL)
        .word   nop8          @ 9f RES 3,A
        .word   nop8          @ a0 RES 4,B
        .word   nop8          @ a1 RES 4,C
        .word   nop8          @ a2 RES 4,D
        .word   nop8          @ a3 RES 4,E
        .word   nop8          @ a4 RES 4,H
        .word   nop8          @ a5 RES 4,L
        .word   nop8          @ a6 RES 4,(HL)
        .word   nop8          @ a7 RES 4,A
        .word   nop8          @ a8 RES 5,B
        .word   nop8          @ a9 RES 5,C
        .word   nop8          @ aa RES 5,D
        .word   nop8          @ ab RES 5,E
        .word   nop8          @ ac RES 5,H
        .word   nop8          @ ad RES 5,L
        .word   nop8          @ ae RES 5,(HL)
        .word   nop8          @ af RES 5,A
        .word   nop8          @ b0 RES 6,B
        .word   nop8          @ b1 RES 6,C
        .word   nop8          @ b2 RES 6,D
        .word   nop8          @ b3 RES 6,E
        .word   nop8          @ b4 RES 6,H
        .word   nop8          @ b5 RES 6,L
        .word   nop8          @ b6 RES 6,(HL)
        .word   nop8          @ b7 RES 6,A
        .word   nop8          @ b8 RES 7,B
        .word   nop8          @ b9 RES 7,C
        .word   nop8          @ ba RES 7,D
        .word   nop8          @ bb RES 7,E
        .word   nop8          @ bc RES 7,H
        .word   nop8          @ bd RES 7,L
        .word   nop8          @ be RES 7,(HL)
        .word   nop8          @ bf RES 7,A
        .word   nop8          @ c0 SET 0,B
        .word   nop8          @ c1 SET 0,C
        .word   nop8          @ c2 SET 0,D
        .word   nop8          @ c3 SET 0,E
        .word   nop8          @ c4 SET 0,H
        .word   nop8          @ c5 SET 0,L
        .word   nop8          @ c6 SET 0,(HL)
        .word   nop8          @ c7 SET 0,A
        .word   nop8          @ c8 SET 1,B
        .word   nop8          @ c9 SET 1,C
        .word   nop8          @ ca SET 1,D
        .word   nop8          @ cb SET 1,E
        .word   nop8          @ cc SET 1,H
        .word   nop8          @ cd SET 1,L
        .word   nop8          @ ce SET 1,(HL)
        .word   nop8          @ cf SET 1,A
        .word   nop8          @ d0 SET 2,B
        .word   nop8          @ d1 SET 2,C
        .word   nop8          @ d2 SET 2,D
        .word   nop8          @ d3 SET 2,E
        .word   nop8          @ d4 SET 2,H
        .word   nop8          @ d5 SET 2,L
        .word   nop8          @ d6 SET 2,(HL)
        .word   nop8          @ d7 SET 2,A
        .word   nop8          @ d8 SET 3,B
        .word   nop8          @ d9 SET 3,C
        .word   nop8          @ da SET 3,D
        .word   nop8          @ db SET 3,E
        .word   nop8          @ dc SET 3,H
        .word   nop8          @ dd SET 3,L
        .word   nop8          @ de SET 3,(HL)
        .word   nop8          @ df SET 3,A
        .word   nop8          @ e0 SET 4,B
        .word   nop8          @ e1 SET 4,C
        .word   nop8          @ e2 SET 4,D
        .word   nop8          @ e3 SET 4,E
        .word   nop8          @ e4 SET 4,H
        .word   nop8          @ e5 SET 4,L
        .word   nop8          @ e6 SET 4,(HL)
        .word   nop8          @ e7 SET 4,A
        .word   nop8          @ e8 SET 5,B
        .word   nop8          @ e9 SET 5,C
        .word   nop8          @ ea SET 5,D
        .word   nop8          @ eb SET 5,E
        .word   nop8          @ ec SET 5,H
        .word   nop8          @ ed SET 5,L
        .word   nop8          @ ee SET 5,(HL)
        .word   nop8          @ ef SET 5,A
        .word   nop8          @ f0 SET 6,B
        .word   nop8          @ f1 SET 6,C
        .word   nop8          @ f2 SET 6,D
        .word   nop8          @ f3 SET 6,E
        .word   nop8          @ f4 SET 6,H
        .word   nop8          @ f5 SET 6,L
        .word   nop8          @ f6 SET 6,(HL)
        .word   nop8          @ f7 SET 6,A
        .word   nop8          @ f8 SET 7,B
        .word   nop8          @ f9 SET 7,C
        .word   nop8          @ fa SET 7,D
        .word   nop8          @ fb SET 7,E
        .word   nop8          @ fc SET 7,H
        .word   nop8          @ fd SET 7,L
        .word   nop8          @ fe SET 7,(HL)
        .word   nop8          @ ff SET 7,A

opxdcb: bmi     opfdcb
        TIME    11
        ldr     lr, [mem, pcff, lsr #16]
        sxtb    r11, lr
        add     r11, ixstart, lsr #16
        b       contcb
opfdcb: TIME    11
        ldr     lr, [mem, pcff, lsr #16]
        sxtb    r11, lr
        add     r11, iyi, lsr #16
contcb: pkhtb   hlmp, hlmp, r11
        ldrb    r10, [mem, r11]
        uxtb    lr, lr, ror #8
        add     pcff, #0x00020000
        ldr     pc, [pc, lr, lsl #2]
c18003: .word   0x00018003
        .word   nop8          @ 00 LD B,RLC (IX+d) // LD B,RLC (IY+d)
        .word   nop8          @ 01 LD C,RLC (IX+d) // LD C,RLC (IY+d)
        .word   nop8          @ 02 LD D,RLC (IX+d) // LD D,RLC (IY+d)
        .word   nop8          @ 03 LD E,RLC (IX+d) // LD E,RLC (IY+d)
        .word   nop8          @ 04 LD H,RLC (IX+d) // LD H,RLC (IY+d)
        .word   nop8          @ 05 LD L,RLC (IX+d) // LD L,RLC (IY+d)
        .word   nop8          @ 06 RLC (IX+d) // RLC (IY+d)
        .word   nop8          @ 07 LD A,RLC (IX+d) // LD A,RLC (IY+d)
        .word   nop8          @ 08 LD B,RRC (IX+d) // LD B,RRC (IY+d)
        .word   nop8          @ 09 LD C,RRC (IX+d) // LD C,RRC (IY+d)
        .word   nop8          @ 0a LD D,RRC (IX+d) // LD D,RRC (IY+d)
        .word   nop8          @ 0b LD E,RRC (IX+d) // LD E,RRC (IY+d)
        .word   nop8          @ 0c LD H,RRC (IX+d) // LD H,RRC (IY+d)
        .word   nop8          @ 0d LD L,RRC (IX+d) // LD L,RRC (IY+d)
        .word   nop8          @ 0e RRC (IX+d) // RRC (IY+d)
        .word   nop8          @ 0f LD A,RRC (IX+d) // LD A,RRC (IY+d)
        .word   nop8          @ 10 LD B,RL (IX+d) // LD B,RL (IY+d)
        .word   nop8          @ 11 LD C,RL (IX+d) // LD C,RL (IY+d)
        .word   nop8          @ 12 LD D,RL (IX+d) // LD D,RL (IY+d)
        .word   nop8          @ 13 LD E,RL (IX+d) // LD E,RL (IY+d)
        .word   nop8          @ 14 LD H,RL (IX+d) // LD H,RL (IY+d)
        .word   nop8          @ 15 LD L,RL (IX+d) // LD L,RL (IY+d)
        .word   nop8          @ 16 RL (IX+d) // RL (IY+d)
        .word   nop8          @ 17 LD A,RL (IX+d) // LD A,RL (IY+d)
        .word   nop8          @ 18 LD B,RR (IX+d) // LD B,RR (IY+d)
        .word   nop8          @ 19 LD C,RR (IX+d) // LD C,RR (IY+d)
        .word   nop8          @ 1a LD D,RR (IX+d) // LD D,RR (IY+d)
        .word   nop8          @ 1b LD E,RR (IX+d) // LD E,RR (IY+d)
        .word   nop8          @ 1c LD H,RR (IX+d) // LD H,RR (IY+d)
        .word   nop8          @ 1d LD L,RR (IX+d) // LD L,RR (IY+d)
        .word   nop8          @ 1e RR (IX+d) // RR (IY+d)
        .word   nop8          @ 1f LD A,RR (IX+d) // LD A,RR (IY+d)
        .word   nop8          @ 20 LD B,SLA (IX+d) // LD B,SLA (IY+d)
        .word   nop8          @ 21 LD C,SLA (IX+d) // LD C,SLA (IY+d)
        .word   nop8          @ 22 LD D,SLA (IX+d) // LD D,SLA (IY+d)
        .word   nop8          @ 23 LD E,SLA (IX+d) // LD E,SLA (IY+d)
        .word   nop8          @ 24 LD H,SLA (IX+d) // LD H,SLA (IY+d)
        .word   nop8          @ 25 LD L,SLA (IX+d) // LD L,SLA (IY+d)
        .word   nop8          @ 26 SLA (IX+d) // SLA (IY+d)
        .word   nop8          @ 27 LD A,SLA (IX+d) // LD A,SLA (IY+d)
        .word   nop8          @ 28 LD B,SRA (IX+d) // LD B,SRA (IY+d)
        .word   nop8          @ 29 LD C,SRA (IX+d) // LD C,SRA (IY+d)
        .word   nop8          @ 2a LD D,SRA (IX+d) // LD D,SRA (IY+d)
        .word   nop8          @ 2b LD E,SRA (IX+d) // LD E,SRA (IY+d)
        .word   nop8          @ 2c LD H,SRA (IX+d) // LD H,SRA (IY+d)
        .word   nop8          @ 2d LD L,SRA (IX+d) // LD L,SRA (IY+d)
        .word   nop8          @ 2e SRA (IX+d) // SRA (IY+d)
        .word   nop8          @ 2f LD A,SRA (IX+d) // LD A,SRA (IY+d)
        .word   nop8          @ 30 LD B,SLL (IX+d) // LD B,SLL (IY+d)
        .word   nop8          @ 31 LD C,SLL (IX+d) // LD C,SLL (IY+d)
        .word   nop8          @ 32 LD D,SLL (IX+d) // LD D,SLL (IY+d)
        .word   nop8          @ 33 LD E,SLL (IX+d) // LD E,SLL (IY+d)
        .word   nop8          @ 34 LD H,SLL (IX+d) // LD H,SLL (IY+d)
        .word   nop8          @ 35 LD L,SLL (IX+d) // LD L,SLL (IY+d)
        .word   nop8          @ 36 SLL (IX+d) // SLL (IY+d)
        .word   nop8          @ 37 LD A,SLL (IX+d) // LD A,SLL (IY+d)
        .word   nop8          @ 38 LD B,SRL (IX+d) // LD B,SRL (IY+d)
        .word   nop8          @ 39 LD C,SRL (IX+d) // LD C,SRL (IY+d)
        .word   nop8          @ 3a LD D,SRL (IX+d) // LD D,SRL (IY+d)
        .word   nop8          @ 3b LD E,SRL (IX+d) // LD E,SRL (IY+d)
        .word   nop8          @ 3c LD H,SRL (IX+d) // LD H,SRL (IY+d)
        .word   nop8          @ 3d LD L,SRL (IX+d) // LD L,SRL (IY+d)
        .word   nop8          @ 3e SRL (IX+d) // SRL (IY+d)
        .word   nop8          @ 3f LD A,SRL (IX+d) // LD A,SRL (IY+d)
        .word   biti0         @ 40 BIT 0,(IX+d) // BIT 0,(IY+d)
        .word   biti0         @ 41 BIT 0,(IX+d) // BIT 0,(IY+d)
        .word   biti0         @ 42 BIT 0,(IX+d) // BIT 0,(IY+d)
        .word   biti0         @ 43 BIT 0,(IX+d) // BIT 0,(IY+d)
        .word   biti0         @ 44 BIT 0,(IX+d) // BIT 0,(IY+d)
        .word   biti0         @ 45 BIT 0,(IX+d) // BIT 0,(IY+d)
        .word   biti0         @ 46 BIT 0,(IX+d) // BIT 0,(IY+d)
        .word   biti0         @ 47 BIT 0,(IX+d) // BIT 0,(IY+d)
        .word   biti1         @ 48 BIT 1,(IX+d) // BIT 1,(IY+d)
        .word   biti1         @ 49 BIT 1,(IX+d) // BIT 1,(IY+d)
        .word   biti1         @ 4a BIT 1,(IX+d) // BIT 1,(IY+d)
        .word   biti1         @ 4b BIT 1,(IX+d) // BIT 1,(IY+d)
        .word   biti1         @ 4c BIT 1,(IX+d) // BIT 1,(IY+d)
        .word   biti1         @ 4d BIT 1,(IX+d) // BIT 1,(IY+d)
        .word   biti1         @ 4e BIT 1,(IX+d) // BIT 1,(IY+d)
        .word   biti1         @ 4f BIT 1,(IX+d) // BIT 1,(IY+d)
        .word   biti2         @ 50 BIT 2,(IX+d) // BIT 2,(IY+d)
        .word   biti2         @ 51 BIT 2,(IX+d) // BIT 2,(IY+d)
        .word   biti2         @ 52 BIT 2,(IX+d) // BIT 2,(IY+d)
        .word   biti2         @ 53 BIT 2,(IX+d) // BIT 2,(IY+d)
        .word   biti2         @ 54 BIT 2,(IX+d) // BIT 2,(IY+d)
        .word   biti2         @ 55 BIT 2,(IX+d) // BIT 2,(IY+d)
        .word   biti2         @ 56 BIT 2,(IX+d) // BIT 2,(IY+d)
        .word   biti2         @ 57 BIT 2,(IX+d) // BIT 2,(IY+d)
        .word   biti3         @ 58 BIT 3,(IX+d) // BIT 3,(IY+d)
        .word   biti3         @ 59 BIT 3,(IX+d) // BIT 3,(IY+d)
        .word   biti3         @ 5a BIT 3,(IX+d) // BIT 3,(IY+d)
        .word   biti3         @ 5b BIT 3,(IX+d) // BIT 3,(IY+d)
        .word   biti3         @ 5c BIT 3,(IX+d) // BIT 3,(IY+d)
        .word   biti3         @ 5d BIT 3,(IX+d) // BIT 3,(IY+d)
        .word   biti3         @ 5e BIT 3,(IX+d) // BIT 3,(IY+d)
        .word   biti3         @ 5f BIT 3,(IX+d) // BIT 3,(IY+d)
        .word   biti4         @ 60 BIT 4,(IX+d) // BIT 4,(IY+d)
        .word   biti4         @ 61 BIT 4,(IX+d) // BIT 4,(IY+d)
        .word   biti4         @ 62 BIT 4,(IX+d) // BIT 4,(IY+d)
        .word   biti4         @ 63 BIT 4,(IX+d) // BIT 4,(IY+d)
        .word   biti4         @ 64 BIT 4,(IX+d) // BIT 4,(IY+d)
        .word   biti4         @ 65 BIT 4,(IX+d) // BIT 4,(IY+d)
        .word   biti4         @ 66 BIT 4,(IX+d) // BIT 4,(IY+d)
        .word   biti4         @ 67 BIT 4,(IX+d) // BIT 4,(IY+d)
        .word   biti5         @ 68 BIT 5,(IX+d) // BIT 5,(IY+d)
        .word   biti5         @ 69 BIT 5,(IX+d) // BIT 5,(IY+d)
        .word   biti5         @ 6a BIT 5,(IX+d) // BIT 5,(IY+d)
        .word   biti5         @ 6b BIT 5,(IX+d) // BIT 5,(IY+d)
        .word   biti5         @ 6c BIT 5,(IX+d) // BIT 5,(IY+d)
        .word   biti5         @ 6d BIT 5,(IX+d) // BIT 5,(IY+d)
        .word   biti5         @ 6e BIT 5,(IX+d) // BIT 5,(IY+d)
        .word   biti5         @ 6f BIT 5,(IX+d) // BIT 5,(IY+d)
        .word   biti6         @ 70 BIT 6,(IX+d) // BIT 6,(IY+d)
        .word   biti6         @ 71 BIT 6,(IX+d) // BIT 6,(IY+d)
        .word   biti6         @ 72 BIT 6,(IX+d) // BIT 6,(IY+d)
        .word   biti6         @ 73 BIT 6,(IX+d) // BIT 6,(IY+d)
        .word   biti6         @ 74 BIT 6,(IX+d) // BIT 6,(IY+d)
        .word   biti6         @ 75 BIT 6,(IX+d) // BIT 6,(IY+d)
        .word   biti6         @ 76 BIT 6,(IX+d) // BIT 6,(IY+d)
        .word   biti6         @ 77 BIT 6,(IX+d) // BIT 6,(IY+d)
        .word   biti7         @ 78 BIT 7,(IX+d) // BIT 7,(IY+d)
        .word   biti7         @ 79 BIT 7,(IX+d) // BIT 7,(IY+d)
        .word   biti7         @ 7a BIT 7,(IX+d) // BIT 7,(IY+d)
        .word   biti7         @ 7b BIT 7,(IX+d) // BIT 7,(IY+d)
        .word   biti7         @ 7c BIT 7,(IX+d) // BIT 7,(IY+d)
        .word   biti7         @ 7d BIT 7,(IX+d) // BIT 7,(IY+d)
        .word   biti7         @ 7e BIT 7,(IX+d) // BIT 7,(IY+d)
        .word   biti7         @ 7f BIT 7,(IX+d) // BIT 7,(IY+d)
        .word   nop8          @ 80 LD B,RES 0,(IX+d) // LD B,RES 0,(IY+d)
        .word   nop8          @ 81 LD C,RES 0,(IX+d) // LD C,RES 0,(IY+d)
        .word   nop8          @ 82 LD D,RES 0,(IX+d) // LD D,RES 0,(IY+d)
        .word   nop8          @ 83 LD E,RES 0,(IX+d) // LD E,RES 0,(IY+d)
        .word   nop8          @ 84 LD H,RES 0,(IX+d) // LD H,RES 0,(IY+d)
        .word   nop8          @ 85 LD L,RES 0,(IX+d) // LD L,RES 0,(IY+d)
        .word   nop8          @ 86 RES 0,(IX+d) // RES 0,(IY+d)
        .word   nop8          @ 87 LD A,RES 0,(IX+d) // LD A,RES 0,(IY+d)
        .word   nop8          @ 88 LD B,RES 1,(IX+d) // LD B,RES 1,(IY+d)
        .word   nop8          @ 89 LD C,RES 1,(IX+d) // LD C,RES 1,(IY+d)
        .word   nop8          @ 8a LD D,RES 1,(IX+d) // LD D,RES 1,(IY+d)
        .word   nop8          @ 8b LD E,RES 1,(IX+d) // LD E,RES 1,(IY+d)
        .word   nop8          @ 8c LD H,RES 1,(IX+d) // LD H,RES 1,(IY+d)
        .word   nop8          @ 8d LD L,RES 1,(IX+d) // LD L,RES 1,(IY+d)
        .word   nop8          @ 8e RES 1,(IX+d) // RES 1,(IY+d)
        .word   nop8          @ 8f LD A,RES 1,(IX+d) // LD A,RES 1,(IY+d)
        .word   nop8          @ 90 LD B,RES 2,(IX+d) // LD B,RES 2,(IY+d)
        .word   nop8          @ 91 LD C,RES 2,(IX+d) // LD C,RES 2,(IY+d)
        .word   nop8          @ 92 LD D,RES 2,(IX+d) // LD D,RES 2,(IY+d)
        .word   nop8          @ 93 LD E,RES 2,(IX+d) // LD E,RES 2,(IY+d)
        .word   nop8          @ 94 LD H,RES 2,(IX+d) // LD H,RES 2,(IY+d)
        .word   nop8          @ 95 LD L,RES 2,(IX+d) // LD L,RES 2,(IY+d)
        .word   nop8          @ 96 RES 2,(IX+d) // RES 2,(IY+d)
        .word   nop8          @ 97 LD A,RES 2,(IX+d) // LD A,RES 2,(IY+d)
        .word   nop8          @ 98 LD B,RES 3,(IX+d) // LD B,RES 3,(IY+d)
        .word   nop8          @ 99 LD C,RES 3,(IX+d) // LD C,RES 3,(IY+d)
        .word   nop8          @ 9a LD D,RES 3,(IX+d) // LD D,RES 3,(IY+d)
        .word   nop8          @ 9b LD E,RES 3,(IX+d) // LD E,RES 3,(IY+d)
        .word   nop8          @ 9c LD H,RES 3,(IX+d) // LD H,RES 3,(IY+d)
        .word   nop8          @ 9d LD L,RES 3,(IX+d) // LD L,RES 3,(IY+d)
        .word   nop8          @ 9e RES 3,(IX+d) // RES 3,(IY+d)
        .word   nop8          @ 9f LD A,RES 3,(IX+d) // LD A,RES 3,(IY+d)
        .word   nop8          @ a0 LD B,RES 4,(IX+d) // LD B,RES 4,(IY+d)
        .word   nop8          @ a1 LD C,RES 4,(IX+d) // LD C,RES 4,(IY+d)
        .word   nop8          @ a2 LD D,RES 4,(IX+d) // LD D,RES 4,(IY+d)
        .word   nop8          @ a3 LD E,RES 4,(IX+d) // LD E,RES 4,(IY+d)
        .word   nop8          @ a4 LD H,RES 4,(IX+d) // LD H,RES 4,(IY+d)
        .word   nop8          @ a5 LD L,RES 4,(IX+d) // LD L,RES 4,(IY+d)
        .word   res4xx        @ a6 RES 4,(IX+d) // RES 4,(IY+d)
        .word   nop8          @ a7 LD A,RES 4,(IX+d) // LD A,RES 4,(IY+d)
        .word   nop8          @ a8 LD B,RES 5,(IX+d) // LD B,RES 5,(IY+d)
        .word   nop8          @ a9 LD C,RES 5,(IX+d) // LD C,RES 5,(IY+d)
        .word   nop8          @ aa LD D,RES 5,(IX+d) // LD D,RES 5,(IY+d)
        .word   nop8          @ ab LD E,RES 5,(IX+d) // LD E,RES 5,(IY+d)
        .word   nop8          @ ac LD H,RES 5,(IX+d) // LD H,RES 5,(IY+d)
        .word   nop8          @ ad LD L,RES 5,(IX+d) // LD L,RES 5,(IY+d)
        .word   nop8          @ ae RES 5,(IX+d) // RES 5,(IY+d)
        .word   nop8          @ af LD A,RES 5,(IX+d) // LD A,RES 5,(IY+d)
        .word   nop8          @ b0 LD B,RES 6,(IX+d) // LD B,RES 6,(IY+d)
        .word   nop8          @ b1 LD C,RES 6,(IX+d) // LD C,RES 6,(IY+d)
        .word   nop8          @ b2 LD D,RES 6,(IX+d) // LD D,RES 6,(IY+d)
        .word   nop8          @ b3 LD E,RES 6,(IX+d) // LD E,RES 6,(IY+d)
        .word   nop8          @ b4 LD H,RES 6,(IX+d) // LD H,RES 6,(IY+d)
        .word   nop8          @ b5 LD L,RES 6,(IX+d) // LD L,RES 6,(IY+d)
        .word   nop8          @ b6 RES 6,(IX+d) // RES 6,(IY+d)
        .word   nop8          @ b7 LD A,RES 6,(IX+d) // LD A,RES 6,(IY+d)
        .word   nop8          @ b8 LD B,RES 7,(IX+d) // LD B,RES 7,(IY+d)
        .word   nop8          @ b9 LD C,RES 7,(IX+d) // LD C,RES 7,(IY+d)
        .word   nop8          @ ba LD D,RES 7,(IX+d) // LD D,RES 7,(IY+d)
        .word   nop8          @ bb LD E,RES 7,(IX+d) // LD E,RES 7,(IY+d)
        .word   nop8          @ bc LD H,RES 7,(IX+d) // LD H,RES 7,(IY+d)
        .word   nop8          @ bd LD L,RES 7,(IX+d) // LD L,RES 7,(IY+d)
        .word   nop8          @ be RES 7,(IX+d) // RES 7,(IY+d)
        .word   nop8          @ bf LD A,RES 7,(IX+d) // LD A,RES 7,(IY+d)
        .word   nop8          @ c0 LD B,SET 0,(IX+d) // LD B,SET 0,(IY+d)
        .word   nop8          @ c1 LD C,SET 0,(IX+d) // LD C,SET 0,(IY+d)
        .word   nop8          @ c2 LD D,SET 0,(IX+d) // LD D,SET 0,(IY+d)
        .word   nop8          @ c3 LD E,SET 0,(IX+d) // LD E,SET 0,(IY+d)
        .word   nop8          @ c4 LD H,SET 0,(IX+d) // LD H,SET 0,(IY+d)
        .word   nop8          @ c5 LD L,SET 0,(IX+d) // LD L,SET 0,(IY+d)
        .word   nop8          @ c6 SET 0,(IX+d) // SET 0,(IY+d)
        .word   nop8          @ c7 LD A,SET 0,(IX+d) // LD A,SET 0,(IY+d)
        .word   nop8          @ c8 LD B,SET 1,(IX+d) // LD B,SET 1,(IY+d)
        .word   nop8          @ c9 LD C,SET 1,(IX+d) // LD C,SET 1,(IY+d)
        .word   nop8          @ ca LD D,SET 1,(IX+d) // LD D,SET 1,(IY+d)
        .word   nop8          @ cb LD E,SET 1,(IX+d) // LD E,SET 1,(IY+d)
        .word   nop8          @ cc LD H,SET 1,(IX+d) // LD H,SET 1,(IY+d)
        .word   nop8          @ cd LD L,SET 1,(IX+d) // LD L,SET 1,(IY+d)
        .word   nop8          @ ce SET 1,(IX+d) // SET 1,(IY+d)
        .word   nop8          @ cf LD A,SET 1,(IX+d) // LD A,SET 1,(IY+d)
        .word   nop8          @ d0 LD B,SET 2,(IX+d) // LD B,SET 2,(IY+d)
        .word   nop8          @ d1 LD C,SET 2,(IX+d) // LD C,SET 2,(IY+d)
        .word   nop8          @ d2 LD D,SET 2,(IX+d) // LD D,SET 2,(IY+d)
        .word   nop8          @ d3 LD E,SET 2,(IX+d) // LD E,SET 2,(IY+d)
        .word   nop8          @ d4 LD H,SET 2,(IX+d) // LD H,SET 2,(IY+d)
        .word   nop8          @ d5 LD L,SET 2,(IX+d) // LD L,SET 2,(IY+d)
        .word   nop8          @ d6 SET 2,(IX+d) // SET 2,(IY+d)
        .word   nop8          @ d7 LD A,SET 2,(IX+d) // LD A,SET 2,(IY+d)
        .word   nop8          @ d8 LD B,SET 3,(IX+d) // LD B,SET 3,(IY+d)
        .word   nop8          @ d9 LD C,SET 3,(IX+d) // LD C,SET 3,(IY+d)
        .word   nop8          @ da LD D,SET 3,(IX+d) // LD D,SET 3,(IY+d)
        .word   nop8          @ db LD E,SET 3,(IX+d) // LD E,SET 3,(IY+d)
        .word   nop8          @ dc LD H,SET 3,(IX+d) // LD H,SET 3,(IY+d)
        .word   nop8          @ dd LD L,SET 3,(IX+d) // LD L,SET 3,(IY+d)
        .word   nop8          @ de SET 3,(IX+d) // SET 3,(IY+d)
        .word   nop8          @ df LD A,SET 3,(IX+d) // LD A,SET 3,(IY+d)
        .word   nop8          @ e0 LD B,SET 4,(IX+d) // LD B,SET 4,(IY+d)
        .word   nop8          @ e1 LD C,SET 4,(IX+d) // LD C,SET 4,(IY+d)
        .word   nop8          @ e2 LD D,SET 4,(IX+d) // LD D,SET 4,(IY+d)
        .word   nop8          @ e3 LD E,SET 4,(IX+d) // LD E,SET 4,(IY+d)
        .word   nop8          @ e4 LD H,SET 4,(IX+d) // LD H,SET 4,(IY+d)
        .word   nop8          @ e5 LD L,SET 4,(IX+d) // LD L,SET 4,(IY+d)
        .word   nop8          @ e6 SET 4,(IX+d) // SET 4,(IY+d)
        .word   nop8          @ e7 LD A,SET 4,(IX+d) // LD A,SET 4,(IY+d)
        .word   nop8          @ e8 LD B,SET 5,(IX+d) // LD B,SET 5,(IY+d)
        .word   nop8          @ e9 LD C,SET 5,(IX+d) // LD C,SET 5,(IY+d)
        .word   nop8          @ ea LD D,SET 5,(IX+d) // LD D,SET 5,(IY+d)
        .word   nop8          @ eb LD E,SET 5,(IX+d) // LD E,SET 5,(IY+d)
        .word   nop8          @ ec LD H,SET 5,(IX+d) // LD H,SET 5,(IY+d)
        .word   nop8          @ ed LD L,SET 5,(IX+d) // LD L,SET 5,(IY+d)
        .word   nop8          @ ee SET 5,(IX+d) // SET 5,(IY+d)
        .word   nop8          @ ef LD A,SET 5,(IX+d) // LD A,SET 5,(IY+d)
        .word   nop8          @ f0 LD B,SET 6,(IX+d) // LD B,SET 6,(IY+d)
        .word   nop8          @ f1 LD C,SET 6,(IX+d) // LD C,SET 6,(IY+d)
        .word   nop8          @ f2 LD D,SET 6,(IX+d) // LD D,SET 6,(IY+d)
        .word   nop8          @ f3 LD E,SET 6,(IX+d) // LD E,SET 6,(IY+d)
        .word   nop8          @ f4 LD H,SET 6,(IX+d) // LD H,SET 6,(IY+d)
        .word   nop8          @ f5 LD L,SET 6,(IX+d) // LD L,SET 6,(IY+d)
        .word   nop8          @ f6 SET 6,(IX+d) // SET 6,(IY+d)
        .word   nop8          @ f7 LD A,SET 6,(IX+d) // LD A,SET 6,(IY+d)
        .word   nop8          @ f8 LD B,SET 7,(IX+d) // LD B,SET 7,(IY+d)
        .word   nop8          @ f9 LD C,SET 7,(IX+d) // LD C,SET 7,(IY+d)
        .word   nop8          @ fa LD D,SET 7,(IX+d) // LD D,SET 7,(IY+d)
        .word   nop8          @ fb LD E,SET 7,(IX+d) // LD E,SET 7,(IY+d)
        .word   nop8          @ fc LD H,SET 7,(IX+d) // LD H,SET 7,(IY+d)
        .word   nop8          @ fd LD L,SET 7,(IX+d) // LD L,SET 7,(IY+d)
        .word   nop8          @ fe SET 7,(IX+d) // SET 7,(IY+d)
        .word   nop8          @ ff LD A,SET 7,(IX+d) // LD A,SET 7,(IY+d)

biti0:  BITI    1
biti1:  BITI    2
biti2:  BITI    4
biti3:  BITI    8
biti4:  BITI    16
biti5:  BITI    32
biti6:  BITI    64
biti7:  BITI    128

res4xx: RESXD   0xffffffef

rl_b:   RL      bcfb, 8
        PREFIX0
rl_c:   RL      bcfb, 0
        PREFIX0
rl_d:   RL      defr, 8
        PREFIX0
rl_e:   RL      defr, 0
        PREFIX0
rl_h:   RL      hlmp, 8
        PREFIX0
rl_l:   RL      hlmp, 0
        PREFIX0
rl_hl:  PREFIX0 @ revisar
rl_a:   RL      arvpref, 8
        PREFIX0

rr_b:   RR      bcfb, 8
        PREFIX0
rr_c:   RR      bcfb, 0
        PREFIX0
rr_d:   RR      defr, 8
        PREFIX0
rr_e:   RR      defr, 0
        PREFIX0
rr_h:   RR      hlmp, 8
        PREFIX0
rr_l:   RR      hlmp, 0
        PREFIX0
rr_hl:  PREFIX0 @ revisar
rr_a:   RR      arvpref, 8
        PREFIX0

sll_b:  SLL     bcfb, 8
        PREFIX0
sll_c:  SLL     bcfb, 0
        PREFIX0
sll_d:  SLL     defr, 8
        PREFIX0
sll_e:  SLL     defr, 0
        PREFIX0
sll_h:  SLL     hlmp, 8
        PREFIX0
sll_l:  SLL     hlmp, 0
        PREFIX0
sll_hl: PREFIX0 @ revisar
sll_a:  SLL     arvpref, 8
        PREFIX0

srl_b:  SRL     bcfb, 8
        PREFIX0
srl_c:  SRL     bcfb, 0
        PREFIX0
srl_d:  SRL     defr, 8
        PREFIX0
srl_e:  SRL     defr, 0
        PREFIX0
srl_h:  SRL     hlmp, 8
        PREFIX0
srl_l:  SRL     hlmp, 0
        PREFIX0
srl_hl: PREFIX0 @ revisar
srl_a:  SRL     arvpref, 8
        PREFIX0

rrca:   TIME    4
        mov     lr, arvpref, lsr #24
        add     lr, lr, lr, lsl #8
        mov     r11, lr, lsr #7
        bic     arvpref, #0xff000000
        orr     arvpref, r11, lsl #24
        eor     r11, pcff
        and     r11, #0x00000028
        eor     pcff, r11
        eor     lr, spfa, defr
        and     lr, #0x00000010
        eor     lr, bcfb
        and     lr, #0x0000007f
        eor     bcfb, lr
        PREFIX0

salida: ldrh    lr, [punt, #oendd]
        cmp     lr, pcff, lsr #16
        beq     exec11

        ldrd    r10, [punt, #ocounter]
        ldr     lr, [punt, #ost+4]
        cmp     stlo, r10
        sbcs    lr, lr, r11
        bcc     exec1

exec11:
        movs    lr, arvpref, lsl #24
        bne     exec1

        str     stlo, [punt, #ost]
        str     pcff, [punt, #off]    @ pc | ff
        str     spfa, [punt, #ofa]    @ sp | fa
        str     bcfb, [punt, #ofb]    @ bc | fb
        str     defr, [punt, #ofr]    @ de | fr
        str     hlmp, [punt, #omp]    @ hl | mp
        str     ixstart, [punt, #ostart]  @ ix | start
        str     iyi, [punt, #odummy]  @ iy | i : intr tap

        uxtb    lr, arvpref, ror #8
        add     lr, lr, lsl #13
        ldr     r11, c18003
        and     lr, r11
        str     lr, [punt, #oim]

        and     arvpref, #0xffff80ff
        str     arvpref, [punt, #oprefix] @ ar | r7 halted_3 iff_2 im: prefix
        

        pop     {r4-r12, lr}
        bx      lr

insth:  ldr     r11, [punt, #ost+4]
        add     r11, r11, #1
        str     r11, [punt, #ost+4]
        bx      lr