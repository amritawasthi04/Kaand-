import 'package:http/http.dart' as http;

void main() async {
  final target = 'https://news.google.com/rss/articles/CBMiuAFBVV95cUxPZGJsTG53bkY5ZkxWREkta0d1X0dnel9lMEF3THBQUzNLTDBLRTBOWEpubUhfb3ZEOWFmRkhBQnZPOTdJQ0xCcXFIQXZMVzE5ajVIYUdfbm44azlhSVBxdktmNzBKaGJjbzhadVg3RGppWDB0anpZMW02RVJuX1Y1NzBfRC1La2FwT0FDV2xlWDRCWnBMLTk3X1QtYUJ0N2xvaVF3ZDVzVzhfdVhPRk11bnNGUnE1RHlr0gHAAUFVX3lxTE5FZXc3RTk0VE12enp3NEc5RXhHakVMRWN6MlhjY1R2eE9NZVVOSTV2MFBibnBWX2FUY0NPVzYzUDZMUG02Rk5XbGlsNlMtVV90bGFFWFNnQ1RlQlg1QUx6X3ZkRmlSNDAtQ0lidXctZ3huUzBra0dsRzhLNWhDaEhMa2RCTmhfSXRyOEQ2aXN6N2xRVEtpbFg0cnZHYWhIY2xMb0QtNElpSkk2RkxtWHhXMHVTMXRqemRmMEd3MFFUaA?oc=5';
  
  print('Fetching HTML from Google News...');
  final response = await http.get(Uri.parse(target));
  final body = response.body;
  
  print('Body length: ${body.length}');
  
  // Search for "ndtv.com" in the html
  final index = body.indexOf('ndtv.com');
  if (index != -1) {
    print('Found "ndtv.com" at index $index');
    final snippet = body.substring(index - 50, index + 150);
    print('Snippet:');
    print(snippet);
  } else {
    print('"ndtv.com" not found in HTML body.');
  }
}
