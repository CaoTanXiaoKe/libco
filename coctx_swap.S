/*
* Tencent is pleased to support the open source community by making Libco available.

* Copyright (C) 2014 THL A29 Limited, a Tencent company. All rights reserved.
*
* Licensed under the Apache License, Version 2.0 (the "License"); 
* you may not use this file except in compliance with the License. 
* You may obtain a copy of the License at
*
*	http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, 
* software distributed under the License is distributed on an "AS IS" BASIS, 
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. 
* See the License for the specific language governing permissions and 
* limitations under the License.
*/

.globl coctx_swap
#if !defined( __APPLE__ ) && !defined( __FreeBSD__ )
.type  coctx_swap, @function
#endif
coctx_swap:

#if defined(__i386__)
	# leal(Load Effective Address)，保存 %esp+4 到 %eax
	# 可以认为保存当前协程栈sp的位置。 
	leal 4(%esp), %eax //sp 
	# 按照函数调用从右到左入栈的顺序，%esp指向了第一个参数: 当前协程 coctx_t 的位置
	movl 4(%esp), %esp 
	# 使得 %esp 指向 regs[] 数组，方便后续使用pushl保存寄存器的值。
	leal 32(%esp), %esp //parm a : &regs[7] + sizeof(void*)

	# 保存各寄存器的值。
	pushl %eax //esp ->parm a 

	pushl %ebp
	pushl %esi
	pushl %edi
	pushl %edx
	pushl %ecx
	pushl %ebx
	# -4(%eax)是刚进入该函数时，%esp指向的位置，即call压入的函数返回地址(PC寄存器的值)
	# 仍旧放到当前协程栈的栈顶，用作当前协程再次被调度时，ret跳转到原来地址的下一条指令。
	pushl -4(%eax)

	# %eax + 4 指向第二个参数，即目的协程的 coctx_t
	movl 4(%eax), %esp //parm b -> &regs[0]

	# 恢复各寄存器的值
	popl %eax  //ret func addr
	popl %ebx  
	popl %ecx
	popl %edx
	popl %edi
	popl %esi
	popl %ebp
	popl %esp
	pushl %eax //set ret func addr, 当前%esp指向该位置。

	# 清零 %eax
	xorl %eax, %eax
	# 跳转到目的协程的PC地址，开始执行目的协程。
	ret	

#elif defined(__x86_64__)
	# 保存 %rsp + 8 的值到 %rax
	leaq 8(%rsp),%rax
	# 使得 %rsp指向 regs[] 数组，方便后续使用pushl保存寄存器的值。
	leaq 112(%rdi),%rsp
	pushq %rax
	pushq %rbx
	pushq %rcx
	pushq %rdx

	# -8(%eax)是刚进入该函数时，%esp指向的位置，即call压入的函数返回地址(PC寄存器的值)
	# 仍旧放到当前协程栈的栈顶，用作当前协程再次被调度时，ret跳转到原来地址的下一条指令。
	pushq -8(%rax) //ret func addr

	pushq %rsi
	pushq %rdi
	pushq %rbp
	pushq %r8
	pushq %r9
	pushq %r12
	pushq %r13
	pushq %r14
	pushq %r15
	
	movq %rsi, %rsp
	popq %r15
	popq %r14
	popq %r13
	popq %r12
	popq %r9
	popq %r8
	popq %rbp
	popq %rdi
	popq %rsi
	popq %rax //ret func addr，当前%esp指向该位置。
	popq %rdx
	popq %rcx
	popq %rbx
	popq %rsp
	pushq %rax
	
	# 清零 %eax
	xorl %eax, %eax
	# 跳转到目的协程的PC地址，开始执行目的协程。
	ret
#endif
