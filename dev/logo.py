#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
A little helper to develop the LOGO Brainfuck program.
"""

LOGO = """
                   _____ _____ _____ _____
  ________________/     V     V     V     \\
 /                |     |     |     |     |
|  T  H  U  M  B  |  F  |  U  |  C  |  K  |
 \________________|     |     |     |     |
                  |     |     |     |     |
                  |     |     |     |     |
                  |     |     |     |     |
                   \___/ \___/ \___/ \___/
"""

print(LOGO)

lines = [line + '\n' for line in LOGO.split('\n')]
for line in lines:
    print(' '.join(f'{ord(char):3d}' for char in line))
print()
chars = {}
for char in LOGO:
    if char in chars:
        chars[char] += 1
    else:
        chars[char] = 1
for char in sorted(chars.keys()):
    c_ord = ord(char)
    c_num = chars[char]
    print(f'{char + " " if c_ord != 0x0A else "LF"} - {c_ord:3d}  ({c_num:3d})')
print()

### LOGO program ###

PROG = """
DP :  0  1  2  3  4  5  6  7  8  9
VAR:  a  b  c  d  e  f  g  h  i  j

++++++++++.                 a=10 out(a)                             DP=a    a='\n'

line 1
[->+>+++<<]>>++             a=0 b=10 c=32                           DP=c
[->+>+++<<]                 c=0 d=32 e=96                           DP=c
<[-<+>>++<]                 a=10 b=0 c=20                           DP=b
>--[->.<]>>-<<              c=0 e=95 18*out(d)                      DP=c    d=' '
++++[->.>.....<<]           4*(out(d) 5*out(e)) out(d)              DP=c    d=' ' e='_'
<<.                         out(a)                                  DP=a    a='\n'

line 2
>>>..                       2*out(d)                                DP=d    d=' '
[--<++<++>>>>+<<]           b=32 c=32 d=0 f=16                      DP=d
>>[-<.<+<+>>>]              c=48 d=16 f=0 16*out(e)                 DP=f    e='_'
<<<-.                       c=47 out(c)                             DP=c    c='/'
>>--------->+++             e=86 f=3                                DP=f
[-<<<<.....>>>.>]           f=0 3*(5*out(b) out(e))                 DP=f    b=' ' e='V'
<<<<.....>>>++++++.         e=92 5*out(b) out(e)                    DP=e    b=' ' e='\\'
<<<<.                       out(a)                                  DP=a    a='\n'

line 3
>.>.                        out(b) out(c)                           DP=c    b=' ' c='/'
>[-<<.>>>>++>++++++++<<<]   d=0 f=32 g=128 16*out(b)                DP=d    b=' '
>>>----.                    g=124 out(g)                            DP=g    g='|'
>++++[-<<.....>.>]          4*(5*out(f) out(g))                     DP=h    f=' ' g='|'
<<<<<<<.                    out(a)                                  DP=a    a='\n'

line 4
>>>>>>.<..                  out(g) 2*out(f)                         DP=f    f=' ' g='|'
<--------.>..               e=84 out(e) 2*out(f)                    DP=f    f=' ' e='T'
[->>+>++>++<<<<]            f=0 h=32 i=64 j=64                      DP=f
>>>++++++++.<..             i=72 j=66 out(i) 2*out(h)               DP=h    h=' ' i='H'
<<<+.>>>..                  e=85 out(e) 2*out(h)                    DP=h    e='U' h=' '
>+++++.<..                  i=77 out(i) 2*out(h)                    DP=h    h=' ' i='M'
>>++.<<..<.                 j=66 out(j) 2*out(h) out(g)             DP=g    g='|' h=' ' j='B'
>..>>++++.<<..<.            j=70 2*out(h) out(j) 2*out(h) out(g)    DP=g    g='|' h=' ' j='F'
>..<<<.>>>..<.              2*out(h) out(e) 2*out(h) out(g)         DP=g    e='U' g='|' h=' '
>..>>---.<<..<.             j=67 2*out(h) out(j) 2*out(h) out(g)    DP=g    g='|' h=' ' j='C'
>..>--.<..<.                i=75 2*out(h) out(i) 2*out(h) out(g)    DP=g    g='|' h=' ' i='K'
<<<<<<.                     out(a)                                  DP=a    a='\n'

line 5 (1st part)
>.>>>+++++++.               e=92 out(b) out(e)                      DP=e    b=' ' e='\\'
+++<<<[-->>>.<<<]           b=0 e=95 16*out(e)                      DP=b    e='_'

line 5 (2nd part) / lines 6 to 8 / line 9 (1st part)
++++[-                      (b=4) b*(                               DP=b
  >>>>>.<<<++++[-             (d=4) out(g) d*(                      DP=d    g='|'
    >>++++>>.....<.<<<          (f=4*4=16) 5*out(h) out(g)          DP=d    g='|' h=' '
  ]<<<.>>>>>++[-              ) (f=18) out(a) f*(                   DP=f    a='\n'
    >>.<<                       out(h)                              DP=f    h=' '
  ]<<<<                       )                                     DP=b
]                           )                                       DP=b

line 9 (2nd part)
>>>>>>[-<-<+>>]<<<<         f=32 g=92 h=0                           DP=d
++++[->>.>.<<...<<.>]       4*(out(f) out(g) 3*out(e) out(c))       DP=d    c='/' e='_' f=' ' g='\\'
<<<..                       2*out(a)                                DP=a    a='\n'
"""

###  quick'n'dirty interpreter ###

PM = [c for c in PROG if c in ('+', '-', '<', '>', ',', '.', '[', ']', '#')]
DM = [0x00] * 16
PP = 0
DP = 0
OUT = []

while True:
    if PP == len(PM):
        break

    op = PM[PP]

    if op == '+':
        PP += 1
        DM[DP] += 1
        if DM[DP] == 256:
            DM[DP] = 0
    elif op == '-':
        PP += 1
        DM[DP] -= 1
        if DM[DP] == -1:
            DM[DP] = 255
    elif op == '<':
        if 0 < DP:
            PP += 1
            DP -= 1
        else:
            bork
    elif op == '>':
        if DP < len(DM) - 1:
            PP += 1
            DP += 1
        else:
            bork
    elif op == ',':
        PP += 1
        # DM[DP], IN = IN[0], IN[1:]
    elif op == '.':
        PP += 1
        OUT.append(DM[DP])
    elif op == '[':
        PP += 1
        if DM[DP] == 0x00:
            loop_count = 1
            while True:
                if PM[PP] == ']':
                    loop_count -= 1
                    if loop_count == 0:
                        PP += 1
                        break
                elif PM[PP] == '[':
                    loop_count += 1
                PP += 1
    elif op == ']':
        if DM[DP] == 0x00:
            PP += 1
        else:
            loop_count = 1
            PP -= 1
            while True:
                if PM[PP] == '[':
                    loop_count -= 1
                    if loop_count == 0:
                        PP += 1
                        break
                elif PM[PP] == ']':
                    loop_count += 1
                PP -= 1
    else:
        assert op == '#'
        print('DP:', DP, f'({chr(ord("a") + DP)}={DM[DP]})')
        print('DM:', DM)
        for c in OUT:
            print(f'{c:3d}', end='\n' if c == 10 else ' ')
        print(''.join(chr(o) for o in OUT))
        PP += 1
        if PP < len(PM):
            input()

print(''.join(chr(o) for o in OUT))
#print(''.join(PM))
#print(len(PM))
print()

### Thumb assembly formatted ###

length = 64
lines = ["".join(PM[i:i + length]) for i in range(0, len(PM), length)]
for line in lines[:-1]:
    print(f'.ascii "{line}"')
print(f'.asciz "{lines[-1]}"')
