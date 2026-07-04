import 'dart:convert';

void main() {
  final b64 = 'CBMiuAFBVV95cUxPZGJsTG53bkY5ZkxWREkta0d1X0dnel9lMEF3THBQUzNLTDBLRTBOWEpubUhfb3ZEOWFmRkhBQnZPOTdJQ0xCcXFIQXZMVzE5ajVIYUdfbm44azlhSVBxdktmNzBKaGJjbzhadVg3RGppWDB0anpZMW02RVJuX1Y1NzBfRC1La2FwT0FDV2xlWDRCWnBMLTk3X1QtYUJ0N2xvaVF3ZDVzVzhfdVhPRk11bnNGUnE1RHlr0gHAAUFVX3lxTE5FZXc3RTk0VE12enp3NEc5RXhHakVMRWN6MlhjY1R2eE9NZVVOSTV2MFBibnBWX2FUY0NPVzYzUDZMUG02Rk5XbGlsNlMtVV90bGFFWFNnQ1RlQlg1QUx6X3ZkRmlSNDAtQ0lidXctZ3huUzBra0dsRzhLNWhDaEhMa2RCTmhfSXRyOEQ2aXN6N2xRVEtpbFg0cnZHYWhIY2xMb0QtNElpSkk2RkxtWHhXMHVTMXRqemRmMEd3MFFUaA';
  
  var normalized = b64;
  while (normalized.length % 4 != 0) {
    normalized += '=';
  }
  
  try {
    final bytes = base64.decode(normalized);
    final decoded = utf8.decode(bytes, allowMalformed: true);
    print('Decoded:');
    print(decoded);
  } catch (e) {
    print('Error: $e');
  }
}
