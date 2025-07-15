%include "errors.asm"
%include "constants.inc"
;extern index_page
;extern index_page_end
;extern about_page
;extern about_page_end

section .data
  listen_socket dq 0
  client_socket dq 0

  http_ok_response db 'HTTP/1.1 200 OK', 13, 10
  content_type_header db 'Content-Type: text/html', 13, 10
  content_length_header db 'Content-Length: ', 0
  ; newline db 13, 10, 13, 10

  request_buffer times 1024 db 0

  ; Available routes
  index_route db 'GET / ', 0
  about_route db 'GET /about ', 0

section .bss
  sockfd resq 1
  sockaddr resb 16

  content_length_str resb 20

section .text
  global _start

; Linux syscall register order
; rax, rdi, rsi, rdx, r10, r8, r9

_start:
  ; Create socket
  mov rax, SYS_SOCKET
  mov rdi, AF_INET
  mov rsi, SOCK_STREAM
  mov rdx, 0 ; default protocol TCP
  syscall
  ; Check creation error
  test rax, rax
  js fail_socket_create
  mov [sockfd], rax

  ;-------------------------
  ; Build sockaddr_in struct
  ; struct sockaddr_in {
  ;   short sin_family;
  ;   short sin_port;
  ;   int   sin_addr;
  ;   char  zero[8];
  ; }
  ;------------------------
  mov word  [sockaddr + 0], AF_INET
  mov ax, PORT ; htons(PORT)
  xchg al, ah
  mov word  [sockaddr + 2], ax
  mov dword [sockaddr + 4], INADDR_ANY
  mov qword [sockaddr + 8], 0

  ; Bind socket
  mov rax, SYS_BIND
  mov rdi, [sockfd]
  lea rsi, [sockaddr]
  mov rdx, 16 ; addrlen
  syscall
  ; Check binding error
  test rax, rax
  js fail_port_bind
  

  ; normal exit
  mov rax, 60 ; SYS_EXIT
  xor rdi, rdi
  syscall

fail_socket_create:
  mov rdi, 0 ; socket create error
  call print_error

fail_port_bind:
  neg rax
  

  mov rdi, 1 ; port bind error
  call print_error
