let
  host = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIzl16KXcQuM5E+EXBfCL5l4CT/HlxQnzi2D42VecyHb guest";
  ksevelyar = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOrgLo+NfYI06fdY1BamC5o2tNeRlw1ZuPAkyy41w0Ir";
in {
  "secrets/wifi.age".publicKeys = [host ksevelyar];
  "secrets/root-password.age".publicKeys = [host ksevelyar];
}
