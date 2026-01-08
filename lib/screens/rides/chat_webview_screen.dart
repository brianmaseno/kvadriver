// lib/presentation/screens/chat_webview_screen.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ChatWebViewScreen extends StatefulWidget {
  final String chatUrl;
  final String passengerName;

  const ChatWebViewScreen({
    Key? key,
    required this.chatUrl,
    required this.passengerName,
  }) : super(key: key);

  @override
  State<ChatWebViewScreen> createState() => _ChatWebViewScreenState();
}

class _ChatWebViewScreenState extends State<ChatWebViewScreen> {
  late final WebViewController controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => isLoading = true),
          onPageFinished: (_) {
            setState(() => isLoading = false);
            // Optional: Make chat look native
            controller.runJavaScript("""
              document.body.style.background = '#f8f9fa';
              document.body.style.margin = '0';
            """);
          },
          onWebResourceError: (error) {
            setState(() => isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.chatUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0066CC),
        title: Text(
          "Chat with ${widget.passengerName}",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF0066CC),
                strokeWidth: 3,
              ),
            ),
        ],
      ),
    );
  }
}