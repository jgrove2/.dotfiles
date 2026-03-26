# Wrapper for opencode CLI with TLS certificate handling
#
# This is needed when behind corporate proxies or VPNs that use
# self-signed certificates. The NODE_TLS_REJECT_UNAUTHORIZED=0
# setting disables certificate validation, which is a security risk
# in untrusted environments.
#
# If possible, use one of these safer alternatives:
#   1. Add the corporate CA cert: NODE_EXTRA_CA_CERTS=/path/to/ca.crt opencode "$@"
#   2. Configure your proxy with valid certificates
#   3. Use a VPN client that handles certs properly

opencode() {
  # Only disable TLS validation if not already set (allow explicit override)
  if [ -z "$NODE_TLS_REJECT_UNAUTHORIZED" ]; then
    NODE_TLS_REJECT_UNAUTHORIZED=0 command opencode "$@"
  else
    command opencode "$@"
  fi
}
