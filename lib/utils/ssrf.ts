import dns from 'dns';
import { promisify } from 'util';

const dnsLookup = promisify(dns.lookup);

export function isPrivateIp(ip: string): boolean {
  // IPv4 Private & Loopback addresses (RFC 1918 & RFC 3927 & RFC 5735)
  if (/^(127\.|10\.|192\.168\.|169\.254\.)/.test(ip)) return true;
  if (/^172\.(1[6-9]|2[0-9]|3[0-1])\./.test(ip)) return true;
  
  // IPv6 Private & Local addresses
  if (ip === '::1' || ip === '0:0:0:0:0:0:0:1') return true;
  if (/^(fe[89ab][0-9a-f]:|fc[0-9a-f]{2}:|fd[0-9a-f]{2}:)/i.test(ip)) return true;
  
  return false;
}

export async function validateUrlForSsrf(urlStr: string): Promise<boolean> {
  try {
    const url = new URL(urlStr);
    const hostname = url.hostname;
    
    // If the hostname is a direct IP address, validate it immediately
    if (/^[0-9.]+$/.test(hostname)) {
      return !isPrivateIp(hostname);
    }
    if (/^\[[0-9a-fA-F:]+\]$/.test(hostname)) {
      const ipv6 = hostname.slice(1, -1);
      return !isPrivateIp(ipv6);
    }

    // Otherwise, perform DNS resolution
    const { address } = await dnsLookup(hostname);
    return !isPrivateIp(address);
  } catch (err) {
    console.error(`SSRF validation failed for URL ${urlStr}:`, err);
    return false; // Fail secure: if URL cannot be parsed/resolved, block it
  }
}
