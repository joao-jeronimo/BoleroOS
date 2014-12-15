VECTOR_pixel    = 2     ; Args: X, Y                    (+5B align)
VECTOR_line     = 3     ; Args: X1, Y1, X2, Y2          (+3B align)
VECTOR_curve    = 4     ; Args: Xc, Yc,  R, As, Ae      (+2B align)
  ; (Advanced: deformed curve!)
VECTOR_dcurve   = 5     ; Args: Xc, Yc,  R, As, Ae, D   (+1B align)


align 8
Jeronimiana_font:
    times 65 dq 0   ; Everything through 'A'.....
    dq  .A
    dq  .B
    ; (ETC!)


 .A:    ; Width: 10; Heigth: 16
    db  VECTOR_line,    0,   0,   5,  16            ,0,0,0
    db  VECTOR_line,    5,  16,  10,   0            ,0,0,0
    db  VECTOR_line,    3,   8,   7,   8            ,0,0,0
    dq  0       ; EOG (end of glyph)
 
 .B:    ; Width: 10; Heigth: 16
    db  VECTOR_line,    0,   0,   0,  16            ,0,0,0
    db  VECTOR_line,    0,   0,   5,   0            ,0,0,0
    db  VECTOR_line,    0,   8,   5,   8            ,0,0,0
    db  VECTOR_line,    0,  16,   5,  16            ,0,0,0
    db  VECTOR_curve,   5,  12,   4,   0, 128         ,0,0
    db  VECTOR_curve,   5,   4,   4,   0, 128         ,0,0







