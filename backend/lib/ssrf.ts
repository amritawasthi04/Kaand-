export function isPrivateUrl(urlStr: string): boolean {
  try {
    const url = new URL(urlStr);
    const hostname = url.hostname.toLowerCase();

    // Block localhost, standard loopback names, and direct IPv6 loopback
    if (hostname === 'localhost' || hostname === 'localhost.localdomain' || hostname === '[::1]' || hostname === '::1') {
      return true;
    }

    // Block private IPv4 ranges:
    // - 127.0.0.0/8 (Loopback)
    // - 10.0.0.0/8 (Private Network)
    // - 172.16.0.0/12 (Private Network)
    // - 192.168.0.0/16 (Private Network)
    // - 169.254.0.0/16 (Link-Local)
    // - 0.0.0.0/8 (Local network)
    if (/^(127\.|10\.|192\.168\.|169\.254\.|0\.)/.test(hostname)) {
      return true;
    }
    if (/^172\.(1[6-9]|2[0-9]|3[0-1])\./.test(hostname)) {
      return true;
    }

    // Block private/local IPv6 ranges:
    // - Link-local (fe80::/10)
    // - Unique local (fc00::/7)
    if (hostname.startsWith('fe80:') || hostname.startsWith('fd00:') || hostname.startsWith('fc00:')) {
      return true;
    }

    return false;
  } catch (_) {
    return true; // Block malformed URLs for safety
  }
}
