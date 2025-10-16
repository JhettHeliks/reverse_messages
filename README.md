# Facebook Chat Fixer (Flutter Edition)

## Overview

Facebook Chat Fixer is a cross-platform desktop and mobile application built with Flutter that solves a common frustration with Facebook's data exports. When you download your message history, the resulting HTML file (`message_1.html`) displays conversations in reverse chronological order (newest messages first), making them difficult to read naturally.

This application provides a simple, user-friendly interface to correct this issue, allowing you to view and save your chat history in the proper, chronological order.

## Key Features

- **File Upload:** Easily select your `message_1.html` file using your system's native file picker.
    
- **Message Reversal:** The core logic parses the HTML, identifies individual message blocks, and reverses their order to be chronological (oldest first).
    
- **Google Messages Style UI:** Instead of just showing the raw HTML, the app extracts the sender, timestamp, and message content, then renders it in a clean, familiar chat bubble interface modeled after Google Messages.
    
- **Local Asset Display:** Intelligently locates the root folder of your Facebook data export to correctly display embedded local assets like images, gifs (videos, and audio files coming soon) directly within the chat view.
    
- **HTML Export:** Allows you to save the corrected, full HTML content—with messages in the right order and properly linked local assets—as a new `_fixed.html` file on your device.
    
- **Privacy-Focused:** All processing is done entirely on your local device. Your files and data are never uploaded to any server.
    

## Technology Stack

- **Framework:** Flutter
    
- **Language:** Dart
    
- **Key Packages:**
    
    - `file_picker`: For selecting the input HTML file.
        
    - `html`: For parsing and manipulating the HTML document structure.
        
    - `flutter_widget_from_html_core`: For rendering HTML content as native Flutter widgets.
        
    - `file_saver`: For exporting the corrected HTML file.
        
    - `intl`: For formatting timestamps into a more readable format.
        
    - `path`: For handling and resolving local file paths for assets.
