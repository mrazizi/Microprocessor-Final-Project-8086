;local micro 1
          
.8086
.MODEL SMALL
.STACK 1024

.DATA

8255A_PORTA     DW 0x0200
8255A_PORTB     DW 0x0202
8255A_PORTC     DW 0x0204
8255A_CW        DW 0x0206      

8255B_PORTA     DW 0x0400
8255B_PORTB     DW 0x0402
8255B_PORTC     DW 0x0404
8255B_CW        DW 0x0406    

8259_ICW1       DW 0x1000
8259_ICW2       DW 0x1002
8259_ICW4       DW 0x1002
8259_OCW1       DW 0X1002

8251_CW         DW 0x0802
8251_MW         DW 0x0802
8251_STATUS     DW 0x0802  
8251_TX         DW 0x0800
  
8251_S0         DW 0x0800
8251_S1         DW 0x0802


TIMER_COUNTER0  DW 0x0600
TIMER_COUNTER1  DW 0x0602
TIMER_COUNTER2  DW 0x0604  
TIMER_COUNTER_CW  DW 0x0606 

COUNTER0_LSB    DB 0x90
COUNTER0_MSB    DB 0x00   

COUNTER1_LSB    DB 0x65
COUNTER1_MSB    DB 0x00 

COUNTER2_LSB    DB 0x64
COUNTER2_MSB    DB 0x00 

LIGHTS_TIME     DB 5,1,5
LIGHT_STATUS    DW 0       ;0: green, 1: yellow, 2: red
TIMER_PERIOD    DB 0       ;for detecting witch light should be turned on
   
;G_LIGHT_TIME    DB 5
;Y_LIGHT_TIME    DB 1
;R_LIGHT_TIME    DB 5 

CARS_NUMBER     DB 0x00 , 0x00 ; save number of cars from keypad
CARS_INFO_FLAG  DW 0x01        ; represent that the keypad output is lsb or msb of cars_number variable in memory.

shift           DB  0xFE , 0xFD , 0xFB , 0xF7
layout          DB  '7'  , '8' , '9' , '/' , '4' , '5' , '6' , '*' , '1' , '2' , '3' , '-' , 'C' , '0' , '=' , '+'
nmi_flag        DB  0x00             
 
;------------------------------------------------------------
 EQUATION_ASCII EQU 13
 CLEAR_ASCII EQU 19
.CODE
    

.STARTUP   
    
    PUSH    ES
    PUSH    DS
    POP     ES
    
    MOV     CX,0        
    PUSH    ES
    XOR     AX,AX
    MOV     ES,AX
    MOV     AL,2H
    XOR     AH,AH
    SHL     AX,1
    SHL     AX,1
    MOV     SI,AX
    MOV     AX,NMI     ; NMI function Name
    MOV     ES:[SI],AX
    INC     SI
    INC     SI
    MOV     BX,CS
    MOV     ES:[SI],BX
    
    POP     ES
;-----------------------------------------------------

;-----------------------------------------------------
    MOV AX,1000H          ; CHANGE STACK SEGMENT REG
    MOV SS,AX
    

    ;initializition of 8259
    MOV DX,8259_ICW1
    MOV AL,00010011B            ;edge trig. , single, ICW4 is needed
    OUT DX,AL                                                       
    
    MOV DX,8259_ICW2
    MOV AL,40H                  ;interrupt vector = 40H
    OUT DX,AL
    
    MOV DX,8259_ICW4
    MOV AL,00000011B            ;not fully nested, nonbuffered mode, auto EOI, for x86
    OUT DX,AL 
    
    MOV DX,8259_OCW1 
    MOV AL,0FEH                 ;mask all except IR0
    OUT DX,AL
    
    
    STI
    
    ;------------------
    
    
    MOV DX,8255A_CW
    MOV AL,10011000B            ; portA and portB are out and port C(0 - 3) are input and port C(4 - 7 ) are output
    OUT DX,AL
    
    
    ;------------------
    
    ;parallel communication & NMIE
    ;portA and portB are out and port C(0 - 3) are input and port C(4 - 7 ) are output
    MOV DX,8255B_CW
    MOV AL,10001000B
    OUT DX,AL   
       
       
    ;------------------
       
       
    ;parallel communication
    ;portA for inout data and portC for handshaking signals
    ;MOV DX,8255C_CW
    ;MOV AL,11000000B            ;portA & portC: mode 2 | portB: mode 0, output | PC0 - PC2: output
    ;OUT DX,AL   
      
        
    ;------------------  
    ;initialization of uart (8251)
    
    MOV DX,8251_S1
    MOV AL,40H                  ;internal reset
    ;OUT DX,AL      
    
    MOV AL,01001110B            ;stop bit: 1 / parity: d / data: 8 / baud rate: 16    
    OUT DX,AL
    
    MOV AL,00110111B            ;txRdy: enable / rxrdy: enable / all flags: reset 
    OUT DX,AL            
    
    ;------------------ 
        
       
    ;CALL TIMER      ;start timer 
    MOV DX,TIMER_COUNTER_CW
    MOV AL,00110100B           ;counter = 0, r/w: leat - most, mode = 2, binary
    OUT DX,AL
            
    MOV DX,TIMER_COUNTER_CW
    MOV AL,01110100B           ;counter = 1, r/w: leat - most, mode = 2, binary
    OUT DX,AL
    
    MOV DX,TIMER_COUNTER_CW
    MOV AL,10110100B           ;counter = 2, r/w: leat - most, mode = 2, binary
    OUT DX,AL 
            
            
    ;initialize value of counter 0
    MOV DX,TIMER_COUNTER0
    MOV AL,100D
    OUT DX,AL
    MOV AL,0D
    OUT DX,AL          
    
    ;initialize value of counter 1
    MOV DX,TIMER_COUNTER1
    MOV AL,10D
    OUT DX,AL
    MOV AL,0D
    OUT DX,AL          
    
    ;initialize value of counter 2
    MOV DX,TIMER_COUNTER2
    MOV AL,10D
    OUT DX,AL
    MOV AL,0D
    OUT DX,AL      
    
    
    ;enable NMIE
    MOV DX,8255A_PORTB
    OR AL,080H        
    OUT DX,AL

       
    BEGIN:
         
         
        XOR BH,BH
        
        
        FOR2: 
        CMP BH,3
        JLE BODY2
        JMP END2 
    
    
        BODY2:                
            MOV SI,BX
            SHR SI,8
             
            MOV AL ,shift[SI]  

            
            MOV DX,8255A_PORTC   
            OUT DX,AL    ; out to shift
            ADD BH,1
         
        JMP FOR2
        END2:

        ;MOV DX,8255A_PORTC
        ;MOV AL,0FFH
        ;OUT DX,AL
        ;CALL UART_SEND_PROC
    jmp BEGIN



;-------------------------

;-------------------------
    


.exit 

;--------------------------------------
; SEND DATA VIA UART
;-------------------------------------- 
UART_SEND_PROC PROC NEAR
    
    MOV DX,8251_S1
    TEST1: 
        IN AL,DX
        TEST AL,00000001B
        JZ TEST1 
        
    MOV DX,8251_S0
    MOV AL,CARS_NUMBER[1] 
    MOV CL,10
    MUL CL
    ADD AL,CARS_NUMBER[0]
    OUT DX,AL           
    OUT DX,AL           
    
         
      
    JMP WAIT_TO_UNPRESSED 
UART_SEND_PROC ENDP



;--------------------------------------
; RECEIVE DATA VIA UART
;--------------------------------------
UART_REC_PROC PROC NEAR
    MOV DX,8251_S1
    TEST4:
        IN AL,DX
        TEST AL,00000010B
        JZ TEST4
        
    MOV DX,8251_S0
    IN  AL,DX
    ADD BYTE PTR LIGHTS_TIME[0],AL
    SUB BYTE PTR LIGHTS_TIME[2],AL            
    
    JMP END_NMI_KEYPAD    
UART_REC_PROC ENDP


;--------------------------------------
; KEYPAP INSTALLATION
;--------------------------------------  

KEYPAD_NMI_PROC PROC NEAR USES AX , BX , CX
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    MOV BH,0    ; use BH for row
    MOV BL,-1   ; use BL for column
    MOV CL,0    ; use CL for position
    
         
    FOR: 
        
        CMP BH,3
        JLE BODY
        JMP END 
    
    
        BODY:                
            MOV SI,BX
            SHR SI,8
             
            MOV AL,shift[SI]  

            
            MOV DX,8255A_PORTC   
            OUT DX,AL    ; out to shift
    
            IN AL,DX     ; read whole port to check whether a button click or not
    
        COLUMN0:
            TEST AL,00010000B      ; if (pin4 = 0)
            JNZ COLUMN1
            MOV BL,0 
            MOV BYTE PTR nmi_flag,1
     
        COLUMN1:
            TEST AL,00100000B      ; if (pin5 = 0)
            JNZ COLUMN2
            MOV BL,1
            MOV BYTE PTR nmi_flag,1
    
        COLUMN2:
            TEST AL,01000000B
            JNZ COLUMN3
            MOV BL,2  
            MOV BYTE PTR nmi_flag,1
    
        COLUMN3:
            TEST AL,10000000B
            JNZ CLICKBUTTON
            MOV BL,3  
            MOV BYTE PTR nmi_flag,1 ; keyboard nmi enable
        
        CLICKBUTTON:
            CMP BL,-1
            JE ENDFOR
        
            SHL BH,2  ; row*4
            ADD BH,BL ; row*4 + column
            MOV CL,BH ; position = row*4 + column
    
            MOV BL,-1 ; column = -1
                
            MOV SI,CX
            AND SI,00FFH
           
            MOV AL,5
            MOV AL,layout[SI]
            SUB AL,48              ; current keypad input
                                      

                                                         
            MOV SI,CARS_INFO_FLAG
            CMP SI,-1              ; is buffer full                                                   
            JE  CLEAR_BUTTON       ; waiting for sending or refreshing data
             
         
         CLEAR_BUTTON:
            CMP AL,CLEAR_ASCII
            JNE ENTER_BUTTON
            MOV WORD PTR CARS_INFO_FLAG,1 ; 1 cars_info_flag
            
            MOV BYTE PTR CARS_NUMBER[0],0;  0 lsb of cars_number
            MOV BYTE PTR CARS_NUMBER[1],0;  0 msb of cars_number
            
            MOV DX,8255B_PORTB ; clear 7 segments 
            MOV AL,0
            OUT DX,AL 
            
            
            ;sending parallel data for test
            ;MOV DX,8255C_PORTA
            ;MOV AL,11110000B
            ;OUT DX,AL   
            
            ;MOV DX,8255C_PORTA
            ;MOV AL,10000000B
            ;OUT DX,AL
            
            JMP END
            
         
         ENTER_BUTTON:               
            CMP AL,EQUATION_ASCII  ; check = is pressed or not 
            JNE  SHOW_CARS_NUMBER  ; TODO : SHOULD BE CHENGED TO SEND DATA TO ANOTHER MICRO 
            CALL UART_SEND_PROC
  
             
          SHOW_CARS_NUMBER:
            MOV SI,CARS_INFO_FLAG
            MOV CARS_NUMBER[SI],AL 
            SUB SI,1
            MOV CARS_INFO_FLAG,SI
             
            MOV AL,CARS_NUMBER[0];   ;read lsb of cars number
            MOV AH,CARS_NUMBER[1];   ;read msb of cars number
            SHL AH,4                 ;shift msb 4 to right
            OR  AL,AH                ;prepare data to show in 7segments

                          
            MOV DX,8255B_PORTB 
            OUT DX,AL
             
         WAIT_TO_UNPRESSED:     ; wait utill that user upressed key
         
            MOV DX,8255A_PORTC
            IN  AL,DX
            SHR AL,4
            CMP AL,0x0F
            JNE WAIT_TO_UNPRESSED
            
            
        ENDFOR:
            ADD BH,1 ; row++
            JMP FOR
        
    END:    
        POP DX       
        POP CX
        POP BX
        POP AX 
        
        JMP END_NMI_KEYPAD



KEYPAD_NMI_PROC ENDP 
         
 
TIMER_NMI_PROC PROC    
    MOV     SI,LIGHT_STATUS                         ; SI = light_status
    CMP     SI,0
    JE      GREEN_LIGHT
    CMP     SI,1
    JE      YELLOW_LIGHT
    CMP     SI,2
    JE      RED_LIGHT
    
    GREEN_LIGHT:
        MOV DX,8255B_PORTC
        MOV AL,1
        OUT DX,AL
        JMP INVERSE_TIMER  
        
    YELLOW_LIGHT:
        MOV DX,8255B_PORTC
        MOV AL,2
        OUT DX,AL
        JMP INVERSE_TIMER 
    
    RED_LIGHT:
        MOV DX,8255B_PORTC
        MOV AL,4
        OUT DX,AL
        JMP INVERSE_TIMER               
    
                  
                  
    INVERSE_TIMER:
        ADD     BYTE PTR TIMER_PERIOD,1                 ;timer_period++ 
        MOV     BL,TIMER_PERIOD                         ; AX = timer_period   
        MOV     DX,8255B_PORTA 
        MOV     AL,LIGHTS_TIME[SI]
        SUB     AL,BL
        INC     AL 
        OUT     DX,AL
    
        CMP     AL,0                                    ; AL == lights_time[SI] 
        JE      NEXT_LIGHT
        JMP     END_NMI_KEYPAD
    
    
    NEXT_LIGHT:
        MOV     BYTE PTR TIMER_PERIOD,0
        INC     BYTE PTR LIGHT_STATUS 
        CMP     BYTE PTR LIGHT_STATUS,3
        JNE     END_NMI_KEYPAD 
        MOV     BYTE PTR LIGHT_STATUS,0     

    
    
    
    JZ      END_NMI_KEYPAD                          ; not equal --> continue counting
        
        
    
        ;MOV AL,LIGHTS_TIME[SI] 
    ;MOV AL,LIGHTS_TIME[SI]
    ;OUT DX,AL

TIMER_NMI_PROC ENDP        

;--------------------------------------
; NMI PROCEDURE
;--------------------------------------
NMI PROC 
   ;disable NMIE
   MOV DX,8255A_PORTB
   AND AL,07FH
   OUT DX,AL  
   
   MOV DX,8255A_PORTA                   ;check for uart nmi
   IN  AL,DX
   CMP AL,1
   JE  UART_NMI
    
   
   
   MOV DX,8255A_PORTC
   IN  AL,DX
       

   CMP  AL,0xF7
   
   JNZ  KEYPAD_NMI
     
                      
   TIMER_NMI:
        CALL TIMER_NMI_PROC
   
   KEYPAD_NMI: 
        CALL KEYPAD_NMI_PROC  
        
   UART_NMI:
        CALL UART_REC_PROC
   
           
                 
   END_NMI_KEYPAD:
        MOV BYTE PTR nmi_flag,0 ; restart nmi_flag
        
        ;enable NMIE
        MOV     DX,8255A_PORTB
        OR      AL,080H        
        OUT     DX,AL
        JMP     BEGIN 
        
   
        
NMI ENDP    


    
;-------------------------------------
; TINER INITILIZE
;-------------------------------------      
TIMER PROC USES AX,DX
    PUSH AX
    PUSH DX
    
   
    
    
    POP DX
    POP AX
    
    RET
    
TIMER ENDP                          

                          

;--------------------------------------
; DELAY PROCEDURE
;--------------------------------------
DELAY PROC NEAR USES CX
    MOV CX,1000
    D1:
    LOOP D1
    RET
DELAY ENDP
             
             
end






