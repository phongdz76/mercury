import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/bloc.dart';
import '../screens/conversation_list_screen_bloc.dart';

class ChatAppBloc extends StatelessWidget {
  const ChatAppBloc({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ConversationBloc>(create: (context) => ConversationBloc()),
        BlocProvider<MessageBloc>(create: (context) => MessageBloc()),
      ],
      child: MaterialApp(
        title: 'Mercury Chat - BLoC Version',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            elevation: 2,
          ),
        ),
        home: const ConversationListScreenBloc(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
