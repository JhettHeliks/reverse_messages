import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:file_saver/file_saver.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:intl/intl.dart';

// Data class to hold message information
class Message {
  final String sender;
  final String contentHtml;
  final String timestamp;

  Message({
    required this.sender,
    required this.contentHtml,
    required this.timestamp,
  });
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Facebook Chat Fixer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: const Color(
          0xFFF0F2F5,
        ), // A slightly different background
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blue,
        ).copyWith(surface: const Color(0xFFF0F2F5)),
      ),
      home: const ChatFixerHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ChatFixerHomePage extends StatefulWidget {
  const ChatFixerHomePage({super.key});

  @override
  State<ChatFixerHomePage> createState() => _ChatFixerHomePageState();
}

class _ChatFixerHomePageState extends State<ChatFixerHomePage> {
  String? _fullHtmlForExport;
  List<Message>? _messages;
  String _currentUser = "Justice L Kierstead"; // Default current user
  bool _isLoading = false;
  String? _errorMessage;
  String? _fileName;

  void _resetState() {
    setState(() {
      _fullHtmlForExport = null;
      _messages = null;
      _isLoading = false;
      _errorMessage = null;
      _fileName = null;
    });
  }

  Future<void> _exportFile() async {
    if (_fullHtmlForExport == null || _fileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No file content to export.')),
      );
      return;
    }

    try {
      Uint8List bytes = utf8.encode(_fullHtmlForExport!);
      String originalName = _fileName!;
      String newName = originalName
          .replaceAll('.html', '_fixed.html')
          .replaceAll('.htm', '_fixed.htm');
      if (newName == originalName) {
        newName = '${originalName.split('.').first}_fixed.html';
      }

      await FileSaver.instance.saveFile(
        name: newName,
        bytes: bytes,
        fileExtension: 'html',
        mimeType: MimeType.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully exported to $newName')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error exporting file: $e')));
      }
    }
  }

  Future<void> _pickAndProcessFile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _fileName = null;
      _messages = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['html', 'htm'],
        withData: true,
      );

      if (result == null || result.files.single.bytes == null) {
        setState(() => _isLoading = false);
        return;
      }

      final file = result.files.single;
      final fileBytes = file.bytes!;
      final htmlString = utf8.decode(fileBytes);
      final doc = html_parser.parse(htmlString);

      const messageContainerSelector = 'main._a706';
      final messageContainer = doc.querySelector(messageContainerSelector);
      final headElement = doc.querySelector('head');

      if (messageContainer == null) {
        throw Exception(
          'Could not find the message container. The file structure might have changed.',
        );
      }

      final messageNodes = messageContainer.children.toList();
      if (messageNodes.isEmpty) {
        throw Exception('No message blocks were found inside the container.');
      }

      // Determine the participants to decide message alignment
      final participants = messageNodes
          .map((node) => node.querySelector('h2')?.text.trim())
          .whereType<String>() // keep only non-null strings
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList();

      if (participants.isNotEmpty) {
        // Assume the user running the app is one of the participants.
        // Let's default to the first one if "Justice L Kierstead" isn't found.
        _currentUser = participants.firstWhere(
          (p) => p == "Justice L Kierstead",
          orElse: () => participants.first,
        );
      }

      // --- 1. Process for Flutter UI ---
      final List<Message> parsedMessages = [];
      for (final node in messageNodes) {
        final sender =
            node.querySelector('h2')?.text.trim() ?? 'Unknown Sender';
        final contentNode = node.querySelector('div._2ph_._a6-p > div');
        final contentHtml = contentNode?.innerHtml ?? '';
        final timestamp = node.querySelector('footer div')?.text.trim() ?? '';
        parsedMessages.add(
          Message(
            sender: sender,
            contentHtml: contentHtml,
            timestamp: timestamp,
          ),
        );
      }

      // --- 2. Process for HTML Export ---
      final reversedMessageNodes = messageNodes.reversed.toList();
      messageContainer.innerHtml = '';
      for (final message in reversedMessageNodes) {
        messageContainer.append(message);
      }
      final finalHtmlForExport =
          '<!DOCTYPE html><html>${headElement?.outerHtml ?? ''}${doc.body?.outerHtml ?? ''}</html>';

      setState(() {
        _fileName = file.name;
        _messages = parsedMessages.reversed
            .toList(); // Reverse for chronological display
        _fullHtmlForExport = finalHtmlForExport;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to process file: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Facebook Chat Fixer'), elevation: 1),
      body: Center(child: _buildBody()),
      floatingActionButton: _messages != null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton.extended(
                  onPressed: _exportFile,
                  label: const Text('Export Fixed HTML'),
                  icon: const Icon(Icons.download),
                  heroTag: 'export',
                ),
                const SizedBox(height: 16),
                FloatingActionButton.extended(
                  onPressed: _resetState,
                  label: const Text('Process Another'),
                  icon: const Icon(Icons.refresh),
                  heroTag: 'reset',
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Processing...'),
        ],
      );
    }
    if (_messages != null) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
        itemCount: _messages!.length,
        itemBuilder: (BuildContext context, int index) {
          final message = _messages![index];
          final bool isCurrentUser = message.sender == _currentUser;
          return MessageBubble(message: message, isCurrentUser: isCurrentUser);
        },
      );
    }
    return _buildUploadScreen();
  }

  Widget _buildUploadScreen() {
    // ... This widget remains the same as your previous version ...
    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
      padding: const EdgeInsets.all(20),
      child: Card(
        elevation: 4.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Facebook Chat Fixer',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const Text(
                '(Flutter Edition)',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Newest messages on top? Let's fix that. Upload your exported Facebook HTML file to see it in the correct order.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: _pickAndProcessFile,
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade50,
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.cloud_upload_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Tap here to browse for a file',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_fileName != null)
                        Text(
                          'Selected: $_fileName',
                          style: const TextStyle(color: Colors.black54),
                          textAlign: TextAlign.center,
                        ),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Your file is processed entirely on your device. Nothing is uploaded to any server.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isCurrentUser;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    // Attempt to parse the date for better formatting
    String formattedTimestamp;
    try {
      // Example format: Jul 25, 2024 5:24:35 pm
      final DateFormat inputFormat = DateFormat('MMM d, yyyy h:mm:ss a');
      final DateTime dateTime = inputFormat.parse(message.timestamp);
      // Example format: 5:24 PM
      final DateFormat outputFormat = DateFormat('h:mm a');
      formattedTimestamp = outputFormat.format(dateTime);
    } catch (e) {
      formattedTimestamp = message.timestamp; // Fallback to original
    }

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        decoration: BoxDecoration(
          color: isCurrentUser ? const Color(0xFFD9FDD3) : Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment:
              isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isCurrentUser)
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  message.sender,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                    fontSize: 13,
                  ),
                ),
              ),
            // Use HtmlWidget for rendering the message content
            if (message.contentHtml.isNotEmpty)
              DefaultTextStyle(
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 15,
                  height: 1.3,
                ),
                child: HtmlWidget(
                  message.contentHtml,
                  // You can add custom styling here if needed
                ),
              ),
            const SizedBox(height: 4),
            Text(
              formattedTimestamp,
              style: TextStyle(color: Colors.grey[600], fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
