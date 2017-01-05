 .386
.model flat,stdcall
option casemap:none

include         include/windows.inc
include         include/gdi32.inc
includelib      lib/gdi32.lib
include         include/user32.inc
includelib      lib/user32.lib
include         include/kernel32.inc
includelib      lib/kernel32.lib


IDI_ICON1       equ     101
ID_TIMER        equ     1
 
                .data?
hInstance       dd      ?
hWinMain        dd      ?
dwCenterX       dd      ?
dwCenterY       dd      ?
dwRadius        dd      ?
hMenu 		dd 	?

                .const
szClassName     db      'Clock',0
_dwPara180      dw      180
                .code


;==========================================================
;                      计算表中心点的坐标
;==========================================================
_CalcClockParam proc

       LOCAL   @stRect:RECT
       invoke  GetClientRect,hWinMain,addr @stRect
       mov     eax,@stRect.right
       sub     eax,@stRect.left            ;宽度
       mov     ecx,@stRect.bottom
       sub     ecx,@stRect.top            ;高度
       .if     eax > ecx
               mov edx,ecx
               sub eax,ecx
               shr eax,1
               mov dwCenterX,0
               mov dwCenterY,eax
       .else   
               mov edx,eax
        sub ecx,eax
        shr ecx,1
        mov dwCenterX,ecx
        mov dwCenterY,0
       .endif
       shr     edx,1
       mov     dwRadius,edx
       add     dwCenterX,edx
       add     dwCenterY,edx
       ret
       
_CalcClockParam endp


;==========================================================
;                        计算表针上端点的横坐标
;==========================================================
_CalcX          proc    _dwDegree,_dwRadius

       LOCAL   @dwReturn
       
       fild    dwCenterX
       fild    _dwDegree
       fldpi   
       fmul
       fild    _dwPara180
       fdivp   st(1),st
       fsin
       fild    _dwRadius
       fmul    
       fadd
       fistp   @dwReturn
       mov     eax,@dwReturn
       ret
_CalcX          endp

;==========================================================
;                        计算表针上端点的纵坐标
;==========================================================
_CalcY          proc    _dwDegree,_dwRadius


                LOCAL   @dwReturn
                
                fild    dwCenterY
                fild    _dwDegree
                fldpi
                fmul
                fild    _dwPara180
                fdivp   st(1),st
                fcos  
                fild    _dwRadius
                fmul
                fsubp   st(1),st
                fistp   @dwReturn
                mov     eax,@dwReturn
                ret
_CalcY          endp

;==========================================================
;                        画一个点
;==========================================================
_DrawDot        proc    _hDC,_dwDegreeInc,_dwRadius

       LOCAL   @dwNowDegree,@dwR
       LOCAL   @dwX,@dwY
       
       mov     @dwNowDegree,0
       mov     eax,dwRadius
       sub     eax,10
       mov     @dwR,eax
       .while  @dwNowDegree <= 360
               finit
               invoke _CalcX,@dwNowDegree,@dwR
               mov    @dwX,eax
               invoke _CalcY,@dwNowDegree,@dwR
               mov    @dwY,eax
              
               mov    eax,@dwX
               mov    ebx,eax
               mov    ecx,@dwY
               mov    edx,ecx
               sub    eax,_dwRadius
               add    ebx,_dwRadius
               sub    ecx,_dwRadius
               add    edx,_dwRadius
               invoke Ellipse,_hDC,eax,ecx,ebx,edx
               mov    eax,_dwDegreeInc
               add    @dwNowDegree,eax
       .endw
       ret


_DrawDot        endp

;==========================================================
;                        画一条直线
;==========================================================
_DrawLine       proc    _hDC,_dwDegree,_dwRadiusAdjust

       LOCAL   @dwR
       LOCAL   @dwX1,@dwY1,@dwX2,@dwY2
       
       mov     eax,dwRadius
       sub     eax,_dwRadiusAdjust
       mov     @dwR,eax
       invoke  _CalcX,_dwDegree,@dwR
       mov     @dwX1,eax
       invoke  _CalcY,_dwDegree,@dwR
       mov     @dwY1,eax
       add     _dwDegree,180
       invoke  _CalcX,_dwDegree,10           ;此处需注意     注意参数10
       mov     @dwX2,eax
       invoke  _CalcY,_dwDegree,10
       mov     @dwY2,eax
       invoke  MoveToEx,_hDC,@dwX1,@dwY1,NULL
       invoke  LineTo,_hDC,@dwX2,@dwY2
       ret


_DrawLine       endp
;==========================================================
;                        画出时钟
;==========================================================

_ShowTime       proc    _hWnd,_hDC

       LOCAL   @stTime:SYSTEMTIME
       
       pushad
       invoke  GetLocalTime,addr @stTime
       invoke  _CalcClockParam
       invoke  GetStockObject,BLACK_BRUSH
       invoke  SelectObject,_hDC,eax
       invoke  _DrawDot,_hDC,360/12,3
       invoke  _DrawDot,_hDC,360/60,1
       invoke  CreatePen,PS_SOLID,1,0
       invoke  SelectObject,_hDC,eax
       invoke  DeleteObject,eax
       movzx   eax,@stTime.wSecond
       mov     ecx,360/60
       mul     ecx
       invoke  _DrawLine,_hDC,eax,15
       invoke  CreatePen,PS_SOLID,2,0
       invoke  SelectObject,_hDC,eax
       invoke  DeleteObject,eax
       movzx   eax,@stTime.wMinute
       mov     ecx,360/60
       mul     ecx
       invoke  _DrawLine,_hDC,eax,20
       invoke  CreatePen,PS_SOLID,3,0
       invoke  SelectObject,_hDC,eax
       invoke  DeleteObject,eax
       movzx   eax,@stTime.wHour
       .if     eax >=12
        sub   eax,12
       .endif
       mov     ecx,360/12
       mul     ecx
       movzx   ecx,@stTime.wMinute
       shr     ecx,1                                
       add     eax,ecx
       invoke  _DrawLine,_hDC,eax,30
       ret


_ShowTime       endp
;=============================================================
;                     主窗口消息处理函数
;=============================================================

_ProcWinMain    proc    uses ebx edi esi hWnd,uMsg,wParam,lParam
                LOCAL   @stPS:PAINTSTRUCT
                LOCAL   @stPos:POINT
                mov     eax,uMsg
                .if     eax == WM_TIMER
                invoke InvalidateRect,hWnd,NULL,TRUE
                .elseif eax == WM_PAINT
                invoke BeginPaint,hWnd,addr @stPS
                invoke _ShowTime,hWnd,eax
                invoke EndPaint,hWnd,addr @stPS
                .elseif eax == WM_RBUTTONDOWN
			.if wParam == MK_RBUTTON
				invoke GetCursorPos,addr @stPos
				invoke TrackPopupMenu,hMenu,TPM_LEFTALIGN,@stPos.x,@stPos.y,NULL,hWnd,NULL
			.endif
                .elseif eax == WM_CREATE
                        	invoke SetTimer,hWnd,ID_TIMER,1000,NULL
                        
                .elseif eax == WM_LBUTTONDOWN
			invoke UpdateWindow,hWnd ;即时刷新
			invoke ReleaseCapture	
			invoke SendMessage,hWnd,WM_NCLBUTTONDOWN,HTCAPTION,0
                .elseif eax == WM_CLOSE
                	invoke KillTimer,hWnd,ID_TIMER
                	invoke DestroyWindow,hWinMain
                	invoke PostQuitMessage,NULL
                .else   
                        invoke DefWindowProc,hWnd,uMsg,wParam,lParam
                ret
                .endif
                xor     eax,eax
                ret
_ProcWinMain    endp

;=========================================================================
;                                主窗口
;=========================================================================
_WinMain        proc    

       LOCAL   @stWndClass:WNDCLASSEX
       LOCAL   @stMsg:MSG
       LOCAL	@hrgn:dword
       invoke  GetModuleHandle,NULL
       mov     hInstance,eax
       invoke  RtlZeroMemory,addr @stWndClass,sizeof @stWndClass
       invoke  LoadIcon,hInstance,IDI_ICON1
       mov     @stWndClass.hIcon,eax
       mov     @stWndClass.hIconSm,eax
       invoke LoadMenu,hInstance,IDI_ICON1
	invoke GetSubMenu,eax,0 ;PopUp 菜单要用到子菜单
	mov hMenu,eax
       invoke  LoadCursor,0,IDC_ARROW
       mov     @stWndClass.hCursor,eax
       push    hInstance
       pop     @stWndClass.hInstance
       mov     @stWndClass.cbSize,sizeof WNDCLASSEX
       mov     @stWndClass.style,CS_HREDRAW or CS_VREDRAW
       mov     @stWndClass.lpfnWndProc,offset _ProcWinMain
       mov     @stWndClass.hbrBackground,COLOR_WINDOW + 1
       mov     @stWndClass.lpszClassName,offset szClassName
       invoke  RegisterClassEx,addr @stWndClass
       invoke  CreateWindowEx,WS_EX_CLIENTEDGE,offset szClassName,offset szClassName,\
               WS_POPUP,100,100,270,270,NULL,NULL,hInstance,NULL
       mov     hWinMain,eax
       
       invoke	CreateEllipticRgn, 0,0,270,270
       mov @hrgn, eax
       invoke	SetWindowRgn, hWinMain, @hrgn,TRUE
       invoke  ShowWindow,hWinMain,SW_SHOWNORMAL
       invoke  UpdateWindow,hWinMain
       .while  TRUE
        invoke  GetMessage,addr @stMsg,NULL,0,0
        .break  .if eax ==0
        invoke  TranslateMessage,addr @stMsg
        invoke  DispatchMessage,addr @stMsg 
       .endw
       ret
_WinMain        endp


start:
                call    _WinMain
                invoke  ExitProcess,NULL
                
end     start

dwCenterX       dd      ?
dwCenterY       dd      ?
dwRadius        dd      ?


                .const
szClassName     db      'Clock',0
_dwPara180      dw      180
                .code


;==========================================================
;                      计算表中心点的坐标
;==========================================================
_CalcClockParam proc

       LOCAL   @stRect:RECT
       invoke  GetClientRect,hWinMain,addr @stRect
       mov     eax,@stRect.right
       sub     eax,@stRect.left            ;宽度
       mov     ecx,@stRect.bottom
       sub     ecx,@stRect.top            ;高度
       .if     eax > ecx
               mov edx,ecx
               sub eax,ecx
               shr eax,1
               mov dwCenterX,0
               mov dwCenterY,eax
       .else   
               mov edx,eax
        sub ecx,eax
        shr ecx,1
        mov dwCenterX,ecx
        mov dwCenterY,0
       .endif
       shr     edx,1
       mov     dwRadius,edx
       add     dwCenterX,edx
       add     dwCenterY,edx
       ret
       
_CalcClockParam endp


;==========================================================
;                        计算表针上端点的横坐标
;==========================================================
_CalcX          proc    _dwDegree,_dwRadius

       LOCAL   @dwReturn
       
       fild    dwCenterX
       fild    _dwDegree
       fldpi   
       fmul
       fild    _dwPara180
       fdivp   st(1),st
       fsin
       fild    _dwRadius
       fmul    
       fadd
       fistp   @dwReturn
       mov     eax,@dwReturn
       ret
_CalcX          endp

;==========================================================
;                        计算表针上端点的纵坐标
;==========================================================
_CalcY          proc    _dwDegree,_dwRadius


                LOCAL   @dwReturn
                
                fild    dwCenterY
                fild    _dwDegree
                fldpi
                fmul
                fild    _dwPara180
                fdivp   st(1),st
                fcos  
                fild    _dwRadius
                fmul
                fsubp   st(1),st
                fistp   @dwReturn
                mov     eax,@dwReturn
                ret
_CalcY          endp

;==========================================================
;                        画一个点
;==========================================================
_DrawDot        proc    _hDC,_dwDegreeInc,_dwRadius

       LOCAL   @dwNowDegree,@dwR
       LOCAL   @dwX,@dwY
       
       mov     @dwNowDegree,0
       mov     eax,dwRadius
       sub     eax,10
       mov     @dwR,eax
       .while  @dwNowDegree <= 360
               finit
               invoke _CalcX,@dwNowDegree,@dwR
               mov    @dwX,eax
               invoke _CalcY,@dwNowDegree,@dwR
               mov    @dwY,eax
              
               mov    eax,@dwX
               mov    ebx,eax
               mov    ecx,@dwY
               mov    edx,ecx
               sub    eax,_dwRadius
               add    ebx,_dwRadius
               sub    ecx,_dwRadius
               add    edx,_dwRadius
               invoke Ellipse,_hDC,eax,ecx,ebx,edx
               mov    eax,_dwDegreeInc
               add    @dwNowDegree,eax
       .endw
       ret


_DrawDot        endp

;==========================================================
;                        画一条直线
;==========================================================
_DrawLine       proc    _hDC,_dwDegree,_dwRadiusAdjust

       LOCAL   @dwR
       LOCAL   @dwX1,@dwY1,@dwX2,@dwY2
       
       mov     eax,dwRadius
       sub     eax,_dwRadiusAdjust
       mov     @dwR,eax
       invoke  _CalcX,_dwDegree,@dwR
       mov     @dwX1,eax
       invoke  _CalcY,_dwDegree,@dwR
       mov     @dwY1,eax
       add     _dwDegree,180
       invoke  _CalcX,_dwDegree,10           ;此处需注意     注意参数10
       mov     @dwX2,eax
       invoke  _CalcY,_dwDegree,10
       mov     @dwY2,eax
       invoke  MoveToEx,_hDC,@dwX1,@dwY1,NULL
       invoke  LineTo,_hDC,@dwX2,@dwY2
       ret


_DrawLine       endp
;==========================================================
;                        画出时钟
;==========================================================

_ShowTime       proc    _hWnd,_hDC

       LOCAL   @stTime:SYSTEMTIME
       
       pushad
       invoke  GetLocalTime,addr @stTime
       invoke  _CalcClockParam
       invoke  GetStockObject,BLACK_BRUSH
       invoke  SelectObject,_hDC,eax
       invoke  _DrawDot,_hDC,360/12,3
       invoke  _DrawDot,_hDC,360/60,1
       invoke  CreatePen,PS_SOLID,1,0
       invoke  SelectObject,_hDC,eax
       invoke  DeleteObject,eax
       movzx   eax,@stTime.wSecond
       mov     ecx,360/60
       mul     ecx
       invoke  _DrawLine,_hDC,eax,15
       invoke  CreatePen,PS_SOLID,2,0
       invoke  SelectObject,_hDC,eax
       invoke  DeleteObject,eax
       movzx   eax,@stTime.wMinute
       mov     ecx,360/60
       mul     ecx
       invoke  _DrawLine,_hDC,eax,20
       invoke  CreatePen,PS_SOLID,3,0
       invoke  SelectObject,_hDC,eax
       invoke  DeleteObject,eax
       movzx   eax,@stTime.wHour
       .if     eax >=12
        sub   eax,12
       .endif
       mov     ecx,360/12
       mul     ecx
       movzx   ecx,@stTime.wMinute
       shr     ecx,1                                
       add     eax,ecx
       invoke  _DrawLine,_hDC,eax,30
       ret


_ShowTime       endp
;=============================================================
;                     主窗口消息处理函数
;=============================================================

_ProcWinMain    proc    uses ebx edi esi hWnd,uMsg,wParam,lParam
                LOCAL   @stPS:PAINTSTRUCT
                
                mov     eax,uMsg
                .if     eax == WM_TIMER
                invoke InvalidateRect,hWnd,NULL,TRUE
                .elseif eax == WM_PAINT
                invoke BeginPaint,hWnd,addr @stPS
                invoke _ShowTime,hWnd,eax
                invoke EndPaint,hWnd,addr @stPS
                .elseif eax == WM_RBUTTONDOWN
			.if wParam == MK_RBUTTON
				invoke GetCursorPos,addr @stPos
				invoke TrackPopupMenu,hMenu,TPM_LEFTALIGN,@stPos.x,@stPos.y,NULL,hWnd,NULL
			.endif
                .elseif eax == WM_CREATE
                        	invoke SetTimer,hWnd,ID_TIMER,1000,NULL
                        
                .elseif eax == WM_LBUTTONDOWN
			invoke UpdateWindow,hWnd ;即时刷新
			invoke ReleaseCapture	
			invoke SendMessage,hWnd,WM_NCLBUTTONDOWN,HTCAPTION,0
                .elseif eax == WM_CLOSE
                	invoke KillTimer,hWnd,ID_TIMER
                	invoke DestroyWindow,hWinMain
                	invoke PostQuitMessage,NULL
                .else   
                        invoke DefWindowProc,hWnd,uMsg,wParam,lParam
                ret
                .endif
                xor     eax,eax
                ret
_ProcWinMain    endp

;=========================================================================
;                                主窗口
;=========================================================================
_WinMain        proc    

       LOCAL   @stWndClass:WNDCLASSEX
       LOCAL   @stMsg:MSG
       LOCAL	@hrgn:dword
       invoke  GetModuleHandle,NULL
       mov     hInstance,eax
       invoke  RtlZeroMemory,addr @stWndClass,sizeof @stWndClass
       invoke  LoadIcon,hInstance,IDI_ICON1
       mov     @stWndClass.hIcon,eax
       mov     @stWndClass.hIconSm,eax
       invoke  LoadCursor,0,IDC_ARROW
       mov     @stWndClass.hCursor,eax
       push    hInstance
       pop     @stWndClass.hInstance
       mov     @stWndClass.cbSize,sizeof WNDCLASSEX
       mov     @stWndClass.style,CS_HREDRAW or CS_VREDRAW
       mov     @stWndClass.lpfnWndProc,offset _ProcWinMain
       mov     @stWndClass.hbrBackground,COLOR_WINDOW + 1
       mov     @stWndClass.lpszClassName,offset szClassName
       invoke  RegisterClassEx,addr @stWndClass
       invoke  CreateWindowEx,WS_EX_CLIENTEDGE,offset szClassName,offset szClassName,\
               WS_POPUP,100,100,270,270,NULL,NULL,hInstance,NULL
       mov     hWinMain,eax
       
       invoke	CreateEllipticRgn, 0,0,270,270
       mov @hrgn, eax
       invoke	SetWindowRgn, hWinMain, @hrgn,TRUE
       invoke  ShowWindow,hWinMain,SW_SHOWNORMAL
       invoke  UpdateWindow,hWinMain
       .while  TRUE
        invoke  GetMessage,addr @stMsg,NULL,0,0
        .break  .if eax ==0
        invoke  TranslateMessage,addr @stMsg
        invoke  DispatchMessage,addr @stMsg 
       .endw
       ret
_WinMain        endp


start:
                call    _WinMain
                invoke  ExitProcess,NULL
                
end     start
