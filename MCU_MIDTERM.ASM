B_2ms BIT 01H            ;; 2ms��ʱ����־
OP_B  BIT  02H           ;; ��־��ǰOPERATOR���Ƿ������������, Ϊ1����ΪOPERATOR��Ч, Ϊ0����Ϊ��ǰ�������
NUM2_BEGIN  BIT  03H     ;; ��ʾ�ڶ����������Ƿ��Ѿ���ʼ����, Ϊ1��ʾ�ڶ������Ѿ���ʼ����, Ϊ0��ʾ�ڶ�������δ����
B_DISPLAY   BIT  04H     ;; 0����ʾ, 1��LED��ʾ
B_EQU       BIT  05H     ;; �Ⱥ��Ƿ񱻰��±�־
B_ADDCARRY  BIT  06H     ;; �ӷ���λ��־

MUL1_BIT    BIT 0AH      ;; ����������λ����
MUL2_BIT    BIT 0BH      ;; ��������λ����


LED_BUF EQU 24H          ;; ��ʾ����������͵�ַ         30H OR 38H
P_BCDDISP EQU 25H

KEYCODE EQU 28H          ;; ����ֵ
LASTCODE EQU 29H
N_SAME   EQU 2AH         ;; KEY_STATE
N_DISP   EQU 2BH         ;; DISP_STATE, ��ÿ��ʱ��Ƭ����ʾ�ڼ�λ��
THERSHORD EQU 2CH        ;; ��ⰴ�� N_SAME ����ֵ


N_LENGTH  EQU 2DH        ;; DISPLAY ָʾ��ʾ�ĳ��� 1~8
N_POINT   EQU 2EH        ;; DISPLAY ָʾС�����λ��, ��N_POINT >= N_LENGTHʱ����ʾС����    0~7
OPERATOR  EQU 2FH        ;; 0->+, 1->-, 2->*, 3->/, 0FFH->�޲�����״̬

NUM1_HEAD EQU 40H               ;; ������1����ֽڵ�ַ 40H
NUM1_TAIL EQU 43H
BCD1_HEAD EQU 44H               ;; ������1 ---- BCD��
NUM2_HEAD EQU 48H               ;; ������2����ֽڵ�ַ 48H
NUM2_TAIL EQU 47H
BCD2_HEAD EQU 4CH               ;; ������2 ---- BCD��

SHIFT_4BIT_P EQU 50H            ;; ���ֽڴ�C����������ֽڵ�ַ
SHIFT_N      EQU 51H            ;; ���ֽ����������ݳ���

CLEAR_MEM_HEAD EQU 52H          ;; CLEAR_MEM ���� ������0һ���ڴ���, ����ֽڵ�ַ
CLEAR_MEM_N    EQU 53H          ;; CLEAR_MEM ���� ���ݳ���
BIN_AREA       EQU 54H          ;; BIN�������� = BCD����-4
BCD_AREA       EQU 55H          ;; BCD����

SIGNED_BIT_HEAD  EQU 56H        ;; SAVE_SIGNED ����������
SIGNED_BIT  BIT 0CH             ;; SAVE_SIGNED����������ȡһ��4�ֽ����ķ���λ

MUL_L          EQU 58H          ;; �˻���4�ֽ�     58H~5FH
MUL_H          EQU 5CH          ;; �˻���4�ֽ�

BUMA_HEAD      EQU 57H          ;; 4�ֽڲ�������ֽڵ�ַ
BUMA_SIGNED    BIT 09H          ;; ����ʱ���ڱ������λ

DIVIDEND_HEAD  EQU 60H          ;; ������4�ֽ� 60H~63H
REMAINDER_HEAD EQU 64H          ;; ����4�ֽ� 68H~6BH
DIVISOR_HEAD   EQU 48H          ;; ����4�ֽ�      ==     NUM2_HEAD
ZERO_ERROR_BIT BIT 0DH          ;; ����Ϊ0�����־


FLOAT_N        EQU 6CH          ;; ת��С��λ������
MOV_HEAD_1     EQU 6DH          ;; MOV_4BIT: Դ����������ֽڵ�ַ
MOV_HEAD_2     EQU 6EH          ;; MOV_4BIT: Ŀ������������ֽڵ�ַ
MOV_N          EQU 6FH          ;; MOV_4BIT: ���ݳ���


ORG 0000H
   LJMP INIT
ORG 000BH
LJMP TIMER0_INT
ORG 0100H
INIT:
    MOV     SP, #0E0H
    MOV     TMOD,#01H              ;;TIMER0 MODE1
    MOV     TCON,#0
    MOV     TH0,#0F8H
    MOV     TL0,#30H               ;;2mS
    MOV     KEYCODE,  #0FFH
    MOV     LASTCODE, #0FFH
    MOV     THERSHORD, #15        ;; N_SAME����ֵ
    MOV     N_SAME, #0
    MOV     N_DISP, #0
    MOV     N_LENGTH, #0
    MOV     N_POINT,  #9
    MOV     OPERATOR, #0FFH
    MOV     LED_BUF, #30H
    CLR     OP_B
    CLR     NUM2_BEGIN
    CLR     B_EQU
    SETB    B_DISPLAY
    SETB    TR0
    SETB    ET0
    SETB    EA
    MOV     CLEAR_MEM_HEAD, LED_BUF                   ;; ����ʾ������     30H~3FH
    MOV     CLEAR_MEM_N, #16
    LCALL   CLEAR_MEM
    MOV     CLEAR_MEM_HEAD, #NUM1_HEAD                ;; ���������       40H~4FH
    MOV     CLEAR_MEM_N, #16
    LCALL   CLEAR_MEM
;; ---------------------------------------------------------------------------------
MAIN_LOOP:
    LCALL   KEY_SCAN
    LCALL   DO_KEY_NUMBER
    LCALL   DO_KEY_BACKSPACE
    LCALL   DO_KEY_OP
    LCALL   DO_KEY_EQU
    LCALL   CAL_ADD_SUBB
    LCALL   CAL_MUL
    LCALL   CAL_DIV
    LCALL   DISPLAY
    JNB     B_2ms, $
    CLR     B_2ms
    SJMP    MAIN_LOOP
;; ---------------------------------------------------------------------------------
;;2ms��ʱ���ж�
TIMER0_INT:
    MOV     TH0, #0F8H
    MOV     TL0, #30H
    SETB    B_2ms
    RETI

;; ---------------------------------------------------------------------------------
;; ����ɨ�����
;;INPUT: P1
;;OUTPUT: KEYCODE
;;INFLUENCED: LASTCODE-�ϴβ����ļ���
;;            N_SAME -��������ͬ����Ĵ���
;;            DPTR
KEY_SCAN:
         MOV     P1, #00FH   ;; �����1�������0
         NOP
         MOV     A,  P1
         MOV     B,  A       ;; ����õ��ĵ���λ
         MOV     P1, #0F0H   ;; �����1�������0
         NOP
         MOV     A,  P1      ;; ��ȡ����λ
         ORL     A,  B       ;; ƴװ����λ�͵���λ
         MOV     DPTR, #TAB_KEY
         MOVC    A, @A+DPTR
         ;; A -> ��ǰ�����İ����ı��
         ;; �Ƚϵ�ǰ��������һ�������İ���
         CJNE    A, LASTCODE, NEW_KEY     ;; �������˵�����µİ���
         MOV     A, N_SAME
         CJNE    A, THERSHORD, N_SAMENOTEQU
         MOV     KEYCODE, LASTCODE
         INC     N_SAME
         RET
N_SAMENOTEQU:
       JNC     EXIT_KEY            ;; N_SAME������ֵ��ֱ�Ӻ��� �˳�
       INC     N_SAME              ;; С����ֵ��ôN_SAME++
       RET
NEW_KEY:
       MOV     LASTCODE, A         ;; �¼�������LASTCODE��
       MOV     N_SAME,   #0
       RET
EXIT_KEY:
       RET

TAB_KEY:
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ;0-10H
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ;10-1FH
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ;20-2FH
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ;30-3FH
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ;40-4FH
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ;50-5FH
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ;60-6FH
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,01H,0FFH,0FFH,0FFH,05H,0FFH,0AH,0BH,0FFH ;70-7FH
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH  ;80-8FH
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH  ;90-9FH
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH  ;A0-AFH
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,02H,0FFH,0FFH,0FFH,06H,0FFH,09H,0CH,0FFH  ;B0-BFH
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH  ;C0-CFH
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,03H,0FFH,0FFH,0FFH,07H,0FFH,00H,0DH,0FFH  ;D0-DFH
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,04H,0FFH,0FFH,0FFH,08H,0FFH,0EH,0FH,0FFH  ;E0-EFH
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH  ;F0-FFH



;; ---------------------------------------------------------------------------------
;; ���ݲ�ͬ�ļ�ֵ��ִ�в�ͬ�Ĳ���

;; ---------------------------------------------------------------------------------
;; ������ʱ��������ӳ���������
;; INPUT: N_LENGTH, ������Ҫ����LED_BUF
;; OUTPUT: LED_BUF���һ������
DO_KEY_NUMBER:
        MOV     A,KEYCODE
        CJNE    A,#0FFH,JUDGE_NUM       ;; FFH��ʾ�޼�����
        MOV     A, N_LENGTH
        JZ      ZERO_N_LENGTH1          ;; Ϊ�˱�֤�˸��ֻ����ǡ����ʧʱLED_BUFҲ�ܱ���0
        RET
ZERO_N_LENGTH1:
        MOV     R0, LED_BUF
        MOV     @R0, #0
        MOV     N_POINT, #9               ;; ����С����
        RET
       ;; �ж��Ƿ������ְ���
JUDGE_NUM:
        CJNE    A, #10, ISNUMBER
ISNUMBER:         ;; ���������� ������ŵ�30H��ͷ���ڴ浥Ԫ��
        JNC     KEY_RET1              ;; �޽�λ�Ļ�, ֱ���˳�, ��Ҫ�޸�KEYCODE
        JB      OP_B, TO_NUM2         ;; �Ѿ������������, ���������൱��NUM_2
        SJMP    DO_KEY_NUM
TO_NUM2:
        JNB     NUM2_BEGIN, CLR_OPERATOR        ;; ���NUM2_BEGIN == 0, ��δ����ڶ����� Ҫ����LED_BUF
        SJMP    DO_KEY_NUM
CLR_OPERATOR:
        MOV     CLEAR_MEM_HEAD, LED_BUF
        MOV     CLEAR_MEM_N, #16
        LCALL   CLEAR_MEM
        MOV     N_LENGTH, #0
        SETB    NUM2_BEGIN
DO_KEY_NUM:
        MOV     R7, N_LENGTH        
        MOV     N_POINT, #9               ;; ����С����       ��������������������
        CJNE    R7, #8, TRANSDATALOOP_INIT      ;; ����������ݳ���8������ֹ����
        SJMP    KEY_CLR_KEY_AND_RET
TRANSDATALOOP_INIT:
        PUSH    A         ;; ����A ���������
        MOV     R6, #7
        MOV     A, N_LENGTH
        PUSH    A
        INC     A
        MOV     N_LENGTH, A
        MOV     A, LED_BUF
        ADD     A, #6
        MOV     R0, A
        MOV     R1, A
        INC     R0
        POP     A
        JZ      PUTDATA
TRANSDATALOOP:      ;; ��30H��ͷ���ڴ浥Ԫ������ǰ��
        MOV     A, @R1
        MOV     @R0, A
        DEC     R0
        DEC     R1
        DJNZ    R6, TRANSDATALOOP
PUTDATA:
        MOV     R0, LED_BUF
        POP     A
        MOV     @R0, A             ;; �ŵ���ʾ��������0λ
KEY_CLR_KEY_AND_RET:
        MOV     KEYCODE,#0FFH
KEY_RET1:
        RET



;; ---------------------------------------------------------------------------------
;; ���˸��ʱ��������ӳ�����
;; INPUT: N_LENGTH,
;; OUTPUT: LED_BUF���һ������
;; INFLUENCED: LED_BUF�е�����, �˸��ĸ�λ��0
DO_KEY_BACKSPACE:
        MOV     A,KEYCODE
        CJNE    A,#0FFH,JUDGE_BACKSPACE       ;; FFH��ʾ�޼�����
        RET
JUDGE_BACKSPACE:
        CJNE    A, #0EH, KEY_RET2    ;; KEYCODE != 0E ˵�������˸�� ֱ���˳�
        JB      OP_B, BACK_RET  ;; �����������ʱ, �����˸����Ч, �˳�
BACKSPACE:
        MOV A, N_LENGTH
        JZ  ZERO_N_LENGTH
        DEC A
        MOV N_LENGTH, A       ;; N_LENGTH--
        MOV R6, A
        MOV R0, LED_BUF
        MOV R1, LED_BUF
        INC R0
        JZ  ZERO_N_LENGTH
BACKSPACELOOP:                      ;; ��LED_BUF�е���������
        MOV A, @R0
        MOV @R1, A
        MOV @R0, #0
        INC R0
        INC R1
        DJNZ R6, BACKSPACELOOP
BACK_RET:
        MOV  KEYCODE, #0FFH
        RET
ZERO_N_LENGTH:
        MOV     R0, LED_BUF
        MOV     @R0, #0
        SJMP    BACK_RET
KEY_RET2:
        RET

;; ---------------------------------------------------------------------------------
;; ���������ʱ��������ӳ�����
;; INPUT: N_LENGTH,
;; OUTPUT: LED_BUF���һ������
;; INFLUENCED:

DO_KEY_OP:
        MOV     A,KEYCODE
        CJNE    A,#0FFH,JUDGE_OP       ;; FFH��ʾ�޼�����
        RET
JUDGE_OP:
        CLR     C                      ;; ���CJNE��Ӱ��
        SUBB    A, #10                 ;; + - * / -> A B C D
        JC      KEY_RET3               ;; KEYCODE < 10
        CJNE    A, #3, NOT_OP

DO_OP:
        JB      OP_B, END_DO_KEY_OP     ;; �Ѿ����������ֱ���˳�
        MOV     OPERATOR, A
        LCALL   SAVE_DATA              ;;���������е����ݱ��浽4��Bytes��
        ADD     A, #20
        MOV     R0, LED_BUF
        MOV     @R0, A
        MOV     N_LENGTH, #1
END_DO_KEY_OP:
        MOV     KEYCODE, #0FFH
        SETB    OP_B
        RET
NOT_OP:
        JC      DO_OP
KEY_RET3:
        RET


;; ---------------------------------------------------------------------------------
;; ��=����ʱ�������γ�����
DO_KEY_EQU:
        MOV     A,KEYCODE
        CJNE    A,#0FFH,JUDGE_EQU       ;; FFH��ʾ�޼�����
        RET
JUDGE_EQU:
        CJNE    A, #0FH, KEY_RET4    ;; KEYCODE != 0F ˵������=�� ֱ���˳�
DO_EQU:
        JNB     NUM2_BEGIN, CLR_KEYCODE_RET     ;; NUM2��û��ʼ����, ���Ⱥż���Ч
        LCALL   SAVE_DATA
        CLR     NUM2_BEGIN
        CLR     OP_B
        SETB    B_EQU
CLR_KEYCODE_RET:
        MOV     KEYCODE, #0FFH
KEY_RET4:
        RET



;; ---------------------------------------------------------------------------------
;; �ӷ�������
;; INPUT: NUM1_HEAD, NUM2_HEAD
;; OUTPUT: NUM1_HEAD
;; ---------------------------------------------------------------------------------
CAL_ADD_SUBB:
      MOV  A, OPERATOR
      CJNE A, #2, JUDGE_A_S            ;; ����+�Ż���-��ֱ���˳�
JUDGE_A_S:
      JNC  EXIT_CAL_ADD                ;; OP >= 2 ���ǼӺŻ��߼���
      JNB  B_EQU, EXIT_CAL_ADD         ;; =��δ����ֱ���˳�
DO_ADD:
      LCALL BIN_ADD_SUBB               ;; �ӷ�����
      CLR  B_EQU
      MOV  OPERATOR, #0FFH
      MOV    BIN_AREA, #NUM1_HEAD
      MOV    BCD_AREA, #BCD1_HEAD

      LCALL  BIN_TO_BCD
      MOV    P_BCDDISP, #BCD1_HEAD
      LCALL  BCD_DISPLAY
      MOV    A, N_LENGTH
      JZ     SHOW_ZERO1 
      SJMP   EXIT_CAL_ADD
SHOW_ZERO1:
      INC  N_LENGTH             
EXIT_CAL_ADD:
      RET


;; ---------------------------------------------------------------------------------
;; �˷�������
;; INPUT: NUM1_HEAD, NUM2_HEAD
;; OUTPUT: MUL_L, MUL_H
;; ---------------------------------------------------------------------------------
CAL_MUL:
      MOV  A, OPERATOR
      CJNE A, #2, EXIT_CAL_MUL
      JNB  B_EQU, EXIT_CAL_MUL
DO_MUL:
      LCALL BIN_MUL
      MOV   MOV_HEAD_1, #MUL_L                       ;; ���ĵ�4�ֽ�ת��NUM1_HEAD
      MOV   MOV_HEAD_2, #NUM1_HEAD
      MOV   MOV_N, #4
      LCALL MOV_4BIT

      CLR   B_EQU
      MOV  OPERATOR, #0FFH

      MOV    BIN_AREA, #NUM1_HEAD
      MOV    BCD_AREA, #BCD1_HEAD
      LCALL  BIN_TO_BCD

      MOV    P_BCDDISP, #BCD1_HEAD
      LCALL  BCD_DISPLAY
      MOV    A, N_LENGTH
      JZ     SHOW_ZERO2 
      SJMP   EXIT_CAL_MUL
SHOW_ZERO2:
      INC  N_LENGTH         
EXIT_CAL_MUL:
      RET


;; ---------------------------------------------------------------------------------
;; ����������
;; INPUT: NUM1_HEAD, NUM2_HEAD
;; OUTPUT: NUM1_HEAD -> ��������, NUM2_HEAD -> С������
;; ---------------------------------------------------------------------------------
CAL_DIV:
      MOV  A, OPERATOR
      CJNE A, #3, EXIT_CAL_DIV
      JNB  B_EQU, EXIT_CAL_DIV
DO_DIV:
    MOV   CLEAR_MEM_HEAD, #DIVIDEND_HEAD
    MOV   CLEAR_MEM_N, #8
    LCALL CLEAR_MEM

    MOV   MOV_HEAD_1, #NUM1_HEAD                     ;; NUM1 -> ������
    MOV   MOV_HEAD_2, #DIVIDEND_HEAD
    MOV   MOV_N, #4
    LCALL MOV_4BIT


    LCALL  BIN_DIV                                  ;; �����������ֺ���������
    
    JB     ZERO_ERROR_BIT, ZERO_ERROR_PROCESS
    SJMP   CAL_DIV_NEXT
    
ZERO_ERROR_PROCESS:    
    LCALL ZERO_PROCESS
    RET
CAL_DIV_NEXT:

    MOV   MOV_HEAD_2, #NUM1_HEAD
    MOV   MOV_HEAD_1, #DIVIDEND_HEAD
    MOV   MOV_N, #4
    LCALL MOV_4BIT                                  ;; �����������ֵ�NUM1��

 ;;  ����ʾ��������
    MOV    BIN_AREA, #NUM1_HEAD
    MOV    BCD_AREA, #BCD1_HEAD
    LCALL  BIN_TO_BCD

    MOV    P_BCDDISP, #BCD1_HEAD
    LCALL  BCD_DISPLAY

    ;;  led_buf �������������ֵ���
    LCALL  ADJUST_N_LENGTH
    
    MOV    A, N_LENGTH
    JZ     RBCD_NEXT            ;; �������������ȫ0�Ļ�����ҪR0��һ
    DEC    R0

RBCD_NEXT:
    MOV    A, LED_BUF   ;; ��37H
    ADD    A, #7
    MOV    R1, A
RBCD_LP:
    MOV    A, @R0
    MOV    @R1, A
    DEC    R0
    DEC    R1
    CJNE   R0, #2FH, RBCD_LP                         ;; ��ҳ��ʱ��29HҪ��  -�� LED_BUF - 1

    MOV    A, R1
    INC    A
    CLR    C
    SUBB   A, LED_BUF
    MOV    N_POINT, A


    MOV    FLOAT_N, N_POINT
    LCALL  REMAINDER_TO_FLOAT                       ;; ������������



    MOV   MOV_HEAD_2, #NUM2_HEAD
    MOV   MOV_HEAD_1, #DIVIDEND_HEAD
    MOV   MOV_N, #4
    LCALL MOV_4BIT                                  ;; ��������ת��NUM2��

    LCALL  PROCESS_FLOAT
    
    MOV   N_LENGTH, #8          ;; �����ʾ8λ
    CLR   B_EQU
    MOV   OPERATOR, #0FFH

EXIT_CAL_DIV:
    RET


ZERO_PROCESS:
    MOV    R0, LED_BUF
    MOV    @R0, #25         ;; ��ʾERROR
    INC    R0
    MOV    @R0, #0         
    INC    R0
    MOV    @R0, #25         
    INC    R0
    MOV    @R0, #25          
    INC    R0
    MOV    @R0, #24         
    MOV    N_LENGTH, #5
    CLR   B_EQU
    MOV   OPERATOR, #0FFH
    MOV   CLEAR_MEM_HEAD, #NUM1_HEAD
    MOV   CLEAR_MEM_N, #8
    LCALL CLEAR_MEM
    RET
PROCESS_FLOAT:
;; ��������    תBCD
    MOV    BIN_AREA, #NUM2_HEAD
    MOV    BCD_AREA, #BCD2_HEAD
    LCALL  BIN_TO_BCD

    MOV    R0, #38H
    MOV    R1, #BCD2_HEAD
    MOV    R4, #4
CHAI:
    MOV    A, @R1
    ANL    A, #00FH
    MOV    @R0, A
    INC    R0
    MOV    A, @R1
    ANL    A, #0F0H
    SWAP   A
    MOV    @R0, A
    INC    R0
    INC    R1
    DJNZ   R4, CHAI

    MOV    MOV_HEAD_1, #38H
    MOV    MOV_HEAD_2, #30H
    MOV    MOV_N, FLOAT_N
    LCALL  MOV_4BIT                            ;; ��������Ų����������



    RET





;; ---------------------------------------------------------------------------------
;; �������ʾ����
;; INPUT: LED_BUF, N_DISP, N_POINT, N_LENGTH
;; OUTPUT: NONE
;; INFLUENCE:
DISPLAY:
        JNB     B_DISPLAY, NOT_DISPLAY
        MOV     A, N_LENGTH
        JNZ     POINT
NOT_DISPLAY:
        MOV     P2, #0FFH
        SJMP    EXIT_DISP
POINT:
        MOV     A, LED_BUF
        ADD     A, N_POINT
        PUSH    A          ;; ��ַѹջ����(Ҫ��ʾС�������һλ)
        MOV     R1, A
        MOV     A, @R1     ;; 35H�ڴ浥Ԫ����+10�ٲ��
        PUSH    A          ;; ����ѹջ����
        ADD     A, #10
        MOV     @R1, A
LED:
        MOV     A, LED_BUF
        ADD     A, N_DISP
        MOV     R0, A
        MOV     A, @R0
        MOV     DPTR, #TAB_LED
        MOVC    A, @A+DPTR
        MOV     P0, A           ;; ���Ҫ��ʾ������
        MOV     A,#0FFH
        CLR     C
        INC     N_DISP
        MOV     R7, N_DISP
LOOP_D1:
        RRC     A
        DJNZ    R7,LOOP_D1
        MOV     P2,A
        ;; N_DISP ���� N_LENGTHʱ����
        MOV     A, N_DISP
        ;CJNE    A, N_LENGTH, POP_POINT_DATA          ;; ����ĳ�SUBB��һЩ����CJNE�ᵼ��N_DISP����N_LENGTH�����ڰ��°���ʱ������ʾ�쳣
        CLR     C
        SUBB    A, N_LENGTH
        JC      POP_POINT_DATA
        MOV     N_DISP, #0
POP_POINT_DATA:
        POP A                     ;; ��ԭ��һλ���޸���ʾС���������
        POP B
        MOV R1, B
        MOV @R1, A
EXIT_DISP:
        RET


TAB_LED:DB 28H, 7EH, 0A2H, 62H, 74H, 61H, 21H, 7AH, 20H, 60H
       ;; 0    1    2     3    4    5    6    7    8    9
        DB 08h, 5EH, 82H, 42H, 54H, 41H, 01H, 5AH, 00H, 40H
       ;; 0.   1.   2.    3.   4.   5.   6.   7.   8.   9.
        DB 0B5H, 0F7H, 34H, 0B6H, 0A1H,  0B7H
           ;20                     24     25
       ;;   +      -    *     /    E      R

;; ---------------------------------------------------------------------------------
;; ����ʾ������������BCD�� ���浽�ĸ��ֽ���
;; INPUT: LED_BUF, NUM1_2_B(0��浽BCD1��, 1��浽BCD2��)
;; OUTPUT: NUM1HEAD, NUM2HEAD
;; ---------------------------------------------------------------------------------
SAVE_DATA:
       PUSH    A                  ;; ����A �� PSW
       PUSH    PSW
       CLR  PSW.3

       ;; ----- ��黺������ǰ���Ƿ���-�� -------
       LCALL  ADJUST_N_LENGTH     ;; �����λ
       DEC    R0                  ;; R0ָ�����λ
       CLR    BUMA_SIGNED            ;; ���� �������λ
       CJNE   @R0, #21, SAVE_DATA_CONTINUE
       SETB   BUMA_SIGNED
       MOV    @R0, #0
       ;;
SAVE_DATA_CONTINUE:          
       LCALL  GET_INT           ;; ȡ��������
       MOV  R7, #4
       MOV  R0, LED_BUF
       MOV  R1, LED_BUF
       INC  R1
       SETB PSW.3   ;;�л��Ĵ���������
       JNB  OP_B, SAVE_TO_NUM_1             ;; ���û�в������ʹ浽NUM1
       MOV  R0, #BCD2_HEAD
       SJMP SAVE_DATA_LOOP_INIT
SAVE_TO_NUM_1:
       MOV  R0, #BCD1_HEAD
       ;; R0ȡ���ֽڣ�R1ȡ���ֽ�
SAVE_DATA_LOOP_INIT:
       MOV  BCD_AREA, R0
       MOV  A, BCD_AREA
       CLR  C
       SUBB A, #4
       MOV  BIN_AREA, A
       CLR  PSW.3
SAVE_DATA_LOOP:
       MOV  A, @R1
       SWAP A
       ANL  A, #0F0H
       MOV  B, A
       MOV  A, @R0
       ANL  A, #00FH
       ORL  A, B
       INC  R1
       INC  R1
       INC  R0
       INC  R0
       SETB PSW.3   ;;�л��Ĵ���������
       MOV  @R0, A
       INC  R0
       CLR  PSW.3
       DJNZ R7, SAVE_DATA_LOOP

       ;; ���OPΪ-��, ��ôNUM2����λȡ��
       MOV   R5, OPERATOR
       CJNE  R5, #1, SAVE_D_END
       JNB   OP_B, SAVE_D_END
       CPL   BUMA_SIGNED
SAVE_D_END:
       LCALL BCD_TO_BIN
       POP  PSW
       POP  A
       RET


;; -------------------------------------------------------------------------------
;; ��LED_BUF�е���ȡ�������� , ����С������ȥ����, �������ֻ���
;; INPUT: N_POINT, LED_BUF
;; OUTPUT: 
;; INFLUENCE:
;; -------------------------------------------------------------------------------
GET_INT:
      PUSH  PSW
      PUSH  A
      
      MOV   A, N_POINT
      CJNE  A, #8, XX8
XX8:
      JC    GET_INT_PART
      SJMP  GET_INT_END
GET_INT_PART:    
      SETB  RS0                 ;; �õ�2��Ĵ���         10H~17H
      CLR   RS1
      
      MOV  A, N_POINT
      ADD  A, LED_BUF
      MOV  R0, A
      MOV  R1, LED_BUF
      MOV  A, #8
      CLR  C
      SUBB A, N_POINT
      MOV  R7, A               ;; ѭ������ȷ��
      ;; ��0С������, ��������Ų����ͷ

      CLR  RS0                          ;; ���Ĵ��������� ��֤R0��Ҫ���ƻ�      
      MOV  CLEAR_MEM_HEAD, LED_BUF
      MOV  CLEAR_MEM_N, N_POINT
      LCALL CLEAR_MEM
      SETB RS0      
GET_INT_LP:
      MOV  A, @R0
      MOV  @R1, A
      MOV  @R0, #0
      INC  R0
      INC  R1      
      DJNZ R7, GET_INT_LP
      MOV  N_POINT, #9
GET_INT_END:            
      POP  A
      POP  PSW
      RET
      


;; -------------------------------------------------------------------------------
;; ������4�ֽڴ��������Ӽ���
;; ���ڴ浥Ԫ�е�����Ϊԭ��
;; INPUT: NUM1_HEAD, NUM2_HEAD
;; OUTPUT: �ͷ���NUM1��
;; INFLUENCE:
;; -------------------------------------------------------------------------------

BIN_ADD_SUBB:
    ;; ��������ȡ����
    MOV  BUMA_HEAD, #NUM2_HEAD
    LCALL BUMA
    MOV  BUMA_HEAD, #NUM1_HEAD         ;; BUMA_HEAD  ����   NUM1_HEAD
    LCALL BUMA
    MOV  R7, #4
    CLR  C
    MOV  R0, #NUM1_HEAD
    MOV  R1, #NUM2_HEAD
BIN_ADD_LP:
    MOV   A, @R0
    ADDC  A, @R1
    MOV   @R0, A
    INC   R0
    INC   R1
    DJNZ  R7, BIN_ADD_LP
    LCALL  BUMA                       ;; ����ǲ���, תΪԭ���ʾ
    RET


;; -------------------------------------------------------------------------------
;; ������4�ֽ�������
;; ���ڴ浥Ԫ�е�����Ϊԭ��
;; INPUT:
;; OUTPUT:
;; INFLUENCE:
;; -------------------------------------------------------------------------------

BUMA:
    MOV  R7, #4
    MOV  R0, BUMA_HEAD
    ;;------ �������λ�ķ���λ ------------
    MOV  A, R0
    ADD  A, #3
    MOV  R1, A
    MOV  A, @R1
    RLC  A
    MOV  BUMA_SIGNED, C
    JNC  BUMA_END
    ;;------ -------------------------------
    SETB C

BUMA_LP:
    MOV  A, @R0
    CPL  A
    ADDC A, #0
    MOV  @R0, A
    INC  R0
    DJNZ R7, BUMA_LP

    ;;-------- ��ԭ���λ����λ -----------
    DEC  R0
    MOV  C, BUMA_SIGNED
    MOV  A, @R0
    MOV  ACC.7, C
    MOV  @R0, A
BUMA_END:
    RET



;; -------------------------------------------------------------------------------
;; ������4�ֽڴ��������˷�
;; ���ڴ浥Ԫ�е�����Ϊԭ��
;; INPUT: NUM1_HEAD, NUM2_HEAD
;; OUTPUT: MUL_H, MUL_L
;; INFLUENCE:
;; -------------------------------------------------------------------------------

BIN_MUL:
    ;;  ����λ����, �˻��ķ���λ�����������ķ���λ���
    MOV  SIGNED_BIT_HEAD, #NUM1_HEAD
    LCALL  SAVE_SIGNED
    MOV   C, SIGNED_BIT
    MOV   MUL1_BIT, C

    MOV  SIGNED_BIT_HEAD, #NUM2_HEAD
    LCALL  SAVE_SIGNED
    MOV   C, SIGNED_BIT
    MOV   MUL2_BIT, C


    MOV   C, MUL2_BIT
    ANL   C, /MUL1_BIT
    MOV   BUMA_SIGNED, C        ;; A /B
    MOV   C, MUL1_BIT
    ANL   C, /MUL2_BIT
    ORL   C, BUMA_SIGNED
    MOV   MUL1_BIT, C
    ;;  ���Ž����MUL1_BIT���棬ͬʱ����ALLRL, ALLRR, ������λȫ����0, ȡ����ֵ���

    ;;  ����ճ˻�����
    MOV  CLEAR_MEM_HEAD, #MUL_L
    MOV  CLEAR_MEM_N   , #8             ;; ���8���ֽ�
    LCALL CLEAR_MEM
    MOV  R6, #32
BIN_MUL_LP:
    MOV   SHIFT_4BIT_P, #NUM2_HEAD       ;; �������ƽ�C��
    MOV   SHIFT_N, #4
    LCALL ALLRR
    JNC   RRMUL
    ;; ������һλ��1, ���ĸ�4�ֽ��뱻�������
    CLR  C
    SETB PSW.3
    MOV  R5, #4
    MOV  R0, #NUM1_HEAD
    MOV  R1, #MUL_H
MUL_ADD_LP:
    MOV  A, @R0
    ADDC A, @R1
    MOV  @R1, A
    INC  R0
    INC  R1
    DJNZ R5, MUL_ADD_LP
    CLR  PSW.3
;; ����4λ��4λ��������
RRMUL:
    MOV  SHIFT_4BIT_P, #MUL_L
    MOV  SHIFT_N, #8
    LCALL ALLRR
    DJNZ  R6, BIN_MUL_LP


;; ��������λ
    MOV   A, #MUL_L
    ADD   A, #3
    MOV   R1,  A
    MOV   A, @R1
    MOV   C, MUL1_BIT
    MOV   ACC.7, C
    MOV   @R1, A
    RET



;; -------------------------------------------------------------------------------
;; ������8�ֽڳ���4�ֽڴ�����������
;; ���ڴ浥Ԫ�е�����Ϊԭ��
;; INPUT: NUM1_HEAD, NUM2_HEAD
;; OUTPUT: REMAINDER_HEAD, DIVIDEND_HEAD
;; INFLUENCE:
;; -------------------------------------------------------------------------------

BIN_DIV:
    ;; ����λȷ��
    MOV  A, #DIVIDEND_HEAD
    MOV  SIGNED_BIT_HEAD, A
    LCALL  SAVE_SIGNED
    MOV   C, SIGNED_BIT
    MOV   MUL1_BIT, C

    MOV  SIGNED_BIT_HEAD, #DIVISOR_HEAD
    LCALL  SAVE_SIGNED
    MOV   C, SIGNED_BIT
    MOV   MUL2_BIT, C


    MOV   C, MUL2_BIT
    ANL   C, /MUL1_BIT
    MOV   BUMA_SIGNED, C        ;; A /B
    MOV   C, MUL1_BIT
    ANL   C, /MUL2_BIT
    ORL   C, BUMA_SIGNED
    MOV   MUL1_BIT, C


    ;; �жϳ����Ƿ����0, ����0ֱ����� ZERO_ERROR_BIT = 1 ���� = 0
    LCALL JUDGE_DIVISOR_Z
    JB    ZERO_ERROR_BIT, BIN_DIV_END

    MOV   SHIFT_4BIT_P, #DIVIDEND_HEAD
    MOV   SHIFT_N, #12                ;; 8+4 = 12 �ֽ�����
    MOV   R4, #32                     ;; ������ȫ���Ƴ�, �� 4*8 = 64��
    ;; �����������
    MOV   CLEAR_MEM_HEAD, #REMAINDER_HEAD
    MOV   CLEAR_MEM_N   , #4
    LCALL CLEAR_MEM

BIN_DIV_LP:
    LCALL  ALLRL
    SETB   PSW.3
    LCALL  JUDGE_REMAINDER            ;; �ж����������Ƿ�>���� , > ����� ���� = ����-����, C=0, ���򲻸��� C=1
    JC     BIN_DIV_LP_JUDGE
;;  ��������������ֽ����λ��1
    MOV    R0, #DIVIDEND_HEAD
    MOV    A, @R0
    SETB   ACC.0
    MOV    @R0, A
BIN_DIV_LP_JUDGE:
    CLR    PSW.3
    DJNZ   R4, BIN_DIV_LP

;; ��ԭ����λ
    MOV   A, #DIVIDEND_HEAD
    ADD   A, #3                      ;; �ҵ��̲�������ֽ�    3��4�ֽڳ���
    MOV   R1,  A
    MOV   A, @R1
    MOV   C, MUL1_BIT
    MOV   ACC.7, C
    MOV   @R1, A

BIN_DIV_END:
    RET



;; -------------------------------------------------------------------------------
;; �ڳ������ж����������Ƿ���ڳ������ֵ��ӳ���
;; ���ڴ浥Ԫ�е�����Ϊԭ��
;; INPUT: NUM1_HEAD, NUM2_HEAD
;; OUTPUT:
;; INFLUENCE:
;; -------------------------------------------------------------------------------

JUDGE_REMAINDER:
    MOV  R0, #REMAINDER_HEAD
    MOV  R1, #DIVISOR_HEAD
    MOV  R3, #4
    CLR  C
JUDGE_REMAINDER_LP:             ;; ��������, �ж����Ľ���Ƿ��� C = 1, =1˵������С
    MOV  A, @R0
    SUBB A, @R1
    PUSH A
    INC  R0
    INC  R1
    DJNZ R3, JUDGE_REMAINDER_LP
    JC   DISCARD_RESULT        ;; ����С��ֱ�Ӷ��������Ľ��
    ;; ��������Ҫ������������
    MOV  R3, #4
UPDATE_RESULT_LP:
    DEC  R0
    POP  A
    MOV  @R0, A
    DJNZ R3, UPDATE_RESULT_LP
    SJMP JUDGE_REMAINDER_END
DISCARD_RESULT:
    POP  A
    POP  A
    POP  A
    POP  A
JUDGE_REMAINDER_END:
    RET

;; -------------------------------------------------------------------------------
;; �ڳ������жϳ��������Ƿ�Ϊ0���ӳ���
;; ���ڴ浥Ԫ�е�����Ϊԭ��
;; INPUT: DIVISOR_HEAD
;; OUTPUT:
;; INFLUENCE:
;; -------------------------------------------------------------------------------

JUDGE_DIVISOR_Z:
    SETB ZERO_ERROR_BIT
    MOV  R0, #DIVISOR_HEAD
    MOV  R2, #4
JUDGE_DIVISOR_Z_LP:
    MOV  A,  @R0
    JNZ  DIVISOR_NOT_ZERO                     ;; ��һ���ֽڲ���0����
    INC  R0
    DJNZ R2, JUDGE_DIVISOR_Z_LP
    SJMP JUDGE_DIVISOR_Z_END
DIVISOR_NOT_ZERO:
    CLR  ZERO_ERROR_BIT
JUDGE_DIVISOR_Z_END:
    RET

;; -------------------------------------------------------------------------------
;; ��������ת����С�����ֵ��ӳ���
;; INPUT: DIVISOR_HEAD, MUL_L -> ���û��ĵ����ֽڼĴ�����FLOAT_N -> С��λ���ľ���
;; OUTPUT:
;; INFLUENCE:
;; -------------------------------------------------------------------------------

REMAINDER_TO_FLOAT:
    ;; ��������3λ + ��������1λ = 10*����
    MOV  CLEAR_MEM_HEAD, #DIVIDEND_HEAD
    MOV  CLEAR_MEM_N, #4
    LCALL CLEAR_MEM                              ;; ����ֻ���������ĳ���

    MOV  SHIFT_4BIT_P, #REMAINDER_HEAD
    MOV  SHIFT_N, #4
    MOV  R3, FLOAT_N
MUL10LP:
    MOV  MOV_HEAD_1, #REMAINDER_HEAD
    MOV  MOV_HEAD_2, #MUL_L
    MOV  MOV_N, #4
    LCALL ALLRL
    LCALL MOV_4BIT
    LCALL ALLRL
    LCALL ALLRL
    CLR   C
    MOV   R0, #REMAINDER_HEAD
    MOV   R1, #MUL_L
    MOV   R2, #4
RTF_ADD_LP:
    MOV   A, @R0
    ADDC  A, @R1
    MOV   @R0, A
    INC   R0
    INC   R1
    DJNZ  R2, RTF_ADD_LP            ;; ��10�Ժ��ٴ�� ����������
    DJNZ  R3, MUL10LP               ;; nλС���ͳ�10^n�ٳ�������

    MOV   MOV_HEAD_1, #REMAINDER_HEAD
    MOV   MOV_HEAD_2, #DIVIDEND_HEAD
    MOV   MOV_N, #4
    LCALL MOV_4BIT
    LCALL BIN_DIV                   ;; ��ʱ�õ����̾���С�����ֵ�������ʾ  3/4 = 0.75  300/4 = 75

    RET



;;  BCD <----> BIN ֻ�����ھ���ֵ��ת��, ����λҪ��������

;; -------------------------------------------------------------------------------
;; 4�ֽڶ�����תBCD���ӳ���   ������λ��
;; INPUT:
;; OUTPUT:
;; INFLUENCE:
;; -------------------------------------------------------------------------------
BIN_TO_BCD:
    ;; ��ȡ�����������λ, �������λ
    MOV  SIGNED_BIT_HEAD, BIN_AREA
    LCALL  SAVE_SIGNED
    ;; ����0 BCD��
    MOV  CLEAR_MEM_HEAD, BCD_AREA
    MOV  CLEAR_MEM_N,    #4
    LCALL  CLEAR_MEM
    MOV  R5, #32        ;; һ��32����λ
    MOV  SHIFT_N, #8
    MOV  SHIFT_4BIT_P, BIN_AREA
BIN_TO_BCD_LP:
    ;; BCD�������
    MOV   R6, #4
    MOV   R0, BCD_AREA
BCD_ADJUST_LP:
    LCALL BCD_ADJUST
    INC   R0
    DJNZ  R6, BCD_ADJUST_LP

    ;; BCD��BIN������������
    LCALL ALLRL
    DJNZ  R5, BIN_TO_BCD_LP
    RET


;; -------------------------------------------------------------------------------
;; BCD���������
;; INPUT: @R0
;; OUTPUT: ԭַ����, �������BCD��
;; INFLUENCE:
;; -------------------------------------------------------------------------------
BCD_ADJUST:
     MOV  A, @R0
     ADD  A, #03H       ;; ���ֽ�+3���Ƿ���ڵ���8
     JB   ACC.3, BCD_ADJUST_L
     SJMP BCD_ADJUST_JUDGE_H
BCD_ADJUST_L:   ;; ��Ҫ����3����
     MOV  @R0, A    ;; ����

BCD_ADJUST_JUDGE_H:
     MOV  A, @R0
     ADD  A, #30H       ;; ���ֽ�+3���Ƿ���ڵ���8
     JB   ACC.7, BCD_ADJUST_H
     SJMP BCD_ADJUST_END
BCD_ADJUST_H:
     MOV  @R0, A
BCD_ADJUST_END:
     RET



;; -------------------------------------------------------------------------------
;; N���ֽ����Ƴ���(N <= 255)
;; INPUT: ��Ҫ�������λ�ֽڵ��ڴ浥Ԫ��ַ SHIFT_4BIT_P, Bytes����SHIFT_N
;; OUTPUT: ԭַ����, �������൱��ԭ�����ĸ�BYTE�еĵ�Ԫ����������, ���λ��0 , C��������ֽڵ����λ
;; INFLUENCE: A, C, PSW, R0
;; -------------------------------------------------------------------------------

ALLRL:
    CLR  C
    MOV  R0, SHIFT_4BIT_P
    MOV  R7, SHIFT_N
ALLRL_LP:
    MOV  A,  @R0                ;; A�д����λ
    RLC  A
    MOV  @R0,  A                ;; �ش�
    INC  R0
    DJNZ R7, ALLRL_LP
    RET

;; -------------------------------------------------------------------------------
;; BCD��ת������BIN�ӳ���   ������λ��   ʵ������BCD_TO_BIN�������
;; INPUT:
;; OUTPUT:
;; INFLUENCE:
;; �ȵ���SAVE_DATA�ٵ���BCD_TO_BIN
;; -------------------------------------------------------------------------------
BCD_TO_BIN:
    ;; ����0 BIN��
    MOV  CLEAR_MEM_HEAD, BIN_AREA
    MOV  CLEAR_MEM_N,    #4
    LCALL CLEAR_MEM
    MOV  R5, #32
    MOV  SHIFT_4BIT_P, BIN_AREA
    MOV  SHIFT_N, #8
BCD_TO_BIN_LP:
    ;; BCD+BIN����������
    LCALL ALLRR

    ;; BCD�������
    MOV  R0, BCD_AREA
    MOV  R6, #4
BCD_IADJUST_LP:
    LCALL BCD_IADJUST
    INC   R0
    DJNZ  R6, BCD_IADJUST_LP
    DJNZ  R5, BCD_TO_BIN_LP
    ;; -------------- �����λ�ķ��Ž��е��� ---------------------
    ;; ��� SAVE_DATA ��ʹ�� BUMA_BIT == 1, ��ôҪ�޸����λ�ķ���
    MOV   A, BIN_AREA
    ADD   A, #3      ;; ������ֽ�
    MOV   R1, A
    MOV   A, @R1
    MOV   C, BUMA_SIGNED
    MOV   ACC.7, C
    MOV   @R1, A
    RET

;; -------------------------------------------------------------------------------
;; BCD�뷴�����
;; INPUT: @R0
;; OUTPUT: ԭַ����, �������BCD��
;; INFLUENCE:
;; -------------------------------------------------------------------------------
BCD_IADJUST:
     MOV  A, @R0
     ;; �жϵ��ֽ�BCD���Ƿ�>=8, ������Ҫ-03H
     JB   ACC.3, BCD_IADJUST_L
     SJMP  BCD_IADJUST_JUDGE_H
BCD_IADJUST_L:
     CLR   C
     SUBB  A, #03H
BCD_IADJUST_JUDGE_H:
     JB   ACC.7, BCD_IADJUST_H
     SJMP  BCD_IADJUST_END
BCD_IADJUST_H:
     CLR   C
     SUBB  A, #30H
BCD_IADJUST_END:
     MOV  @R0, A
     RET


;; -------------------------------------------------------------------------------
;; 4���ֽ����Ƴ���
;; INPUT: ��Ҫ�������λ�ֽڵ��ڴ浥Ԫ��ַ SHIFT_4BIT_P, Bytes����SHIFT_N
;; OUTPUT: ԭַ����, �������൱��ԭ�����ĸ�BYTE�еĵ�Ԫ����������, ���λ��0, C��������ֽڵ����λ
;; INFLUENCE: A, C, PSW, R0
;; -------------------------------------------------------------------------------
ALLRR:
    CLR  C
    MOV  R0, SHIFT_4BIT_P
    MOV  A, R0
    ADD  A, SHIFT_N
    DEC  A
    MOV  R0, A          ;; R0�������SHIFT_N���ҵ���ߵ�ַ���ֽ� 30H -> 33H
    MOV  R7, SHIFT_N
ALLRR_LP:
    MOV  A,  @R0                ;; A�д����λ
    RRC  A
    MOV  @R0,  A                ;; �ش�
    DEC  R0
    DJNZ R7, ALLRR_LP
    RET


;; -------------------------------------------------------------------------------
;; CLEAR_MEM, ��0һ���ڴ浥Ԫ
;; INPUT: CLEAR_MEM_HEAD, CLEAR_MEM_N
;; OUTPUT:
;; INFLUENCE:
;; -------------------------------------------------------------------------------
CLEAR_MEM:
    MOV  R0, CLEAR_MEM_HEAD
    MOV  R7, CLEAR_MEM_N
CLEAR_MEM_LP:
    MOV  @R0, #0
    INC  R0
    DJNZ R7,  CLEAR_MEM_LP
    RET


;; -------------------------------------------------------------------------------
;; ȡ��4�ֽڶ��������ķ���λ, ��ȡ�����ľ���ֵ
;; INPUT: ����ֽڵ�ַSAVE_BIT_HEAD
;; OUTPUT: ����λ������SAVE_BIT��
;; INFLUENCE: R1, PSW, A, SAVE_BIT
;; -------------------------------------------------------------------------------

SAVE_SIGNED:
    MOV  A, SIGNED_BIT_HEAD
    ADD  A, #3
    MOV  R1,  A
    MOV  A, @R1
    RLC  A  ;; ����λ�Ƶ�C��
    RR   A
    MOV  @R1, A
    MOV  SIGNED_BIT, C
    RET


;; -------------------------------------------------------------------------------
;; N�ֽ����ݴ����ӳ���
;; INPUT: MOV_HEAD_1, MOV_HEAD_2, MOV_N
;; OUTPUT: ��1�������ݵ�2
;; INFLUENCE:
;; -------------------------------------------------------------------------------

MOV_4BIT:
    MOV  R0, MOV_HEAD_1
    MOV  R1, MOV_HEAD_2
    MOV  R2, MOV_N
MOV_4BIT_LP:
    MOV  A, @R0
    MOV  @R1, A
    INC  R0
    INC  R1
    DJNZ R2, MOV_4BIT_LP
    RET


;; ----------------------------------------------------------------------------------
;; ��4Bytes��ѹ����BCD����8λ��ѹ����BCD��, ���ڽ���������ʾ���������
;; INPUT: ��ת���������λ�ĵ�ַ  P_BCDDISP,
;; OUTPUT: LED_BUF
;; INFLUENCE:
;; �ȵ��� BIN_TO_BCD�ٵ�����γ���
;; ----------------------------------------------------------------------------------
BCD_DISPLAY:
       PUSH  A
       PUSH  PSW
       MOV   R0, LED_BUF
       MOV   R1, P_BCDDISP
       MOV   R7, #4
BCD_DISPLAY_LOOP:
       MOV   A, @R1
       ANL   A, #0FH    ;; ��ȡ����λ

       MOV   @R0, A
       INC   R0

       MOV   A, @R1
       ANL   A, #0F0H
       SWAP  A
       MOV   @R0, A
       INC   R0
       INC   R1

       DJNZ  R7, BCD_DISPLAY_LOOP
       LCALL  ADJUST_N_LENGTH                 ;; ������ʾλ��
       JB    SIGNED_BIT, BCD_N_PROCESS            ;; ��������
       SJMP  BCD_DISPLAY_END
BCD_N_PROCESS:
       MOV   @R0, #21
       INC   N_LENGTH
BCD_DISPLAY_END:
       POP   PSW
       POP   A
       RET


;; -------------------------------------------------------------------------------
;;  ��鵱ǰLED_BUF�����ж�����Ч������0��
;;  ���R0�б��������һλ��   1 2 3 0 0 0 0 0 -> N_LENGTH == 3, R0 = LED_BUF + N_LENGTH  = 33
;; -------------------------------------------------------------------------------
ADJUST_N_LENGTH:
       PUSH A
       PUSH PSW
       MOV  A, LED_BUF
       ADD  A, #7
       MOV  R0, A
       MOV  R7, #8
ADJUST_LOOP:
       MOV  A, @R0
       JNZ  END_ADJUST_LOOP
       DEC  R0
       DJNZ R7, ADJUST_LOOP
END_ADJUST_LOOP:
       INC  R0
       MOV  A, R0
       CLR  C
       SUBB A, LED_BUF
       MOV  N_LENGTH, A
                 
       POP  PSW
       POP  A
       RET