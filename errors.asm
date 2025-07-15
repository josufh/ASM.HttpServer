section .data
  error_socket_create_msg db 'Error creating socket', 10
  error_socket_create_len equ $ - error_socket_create_msg

  error_port_bind_msg db 'Error binding port', 10
  error_port_bind_len equ $ - error_port_bind_msg

  error_socket_listen_msg db 'Error listening socket', 10
  error_socket_listen_len equ $ - error_socket_listen_msg

  error_conncetion_accept_msg db 'Error accepting client connection', 10
  error_conncetion_accept_len equ $ - error_conncetion_accept_msg

section .text
  global print_error

print_error:
  ; rdi is the error number
  cmp rdi, 0
  je .socket_create

  cmp rdi, 1
  je .port_bind

  cmp rdi, 2
  je .socket_listen

  cmp rdi, 3
  je .accept_connection

.socket_create:
  mov rsi, error_socket_create_msg
  mov rdx, error_socket_create_len
  jmp .write

.port_bind:
  mov rsi, error_port_bind_msg
  mov rdx, error_port_bind_len
  jmp .write

.socket_listen:
  mov rsi, error_socket_listen_msg
  mov rdx, error_socket_listen_len
  jmp .write

.accept_connection:
  mov rsi, error_conncetion_accept_msg
  mov rdx, error_conncetion_accept_len
  jmp .write

.write:
  mov rax, 1 ; SYS_WRITE
  mov rdi, 2 ; STDERR
  syscall

.done:
  mov rax, 60 ; SYS_EXIT
  mov rdi, 1  ; EXIT CODE 1
  syscall

