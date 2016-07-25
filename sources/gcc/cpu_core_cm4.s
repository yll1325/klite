/******************************************************************************
* lowlevel cpu arch functions of Cortex-M4
* Copyright (C) 2015-2016 jiangxiaogang <kerndev@foxmail.com>
*
* This file is part of klite.
* 
* klite is free software; you can redistribute it and/or modify it under the 
* terms of the GNU Lesser General Public License as published by the Free 
* Software Foundation; either version 2.1 of the License, or (at your option) 
* any later version.
*
* klite is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* Lesser General Public License for more details.
*
* You should have received a copy of the GNU Lesser General Public
* License along with klite; if not, write to the Free Software
* Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
******************************************************************************/
	.syntax unified
	
	.equ TCB_OFFSET_STATE,	0
	.equ TCB_OFFSET_SP,	   	4
	.equ TCB_OFFSET_MAIN,	8
	.equ TCB_OFFSET_ARG,	12
	.equ NVIC_INT_CTRL,   	(0xE000ED04)
	.equ PEND_INT_SET,		(1<<28)
	
	.extern	kern_tcb_now
	.extern	kern_tcb_new
	.extern	kernel_tick
	.extern	kthread_exit
	
	.global cpu_irq_enable
	.global cpu_irq_disable
	.global cpu_tcb_switch
	.global cpu_tcb_init
	.global PendSV_Handler
	.global SysTick_Handler
	
	.thumb
	.section ".text"
	.align  4
	
cpu_irq_disable:
	.fnstart
	.cantunwind
	CPSID 	I
	BX		LR
	.fnend
	
cpu_irq_enable:
	.fnstart
	.cantunwind
	CPSIE 	I
	BX		LR
	.fnend
	
cpu_tcb_switch:
	.fnstart
	.cantunwind
	LDR		R0,=NVIC_INT_CTRL
	LDR		R1,=PEND_INT_SET
	STR		R1,[R0]
	BX		LR
	.fnend

PendSV_Handler:
	.fnstart
	.cantunwind
    CPSID   I
    LDR     R0, =kern_tcb_now
	LDR     R1, [R0]
	CBZ     R1, POPSTACK

	TST     LR,#0x10					//CHECK FPU
	IT      EQ
	VPUSHEQ	{S16-S31}
	PUSH	{LR}
    PUSH    {R4-R11}
    STR     SP, [R1,#TCB_OFFSET_SP]

POPSTACK:
    LDR     R2, =kern_tcb_new
	LDR     R3, [R2]
    STR     R3, [R0]
	MOV		R0, #0						//TCB_STAT_RUNNING
	STR		R0, [R3,#TCB_OFFSET_STATE]
	
    LDR     SP, [R3,#TCB_OFFSET_SP]
    POP     {R4-R11}
	POP		{LR}
	TST     LR,#0x10
	IT      EQ
	VPOPEQ	{S16-S31}
	
    CPSIE   I
    BX      LR
	.fnend
	
SysTick_Handler:
	.fnstart
	.cantunwind
	PUSH    {LR}
	LDR		R0, =kernel_tick
	BLX		R0
	POP		{LR}
	BX		LR
	.fnend
	
//void cpu_tcb_init(struct tcb* tcb, uint32_t sp_min, uint32_t sp_max)
cpu_tcb_init:
    .fnstart
    .cantunwind
	PUSH    {R12}
	LSR		R12,R2,#+3
    LSL    	R12,R12,#+3
	SUB     R12,R12,#+4
//xPSR = 0x01000000
	LDR		R3,=0x01000000
	STMDB   R12!,{R3}
//PC=tcb->main
	LDR		R3,[R0,#TCB_OFFSET_MAIN]
	STMDB   R12!,{R3}
//R14(LR)=kthread_exit
	LDR		R3,=kthread_exit
	STMDB   R12!,{R3}
//R12
	MOV		R3,#0
	STMDB   R12!,{R3}
//R1-R3
	MOV		R3,#0
	STMDB   R12!,{R3}
	STMDB   R12!,{R3}
	STMDB   R12!,{R3}
//R0
	LDR		R3,[R0,#TCB_OFFSET_ARG]
	STMDB   R12!,{R3}
//LR=0xFFFFFFF9;
	LDR		R3,=0xFFFFFFF9
	STMDB   R12!,{R3}
//R4-R11
	MOV		R3,#0
	STMDB   R12!,{R3}
	STMDB   R12!,{R3}
	STMDB   R12!,{R3}
	STMDB   R12!,{R3}
	STMDB   R12!,{R3}
	STMDB   R12!,{R3}
	STMDB   R12!,{R3}
	STMDB   R12!,{R3}
//tcb->sp = R12
	STR     R12,[R0, #TCB_OFFSET_SP]
	POP     {R12}
	BX		LR
	.fnend
	
	.end
	