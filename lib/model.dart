enum ChatMessageType { user, bot }
//logika je da napravimo dva enum koji označavaju korisnika i bot-a tj server

class ChatMessage {
  ChatMessage({
    //treba tekst i tip
    required this.text,
    required this.chatMessageType,
  });

  final String text;
  final ChatMessageType chatMessageType;
}
