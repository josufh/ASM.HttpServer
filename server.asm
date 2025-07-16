%include "errors.asm"
%include "constants.inc"
;extern index_page
;extern index_page_end
;extern about_page
;extern about_page_end

section .data
  listen_socket dq 0
  client_socket dq 0

  http_ok_response db "HTTP/1.1 200 OK", 13, 10
  content_type_header db "Content-Type: text/html", 13, 10
  content_length_header db "Content-Length: ", 0
  ; newline db 13, 10, 13, 10

  request_buffer times 1024 db 0

  ; Available routes
  index_route db "GET / ", 0
  about_route db "GET /about ", 0

section .bss
  sockfd resq 1
  sockaddr resb 16

  client_addr resb 16
  client_addr_len resq 1
  clientfd resq 1

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

  ; Bind port
  mov rax, SYS_BIND
  mov rdi, [sockfd]
  lea rsi, [sockaddr]
  mov rdx, 16 ; addrlen
  syscall
  ; Check binding error
  test rax, rax
  js fail_port_bind
  
  ; Listen socket
  mov rax, SYS_LISTEN
  mov rdi, [sockfd]
  mov rsi, BACKLOG
  syscall
  test rax, rax
  js fail_socket_listen

  ; Accept connection
  mov rax, SYS_ACCEPT
  mov rdi, [sockfd]
  lea rsi, [client_addr]
  lea rdx, [client_addr_len]
  mov qword [client_addr_len], 16
  syscall
  test rax, rax
  js fail_connection_accept

  mov [clientfd], rax

  ; normal exit
  mov rax, 60 ; SYS_EXIT
  xor rdi, rdi
  syscall

fail_socket_create:
  mov rdi, 0 ; socket create error
  call print_error

fail_port_bind:
  mov rdi, 1 ; port bind error
  call print_error

fail_socket_listen:
  mov rdi, 2 ; print listen error
  call print_error

fail_connection_accept:
  mov rdi, 3
  call print_error