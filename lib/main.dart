import 'dart:convert';

import 'package:flutter/material.dart';
//za slanje http request koristimo paket zvani http (Kobe reko wow)
import 'package:http/http.dart' as http;
//pogledaj model.dart tu imaš objašenjeno lepo
import 'model.dart';

//klasik shit
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ChatPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

//dve konstante za boju
const backgroundColor = Color.fromARGB(255, 250, 1, 1);
const botBackgroundColor = Color.fromARGB(255, 248, 150, 2);

//klasa chat stranica
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});
//naslešivanje stanja
  @override
  State<ChatPage> createState() => _ChatPageState();
}

//ovo služi za generisanje odgovora od strane servera
//obrati pažnju na upotrebu async await
const apiSecretKey = "ubacisvojapikey";
Future<String> generateResponse(String prompt) async {
  const apiKey = apiSecretKey;

//sa koje adrese generišemo response od api
  var url = Uri.https("api.openai.com", "/v1/completions");
  //format odgovora, bukv zvekno copy paste iz dokumentacije
  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey'
    },
    body: jsonEncode({
      "model": "text-davinci-003",
      "prompt": prompt,
      'temperature': 0,
      'max_tokens': 2000,
      'top_p': 1,
      'frequency_penalty': 0.0,
      'presence_penalty': 0.0,
    }),
  );

  // dekodiraj odgovor
  Map<String, dynamic> newresponse = jsonDecode(response.body);
  return newresponse['choices'][0]['text'];
}

//kontroleri za tekst,skrol, prikaži poruke u listi i bool da li učitava (tru/f)
class _ChatPageState extends State<ChatPage> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  late bool isLoading;

  //initState, flutter ga poziva prilikom kreiranja svakog objekta
  //setite se widget tree za koji sam i ja zaboravio da sam vam objašnjavao jbg
  @override
  void initState() {
    super.initState();
    isLoading = false;
  }

  //ovo je šminka iliti front end
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100,
        title: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            //onaj tekst gore u zaglavlju
            "OpenAI ChatGPT Flutter Fonis",
            maxLines: 2,
            textAlign: TextAlign.center,
          ),
        ),
        //dve konstante za boje
        backgroundColor: botBackgroundColor,
      ),
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _buildList(),
            ),
            Visibility(
              //ako učitava, zvekni onu loading ikonicu
              visible: isLoading,
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  _buildInput(), //linija 132...
                  _buildSubmit(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  //potvrdi
  Widget _buildSubmit() {
    return Visibility(
      visible: !isLoading,
      child: Container(
        color: botBackgroundColor,
        child: IconButton(
          //send ikonica
          icon: const Icon(
            Icons.send_rounded,
            color: Color.fromRGBO(142, 142, 160, 1),
          ),
          //logika-kad se pritisne šalje se poruka preko chatKontrolera
          onPressed: () async {
            setState(
              () {
                _messages.add(
                  ChatMessage(
                    text: _textController.text,
                    chatMessageType:
                        ChatMessageType.user, //model.dart vam određuje tip
                  ),
                );
                isLoading = true; //kad je poslao onda tek učitava tj true
              },
            );
            var input = _textController.text;
            _textController.clear();
            Future.delayed(const Duration(milliseconds: 50)) //koliko "ćeka"
                .then((_) => _scrollDown());
            generateResponse(input).then((value) {
              //generiši odgovor
              setState(() {
                isLoading = false;
                _messages.add(
                  ChatMessage(
                    //sad dobija odgovor od bota
                    text: value,
                    chatMessageType: ChatMessageType.bot,
                  ),
                );
              });
            });
            _textController.clear();
            Future.delayed(const Duration(milliseconds: 50))
                .then((_) => _scrollDown());
          },
        ),
      ),
    );
  }

  //expanded da bi se prilagodilo različitim veličinama ekrana, popunjava mesto na osi
  //bukv kursorom pređi preko Expanded i tu će ti objasniti šta treba, tako i kod svega ostalog
  Expanded _buildInput() {
    return Expanded(
      child: TextField(
        textCapitalization: TextCapitalization.sentences,
        style: const TextStyle(color: Colors.white),
        controller: _textController,
        decoration: const InputDecoration(
          fillColor: botBackgroundColor,
          filled: true,
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
        ),
      ),
    );
  }

  //widget za skrolanje poruka u listi
  ListView _buildList() {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        var message = _messages[index];
        return ChatMessageWidget(
          text: message.text,
          chatMessageType: message.chatMessageType,
        );
      },
    );
  }

  //skroluj, animacija, pozicija, trajanje skrola
  void _scrollDown() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }
}

// widget za chat poruku
class ChatMessageWidget extends StatelessWidget {
  const ChatMessageWidget(
      {super.key, required this.text, required this.chatMessageType});

  final String text;
  final ChatMessageType chatMessageType;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      padding: const EdgeInsets.all(16),
      //u zavisnosti od tipa poruke će biti prikazana pozadina
      //tj da li je unos korisnika ili server response tj bot
      color: chatMessageType == ChatMessageType.bot
          ? botBackgroundColor
          : backgroundColor,
      //horizontalni red dece widget-a (Prežo, ne midgeta ne budi Tarzan)
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          chatMessageType == ChatMessageType.bot
              ? Container(
                  margin: const EdgeInsets.only(right: 16.0),
                  //šminka za bot-a
                  child: CircleAvatar(
                    backgroundColor: const Color.fromRGBO(16, 163, 127, 1),
                    //pogledajte pubspec.yaml dodavanje slike lokalno
                    child: Image.asset(
                      'assets/bot.png', //putanja tj lokacija
                      color: Colors.white, //overlay boja
                      scale: 1.5, //veličina
                    ),
                  ),
                )
              : Container(
                  margin: const EdgeInsets.only(right: 16.0),
                  child: const CircleAvatar(
                    child: Icon(
                      Icons.person,
                    ),
                  ),
                ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                  ),
                  child: Text(
                    text,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
