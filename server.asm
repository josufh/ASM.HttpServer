; Reference: https://gaultier.github.io/blog/x11_x64.html

BITS 64 ; 64 bit asm
CPU X64 ; Target the x86_64 family

%include "constants.inc"

; System V ABI:
;  rax <- SYS_CODE
;  rdi rsi rdx rcx r8 r9 STACK
;  return value usually on rax

section .rodata
  index_path db "pages/index.html", 0

  http_ok db "HTTP/1.1 200 OK", 13, 10
  http_ok_len equ $ - http_ok
  content_type db "Content-Type: text/html", 13, 10, 13, 10
  content_type_len equ $ - content_type
  content_length_header db "Content-Length: ", 0
  content_length_len equ $ - content_length_header
  newline db 13, 10, 13, 10

section .bss
  sockfd resq 1
  clientfd resq 1
  client_addr resb 16
  client_addr_len resq 1

  file_buf resb 65536

section .text ; This tells the compiler and linker that the text that follows is executable

; Create a AF_INET domain socket, bind the port and listen to it
setup_http_server:
static setup_http_server:function
  push rbp
  mov rbp, rsp

  ; socket(AF_INET, SOCK_STREAM, 0)
  mov rax, SYS_SOCKET
  mov rdi, AF_INET
  mov rsi, SOCK_STREAM
  mov rdx, 0
  syscall

  mov [sockfd], rax ; Assign de sockfd
  cmp rax, 0
  jle crash

  %define sockaddr_in_len 16
  sub rsp, sockaddr_in_len ; Store struct sockaddr_in on the stack

  mov WORD [rsp], AF_INET ; Set sockaddr_in.sin_family = AF_INET
  mov ax, PORT ; htons(PORT)
  xchg al, ah
  mov WORD [rsp + 2], ax
  mov DWORD [rsp + 4], INADDR_ANY ; 0.0.0.0
  mov QWORD [rsp + 8], 0 ; Padding
  
  ; bind(sockfd, {AF_INET, htons(PORT), INADDR_ANY}, 16)
  mov rax, SYS_BIND
  mov rdi, [sockfd]
  lea rsi, [rsp]
  mov rdx, sockaddr_in_len
  syscall 

  cmp rax, 0
  jl crash

  ; listen(sockfd, backlog)
  mov rax, SYS_LISTEN
  mov rdi, [sockfd]
  mov rsi, BACKLOG
  syscall

  cmp rax, 0
  jl crash

  add rsp, sockaddr_in_len
  pop rbp
  ret

accept_loop:
static accept_loop:function
  ; clientfd = accept([sockfd], client_addr, client_addr_len)
  mov rax, SYS_ACCEPT
  mov rdi, [sockfd]
  lea rsi, [client_addr]
  lea rdx, [client_addr_len]
  syscall

  mov [clientfd], rax
  cmp rax, 0
  jle crash

  ; open("pages/index.html", ro)
  mov rax, SYS_OPEN
  lea rdi, [index_path]
  mov rsi, O_RDONLY
  syscall

  cmp rax, 0
  jle crash

  ; File fd
  mov r12, rax

  ; read([fd], buffer, len)
  mov rax, SYS_READ
  mov rdi, r12
  lea rsi, [file_buf]
  mov rdx, 65536
  syscall

  ; File length
  mov r12, rax

  mov rax, SYS_CLOSE
  mov rdi, r12
  syscall

  ; write([clientfd], [http_ok], http_ok_len)
  mov rax, SYS_WRITE
  mov rdi, [clientfd]
  lea rsi, [http_ok]
  mov rdx, http_ok_len
  syscall

  mov rax, SYS_WRITE
  mov rdi, [clientfd]
  lea rsi, [content_type]
  mov rdx, content_type_len
  syscall

  mov rax, SYS_WRITE
  mov rdi, [clientfd]
  lea rsi, [file_buf]
  mov rdx, r12
  syscall

  mov rax, SYS_CLOSE
  mov rdi, [clientfd]
  syscall

  ret

crash:
  mov rdx, 1

; rax: exit code 
return:
  ; close([sockfd])
  mov rax, SYS_CLOSE
  mov rdi, [sockfd]
  syscall

  ; close([clientfd])
  mov rax, SYS_CLOSE
  mov rdi, [clientfd]
  syscall

  ; exit([rdi])
  mov rax, SYS_EXIT
  mov rdi, rdx
  syscall

_start:
global _start:function
  call setup_http_server
  call accept_loop

  mov rdx, 0
  jmp return
