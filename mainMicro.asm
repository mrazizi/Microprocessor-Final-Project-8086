;main micro


;address names are written backwards
.8086
.MODEL SMALL
.STACK 1024

.DATA

PORTA_8255A     EQU 0x0200
PORTB_8255A     EQU 0x0202
PORTC_8255A     EQU 0x0204
CW_8255A        EQU 0x0206      


ICW1_8259       EQU 0x1000
ICW2_8259       EQU 0x1002
ICW4_8259       EQU 0x1002
OCW1_8259       EQU 0X1002

CW_8251         EQU 0x0802
MW_8251         EQU 0x0802
STATUS_8251     EQU 0x0802  
TX_8251         EQU 0x0800
  
S0_MICRO1_8251         EQU 0x0800
S1_MICRO1_8251         EQU 0x0802

  
S0_MICRO2_8251         EQU 0x0400
S1_MICRO2_8251         EQU 0x0402


CARS_NUMBER_MICRO1     DB 0x00        ; save number of cars that's sent from local micro 1
CARS_NUMBER_MICRO2     DB 0x00        ; save number of cars that's sent from local micro 2


CARS_INFO_FLAG         DW 0x01        ; represent that the keypad output is lsb or msb of cars_number variable in memory.
UART_SEND_FLAG         DB 0x00    

BCD1                   DB 2 DUP(0)
BCD2                   DB 2 DUP(0)       
 
;------------------------------------------------------------
 EQUATION_ASCII EQU 13
 CLEAR_ASCII EQU 19
.CODE
.STARTUP    
    
    
    ;NMI initialization:
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
    MOV CX,0
;-----------------------------------------------------

;-----------------------------------------------------
    START:
        ;XOR AX,AX
        ;MOV DS,AX
        
        ;MOV DS:[100H], OFFSET REC_DATA_MICRO1_ISR40
        ;MOV DS:[102H], CS
    
        ;MOV DX,OFFSET START
        ;SHR DX,4
        ;INC DX
        ;MOV AX,3100H
        ;INT 21H
          
    
    
    MOV AX,1000H          ; CHANGE STACK SEGMENT REG
    MOV SS,AX
    

    ;initializition of 8259
    MOV DX,ICW1_8259
    MOV AL,00010011B            ;edge trig. , single, ICW4 is needed
    OUT DX,AL                                                       
    
    MOV DX,ICW2_8259
    MOV AL,40H                  ;interrupt vector = 40H
    OUT DX,AL
    
    MOV DX,ICW4_8259
    MOV AL,00000011B            ;not fully nested, nonbuffered mode, auto EOI, for x86
    OUT DX,AL 
    
    MOV DX,OCW1_8259 
    MOV AL,0FCH                 ;mask all except IR0 , IR1
    OUT DX,AL
    
    
    STI
    
    ;------------------
    
    
    MOV DX,CW_8255A
    MOV AL,10001011B            ; portA is output and portB is input and port C(0 - 3) are input and port C(4 - 7 ) are input
    OUT DX,AL
    
 
    ;------------------  
    ;initialization of uart (8251)
    
    MOV DX,S1_MICRO1_8251
    MOV AL,40H                  ;internal reset
    ;OUT DX,AL      
    
    MOV AL,01001110B            ;stop bit: 1 / parity: d / data: 8 / baud rate: 16    
    OUT DX,AL
    
    MOV AL,00110111B            ;txRdy: enable / rxrdy: enable / all flags: reset 
    OUT DX,AL 
    
    ;----
    
    MOV DX,S1_MICRO2_8251
    MOV AL,40H                  ;internal reset
    ;OUT DX,AL      
    
    MOV AL,01001110B            ;stop bit: 1 / parity: d / data: 8 / baud rate: 16    
    OUT DX,AL
    
    MOV AL,00110111B            ;txRdy: enable / rxrdy: enable / all flags: reset 
    OUT DX,AL            
    
;------------------------- 
      
        
    ;enable NMIE
    MOV DX,PORTB_8255A
    OR AL,080H        
    OUT DX,AL
    
    
       
    BEGIN:
         
        
    jmp BEGIN



;-------------------------
    


.exit 

;--------------------------------------
; SEND DATA VIA UART TO MICRO1
;-------------------------------------- 
UART_SEND_MICRO1_PROC PROC NEAR
   
    
    MOV DX,S1_MICRO1_8251
    TEST1: 
        IN AL,DX
        TEST AL,00000001B
        JZ TEST1   
     
   
    MOV DX,S0_MICRO1_8251
    MOV AL,CL
    OUT DX,AL
    OUT DX,AL 
    
    MOV AL,UART_SEND_FLAG                       
    
    CMP AL,1                            ; micro1 = 1  ---- micro2 = -1
    JE  TIME_PROCESSING_MICRO1_50_2
    
    CMP AL,2                            ; micro1 = -1 ---- micro2 = 1
    JE  TIME_PROCESSING_MICRO1_40_2  
    
    CMP AL,3
    JE  TIME_PROCESSING_MICRO2_50_2     ; micro1 = -1 ---- micro2 = 1 
    
    CMP AL,4
    JE  TIME_PROCESSING_MICRO2_40_2     ; micro1 = 1  ---- micro2 = -1
     
 
UART_SEND_MICRO1_PROC ENDP
   

;--------------------------------------
; SEND DATA VIA UART TO MICRO2
;--------------------------------------

UART_SEND_MICRO2_PROC PROC NEAR
   
    
    MOV DX,S1_MICRO2_8251
    TEST2: 
        IN AL,DX
        TEST AL,00000001B
        JZ TEST2   
     
   
    MOV DX,S0_MICRO2_8251
    MOV AL,CL
    OUT DX,AL
    OUT DX,AL 
    
    CMP AL,1                            
    JE  END_TIME_PROCESSING_MICRO1
    
    CMP AL,2                            
    JE  END_TIME_PROCESSING_MICRO1  
    
    CMP AL,3
    JE  END_TIME_PROCESSING_MICRO2     
    
    CMP AL,4
    JE  END_TIME_PROCESSING_MICRO2      
          
UART_SEND_MICRO2_PROC ENDP
    
 
  
    
                      
;--------------------------------------
; RECIEVE DATA FROM UART FROM MICRO1
;--------------------------------------   
UART_REC_MICRO1_PROC PROC NEAR  
    MOV DX,S1_MICRO1_8251
    MOV AX,0
    TEST3: 
        
        IN AL,DX
        TEST AL,00000010B
        JZ TEST3
        
    MOV DX,S0_MICRO1_8251
    IN  AL,DX
    MOV CARS_NUMBER_MICRO1 , AL                        
                            
    
    ;binary to BCD Convert
    MOV CL,64H
    DIV CL
    MOV BCD1+1,AL
    MOV AL,AH
    MOV AH,00H
    MOV CL,0AH
    DIV CL
    MOV CL,04
    ROR AL,CL
    ADD AL,AH
    MOV AH,4CH                         
  
    
    UART_REC_MICRO1_SHOW:
        MOV DX,PORTA_8255A 
        OUT DX,AL  
    
    CALL TIME_PROCESSING_MICRO1_PROC
    
    
    JMP END_NMI
     
UART_REC_MICRO1_PROC ENDP       
                    
                    
               
    
;--------------------------------------
; RECIEVE DATA FROM UART FROM MICRO2
;--------------------------------------   
UART_REC_MICRO2_PROC PROC NEAR  
    MOV DX,S1_MICRO2_8251
    MOV AX,0
    TEST4:
        IN AL,DX
        TEST AL,00000010B
        JZ TEST4
        
    MOV DX,S0_MICRO2_8251
    IN  AL,DX
    MOV CARS_NUMBER_MICRO2 , AL 
    
    
    ;binary to BCD Convert
    MOV CL,64H
    DIV CL
    MOV BCD2+1,AL
    MOV AL,AH
    MOV AH,00H
    MOV CL,0AH
    DIV CL
    MOV CL,04
    ROR AL,CL
    ADD AL,AH
    MOV AH,4CH 
    
    
    MOV DX,PORTA_8255A 
    OUT DX,AL                
    
    CALL TIME_PROCESSING_MICRO2_PROC
    
    JMP END_NMI
     
UART_REC_MICRO2_PROC ENDP      
    
      
      
;--------------------------------------
; TIME_PROCESSING_MICRO1: 
;   CALCULATES TIME BASED ON 
;   CARS_NUMBER_MICRO1 AND CALLS   
;   UART_SEND TO BOTH MICROS
;--------------------------------------    
TIME_PROCESSING_MICRO1_PROC PROC NEAR 
    MOV BL,CARS_NUMBER_MICRO1
    
    CMP BL,50                                   ;if cars_number_mucro1 <= 50 then jmp to next_check
    JLE NEXT_CHECK_MICRO1
    
    TIME_PROCESSING_MICRO1_50_1:
        MOV CL,1                                ;micro1: green_light++ and red_light--  
        MOV UART_SEND_FLAG,1
        CALL UART_SEND_MICRO1_PROC
    
    
    TIME_PROCESSING_MICRO1_50_2:
        MOV CL,0FFH                             ;micro2: green_light-- and red_light++
        CALL UART_SEND_MICRO2_PROC
    
    
    
    
    NEXT_CHECK_MICRO1:
        CMP BL,40                               ;if cars_number_mucro1 >= 40 then jmp to end
        JGE END_TIME_PROCESSING_MICRO1
    
        TIME_PROCESSING_MICRO1_40_1:
            MOV  CL,0FFH                        ;micro1: green_light-- and red_light++ 
            MOV  UART_SEND_FLAG,2
            CALL UART_SEND_MICRO1_PROC
            
        TIME_PROCESSING_MICRO1_40_2:
            MOV  CL,1                           ;micro2: green_light++ and red_light--             
            CALL UART_SEND_MICRO2_PROC
    
    END_TIME_PROCESSING_MICRO1:
        JMP END_NMI
TIME_PROCESSING_MICRO1_PROC ENDP   








;--------------------------------------
; TIME_PROCESSING_MICRO2: 
;   CALCULATES TIME BASED ON 
;   CARS_NUMBER_MICRO1 AND CALLS   
;   UART_SEND TO BOTH MICROS
;--------------------------------------    
TIME_PROCESSING_MICRO2_PROC PROC NEAR 
    MOV BL,CARS_NUMBER_MICRO2
    
    CMP BL,50                                   ;if cars_number_mucro1 <= 50 then jmp to next_check
    JLE NEXT_CHECK_MICRO2
    
    TIME_PROCESSING_MICRO2_50_1:
        MOV CL,0FFH                             ;micro1: green_light-- and red_light++  
        MOV UART_SEND_FLAG,3
        CALL UART_SEND_MICRO1_PROC
    
    
    TIME_PROCESSING_MICRO2_50_2:
        MOV CL,1                                ;micro2: green_light++ and red_light--
        CALL UART_SEND_MICRO2_PROC
    
    
    
    
    NEXT_CHECK_MICRO2:
        CMP BL,40                               ;if cars_number_mucro1 >= 40 then jmp to end
        JGE END_TIME_PROCESSING_MICRO1
    
        TIME_PROCESSING_MICRO2_40_1:
            MOV  CL,1                           ;micro1: green_light++ and red_light--
            MOV  UART_SEND_FLAG,4
            CALL UART_SEND_MICRO1_PROC
            
        TIME_PROCESSING_MICRO2_40_2:
            MOV  CL,0FFH                         ;micro2: green_light-- and red_light++         
            CALL UART_SEND_MICRO2_PROC
    
    END_TIME_PROCESSING_MICRO2:
        JMP END_NMI
TIME_PROCESSING_MICRO2_PROC ENDP


    
       

    
    
    
 
 
    
;--------------------------------------
; NMI PROCEDURE
;--------------------------------------
NMI PROC 
   ;disable NMIE
    MOV DX,PORTB_8255A
    AND AL,07FH
    OUT DX,AL
   
    MOV DX,PORTC_8255A                       ;checking to see which 8259 gives(?) NMI
    IN  AL,DX
    
    CMP AL,2
    JE  UART2_REC_DATA
    CMP AL,1
    JE  UART1_REC_DATA
    JMP END_NMI
   
    UART1_REC_DATA: 
        CALL UART_REC_MICRO1_PROC    
        
    UART2_REC_DATA:
        CALL UART_REC_MICRO2_PROC
   
   END_NMI:
   ;enable NMIE
   MOV     DX,PORTB_8255A
   OR      AL,080H        
   OUT     DX,AL
   JMP     BEGIN 
        
NMI ENDP    
            
end








  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
      
    ;REC_DATA_MICRO1_ISR40 PROC FAR
    ;    MOV DX,PORTA_8255A
    ;    MOV AL,50
    ;    OUT DX,AL

        
    ;    IRET    
    ;REC_DATA_MICRO1_ISR40 ENDP 