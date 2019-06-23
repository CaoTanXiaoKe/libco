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


#ifndef __CO_ROUTINE_INNER_H__

#include "co_routine.h"
#include "coctx.h"
struct stCoRoutineEnv_t;
struct stCoSpec_t
{
	void *value;
};

struct stStackMem_t
{
	stCoRoutine_t* occupy_co;
	int stack_size;
	char* stack_bp; //stack_buffer + stack_size
	char* stack_buffer;

};

struct stShareStack_t
{
	unsigned int alloc_idx;
	int stack_size;
	int count;
	stStackMem_t** stack_array;
};



struct stCoRoutine_t
{
	// 同属于一个线程，所有协程的执行上下文环境。
	stCoRoutineEnv_t *env;

	// 协程函数
	pfn_co_routine_t pfn;

	// 协程函数参数
	void *arg;

	// 协程上下文, 即协程切换时，用于保存寄存器的值。
	coctx_t ctx;

	// 标识协程是否已经开始被执行。
	char cStart;

	// 标识协程是否已经被执行结束。
	char cEnd;

	// 标识是否是第一个协程(通常为main函数)
	char cIsMain;

	// 是否开启了 socket簇函数的hook
	char cEnableSysHook;

	// 是否开启了共享栈模式。
	char cIsShareStack;

	// 指向进程的 env。
	void *pvEnv;

	// 运行时栈, 128k。
	// char sRunStack[ 1024 * 128 ];
	stStackMem_t* stack_mem;


	// 由于运行时栈大小为 128k, 100万个协程，需要近 128G内存。为了节约内存，在共享栈模式下，
	// 当协程上下文切换时，会把运行时栈存放到缓冲区内(只存栈实际占用的内存大小)。下面的缓冲区即
	// 为了这个目的。
	//save satck buffer while confilct on same stack_buffer;
	char* stack_sp; 
	unsigned int save_size;
	char* save_buffer;

	stCoSpec_t aSpec[1024];

};



//1.env
void 				co_init_curr_thread_env();
stCoRoutineEnv_t *	co_get_curr_thread_env();

//2.coroutine
void    co_free( stCoRoutine_t * co );
void    co_yield_env(  stCoRoutineEnv_t *env );

//3.func



//-----------------------------------------------------------------------------------------------

struct stTimeout_t;
struct stTimeoutItem_t ;

stTimeout_t *AllocTimeout( int iSize );
void 	FreeTimeout( stTimeout_t *apTimeout );
int  	AddTimeout( stTimeout_t *apTimeout,stTimeoutItem_t *apItem ,uint64_t allNow );

struct stCoEpoll_t;
stCoEpoll_t * AllocEpoll();
void 		FreeEpoll( stCoEpoll_t *ctx );

stCoRoutine_t *		GetCurrThreadCo();
void 				SetEpoll( stCoRoutineEnv_t *env,stCoEpoll_t *ev );

typedef void (*pfnCoRoutineFunc_t)();

#endif

#define __CO_ROUTINE_INNER_H__
